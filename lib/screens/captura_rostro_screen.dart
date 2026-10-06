import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/camera_capture_widget.dart';

/// Captura las MAX_FOTOS_ROSTRO fotos frontales de la cara y las sube en un
/// solo request a POST /api/dogs/:id/rostro. Solo se almacenan (no generan
/// embedding ni se usan para identificar), por eso no necesitan granularidad.
class CapturaRostroScreen extends StatefulWidget {
  final String token;
  final String dogId;
  final VoidCallback onCompleto;

  const CapturaRostroScreen({
    super.key,
    required this.token,
    required this.dogId,
    required this.onCompleto,
  });

  @override
  State<CapturaRostroScreen> createState() => _CapturaRostroScreenState();
}

class _CapturaRostroScreenState extends State<CapturaRostroScreen> {
  bool _subiendo = false;
  String? _error;

  Future<void> _subirFotos(List<String> paths) async {
    setState(() {
      _subiendo = true;
      _error = null;
    });
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.dogsUrl}/${widget.dogId}/rostro'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      for (final path in paths) {
        request.files.add(await http.MultipartFile.fromPath('fotos', path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (!mounted) return;

      if (response.statusCode == 201) {
        widget.onCompleto();
      } else {
        setState(() {
          _subiendo = false;
          _error = 'Error al subir las fotos: ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subiendo = false;
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
            cantidadFotos: BiometricConstants.maxFotosRostro,
            instruccion: 'Estas fotos ayudarán a mejorar\n'
                'la identificación en el futuro',
            permitirLinterna: false,
            onCompleto: (fotos) => _subirFotos(fotos.map((f) => f.path).toList()),
          ),
          if (_subiendo)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.turquoise),
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
