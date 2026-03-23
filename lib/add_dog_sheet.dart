import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_colors.dart';
import 'dog_detector.dart';

const List<String> kRazas = [
  'Mestizo',
  'Akita',
  'Australian Shepherd',
  'Basset Hound',
  'Beagle',
  'Bernese Mountain Dog',
  'Bichón Frisé',
  'Border Collie',
  'Boxer',
  'Bulldog Francés',
  'Bulldog Inglés',
  'Chihuahua',
  'Chow Chow',
  'Cocker Spaniel',
  'Dachshund',
  'Dálmata',
  'Dobermann',
  'Golden Retriever',
  'Gran Danés',
  'Labrador Retriever',
  'Maltés',
  'Pastor Alemán',
  'Pitbull',
  'Pomerania',
  'Poodle',
  'Pug',
  'Rottweiler',
  'Samoyedo',
  'Schnauzer',
  'Shar Pei',
  'Shiba Inu',
  'Shih Tzu',
  'Siberian Husky',
  'Weimaraner',
  'Yorkshire Terrier',
];

class AddDogSheet extends StatefulWidget {
  const AddDogSheet({Key? key}) : super(key: key);

  @override
  State<AddDogSheet> createState() => _AddDogSheetState();
}

class _AddDogSheetState extends State<AddDogSheet> {
  final _formKey = GlobalKey<FormState>();

  String nombre = '';
  String? genero;
  int edadAnios = 0;
  int edadMeses = 0;
  String raza = 'Mestizo';
  bool esterilizado = false;
  String codigoEsterilizacion = '';
  File? fotoFile;
  bool _detectando = false;

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _detectando = true);

    final hayPerro = await _detectarPerro(picked.path);

    if (!mounted) return;
    setState(() => _detectando = false);

    if (hayPerro) {
      setState(() => fotoFile = File(picked.path));
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.dark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 22),
                SizedBox(width: 10),
                Text(
                  'No se detectó un perro',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          content: const Text(
            'La foto no parece contener un perro. Por favor intenta nuevamente con una foto más clara.',
            style: TextStyle(color: AppColors.dark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.primary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _tomarFoto();
              },
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _detectarPerro(String imagePath) async {
    final detector = DogDetector();
    try {
      await detector.load();
      return await detector.containsDog(imagePath);
    } finally {
      detector.dispose();
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> data = {
        'nombre': nombre,
        'genero': genero,
        'edadAnios': edadAnios,
        'edadMeses': edadMeses,
        'raza': raza,
        'esterilizado': esterilizado,
        if (esterilizado && codigoEsterilizacion.isNotEmpty)
          'codigoEsterilizacion': codigoEsterilizacion,
        if (fotoFile != null) 'fotoPath': fotoFile!.path,
      };
      Navigator.pop(context, data);
    }
  }

  void _selectRaza() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _RazaPicker(),
    );
    if (selected != null) {
      setState(() => raza = selected);
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.primary),
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header con gradiente
          Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.dark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Registrar mascota',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Formulario
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto del perro
                    GestureDetector(
                      onTap: _tomarFoto,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: fotoFile != null ? AppColors.primary : AppColors.secondary,
                            width: fotoFile != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.secondary.withValues(alpha: 0.06),
                        ),
                        child: _detectando
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: AppColors.primary),
                                  SizedBox(height: 12),
                                  Text(
                                    'Verificando si hay un perro...',
                                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                                  ),
                                ],
                              )
                            : fotoFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.file(fotoFile!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 30),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Agregar foto del perro',
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Toca para tomar foto o elegir de galería',
                                        style: TextStyle(color: AppColors.secondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    if (fotoFile != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _tomarFoto,
                          icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                          label: const Text('Cambiar foto', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Nombre
                    TextFormField(
                      decoration: _fieldDecoration('Nombre de la mascota', Icons.pets),
                      validator: (v) => v != null && v.isNotEmpty ? null : 'Nombre obligatorio',
                      onChanged: (v) => nombre = v,
                    ),
                    const SizedBox(height: 20),

                    // Género
                    const Text(
                      'Género',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                        fontSize: 13,
                      ),
                    ),
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
                        child: Text(
                          'Selecciona el género',
                          style: TextStyle(color: AppColors.highlight, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Edad
                    const Text(
                      'Edad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                        fontSize: 13,
                      ),
                    ),
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

                    // Raza
                    const Text(
                      'Raza',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectRaza,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.category, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                raza,
                                style: const TextStyle(fontSize: 15, color: AppColors.dark),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Esterilizado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.secondary.withValues(alpha: 0.06),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                esterilizado ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: esterilizado ? AppColors.primary : AppColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '¿Está esterilizado/a?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.dark,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: esterilizado,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.secondary,
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
                      TextFormField(
                        decoration: _fieldDecoration('Código de esterilización', Icons.tag),
                        onChanged: (v) => codigoEsterilizacion = v,
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (genero == null) {
                                setState(() {});
                                return;
                              }
                              _submit();
                            },
                            child: const Text(
                              'Registrar',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderButton({
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
          color: selected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.secondary,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.dark,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  const _NumberSlider({
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
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
        color: AppColors.secondary.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.dark,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.secondary.withValues(alpha: 0.3),
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withValues(alpha: 0.2),
              valueIndicatorColor: AppColors.dark,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              label: '$value',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _RazaPicker extends StatefulWidget {
  const _RazaPicker();

  @override
  State<_RazaPicker> createState() => _RazaPickerState();
}

class _RazaPickerState extends State<_RazaPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = kRazas
        .where((r) => r.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Selecciona la raza',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar raza...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                hintStyle: const TextStyle(color: AppColors.secondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final r = filtered[index];
                return ListTile(
                  leading: const Icon(Icons.pets, color: AppColors.primary, size: 18),
                  title: Text(r, style: const TextStyle(color: AppColors.dark)),
                  onTap: () => Navigator.pop(context, r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
