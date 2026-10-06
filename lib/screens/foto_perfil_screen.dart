import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/registro_header.dart';
import '../services/ml/dog_detector.dart';
import '../services/ml/breed_classifier.dart';
import 'captura_rostro_screen.dart';
import 'captura_trufa_screen.dart';
import 'resumen_registro_screen.dart';

/// Paso 2 del registro: 1 foto general del perro (fotoPerfil). Aquí sí se usa
/// dog_detector (verificar que hay un perro) y breed_classifier (sugerir raza
/// como dato descriptivo, ver D5) — igual que hacía add_dog_sheet.dart.
/// Al continuar, crea el perro en el backend (estadoRegistro='incompleto')
/// y pasa a captura_trufa_screen.
class FotoPerfilScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> datos;

  const FotoPerfilScreen({super.key, required this.token, required this.datos});

  @override
  State<FotoPerfilScreen> createState() => _FotoPerfilScreenState();
}

class _FotoPerfilScreenState extends State<FotoPerfilScreen> {
  File? _fotoFile;
  bool _detectando = false;
  bool _creando = false;
  List<BreedResult> _razasDetectadas = [];

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.turquoise),
              title: const Text('Tomar foto', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.turquoise),
              title: const Text('Elegir de galería', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _detectando = true);

    final detector = DogDetector();
    bool hayPerro = false;
    try {
      await detector.load();
      hayPerro = await detector.containsDog(picked.path);
    } finally {
      detector.dispose();
    }

    if (!mounted) return;

    if (!hayPerro) {
      setState(() => _detectando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se detectó un perro en la foto. Intenta de nuevo.')),
      );
      return;
    }

    final razas = await BreedClassifier().classify(picked.path);
    if (!mounted) return;
    setState(() {
      _detectando = false;
      _fotoFile = File(picked.path);
      _razasDetectadas = razas;
    });
  }

  Future<void> _continuar() async {
    setState(() => _creando = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.dogsUrl));
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.fields['nombre'] = widget.datos['nombre'] ?? '';
      request.fields['genero'] = widget.datos['genero'] ?? '';
      request.fields['edadAnios'] = widget.datos['edadAnios'].toString();
      request.fields['edadMeses'] = widget.datos['edadMeses'].toString();
      request.fields['raza'] = widget.datos['raza'] ?? '';
      request.fields['esterilizado'] = widget.datos['esterilizado'].toString();
      if (widget.datos['codigoEsterilizacion'] != null) {
        request.fields['codigoEsterilizacion'] = widget.datos['codigoEsterilizacion'];
      }
      if (_razasDetectadas.isNotEmpty) {
        request.fields['razasDetectadas'] =
            jsonEncode(_razasDetectadas.map((r) => {'raza': r.breed, 'confianza': r.confidence}).toList());
      }
      if (_fotoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', _fotoFile!.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final dogId = data['dog']['_id'] as String;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CapturaTrufaScreen(
              token: widget.token,
              dogId: dogId,
              onCompleto: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CapturaRostroScreen(
                      token: widget.token,
                      dogId: dogId,
                      onCompleto: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResumenRegistroScreen(
                              nombrePerro: widget.datos['nombre'] ?? 'Tu perro',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        setState(() => _creando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _creando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              const RegistroHeader(title: 'Foto del perro', paso: 2, total: 5),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _tomarFoto,
                        child: Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _detectando
                              ? const Center(child: CircularProgressIndicator(color: AppColors.turquoise))
                              : _fotoFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.file(_fotoFile!, fit: BoxFit.cover),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.camera_alt, color: AppColors.turquoise, size: 36),
                                          SizedBox(height: 10),
                                          Text('Agregar foto del perro',
                                              style: TextStyle(color: AppColors.textPrimary)),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                      if (_razasDetectadas.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Raza sugerida (informativo)',
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 8),
                              ..._razasDetectadas.map((r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '${r.breed} · ${(r.confidence * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(color: AppColors.turquoise, fontSize: 12),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Continuar',
                        icon: Icons.arrow_forward,
                        loading: _creando,
                        onPressed: _fotoFile != null ? _continuar : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
