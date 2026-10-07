import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/camera_capture_widget.dart';

/// Captura las MAX_FOTOS_ROSTRO fotos frontales de la cara.
///
/// Dos modos, exactamente uno de [dogId]/[datosDog] debe venir no-nulo:
/// - Re-captura biométrica ([dogId]): el perro ya existe, solo se suben las
///   fotos a POST /api/dogs/:id/rostro (comportamiento original).
/// - Registro nuevo ([datosDog]): el perro todavía no existe. La PRIMERA foto
///   de rostro se envía como fotoPerfil al crear el perro (POST /api/dogs),
///   y luego se suben ambas fotos a /rostro igual que en el otro modo.
class CapturaRostroScreen extends StatefulWidget {
  final String token;
  final String? dogId;
  final Map<String, dynamic>? datosDog;
  final void Function(String dogId) onCompleto;

  const CapturaRostroScreen({
    super.key,
    required this.token,
    this.dogId,
    this.datosDog,
    required this.onCompleto,
  }) : assert(
          (dogId == null) != (datosDog == null),
          'Pasa exactamente uno de dogId (re-captura) o datosDog (registro nuevo)',
        );

  @override
  State<CapturaRostroScreen> createState() => _CapturaRostroScreenState();
}

class _CapturaRostroScreenState extends State<CapturaRostroScreen> {
  bool _subiendo = false;
  String? _error;

  /// Crea el perro usando la primera foto de rostro como fotoPerfil.
  /// @returns el dogId del perro recién creado.
  Future<String> _crearPerro(String fotoPerfilPath) async {
    final datos = widget.datosDog!;
    final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.dogsUrl));
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.fields['nombre'] = datos['nombre'] ?? '';
    request.fields['genero'] = datos['genero'] ?? '';
    request.fields['edadAnios'] = datos['edadAnios'].toString();
    request.fields['edadMeses'] = datos['edadMeses'].toString();
    request.fields['raza'] = datos['raza'] ?? '';
    request.fields['esterilizado'] = datos['esterilizado'].toString();
    if (datos['codigoEsterilizacion'] != null) {
      request.fields['codigoEsterilizacion'] = datos['codigoEsterilizacion'];
    }
    request.files.add(await http.MultipartFile.fromPath('foto', fotoPerfilPath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw Exception('Error al registrar: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['dog']['_id'] as String;
  }

  Future<void> _subirFotosRostro(String dogId, List<String> paths) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.dogsUrl}/$dogId/rostro'),
    );
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    for (final path in paths) {
      request.files.add(await http.MultipartFile.fromPath('fotos', path));
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw Exception('Error al subir las fotos: ${response.body}');
    }
  }

  Future<void> _procesarFotos(List<String> paths) async {
    setState(() {
      _subiendo = true;
      _error = null;
    });
    try {
      final dogId = widget.dogId ?? await _crearPerro(paths.first);
      await _subirFotosRostro(dogId, paths);
      if (!mounted) return;
      widget.onCompleto(dogId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subiendo = false;
        _error = '$e'.replaceFirst('Exception: ', '');
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
            mostrarGuiaCirculo: false,
            instruccion: widget.dogId == null
                ? 'Toma 2 fotos del rostro de tu perro\n'
                    'la primera será su foto de perfil'
                : 'Estas fotos ayudarán a mejorar\n'
                    'la identificación en el futuro',
            permitirLinterna: false,
            onCompleto: (fotos) => _procesarFotos(fotos.map((f) => f.path).toList()),
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
