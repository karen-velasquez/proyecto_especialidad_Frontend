import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/dog_form_widgets.dart';
import '../widgets/registro_header.dart';
import 'captura_rostro_screen.dart';
import 'captura_trufa_screen.dart';
import 'resumen_registro_screen.dart';

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
    final datosDog = {
      'nombre': nombre,
      'genero': genero,
      'edadAnios': edadAnios,
      'edadMeses': edadMeses,
      'raza': raza,
      'esterilizado': esterilizado,
      if (esterilizado && codigoEsterilizacion.isNotEmpty)
        'codigoEsterilizacion': codigoEsterilizacion,
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapturaRostroScreen(
          token: widget.token,
          datosDog: datosDog,
          onCompleto: (dogId) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CapturaTrufaScreen(
                  token: widget.token,
                  dogId: dogId,
                  onCompleto: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResumenRegistroScreen(nombrePerro: nombre),
                      ),
                    );
                  },
                ),
              ),
            );
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
              const RegistroHeader(title: 'Datos del perro', paso: 1, total: 4),
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
                          maxLength: 30,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Nombre obligatorio';
                            return v.trim().length >= 2 ? null : 'Mínimo 2 caracteres';
                          },
                          onChanged: (v) => nombre = v,
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
                            maxLength: 30,
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
    List<String> razas;
    try {
      razas = await fetchRazas(widget.token);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
      return;
    }
    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => RazaPicker(razas: razas),
    );
    if (selected != null) setState(() => raza = selected);
  }
}
