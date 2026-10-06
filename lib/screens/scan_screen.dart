import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/camera_capture_widget.dart';
import 'resultados_screen.dart';
import 'sin_coincidencia_screen.dart';

/// Pantalla de identificación: toma 1 foto de trufa y la envía a
/// POST /api/identify. El backend devuelve hasta TOP_K candidatos (sin datos
/// de dueño); el usuario confirma manualmente en ResultadosScreen.
class ScanScreen extends StatefulWidget {
  final String token;
  const ScanScreen({super.key, required this.token});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _identificando = false;
  String? _error;
  final Stopwatch _stopwatch = Stopwatch();

  Future<void> _identificar(String path) async {
    setState(() {
      _identificando = true;
      _error = null;
    });
    _stopwatch
      ..reset()
      ..start();
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.identifyUrl));
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(await http.MultipartFile.fromPath('foto', path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _stopwatch.stop();
      // ponytail: medición simple de extremo a extremo para HE2, solo a consola
      debugPrint('Identificación end-to-end: ${_stopwatch.elapsedMilliseconds} ms');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => _identificando = false);
        final candidatos = (data['candidatos'] as List).cast<Map<String, dynamic>>();
        if (candidatos.isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SinCoincidenciaScreen(token: widget.token),
            ),
          );
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultadosScreen(
              token: widget.token,
              consultaId: data['consultaId'],
              candidatos: candidatos,
            ),
          ),
        );
      } else if (response.statusCode == 422) {
        final detalle = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _identificando = false;
          _error = detalle['motivo'] ?? 'Foto rechazada, intenta de nuevo';
        });
      } else {
        setState(() {
          _identificando = false;
          _error = 'Error al identificar: ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _identificando = false;
        _error = 'No se pudo conectar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          CameraCaptureWidget(
            key: const ValueKey('scan'),
            cantidadFotos: 1,
            instruccion: 'Acerca la cámara a la nariz hasta llenar el círculo',
            onCompleto: (fotos) => _identificar(fotos.first.path),
          ),
          if (_identificando)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.turquoise),
                    SizedBox(height: 14),
                    Text('Buscando coincidencias...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 160,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
