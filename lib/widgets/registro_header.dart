import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Encabezado con botón de retroceso y barra de progreso, compartido por las
/// pantallas del flujo de registro (datos, foto de perfil, trufa, rostro, resumen).
class RegistroHeader extends StatelessWidget {
  final String title;
  final int paso;
  final int total;

  const RegistroHeader({super.key, required this.title, required this.paso, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: paso / total,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(AppColors.turquoise),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
