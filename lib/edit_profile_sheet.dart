import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_colors.dart';

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

  InputDecoration _fieldDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.primary),
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  TextInputFormatter get _upperCaseFormatter =>
      TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(
            text: newValue.text.toUpperCase(),
            selection: newValue.selection,
          ));

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
            margin: const EdgeInsets.only(top: 16),
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
                  child: const Icon(Icons.person_outline, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Editar perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Flexible(
            flex: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: isFetchingProfile
                ? const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                : SingleChildScrollView(
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
                          // Sección: Información personal
                          const Text(
                            'Información personal',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nombresCtrl,
                                  decoration: _fieldDecoration('Nombres', Icons.person),
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [_upperCaseFormatter],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _apellidosCtrl,
                                  decoration: _fieldDecoration('Apellidos', Icons.person_outline),
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [_upperCaseFormatter],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _telefonoCtrl,
                            decoration: _fieldDecoration('Teléfono', Icons.phone),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _emailCtrl,
                            decoration: _fieldDecoration('Correo electrónico (opcional)', Icons.email),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v != null && v.isNotEmpty && !v.contains('@')) {
                                return 'Correo inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Fecha de nacimiento
                          GestureDetector(
                            onTap: () async {
                              final initial = fechaNacimiento.isNotEmpty
                                  ? DateTime.tryParse(fechaNacimiento) ?? DateTime(2000)
                                  : DateTime(2000);
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                locale: const Locale('es', 'ES'),
                              );
                              if (picked != null) {
                                final today = DateTime.now();
                                final age = today.year - picked.year -
                                    ((today.month < picked.month ||
                                            (today.month == picked.month && today.day < picked.day))
                                        ? 1
                                        : 0);
                                if (!mounted) return;
                                if (age < 18) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Debes tener al menos 18 años'),
                                    ),
                                  );
                                  return;
                                }
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
                                decoration: _fieldDecoration(
                                  'Fecha de nacimiento',
                                  Icons.calendar_today,
                                  suffix: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                ),
                                controller: TextEditingController(
                                  text: fechaNacimiento.isEmpty ? '' : fechaNacimiento,
                                ),
                              ),
                            ),
                          ),
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
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
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
                                      : const Text(
                                          'Guardar',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
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
          ),
        ],
      ),
    );
  }
}
