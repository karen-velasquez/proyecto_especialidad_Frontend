import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import 'enviar_notificacion_screen.dart';

/// Busca perros por código de esterilización exacto, sin filtrar por
/// propietario (GET /api/dogs/search-by-codigo-esterilizacion).
class BusquedaEsterilizacionScreen extends StatefulWidget {
  final String token;
  final bool mostrarBackButton;
  const BusquedaEsterilizacionScreen({
    super.key,
    required this.token,
    this.mostrarBackButton = true,
  });

  @override
  State<BusquedaEsterilizacionScreen> createState() => _BusquedaEsterilizacionScreenState();
}

class _BusquedaEsterilizacionScreenState extends State<BusquedaEsterilizacionScreen> {
  final _controller = TextEditingController();
  List<dynamic>? _resultados;
  bool _buscando = false;
  String? _error;

  Future<void> _buscar() async {
    final codigo = _controller.text.trim();
    if (codigo.isEmpty) return;
    setState(() {
      _buscando = true;
      _error = null;
      _resultados = null;
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.dogsUrl}/search-by-codigo-esterilizacion?codigo=$codigo'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _resultados = jsonDecode(response.body);
          _buscando = false;
        });
      } else {
        setState(() {
          _error = 'Error al buscar: ${response.body}';
          _buscando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mensajeDeError(e);
        _buscando = false;
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
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    if (widget.mostrarBackButton)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        'Búsqueda por esterilización',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GlassInput(
                        label: 'Código de esterilización',
                        icon: Icons.tag,
                        maxLength: 30,
                        controller: _controller,
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppColors.turquoise),
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: _buscar,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buscando
                    ? const Center(child: CircularProgressIndicator(color: AppColors.turquoise))
                    : _error != null
                        ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                        : _resultados == null
                            ? const Center(
                                child: Text('Ingresa un código y busca',
                                    style: TextStyle(color: AppColors.textSecondary)),
                              )
                            : _resultados!.isEmpty
                                ? const Center(
                                    child: Text('No se encontraron mascotas con ese código',
                                        style: TextStyle(color: AppColors.textSecondary)),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    itemCount: _resultados!.length + 1,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (_, i) {
                                      if (i == 0) {
                                        return const Padding(
                                          padding: EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            'Toca la foto del perro para verla más grande',
                                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                          ),
                                        );
                                      }
                                      final dog = _resultados![i - 1] as Map<String, dynamic>;
                                      final fallecido = dog['estadoMascota'] == 'fallecido';
                                      final owner = fallecido ? null : dog['owner'] as Map<String, dynamic>?;
                                      final fotoPerfil = dog['fotoPerfil'] as String?;
                                      return GlassCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: fotoPerfil != null ? () => _verFoto(fotoPerfil) : null,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
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
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Nombre: ${dog['nombre'] ?? 'Sin nombre'}',
                                                    style: const TextStyle(
                                                        color: AppColors.textPrimary,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text('Raza: ${dog['raza'] ?? '-'}',
                                                      style: const TextStyle(
                                                          color: AppColors.textSecondary, fontSize: 13)),
                                                  if (fallecido) ...[
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.textSecondary.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: const Text(
                                                        'Reportada como fallecida',
                                                        style: TextStyle(
                                                            color: AppColors.textSecondary,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                  if (owner != null) ...[
                                                    const Divider(color: Colors.white12, height: 20),
                                                    Text(
                                                      'Dueño: ${'${owner['nombres'] ?? ''} ${owner['apellidos'] ?? ''}'.trim()}',
                                                      style: const TextStyle(
                                                          color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                                    ),
                                                    if (dog['estadoMascota'] == 'extraviado')
                                                      Text(
                                                        'Tel: ${owner['telefono'] ?? '-'}',
                                                        style: const TextStyle(
                                                            color: AppColors.textSecondary, fontSize: 13),
                                                      ),
                                                    Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: TextButton.icon(
                                                        onPressed: () async {
                                                          final enviado = await showEnviarNotificacionDialog(
                                                            context,
                                                            token: widget.token,
                                                            dogId: dog['_id'],
                                                            nombrePerro: dog['nombre'] ?? 'este perro',
                                                            tipoOrigen: 'esterilizacion',
                                                            extraviado: dog['estadoMascota'] == 'extraviado',
                                                          );
                                                          if (!mounted) return;
                                                          if (enviado) showMensajeEnviadoDialog(context);
                                                        },
                                                        icon: const Icon(Icons.notifications_active_outlined,
                                                            size: 18, color: AppColors.turquoise),
                                                        label: const Text('Avisar al dueño',
                                                            style: TextStyle(color: AppColors.turquoise)),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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

  Widget _fotoFallback() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.pets, size: 28, color: AppColors.turquoise),
    );
  }

  void _verFoto(String foto) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                foto,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
