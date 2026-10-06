import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/registro_header.dart';
import 'add_dog_sheet.dart' show kRazas;
import 'foto_perfil_screen.dart';

/// Paso 1 del registro: datos básicos del perro (nombre, género, edad, raza,
/// esterilización). La raza es solo un dato descriptivo (ver D5) y no afecta
/// la identificación biométrica, que ocurre en captura_trufa_screen.
class RegistroDatosScreen extends StatefulWidget {
  final String token;
  const RegistroDatosScreen({super.key, required this.token});

  @override
  State<RegistroDatosScreen> createState() => _RegistroDatosScreenState();
}

class _RegistroDatosScreenState extends State<RegistroDatosScreen> {
  final _formKey = GlobalKey<FormState>();
  String nombre = '';
  String? genero;
  int edadAnios = 0;
  int edadMeses = 0;
  String raza = 'Mestizo';
  bool esterilizado = false;
  String codigoEsterilizacion = '';

  void _continuar() {
    if (genero == null) {
      setState(() {});
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FotoPerfilScreen(
          token: widget.token,
          datos: {
            'nombre': nombre,
            'genero': genero,
            'edadAnios': edadAnios,
            'edadMeses': edadMeses,
            'raza': raza,
            'esterilizado': esterilizado,
            if (esterilizado && codigoEsterilizacion.isNotEmpty)
              'codigoEsterilizacion': codigoEsterilizacion,
          },
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
              const RegistroHeader(title: 'Datos del perro', paso: 1, total: 5),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassInput(
                          label: 'Nombre de la mascota',
                          icon: Icons.pets,
                          validator: (v) => v != null && v.isNotEmpty ? null : 'Nombre obligatorio',
                          onChanged: (v) => nombre = v,
                        ),
                        const SizedBox(height: 20),
                        const Text('Género',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _GenderButton(
                                label: 'Macho',
                                icon: Icons.male,
                                selected: genero == 'macho',
                                onTap: () => setState(() => genero = 'macho'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GenderButton(
                                label: 'Hembra',
                                icon: Icons.female,
                                selected: genero == 'hembra',
                                onTap: () => setState(() => genero = 'hembra'),
                              ),
                            ),
                          ],
                        ),
                        if (genero == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 6, left: 4),
                            child: Text('Selecciona el género',
                                style: TextStyle(color: AppColors.error, fontSize: 12)),
                          ),
                        const SizedBox(height: 20),
                        const Text('Edad',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _NumberSlider(
                                label: 'Años',
                                value: edadAnios,
                                min: 0,
                                max: 20,
                                onChanged: (v) => setState(() => edadAnios = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _NumberSlider(
                                label: 'Meses',
                                value: edadMeses,
                                min: 0,
                                max: 11,
                                onChanged: (v) => setState(() => edadMeses = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('Raza',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectRaza,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.category, color: AppColors.turquoise, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text(raza, style: const TextStyle(color: AppColors.textPrimary))),
                                const Icon(Icons.arrow_drop_down, color: AppColors.turquoise),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('¿Está esterilizado/a?',
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                              Switch(
                                value: esterilizado,
                                activeThumbColor: AppColors.turquoise,
                                onChanged: (v) => setState(() {
                                  esterilizado = v;
                                  if (!v) codigoEsterilizacion = '';
                                }),
                              ),
                            ],
                          ),
                        ),
                        if (esterilizado) ...[
                          const SizedBox(height: 12),
                          GlassInput(
                            label: 'Código de esterilización',
                            icon: Icons.tag,
                            onChanged: (v) => codigoEsterilizacion = v,
                          ),
                        ],
                        const SizedBox(height: 28),
                        GradientButton(label: 'Continuar', icon: Icons.arrow_forward, onPressed: _continuar),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRaza() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RazaPicker(razas: kRazas),
    );
    if (selected != null) setState(() => raza = selected);
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _GenderButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.ctaGradient : null,
          border: Border.all(color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.turquoise, size: 20),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _NumberSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _NumberSlider(
      {required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.turquoise, borderRadius: BorderRadius.circular(20)),
                child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: AppColors.turquoise,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _RazaPicker extends StatefulWidget {
  final List<String> razas;
  const _RazaPicker({required this.razas});

  @override
  State<_RazaPicker> createState() => _RazaPickerState();
}

class _RazaPickerState extends State<_RazaPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.razas.where((r) => r.toLowerCase().contains(query.toLowerCase())).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar raza...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.turquoise),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.pets, color: AppColors.turquoise, size: 18),
                title: Text(filtered[i], style: const TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(context, filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
