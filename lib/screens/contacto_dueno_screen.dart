import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/auth_widgets.dart';
import 'enviar_notificacion_screen.dart';

/// Se muestra SOLO después de que el usuario confirma un candidato en
/// ResultadosScreen (ver D7 del documento de diseño).
///
/// Si el perro está 'extraviado', se revela el teléfono del dueño para
/// contacto directo (es una emergencia). Si no, probablemente el dueño
/// olvidó actualizar el estado: en vez de teléfono se ofrece enviarle una
/// notificación in-app para avisarle.
class ContactoDuenoScreen extends StatelessWidget {
  final String token;
  final String nombrePerro;
  final Map<String, dynamic> contacto;

  const ContactoDuenoScreen({
    super.key,
    required this.token,
    required this.nombrePerro,
    required this.contacto,
  });

  @override
  Widget build(BuildContext context) {
    final nombreDueno = '${contacto['nombres'] ?? ''} ${contacto['apellidos'] ?? ''}'.trim();
    final extraviado = contacto['estadoMascota'] == 'extraviado';
    final dogId = contacto['dogId'] as String?;

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
                Text(
                  extraviado
                      ? 'Contacta a su dueño para coordinar la devolución'
                      : 'Este perro no está marcado como extraviado. '
                          'Avísale a su dueño por si no se dio cuenta.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 28),
                if (extraviado)
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
                if (dogId != null) ...[
                  if (extraviado) const SizedBox(height: 16),
                  GradientButton(
                    label: 'Avisar al dueño',
                    icon: Icons.notifications_active_outlined,
                    onPressed: () async {
                      final enviado = await showEnviarNotificacionDialog(
                        context,
                        token: token,
                        dogId: dogId,
                        nombrePerro: nombrePerro,
                        tipoOrigen: 'identificacion',
                        extraviado: extraviado,
                      );
                      if (!context.mounted) return;
                      if (enviado) showMensajeEnviadoDialog(context);
                    },
                  ),
                ],
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
