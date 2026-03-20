import 'package:flutter/material.dart';

import 'register_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String carnet = '';
  String password = '';
  bool isLoading = false;

  String? _token;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        const String backendBaseUrl = 'http://192.168.0.4:3000/api/auth';
        final String url = backendBaseUrl + '/login';
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'carnet': carnet, 'password': password}),
        );
        setState(() => isLoading = false);
        try {
          final Map<String, dynamic> data = jsonDecode(response.body);
          if (response.statusCode == 200 &&
              data['message'] == 'Login exitoso') {
            // Guardar el token
            _token = data['token'];
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage(token: _token)),
            );
          } else {
            final msg =
                data['error'] ?? data['message'] ?? 'Error al iniciar sesión';
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

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                const Text(
                  'Bienvenido',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
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
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Ingresar'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _goToRegister,
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
