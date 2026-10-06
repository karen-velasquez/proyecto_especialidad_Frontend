import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';

/// Se muestra cuando /api/identify no devuelve candidatos, o cuando el
/// usuario eligió "Ninguno coincide" en ResultadosScreen.
class SinCoincidenciaScreen extends StatefulWidget {
  final String token;
  final String? consultaId;

  const SinCoincidenciaScreen({super.key, required this.token, this.consultaId});

  @override
  State<SinCoincidenciaScreen> createState() => _SinCoincidenciaScreenState();
}

class _SinCoincidenciaScreenState extends State<SinCoincidenciaScreen> {
  @override
  void initState() {
    super.initState();
    _marcarSinCoincidencia();
  }

  Future<void> _marcarSinCoincidencia() async {
    if (widget.consultaId == null) return;
    try {
      await http.post(
        Uri.parse('${ApiConstants.identifyUrl}/${widget.consultaId}/sin-coincidencia'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.error, width: 2),
                  ),
                  child: const Icon(Icons.search_off, color: AppColors.error, size: 64),
                ),
                const SizedBox(height: 28),
                const Text(
                  'No encontramos coincidencias',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ningún perro registrado coincide con esta foto. '
                  'Puedes intentar con otra foto de la trufa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 36),
                GradientButton(
                  label: 'Volver',
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
