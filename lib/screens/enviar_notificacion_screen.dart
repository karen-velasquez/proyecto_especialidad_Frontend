import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';

/// Popup para enviar un mensaje al dueño de un perro (POST /api/notificaciones).
/// El backend solo rechaza el envío si el perro está 'fallecido'.
///
/// [extraviado] cambia los mensajes rápidos sugeridos: si el perro ya está
/// marcado como extraviado, el dueño ya lo sabe y esto es solo un respaldo
/// por si no contesta el teléfono (que también se le muestra aparte).
///
/// Devuelve `true` si el mensaje se envió, para que el llamador muestre la
/// confirmación con su propio `context` (evita usar un context ya cerrado).
Future<bool> showEnviarNotificacionDialog(
  BuildContext context, {
  required String token,
  required String dogId,
  required String nombrePerro,
  required String tipoOrigen,
  bool extraviado = false,
}) async {
  final enviado = await showDialog<bool>(
    context: context,
    builder: (_) => _EnviarNotificacionDialog(
      token: token,
      dogId: dogId,
      nombrePerro: nombrePerro,
      tipoOrigen: tipoOrigen,
      extraviado: extraviado,
    ),
  );
  return enviado ?? false;
}

/// Muestra la confirmación "¡Mensaje enviado!" (mismo estilo que
/// ResumenRegistroScreen). Llamar después de que showEnviarNotificacionDialog
/// resuelva a `true`, usando el `context` del llamador.
void showMensajeEnviadoDialog(BuildContext context) {
  showDialog(context: context, builder: (_) => const _MensajeEnviadoDialog());
}

class _EnviarNotificacionDialog extends StatefulWidget {
  final String token;
  final String dogId;
  final String nombrePerro;
  final String tipoOrigen;
  final bool extraviado;

  const _EnviarNotificacionDialog({
    required this.token,
    required this.dogId,
    required this.nombrePerro,
    required this.tipoOrigen,
    required this.extraviado,
  });

  @override
  State<_EnviarNotificacionDialog> createState() => _EnviarNotificacionDialogState();
}

class _EnviarNotificacionDialogState extends State<_EnviarNotificacionDialog> {
  final _controller = TextEditingController();
  bool _enviando = false;
  String? _error;

  Future<void> _enviar() async {
    final mensaje = _controller.text.trim();
    if (mensaje.isEmpty) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.notificacionesUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'dogId': widget.dogId,
          'mensaje': mensaje,
          'tipoOrigen': widget.tipoOrigen,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        Navigator.of(context).pop(true);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _enviando = false;
          _error = body['error'] ?? 'No se pudo enviar el mensaje';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = mensajeDeError(e);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Avisar sobre ${widget.nombrePerro}',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Mensajes rápidos',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sugerido in widget.extraviado
                      ? NotificacionConstants.mensajesPredeterminadosExtraviado
                      : NotificacionConstants.mensajesPredeterminados)
                    ActionChip(
                      label: Text(sugerido, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      onPressed: () => setState(() => _controller.text = sugerido),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('O escribe tu propio mensaje',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              GlassInput(
                label: 'Mensaje',
                icon: Icons.message_outlined,
                controller: _controller,
                maxLength: NotificacionConstants.maxCaracteres,
                onChanged: (_) {},
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              GradientButton(
                label: 'Enviar',
                icon: Icons.send,
                loading: _enviando,
                onPressed: _enviando ? null : _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmación tras enviar, con el mismo lenguaje visual que
/// ResumenRegistroScreen (ícono circular de check + título + botón).
class _MensajeEnviadoDialog extends StatelessWidget {
  const _MensajeEnviadoDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Mensaje enviado!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'El dueño verá tu aviso en sus notificaciones.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Listo',
              icon: Icons.check,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
