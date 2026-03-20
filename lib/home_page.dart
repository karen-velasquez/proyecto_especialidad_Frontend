import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  final String? token;
  const HomePage({Key? key, this.token}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> dogs = [];
  bool isLoading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchDogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDogDialog() {
    final dogFormKey = GlobalKey<FormState>();
    String name = '';
    String breed = '';
    String age = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar nuevo perro'),
          content: Form(
            key: dogFormKey,
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
                if (dogFormKey.currentState!.validate()) {
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
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perro registrado correctamente')),
        );
        fetchDogs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
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
          errorMsg = 'Error: ${response.body}';
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

  Widget _buildDogsTab() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMsg != null) return Center(child: Text(errorMsg!));
    if (dogs.isEmpty) {
      return const Center(child: Text('No tienes perros registrados.'));
    }
    return ListView.builder(
      itemCount: dogs.length,
      itemBuilder: (context, index) {
        final dog = dogs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.pets, size: 32, color: Colors.blueAccent),
            title: Text(dog['name'] ?? 'Sin nombre'),
            subtitle: Text(
              'Raza: ${dog['breed'] ?? 'Desconocida'}\nEdad: ${dog['age'] ?? '-'}',
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🐽', style: TextStyle(fontSize: 80)),
          SizedBox(height: 16),
          Text('Escanear', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 36, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mi perfil',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar perfil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: navegar a editar perfil
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: cerrar sesión
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Dog Biometric'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pets), text: 'Mis Perros'),
            Tab(icon: Text('🐽', style: TextStyle(fontSize: 22)), text: 'Escanear'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDogsTab(),
          _buildScanTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return FloatingActionButton(
              onPressed: _showAddDogDialog,
              tooltip: 'Agregar perro',
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
