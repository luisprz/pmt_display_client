import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';

// Configuración por pantalla (la cambias para cada negocio/pantalla)
const String kDisplayId = 'gala-deli-playlist'; 
const String kBaseConfigUrl =
    'https://luisprz.github.io/pmt-signage/screens/gala-deli';

// Mostrar cuadrito de debug abajo a la izquierda
const bool kShowDebugOverlay = true;

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

class _SignageScreenState extends State<SignageScreen> {
  String _mode = 'single'; // 'single' o 'playlist'
  String? _currentImageUrl;
  List<String> _playlist = [];
  int _currentIndex = 0;

  int _rotationSeconds = 0; // para playlist
  int _refreshSeconds = 300; // para recargar JSON

  Timer? _rotationTimer;
  Timer? _refreshTimer;

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfigFromServer();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConfigFromServer() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    // Cancelar timers anteriores
    _rotationTimer?.cancel();
    _refreshTimer?.cancel();

    try {
      final uri = Uri.parse(
        '$kBaseConfigUrl/$kDisplayId.json?t=${DateTime.now().millisecondsSinceEpoch}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final String mode = (data['mode'] as String?)?.toLowerCase() ?? 'single';
      final int refreshSeconds = (data['refresh_seconds'] as int?) ?? 300;

      String? singleUrl;
      List<String> playlist = [];
      int rotationSeconds = 0;

      if (mode == 'playlist') {
        final rawImages = data['images'];
        if (rawImages is List) {
          playlist = rawImages
              .whereType<String>()
              .where((url) => url.isNotEmpty)
              .toList();
        }
        rotationSeconds = (data['rotation_seconds'] as int?) ?? 15;
        if (playlist.isEmpty) {
          throw Exception("Playlist vacía en modo 'playlist'.");
        }
      } else {
        // modo single
        singleUrl = data['image_url'] as String?;
        if (singleUrl == null || singleUrl.isEmpty) {
          throw Exception("Falta 'image_url' en modo 'single'.");
        }
      }

      setState(() {
        _mode = mode;
        _refreshSeconds = refreshSeconds;
        _rotationSeconds = rotationSeconds;
        _playlist = playlist;
        _currentIndex = 0;

        if (_mode == 'playlist') {
          _currentImageUrl = _playlist.first;
        } else {
          _currentImageUrl = singleUrl;
        }

        _loading = false;
      });

      // Timer para recargar el JSON periódicamente
      _refreshTimer = Timer.periodic(
        Duration(seconds: _refreshSeconds),
        (_) => _loadConfigFromServer(),
      );

      // Timer para rotar imágenes en modo playlist
      if (_mode == 'playlist' &&
          _playlist.length > 1 &&
          _rotationSeconds > 0) {
        _rotationTimer = Timer.periodic(
          Duration(seconds: _rotationSeconds),
          (_) {
            setState(() {
              _currentIndex = (_currentIndex + 1) % _playlist.length;
              _currentImageUrl = _playlist[_currentIndex];
            });
          },
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });

      // En caso de error, reintentar cargar config después de 30s
      _refreshTimer = Timer(
        const Duration(seconds: 30),
        () => _loadConfigFromServer(),
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
          _currentImageUrl == null
              ? Image.asset(
                  'assets/fallback.jpg',
                  fit: BoxFit.cover,
                )
              : CachedNetworkImage(
                  imageUrl: _currentImageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Image.asset(
                    'assets/fallback.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

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
                        Text('ID: $kDisplayId'),
                        Text('Mode: $_mode'),
                        Text('Loading: $_loading'),
                        Text('Current: ${_currentImageUrl ?? "fallback"}'),
                        Text('Rotation: $_rotationSeconds s'),
                        Text('Refresh: $_refreshSeconds s'),
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
