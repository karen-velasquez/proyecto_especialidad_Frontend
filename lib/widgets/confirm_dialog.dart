import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Diálogo de confirmación genérico para acciones irreversibles o que
/// requieren un paso extra de aviso. Devuelve `true` si el usuario confirma.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool danger = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: danger ? AppColors.error : AppColors.turquoise, size: 40),
            const SizedBox(height: 12),
          ],
          Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: danger ? AppColors.error : AppColors.turquoise),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
