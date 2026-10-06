import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/auth_widgets.dart';

/// Último paso del registro: datos, foto de perfil, trufa y rostro ya se
/// enviaron de forma incremental en cada pantalla anterior (ver
/// registro_datos_screen, foto_perfil_screen, captura_trufa_screen,
/// captura_rostro_screen). Esta pantalla solo confirma que el registro
/// quedó completo y vuelve al inicio.
class ResumenRegistroScreen extends StatelessWidget {
  final String nombrePerro;
  const ResumenRegistroScreen({super.key, required this.nombrePerro});

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
                    color: AppColors.success.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.success, width: 2),
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.success, size: 64),
                ),
                const SizedBox(height: 28),
                Text(
                  '¡$nombrePerro está registrado!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ya puede ser identificado por su trufa nasal en caso de pérdida.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 36),
                GradientButton(
                  label: 'Ir al inicio',
                  icon: Icons.home,
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
