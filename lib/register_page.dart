import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:convert';
import 'app_colors.dart';

const String backendBaseUrl = 'http://192.168.0.4:3000/api/auth';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();

  String nombres = '';
  String apellidos = '';
  String carnet = '';
  String fechaNacimiento = '';
  String telefono = '';
  bool _phoneValid = false;
  String email = '';
  String password = '';
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_phoneValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de teléfono inválido para el país seleccionado')),
        );
        return;
      }
      setState(() => isLoading = true);
      try {
        final response = await http.post(
          Uri.parse('$backendBaseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nombres': nombres,
            'apellidos': apellidos,
            'carnet': carnet,
            'fechaNacimiento': fechaNacimiento,
            'telefono': telefono,
            'email': email,
            'password': password,
          }),
        );
        setState(() => isLoading = false);
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          if (response.statusCode == 200 || response.statusCode == 201) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Registro exitoso')),
            );
            Navigator.pop(context);
          } else {
            final msg = data['error'] ?? data['message'] ?? 'Error al registrar';
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Respuesta inesperada: ${response.body}')),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.dark, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Crear cuenta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Ícono
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
                child: const Icon(Icons.pets, size: 40, color: AppColors.secondary),
              ),
              const SizedBox(height: 16),

              // Card con formulario
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información personal',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Nombres y Apellidos en fila
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nombresController,
                                  decoration: _fieldDecoration('Nombres', Icons.person),
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [
                                    TextInputFormatter.withFunction((oldValue, newValue) {
                                      return newValue.copyWith(
                                        text: newValue.text.toUpperCase(),
                                        selection: newValue.selection,
                                      );
                                    }),
                                  ],
                                  validator: (v) => v != null && v.isNotEmpty ? null : 'Requerido',
                                  onChanged: (v) => nombres = v,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _apellidosController,
                                  decoration: _fieldDecoration('Apellidos', Icons.person_outline),
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [
                                    TextInputFormatter.withFunction((oldValue, newValue) {
                                      return newValue.copyWith(
                                        text: newValue.text.toUpperCase(),
                                        selection: newValue.selection,
                                      );
                                    }),
                                  ],
                                  validator: (v) => v != null && v.isNotEmpty ? null : 'Requerido',
                                  onChanged: (v) => apellidos = v,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            decoration: _fieldDecoration('Carnet de identidad', Icons.badge),
                            keyboardType: TextInputType.number,
                            validator: (v) => v != null && v.isNotEmpty ? null : 'Carnet requerido',
                            onChanged: (v) => carnet = v,
                          ),
                          const SizedBox(height: 14),

                          // Fecha de nacimiento
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
                                      content: Text('Debes tener al menos 18 años para registrarte'),
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
                                controller: TextEditingController(text: fechaNacimiento),
                                validator: (_) => fechaNacimiento.isNotEmpty ? null : 'Fecha requerida',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Correo electrónico (opcional)
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico (opcional)',
                              labelStyle: const TextStyle(color: AppColors.primary),
                              prefixIcon: const Icon(Icons.email, color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              return v.contains('@') ? null : 'Correo inválido';
                            },
                            onChanged: (v) => email = v,
                          ),
                          const SizedBox(height: 14),

                          // Teléfono con código de país
                          IntlPhoneField(
                            decoration: InputDecoration(
                              labelText: 'Teléfono',
                              labelStyle: const TextStyle(color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            initialCountryCode: 'BO',
                            keyboardType: TextInputType.phone,
                            onChanged: (phone) {
                              telefono = phone.completeNumber;
                              // isValidNumber() valida según las reglas del país seleccionado
                              setState(() {
                                _phoneValid = phone.isValidNumber();
                              });
                            },
                            onCountryChanged: (country) {
                              setState(() {
                                _phoneValid = false;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Información de acceso',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            decoration: _fieldDecoration(
                              'Contraseña',
                              Icons.lock,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.primary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
                            onChanged: (v) => password = v,
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              onPressed: isLoading ? null : _register,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Crear cuenta',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
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
