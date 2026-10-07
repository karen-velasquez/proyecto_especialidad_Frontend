import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';

/// Captura [cantidadFotos] fotos con la cámara trasera, mostrando una guía
/// circular de encuadre en vivo. Reutilizado por las pantallas de trufa,
/// rostro e identificación (varía solo la cantidad y el texto de instrucción).
///
/// El reintento tras un rechazo del backend (ej. 422 por calidad) es
/// responsabilidad de la pantalla llamadora: este widget solo captura y,
/// al completar [cantidadFotos], llama [onCompleto]. La pantalla puede volver
/// a mostrar este mismo widget con menos fotos pendientes si necesita repetir una.
class CameraCaptureWidget extends StatefulWidget {
  final int cantidadFotos;
  final String instruccion;
  final void Function(List<XFile> fotos) onCompleto;
  final bool permitirLinterna;
  final bool mostrarGuiaCirculo;

  const CameraCaptureWidget({
    super.key,
    required this.cantidadFotos,
    required this.instruccion,
    required this.onCompleto,
    this.permitirLinterna = true,
    this.mostrarGuiaCirculo = true,
  });

  @override
  State<CameraCaptureWidget> createState() => _CameraCaptureWidgetState();
}

class _CameraCaptureWidgetState extends State<CameraCaptureWidget> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _linternaOn = false;
  bool _capturando = false;
  final List<XFile> _fotos = [];

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    final camaras = await availableCameras();
    final trasera = camaras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => camaras.first,
    );
    _controller = CameraController(trasera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
  }

  Future<void> _subirDeGaleria() async {
    final foto = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (foto == null) return;
    setState(() => _fotos.add(foto));
    if (_fotos.length >= widget.cantidadFotos) {
      widget.onCompleto(List.of(_fotos));
    }
  }

  Future<void> _toggleLinterna() async {
    if (_controller == null) return;
    final nuevo = !_linternaOn;
    await _controller!.setFlashMode(nuevo ? FlashMode.torch : FlashMode.off);
    setState(() => _linternaOn = nuevo);
  }

  Future<void> _tomarFoto() async {
    if (_controller == null || _capturando) return;
    setState(() => _capturando = true);
    try {
      final foto = await _controller!.takePicture();
      setState(() {
        _fotos.add(foto);
        _capturando = false;
      });
      if (_fotos.length >= widget.cantidadFotos) {
        widget.onCompleto(List.of(_fotos));
      }
    } catch (_) {
      setState(() => _capturando = false);
    }
  }

  void _repetirFoto(int index) {
    setState(() => _fotos.removeAt(index));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || _controller == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.turquoise));
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_controller!),
            _buildOverlayCirculo(),
            _buildBotonLinterna(),
            _buildHeader(),
            _buildMiniaturas(),
          ],
        );
      },
    );
  }

  Widget _buildOverlayCirculo() {
    final texto = Padding(
      padding: const EdgeInsets.only(top: 260),
      child: Text(
        widget.instruccion,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Colors.black, blurRadius: 8)],
        ),
      ),
    );
    return IgnorePointer(
      child: widget.mostrarGuiaCirculo
          ? CustomPaint(
              painter: _CirculoGuiaPainter(),
              child: Center(child: texto),
            )
          : Center(child: texto),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Foto ${_fotos.length + 1} de ${widget.cantidadFotos}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonLinterna() {
    if (!widget.permitirLinterna) return const SizedBox.shrink();
    return Positioned(
      top: 170,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _toggleLinterna,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            ),
            child: Icon(
              _linternaOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniaturas() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_fotos.isNotEmpty)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _fotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _repetirFoto(i),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_fotos[i].path),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _subirDeGaleria();
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.photo_library, color: Colors.white, size: 24),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _tomarFoto();
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.ctaGradient,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: _capturando
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 52), // balancea el Row para que el botón de cámara quede centrado
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CirculoGuiaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final radius = size.width * 0.35;

    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.35);
    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, circlePath),
      overlay,
    );

    final borde = Paint()
      ..color = AppColors.turquoise
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borde);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
