import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Botón de selección de género (macho/hembra), usado en el formulario de
/// datos del perro (registro y edición).
class GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const GenderButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

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

/// Slider con valor numérico (años/meses de edad), usado en el formulario
/// de datos del perro.
class NumberSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const NumberSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

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

/// Selector de raza con búsqueda, usado en el formulario de datos del perro.
class RazaPicker extends StatefulWidget {
  final List<String> razas;
  const RazaPicker({super.key, required this.razas});

  @override
  State<RazaPicker> createState() => _RazaPickerState();
}

class _RazaPickerState extends State<RazaPicker> {
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
