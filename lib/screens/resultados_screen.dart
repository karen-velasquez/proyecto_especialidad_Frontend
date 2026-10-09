import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import 'contacto_dueno_screen.dart';
import 'sin_coincidencia_screen.dart';

/// Lista de hasta TOP_K candidatos devueltos por POST /api/identify.
/// El usuario confirma manualmente cuál es el perro correcto (ver D3): el
/// sistema nunca decide solo. Ningún candidato muestra datos del dueño
/// hasta que se confirme (ver D7).
class ResultadosScreen extends StatefulWidget {
  final String token;
  final String consultaId;
  final List<Map<String, dynamic>> candidatos;

  const ResultadosScreen({
    super.key,
    required this.token,
    required this.consultaId,
    required this.candidatos,
  });

  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  bool _confirmando = false;

  Future<void> _confirmar(Map<String, dynamic> candidato) async {
    setState(() => _confirmando = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.identifyUrl}/${widget.consultaId}/confirm'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'dogId': candidato['dogId']}),
      );
      if (!mounted) return;
      setState(() => _confirmando = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ContactoDuenoScreen(
              token: widget.token,
              nombrePerro: candidato['nombre'] ?? 'este perro',
              contacto: data['contacto'] as Map<String, dynamic>,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo confirmar: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirmando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(e))),
      );
    }
  }

  void _ningunoCoincide() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SinCoincidenciaScreen(
          token: widget.token,
          consultaId: widget.consultaId,
        ),
      ),
    );
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
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                    const Expanded(
                      child: Text(
                        'Posibles coincidencias',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: widget.candidatos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CandidatoCard(
                    candidato: widget.candidatos[i],
                    onConfirmar: () => _confirmar(widget.candidatos[i]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: OutlinedButton.icon(
                  onPressed: _confirmando ? null : _ningunoCoincide,
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                  label: const Text('Ninguno coincide', style: TextStyle(color: AppColors.textSecondary)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

class _CandidatoCard extends StatelessWidget {
  final Map<String, dynamic> candidato;
  final VoidCallback onConfirmar;

  const _CandidatoCard({required this.candidato, required this.onConfirmar});

  @override
  Widget build(BuildContext context) {
    final similitud = (candidato['similitud'] as num?)?.toDouble() ?? 0;
    final pct = (similitud * 100).clamp(0, 100).toStringAsFixed(1);
    final similitudCara = (candidato['similitudCara'] as num?)?.toDouble();
    final pctCara = similitudCara == null
        ? null
        : (similitudCara * 100).clamp(0, 100).toStringAsFixed(1);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: candidato['fotoPerfil'] != null
                ? Image.network(
                    candidato['fotoPerfil'],
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidato['nombre'] ?? 'Sin nombre',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  candidato['raza'] ?? '-',
                  style: const TextStyle(color: AppColors.turquoise, fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.turquoise.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$pct% trufa',
                        style: const TextStyle(color: AppColors.turquoise, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (pctCara != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pctCara% cara',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onConfirmar,
            child: const Text('Es este perro', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.turquoise.withValues(alpha: 0.12),
      child: const Icon(Icons.pets, size: 28, color: AppColors.turquoise),
    );
  }
}
