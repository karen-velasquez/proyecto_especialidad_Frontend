import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileSheet extends StatefulWidget {
  final String? token;
  const EditProfileSheet({super.key, this.token});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String fechaNacimiento = '';

  bool isLoading = false;
  bool isFetchingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.4:3000/api/users/me'),
        headers: {
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _nombresCtrl.text = data['nombres'] ?? '';
        _apellidosCtrl.text = data['apellidos'] ?? '';
        _telefonoCtrl.text = data['telefono'] ?? '';
        _emailCtrl.text = data['email'] ?? '';
        if (data['fechaNacimiento'] != null) {
          setState(() {
            fechaNacimiento = data['fechaNacimiento'].toString().substring(0, 10);
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => isFetchingProfile = false);
  }

  @override
  void dispose() {
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final body = <String, dynamic>{};
    if (_nombresCtrl.text.isNotEmpty) body['nombres'] = _nombresCtrl.text;
    if (_apellidosCtrl.text.isNotEmpty) body['apellidos'] = _apellidosCtrl.text;
    if (_telefonoCtrl.text.isNotEmpty) body['telefono'] = _telefonoCtrl.text;
    if (_emailCtrl.text.isNotEmpty) body['email'] = _emailCtrl.text;
    if (fechaNacimiento.isNotEmpty) body['fechaNacimiento'] = fechaNacimiento;

    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('http://192.168.0.4:3000/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );
      if (!mounted) return;
      setState(() => isLoading = false);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Perfil actualizado')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Error al actualizar')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
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
      child: isFetchingProfile
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Editar perfil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nombresCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombres',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _apellidosCtrl,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null && v.isNotEmpty && !v.contains('@')) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Fecha de nacimiento con calendario
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('es', 'ES'),
                  );
                  if (picked != null) {
                    setState(() {
                      fechaNacimiento =
                          '${picked.year.toString().padLeft(4, '0')}-'
                          '${picked.month.toString().padLeft(2, '0')}-'
                          '${picked.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Fecha de nacimiento',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      hintText: fechaNacimiento.isEmpty
                          ? 'Sin cambios'
                          : null,
                    ),
                    controller: TextEditingController(text: fechaNacimiento),
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                      onPressed: isLoading ? null : _save,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar'),
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

