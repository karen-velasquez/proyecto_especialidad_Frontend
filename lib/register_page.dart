import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

// Cambia esta IP si tu backend cambia de dirección
const String backendBaseUrl = 'http://192.168.0.4:3000/api/auth';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String nombres = '';
  String apellidos = '';
  String carnet = '';
  String fechaNacimiento = '';
  String telefono = '';
  String email = '';
  String password = '';
  bool isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final String url = backendBaseUrl + '/register';
        final response = await http.post(
          Uri.parse(url),
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
            Navigator.pop(context); // Vuelve al login
          } else {
            final msg =
                data['error'] ?? data['message'] ?? 'Error al registrar';
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : 'Nombres requeridos',
                  onChanged: (value) => nombres = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : 'Apellidos requeridos',
                  onChanged: (value) => apellidos = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Carnet de identidad',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : 'Carnet requerido',
                  onChanged: (value) => carnet = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : 'Fecha requerida',
                  onChanged: (value) => fechaNacimiento = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value != null && value.isNotEmpty
                      ? null
                      : 'Teléfono requerido',
                  onChanged: (value) => telefono = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : 'Correo inválido',
                  onChanged: (value) => email = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) => value != null && value.length >= 6
                      ? null
                      : 'Mínimo 6 caracteres',
                  onChanged: (value) => password = value,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Registrarse'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
