import 'package:flutter/material.dart';

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
      };
      Navigator.pop(context, data);
    }
  }

  void _selectRaza() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _RazaPicker(),
    );
    if (selected != null) {
      setState(() => raza = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar mascota',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Nombre
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nombre de la mascota',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : 'Nombre obligatorio',
                onChanged: (v) => nombre = v,
              ),
              const SizedBox(height: 16),

              // Género
              const Text('Género', style: TextStyle(fontWeight: FontWeight.w500)),
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
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Edad: años y meses lado a lado
              const Text('Edad', style: TextStyle(fontWeight: FontWeight.w500)),
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
              const SizedBox(height: 16),

              // Raza
              const Text('Raza', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectRaza,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(raza, style: const TextStyle(fontSize: 16)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Esterilizado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '¿Está esterilizado/a?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: esterilizado,
                    onChanged: (v) => setState(() {
                      esterilizado = v;
                      if (!v) codigoEsterilizacion = '';
                    }),
                  ),
                ],
              ),
              if (esterilizado) ...[
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Código de esterilización',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                  onChanged: (v) => codigoEsterilizacion = v,
                ),
              ],
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (genero == null) {
                          setState(() {});
                          return;
                        }
                        _submit();
                      },
                      child: const Text('Registrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget botón de género
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.transparent,
          border: Border.all(
            color: selected ? Colors.blueAccent : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget slider numérico con label y valor
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
    return Column(
      children: [
        Text(
          '$label: $value',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$value',
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

// Panel selector de raza con buscador
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Selecciona la raza',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar raza...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
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
                  title: Text(r),
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
