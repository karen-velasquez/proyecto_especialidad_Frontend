import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/auth_widgets.dart';

/// Se muestra SOLO después de que el usuario confirma un candidato en
/// ResultadosScreen (ver D7 del documento de diseño): revela el contacto
/// del dueño del perro encontrado.
class ContactoDuenoScreen extends StatelessWidget {
  final String nombrePerro;
  final Map<String, dynamic> contacto;

  const ContactoDuenoScreen({
    super.key,
    required this.nombrePerro,
    required this.contacto,
  });

  @override
  Widget build(BuildContext context) {
    final nombreDueno = '${contacto['nombres'] ?? ''} ${contacto['apellidos'] ?? ''}'.trim();
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
                const SizedBox(height: 24),
                Text(
                  '¡Encontraste a $nombrePerro!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contacta a su dueño para coordinar la devolución',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 28),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fila(Icons.person, 'Dueño', nombreDueno.isNotEmpty ? nombreDueno : '-'),
                      if (contacto['telefono'] != null)
                        _fila(Icons.phone, 'Teléfono', contacto['telefono']),
                      if (contacto['email'] != null &&
                          (contacto['email'] as String).isNotEmpty)
                        _fila(Icons.email, 'Correo', contacto['email']),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                GradientButton(
                  label: 'Listo',
                  icon: Icons.check,
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fila(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.turquoise),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
