import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  final String? token;
  const HomePage({Key? key, this.token}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _showAddDogDialog() {
    final _dogFormKey = GlobalKey<FormState>();
    String name = '';
    String breed = '';
    String age = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar nuevo perro'),
          content: Form(
            key: _dogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : 'Obligatorio',
                  onChanged: (v) => name = v,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Raza'),
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : 'Obligatorio',
                  onChanged: (v) => breed = v,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Edad'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v != null && int.tryParse(v) != null
                      ? null
                      : 'Número válido',
                  onChanged: (v) => age = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_dogFormKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _registerDog(name, breed, int.parse(age));
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerDog(String name, String breed, int age) async {
    try {
      const String url = 'http://192.168.0.4:3000/api/dogs';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'name': name, 'breed': breed, 'age': age}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perro registrado correctamente')),
        );
        fetchDogs();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  List<dynamic> dogs = [];
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchDogs();
  }

  Future<void> fetchDogs() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      const String url = 'http://192.168.0.4:3000/api/dogs';
      final response = await http.get(
        Uri.parse(url),
        headers: widget.token != null
            ? {'Authorization': 'Bearer ${widget.token}'}
            : {},
      );
      if (response.statusCode == 200) {
        setState(() {
          dogs = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMsg = 'Error: ' + response.body;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = 'Error de conexión: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Perros')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
          ? Center(child: Text(errorMsg!))
          : dogs.isEmpty
          ? const Center(child: Text('No tienes perros registrados.'))
          : ListView.builder(
              itemCount: dogs.length,
              itemBuilder: (context, index) {
                final dog = dogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.pets,
                      size: 32,
                      color: Colors.blueAccent,
                    ),
                    title: Text(dog['name'] ?? 'Sin nombre'),
                    subtitle: Text(
                      'Raza: ${dog['breed'] ?? 'Desconocida'}\nEdad: ${dog['age'] ?? '-'}',
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDogDialog,
        child: const Icon(Icons.add),
        tooltip: 'Agregar perro',
      ),
    );
  }
}
