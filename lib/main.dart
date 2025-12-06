import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await WakelockPlus.enable();

  runApp(const PMTDisplayApp());
}

class PMTDisplayApp extends StatelessWidget {
  const PMTDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ProMultiTech Display',
      debugShowCheckedModeBanner: false,
      home: SignageScreen(),
    );
  }
}

class SignageScreen extends StatefulWidget {
  const SignageScreen({super.key});

  @override
  State<SignageScreen> createState() => _SignageScreenState();
}

//Quitar (o dejar opcional) el cuadrito de debug
const bool kShowDebugOverlay = true;


class _SignageScreenState extends State<SignageScreen> {
  static const String displayId = 'SantaSpanish';

  static const String baseConfigUrl =
      'https://luisprz.github.io/pmt-signage/screens/gala-deli';

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
        '$baseConfigUrl/$displayId.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final newImageUrl = data['image_url'] as String?;
      final newReloadSeconds = (data['reload_seconds'] as int?) ?? 300;

      if (newImageUrl == null || newImageUrl.isEmpty) {
        throw Exception("JSON sin 'image_url' válido");
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
      _timer = Timer(
        const Duration(seconds: 30),
        () => _loadConfigAndImage(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen principal o fallback
          _imageUrl == null
              ? Image.asset(
                  'assets/fallback.jpeg',
                  fit: BoxFit.cover,
                )
              : CachedNetworkImage(
                  imageUrl: _imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Image.asset(
                    'assets/fallback.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),

          // 🔹 Overlay de debug SOLO si kShowDebugOverlay = true
          if (kShowDebugOverlay)
            Positioned(
              left: 12,
              bottom: 12,
              child: Opacity(
                opacity: 0.7,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: $displayId'),
                        Text('Loading: $_loading'),
                        Text('URL: ${_imageUrl ?? "fallback"}'),
                        if (_errorMessage != null)
                          SizedBox(
                            width: 260,
                            child: Text(
                              'Error: $_errorMessage',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
