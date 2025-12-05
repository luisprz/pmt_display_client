import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pantalla completa sin barras
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Mantener pantalla encendida
  await WakelockPlus.enable();

  runApp(const PMTDisplayApp());
}

class PMTDisplayApp extends StatelessWidget {
  const PMTDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProMultiTech Display',
      debugShowCheckedModeBanner: false,
      home: const SignageScreen(),
    );
  }
}

class SignageScreen extends StatefulWidget {
  const SignageScreen({super.key});

  @override
  State<SignageScreen> createState() => _SignageScreenState();
}

class _SignageScreenState extends State<SignageScreen> {
  // Cambia este ID por cada pantalla
  static const String displayId = 'gala-deli';

  // Cambia esto por TU URL de GitHub Pages
  static const String baseConfigUrl =
      'https://luisprz.github.io/pmt-signage/screens';

  String? _imageUrl;
  int _reloadSeconds = 300; 
  Timer? _timer;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfigAndImage();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadConfigAndImage() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '$baseConfigUrl/$displayId.json?t=${DateTime.now().millisecondsSinceEpoch}'
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body);

      final newImageUrl = data['image_url'];
      final newReloadSeconds = data['reload_seconds'] ?? 300;

      if (newImageUrl == null) {
        throw Exception("JSON sin 'image_url'");
      }

      setState(() {
        _imageUrl = newImageUrl;
        _reloadSeconds = newReloadSeconds;
        _loading = false;
      });

      _timer?.cancel();
      _timer = Timer.periodic(
        Duration(seconds: _reloadSeconds),
        (_) => _loadConfigAndImage(),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });

      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 30), () => _loadConfigAndImage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _imageUrl == null
          ? Image.asset("assets/fallback.jpg", fit: BoxFit.cover)
          : CachedNetworkImage(
              imageUrl: _imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Image.asset("assets/fallback.jpg", fit: BoxFit.cover),
            ),
    );
  }
}
