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
        onPressed: () {
          // Aquí puedes navegar a la pantalla de agregar perro
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar perro',
      ),
    );
  }
}
