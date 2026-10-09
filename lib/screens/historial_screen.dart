import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/confirm_dialog.dart';
import 'enviar_notificacion_screen.dart';

/// Historial de identificaciones del usuario autenticado (GET /api/identify/historial).
class HistorialScreen extends StatefulWidget {
  final String token;
  const HistorialScreen({super.key, required this.token});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<dynamic> _consultas = [];
  bool _cargando = true;
  String? _error;

  /// Para distinguir los perros propios: a uno mismo no tiene sentido
  /// "avisarle" (el backend además rechaza esa notificación con 400).
  String? _miUsuarioId;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarMiUsuario();
  }

  Future<void> _cargarMiUsuario() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.usersUrl}/me'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted || response.statusCode != 200) return;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() => _miUsuarioId = data['_id']);
    } catch (_) {
      // Si falla, simplemente no se marca "Tu mascota"; no bloquea el historial.
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.identifyUrl}/historial'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _consultas = jsonDecode(response.body);
          _cargando = false;
        });
      } else {
        setState(() {
          _error = 'Error: ${response.body}';
          _cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mensajeDeError(e);
        _cargando = false;
      });
    }
  }

  Future<void> _eliminarUna(String consultaId) async {
    final confirmado = await showConfirmDialog(
      context,
      title: 'Eliminar identificación',
      message: '¿Seguro que quieres eliminar esta identificación de tu historial?',
      confirmLabel: 'Eliminar',
      danger: true,
      icon: Icons.delete_outline,
    );
    if (!confirmado || !mounted) return;

    try {
      await http.delete(
        Uri.parse('${ApiConstants.identifyUrl}/$consultaId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      setState(() => _consultas.removeWhere((c) => c['_id'] == consultaId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e))),
      );
    }
  }

  Future<void> _limpiarHistorial() async {
    if (_consultas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes identificaciones para eliminar')),
      );
      return;
    }

    final confirmado = await showConfirmDialog(
      context,
      title: 'Limpiar historial',
      message: '¿Seguro que quieres eliminar todo tu historial de identificaciones?',
      confirmLabel: 'Eliminar todas',
      danger: true,
      icon: Icons.delete_sweep_outlined,
    );
    if (!confirmado || !mounted) return;

    try {
      await http.delete(
        Uri.parse('${ApiConstants.identifyUrl}/historial/todas'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      setState(() => _consultas = []);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e))),
      );
    }
  }

  String _estadoLabel(String estado) {
    switch (estado) {
      case 'confirmado':
        return 'Confirmado';
      case 'sin_coincidencia':
        return 'Sin coincidencia';
      default:
        return 'Pendiente';
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'confirmado':
        return AppColors.success;
      case 'sin_coincidencia':
        return AppColors.error;
      default:
        return AppColors.turquoise;
    }
  }

  String _formatearFecha(String? iso) {
    if (iso == null) return '';
    final fecha = DateTime.tryParse(iso);
    if (fecha == null) return iso;
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year} · $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Historial de identificaciones',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Limpiar historial',
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                      onPressed: _limpiarHistorial,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator(color: AppColors.turquoise))
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                        : _consultas.isEmpty
                            ? const Center(
                                child: Text('Aún no tienes identificaciones',
                                    style: TextStyle(color: AppColors.textSecondary)),
                              )
                            : RefreshIndicator(
                                color: AppColors.turquoise,
                                onRefresh: _cargar,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  itemCount: _consultas.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final c = _consultas[i] as Map<String, dynamic>;
                                    final estado = c['estado'] ?? 'pendiente';
                                    final confirmado = c['confirmado'] as Map<String, dynamic>?;
                                    final candidatos = (c['candidatos'] as List?) ?? [];
                                    final mejorSimilitud = candidatos.isEmpty
                                        ? null
                                        : candidatos
                                            .map((cand) => (cand['similitud'] as num?)?.toDouble() ?? 0)
                                            .reduce((a, b) => a > b ? a : b);
                                    final tiempos = c['tiempos'] as Map<String, dynamic>?;

                                    return GestureDetector(
                                      onTap: candidatos.isEmpty
                                          ? null
                                          : () => _verCandidatos(c),
                                      child: GlassCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: confirmado?['fotoPerfil'] != null
                                                    ? Image.network(
                                                        confirmado!['fotoPerfil'],
                                                        width: 56,
                                                        height: 56,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => _fotoFallback(),
                                                      )
                                                    : _fotoFallback(),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            confirmado != null
                                                                ? (confirmado['nombre'] ?? 'Perro confirmado')
                                                                : '${candidatos.length} candidato${candidatos.length == 1 ? '' : 's'} encontrado${candidatos.length == 1 ? '' : 's'}',
                                                            style: const TextStyle(
                                                                color: AppColors.textPrimary,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 15),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: _estadoColor(estado).withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            _estadoLabel(estado),
                                                            style: TextStyle(
                                                                color: _estadoColor(estado),
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        GestureDetector(
                                                          onTap: () => _eliminarUna(c['_id']),
                                                          child: const Icon(Icons.delete_outline,
                                                              size: 18, color: AppColors.textSecondary),
                                                        ),
                                                      ],
                                                    ),
                                                    if (confirmado?['raza'] != null) ...[
                                                      const SizedBox(height: 2),
                                                      Text('Raza: ${confirmado!['raza']}',
                                                          style: const TextStyle(
                                                              color: AppColors.turquoise, fontSize: 12)),
                                                    ],
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _formatearFecha(c['createdAt']),
                                                      style: const TextStyle(
                                                          color: AppColors.textSecondary, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (mejorSimilitud != null || tiempos?['total_ms'] != null) ...[
                                            const Divider(color: Colors.white12, height: 20),
                                            Row(
                                              children: [
                                                if (mejorSimilitud != null)
                                                  Expanded(
                                                    child: Text(
                                                      'Mejor similitud: ${(mejorSimilitud * 100).clamp(0, 100).toStringAsFixed(1)}%',
                                                      style: const TextStyle(
                                                          color: AppColors.textSecondary, fontSize: 11),
                                                    ),
                                                  ),
                                                if (tiempos?['total_ms'] != null)
                                                  Text(
                                                    'Procesado en ${(tiempos!['total_ms'] as num).toStringAsFixed(0)} ms',
                                                    style: const TextStyle(
                                                        color: AppColors.textSecondary, fontSize: 11),
                                                  ),
                                              ],
                                            ),
                                          ],
                                          if (confirmado != null) ...[
                                            const Divider(color: Colors.white12, height: 20),
                                            Builder(builder: (_) {
                                              final owner =
                                                  confirmado['owner'] as Map<String, dynamic>?;
                                              final esPropio =
                                                  _miUsuarioId != null && owner?['_id'] == _miUsuarioId;

                                              if (esPropio) {
                                                return Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.turquoise.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: const Text(
                                                        'Es tu mascota',
                                                        style: TextStyle(
                                                            color: AppColors.turquoise,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }

                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (confirmado['estadoMascota'] == 'extraviado') ...[
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 8, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.error.withValues(alpha: 0.15),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: const Text(
                                                            'Extraviado',
                                                            style: TextStyle(
                                                                color: AppColors.error,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        if (owner?['telefono'] != null)
                                                          Expanded(
                                                            child: Text(
                                                              'Tel: ${owner!['telefono']}',
                                                              style: const TextStyle(
                                                                  color: AppColors.textPrimary,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                  ],
                                                  TextButton.icon(
                                                    onPressed: () => _avisarDueno(confirmado),
                                                    icon: const Icon(Icons.notifications_active_outlined,
                                                        size: 18, color: AppColors.turquoise),
                                                    label: const Text('Avisar al dueño',
                                                        style: TextStyle(color: AppColors.turquoise)),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ],
                                          if (candidatos.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  estado == 'pendiente'
                                                      ? 'Ver y confirmar candidatos'
                                                      : 'Ver candidatos',
                                                  style: const TextStyle(
                                                      color: AppColors.turquoise, fontSize: 11),
                                                ),
                                                const Icon(Icons.chevron_right,
                                                    color: AppColors.turquoise, size: 16),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fotoFallback() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.pets, size: 24, color: AppColors.turquoise),
    );
  }

  /// Lista los perros que el sistema propuso en esa consulta, ordenados por
  /// similitud, marcando cuál fue el confirmado (si el usuario confirmó alguno).
  void _verCandidatos(Map<String, dynamic> consulta) {
    final candidatos = List<Map<String, dynamic>>.from(consulta['candidatos'] ?? [])
      ..sort((a, b) {
        final sa = (a['similitud'] as num?)?.toDouble() ?? 0;
        final sb = (b['similitud'] as num?)?.toDouble() ?? 0;
        return sb.compareTo(sa);
      });
    final confirmadoId = (consulta['confirmado'] as Map<String, dynamic>?)?['_id'];
    // Solo una consulta pendiente admite confirmar: ya confirmada o descartada,
    // la decisión está tomada (ver identify.service.js#confirmar).
    final pendiente = (consulta['estado'] ?? 'pendiente') == 'pendiente';
    final consultaId = consulta['_id'] as String;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Candidatos propuestos',
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatearFecha(consulta['createdAt']),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const Divider(color: Colors.white12, height: 24),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidatos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final cand = candidatos[i];
                    final dog = cand['dog'] as Map<String, dynamic>?;
                    final similitud = (cand['similitud'] as num?)?.toDouble() ?? 0;
                    final pct = (similitud * 100).clamp(0, 100).toStringAsFixed(1);
                    final similitudCara = (cand['similitudCara'] as num?)?.toDouble();
                    final pctCara = similitudCara == null
                        ? null
                        : (similitudCara * 100).clamp(0, 100).toStringAsFixed(1);
                    final esConfirmado = dog != null && dog['_id'] == confirmadoId;

                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: dog?['fotoPerfil'] != null
                              ? Image.network(
                                  dog!['fotoPerfil'],
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _fotoMini(),
                                )
                              : _fotoMini(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dog?['nombre'] ?? 'Perro sin nombre',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (esConfirmado)
                                    const Icon(Icons.check_circle,
                                        color: AppColors.success, size: 18),
                                ],
                              ),
                              if (dog?['raza'] != null)
                                Text(dog!['raza'],
                                    style: const TextStyle(
                                        color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text('$pct% trufa',
                                      style: const TextStyle(
                                          color: AppColors.turquoise, fontSize: 11)),
                                  if (pctCara != null)
                                    Text('$pctCara% cara',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (pendiente && dog != null)
                          TextButton(
                            onPressed: () => _confirmarCandidato(consultaId, dog),
                            child: const Text('Es este',
                                style: TextStyle(
                                    color: AppColors.success, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fotoMini() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.pets, size: 22, color: AppColors.turquoise),
    );
  }

  /// Envía un mensaje al dueño del perro confirmado en esa identificación.
  Future<void> _avisarDueno(Map<String, dynamic> confirmado) async {
    final enviado = await showEnviarNotificacionDialog(
      context,
      token: widget.token,
      dogId: confirmado['_id'],
      nombrePerro: confirmado['nombre'] ?? 'este perro',
      tipoOrigen: 'identificacion',
      extraviado: confirmado['estadoMascota'] == 'extraviado',
    );
    if (!mounted) return;
    if (enviado) showMensajeEnviadoDialog(context);
  }

  /// Confirma desde el historial que uno de los candidatos era el perro
  /// buscado (POST /api/identify/:id/confirm), para consultas que quedaron
  /// pendientes sin tener que volver a escanear.
  Future<void> _confirmarCandidato(String consultaId, Map<String, dynamic> dog) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.identifyUrl}/$consultaId/confirm'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'dogId': dog['_id']}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pop(context); // cierra el popup de candidatos
        await _cargar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo confirmar: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e))),
      );
    }
  }
}
