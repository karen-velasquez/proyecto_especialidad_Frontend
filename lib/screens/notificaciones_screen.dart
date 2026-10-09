import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/confirm_dialog.dart';

/// Cómo el remitente llegó al perro: por escaneo biométrico de la trufa
/// (/api/identify) o por búsqueda de código de esterilización.
String _etiquetaTipoOrigen(String? tipo) {
  switch (tipo) {
    case 'identificacion':
      return 'Por escaneo de trufa';
    case 'esterilizacion':
      return 'Por código de esterilización';
    default:
      return 'Origen desconocido';
  }
}

IconData _iconoTipoOrigen(String? tipo) {
  switch (tipo) {
    case 'identificacion':
      return Icons.camera_alt_outlined;
    case 'esterilizacion':
      return Icons.tag;
    default:
      return Icons.help_outline;
  }
}

/// Mensajes entre usuarios sobre un perro. Dos pestañas:
/// - Recibidas (GET /api/notificaciones): mensajes que otros te enviaron.
/// - Enviadas (GET /api/notificaciones/enviadas): para hacer seguimiento de
///   los avisos que tú mandaste.
class NotificacionesScreen extends StatefulWidget {
  final String token;
  const NotificacionesScreen({super.key, required this.token});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<dynamic> _recibidas = [];
  List<dynamic> _enviadas = [];
  bool _cargando = true;
  String? _error;

  int get _noLeidas => _recibidas.where((n) => n['leida'] != true).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final respRecibidas = await http.get(Uri.parse(ApiConstants.notificacionesUrl), headers: headers);
      final respEnviadas =
          await http.get(Uri.parse('${ApiConstants.notificacionesUrl}/enviadas'), headers: headers);
      if (!mounted) return;
      if (respRecibidas.statusCode == 200 && respEnviadas.statusCode == 200) {
        setState(() {
          _recibidas = jsonDecode(respRecibidas.body);
          _enviadas = jsonDecode(respEnviadas.body);
          _cargando = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar notificaciones';
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

  Future<void> _marcarLeida(String id, int index) async {
    try {
      await http.patch(
        Uri.parse('${ApiConstants.notificacionesUrl}/$id/leida'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      setState(() => _recibidas[index]['leida'] = true);
    } catch (_) {
      // Si falla, simplemente se queda como no leída; no bloquea la lectura.
    }
  }

  void _abrirDetalle(Map<String, dynamic> n, {required String etiquetaPersona, required Map<String, dynamic>? persona}) {
    showDialog(
      context: context,
      builder: (_) => _NotificacionDetalleDialog(
        notificacion: n,
        etiquetaPersona: etiquetaPersona,
        persona: persona,
      ),
    );
  }

  Future<void> _eliminarUna(String id, bool esRecibida) async {
    final confirmado = await showConfirmDialog(
      context,
      title: 'Eliminar notificación',
      message: '¿Seguro que quieres eliminar esta notificación? Solo se quitará de tu lista; '
          'la otra persona seguirá viéndola en la suya.',
      confirmLabel: 'Eliminar',
      danger: true,
      icon: Icons.delete_outline,
    );
    if (!confirmado || !mounted) return;

    try {
      await http.delete(
        Uri.parse('${ApiConstants.notificacionesUrl}/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      setState(() {
        if (esRecibida) {
          _recibidas.removeWhere((n) => n['_id'] == id);
        } else {
          _enviadas.removeWhere((n) => n['_id'] == id);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    }
  }

  Future<void> _limpiarBandeja(bool esRecibida) async {
    final lista = esRecibida ? _recibidas : _enviadas;
    if (lista.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes notificaciones para eliminar')),
      );
      return;
    }

    final confirmado = await showConfirmDialog(
      context,
      title: 'Limpiar notificaciones',
      message: esRecibida
          ? '¿Seguro que quieres eliminar todas las notificaciones recibidas? '
              'Solo se quitarán de tu lista; los remitentes seguirán viéndolas en la suya.'
          : '¿Seguro que quieres eliminar todas las notificaciones que enviaste? '
              'Solo se quitarán de tu lista; los destinatarios seguirán viéndolas en la suya.',
      confirmLabel: 'Eliminar todas',
      danger: true,
      icon: Icons.delete_sweep_outlined,
    );
    if (!confirmado || !mounted) return;

    try {
      final bandeja = esRecibida ? 'recibidas' : 'enviadas';
      await http.delete(
        Uri.parse('${ApiConstants.notificacionesUrl}/todas?bandeja=$bandeja'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      setState(() {
        if (esRecibida) {
          _recibidas = [];
        } else {
          _enviadas = [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo limpiar: $e')),
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
                        'Notificaciones',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Limpiar notificaciones',
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                      onPressed: () => _limpiarBandeja(_tabController.index == 0),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.turquoise,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.turquoise,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Recibidas'),
                        if (_noLeidas > 0) ...[
                          const SizedBox(width: 6),
                          _countBadge(_noLeidas),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Enviadas'),
                ],
              ),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator(color: AppColors.turquoise))
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _listaRecibidas(),
                              _listaEnviadas(),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listaRecibidas() {
    if (_recibidas.isEmpty) {
      return const Center(
          child: Text('No tienes notificaciones recibidas', style: TextStyle(color: AppColors.textSecondary)));
    }
    return RefreshIndicator(
      color: AppColors.turquoise,
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _recibidas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = _recibidas[i] as Map<String, dynamic>;
          final dog = n['dog'] as Map<String, dynamic>?;
          final remitente = n['remitente'] as Map<String, dynamic>?;
          final leida = n['leida'] == true;
          return GestureDetector(
            onTap: () {
              if (!leida) _marcarLeida(n['_id'], i);
              _abrirDetalle(n, etiquetaPersona: 'De', persona: remitente);
            },
            child: _NotificacionCard(
              dogNombre: dog?['nombre'],
              mensaje: n['mensaje'] ?? '',
              etiquetaPersona: 'De',
              persona: remitente,
              noLeida: !leida,
              createdAt: n['createdAt'],
              tipoOrigen: n['tipoOrigen'],
              onEliminar: () => _eliminarUna(n['_id'], true),
            ),
          );
        },
      ),
    );
  }

  Widget _listaEnviadas() {
    if (_enviadas.isEmpty) {
      return const Center(
          child: Text('No has enviado notificaciones', style: TextStyle(color: AppColors.textSecondary)));
    }
    return RefreshIndicator(
      color: AppColors.turquoise,
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _enviadas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = _enviadas[i] as Map<String, dynamic>;
          final dog = n['dog'] as Map<String, dynamic>?;
          final destinatario = n['destinatario'] as Map<String, dynamic>?;
          return GestureDetector(
            onTap: () => _abrirDetalle(n, etiquetaPersona: 'Para', persona: destinatario),
            child: _NotificacionCard(
              dogNombre: dog?['nombre'],
              mensaje: n['mensaje'] ?? '',
              etiquetaPersona: 'Para',
              persona: destinatario,
              noLeida: false,
              createdAt: n['createdAt'],
              tipoOrigen: n['tipoOrigen'],
              onEliminar: () => _eliminarUna(n['_id'], false),
            ),
          );
        },
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      constraints: const BoxConstraints(minWidth: 22),
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _NotificacionCard extends StatelessWidget {
  final String? dogNombre;
  final String mensaje;
  final String etiquetaPersona;
  final Map<String, dynamic>? persona;
  final bool noLeida;
  final String? createdAt;
  final String? tipoOrigen;
  final VoidCallback onEliminar;

  const _NotificacionCard({
    required this.dogNombre,
    required this.mensaje,
    required this.etiquetaPersona,
    required this.persona,
    required this.noLeida,
    required this.createdAt,
    required this.tipoOrigen,
    required this.onEliminar,
  });

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
    final nombrePersona = '${persona?['nombres'] ?? ''} ${persona?['apellidos'] ?? ''}'.trim();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (noLeida)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 10),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sobre ${dogNombre ?? 'una mascota'}',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(mensaje, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  '$etiquetaPersona: ${nombrePersona.isNotEmpty ? nombrePersona : '-'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatearFecha(createdAt),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                if (tipoOrigen != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconoTipoOrigen(tipoOrigen), size: 13, color: AppColors.turquoise),
                      const SizedBox(width: 4),
                      Text(_etiquetaTipoOrigen(tipoOrigen),
                          style: const TextStyle(color: AppColors.turquoise, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onEliminar,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Popup con el detalle completo de una notificación: foto del perro,
/// mensaje completo, persona involucrada, fecha y cómo se llegó al perro.
class _NotificacionDetalleDialog extends StatelessWidget {
  final Map<String, dynamic> notificacion;
  final String etiquetaPersona;
  final Map<String, dynamic>? persona;

  const _NotificacionDetalleDialog({
    required this.notificacion,
    required this.etiquetaPersona,
    required this.persona,
  });

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
    final dog = notificacion['dog'] as Map<String, dynamic>?;
    final fotoPerfil = dog?['fotoPerfil'] as String?;
    final nombrePersona = '${persona?['nombres'] ?? ''} ${persona?['apellidos'] ?? ''}'.trim();
    final tipoOrigen = notificacion['tipoOrigen'] as String?;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: fotoPerfil != null
                        ? Image.network(
                            fotoPerfil,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fotoFallback(),
                          )
                        : _fotoFallback(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      dog?['nombre'] ?? 'Mascota',
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
              const Divider(color: Colors.white12, height: 24),
              Text(notificacion['mensaje'] ?? '',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4)),
              const SizedBox(height: 16),
              _fila(Icons.person_outline, etiquetaPersona, nombrePersona.isNotEmpty ? nombrePersona : '-'),
              _fila(Icons.schedule, 'Fecha', _formatearFecha(notificacion['createdAt'])),
              _fila(_iconoTipoOrigen(tipoOrigen), 'Origen', _etiquetaTipoOrigen(tipoOrigen)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fotoFallback() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.pets, size: 28, color: AppColors.turquoise),
    );
  }

  Widget _fila(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.turquoise),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
