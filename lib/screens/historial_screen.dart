import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _cargar();
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
        _error = 'No se pudo conectar: $e';
        _cargando = false;
      });
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
                    const SizedBox(width: 48),
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
                                    final confirmado = c['confirmado'];
                                    return GlassCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  confirmado != null
                                                      ? (confirmado['nombre'] ?? 'Perro confirmado')
                                                      : '${(c['candidatos'] as List?)?.length ?? 0} candidatos',
                                                  style: const TextStyle(
                                                      color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  c['createdAt'] ?? '',
                                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                        ],
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
}
