import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/camera_capture_widget.dart';

/// Captura las MIN_FOTOS_TRUFA fotos de trufa del perro recién creado y las
/// sube una por una a POST /api/dogs/:id/trufa. Si el backend rechaza una por
/// calidad (422), se descarta y se pide repetir solo esa (no las demás).
class CapturaTrufaScreen extends StatefulWidget {
  final String token;
  final String dogId;
  final VoidCallback onCompleto;

  const CapturaTrufaScreen({
    super.key,
    required this.token,
    required this.dogId,
    required this.onCompleto,
  });

  @override
  State<CapturaTrufaScreen> createState() => _CapturaTrufaScreenState();
}

class _CapturaTrufaScreenState extends State<CapturaTrufaScreen> {
  int _subidas = 0;
  int _intentos = 0;
  bool _subiendo = false;
  String? _error;

  Future<void> _subirFoto(String path) async {
    setState(() {
      _subiendo = true;
      _error = null;
    });
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.dogsUrl}/${widget.dogId}/trufa'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(await http.MultipartFile.fromPath('foto', path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 201) {
        setState(() {
          _subidas++;
          _intentos++;
          _subiendo = false;
        });
        if (_subidas >= BiometricConstants.minFotosTrufa) {
          widget.onCompleto();
        }
      } else if (response.statusCode == 422) {
        final detalle = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _intentos++;
          _subiendo = false;
          _error = detalle['motivo'] ?? 'Foto rechazada, intenta de nuevo';
        });
      } else {
        setState(() {
          _intentos++;
          _subiendo = false;
          _error = 'Error al subir la foto: ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _intentos++;
        _subiendo = false;
        _error = mensajeDeError(e);
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
            key: ValueKey(_intentos), // recrea el widget tras cada intento (éxito o rechazo) para limpiar la miniatura
            cantidadFotos: 1,
            instruccion: 'Acerca la cámara a la nariz hasta llenar el círculo\n'
                'Foto ${_subidas + 1} de ${BiometricConstants.minFotosTrufa}',
            onCompleto: (fotos) => _subirFoto(fotos.first.path),
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
