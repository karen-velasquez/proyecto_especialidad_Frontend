import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/dog_form_widgets.dart';
import 'add_dog_sheet.dart' show kRazas;

/// Edita los datos descriptivos de un perro ya registrado (no toca fotos
/// ni biometría). Mismo formulario que registro_datos_screen.dart, pero
/// pre-poblado y guardando con PUT en vez de crear.
class EditarDatosPerroScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> dog;
  const EditarDatosPerroScreen({super.key, required this.token, required this.dog});

  @override
  State<EditarDatosPerroScreen> createState() => _EditarDatosPerroScreenState();
}

class _EditarDatosPerroScreenState extends State<EditarDatosPerroScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late String? genero;
  late int edadAnios;
  late int edadMeses;
  late String raza;
  late bool esterilizado;
  late final TextEditingController _codigoController;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.dog['nombre'] ?? '');
    genero = widget.dog['genero'];
    edadAnios = widget.dog['edadAnios'] ?? 0;
    edadMeses = widget.dog['edadMeses'] ?? 0;
    raza = widget.dog['raza'] ?? 'Mestizo';
    esterilizado = widget.dog['esterilizado'] == true;
    _codigoController = TextEditingController(text: widget.dog['codigoEsterilizacion'] ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (genero == null) {
      setState(() {});
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.dogsUrl}/${widget.dog['_id']}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': _nombreController.text,
          'genero': genero,
          'edadAnios': edadAnios,
          'edadMeses': edadMeses,
          'raza': raza,
          'esterilizado': esterilizado,
          if (esterilizado) 'codigoEsterilizacion': _codigoController.text,
        }),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar: $e')),
      );
    }
  }

  void _selectRaza() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => RazaPicker(razas: kRazas),
    );
    if (selected != null) setState(() => raza = selected);
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Editar datos',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassInput(
                          controller: _nombreController,
                          label: 'Nombre de la mascota',
                          icon: Icons.pets,
                          maxLength: 30,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Nombre obligatorio';
                            return v.trim().length >= 2 ? null : 'Mínimo 2 caracteres';
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text('Género',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GenderButton(
                                label: 'Macho',
                                icon: Icons.male,
                                selected: genero == 'macho',
                                onTap: () => setState(() => genero = 'macho'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GenderButton(
                                label: 'Hembra',
                                icon: Icons.female,
                                selected: genero == 'hembra',
                                onTap: () => setState(() => genero = 'hembra'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('Edad',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: NumberSlider(
                                label: 'Años',
                                value: edadAnios,
                                min: 0,
                                max: 20,
                                onChanged: (v) => setState(() => edadAnios = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: NumberSlider(
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
                                  if (!v) _codigoController.clear();
                                }),
                              ),
                            ],
                          ),
                        ),
                        if (esterilizado) ...[
                          const SizedBox(height: 12),
                          GlassInput(
                            controller: _codigoController,
                            label: 'Código de esterilización',
                            icon: Icons.tag,
                            maxLength: 30,
                          ),
                        ],
                        const SizedBox(height: 28),
                        GradientButton(
                          label: 'Guardar cambios',
                          icon: Icons.check,
                          loading: _guardando,
                          onPressed: _guardar,
                        ),
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
}
