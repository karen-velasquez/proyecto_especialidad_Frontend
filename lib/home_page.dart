import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_dog_sheet.dart';
import 'edit_profile_sheet.dart';

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

  void _showAddDogSheet() async {
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const AddDogSheet(),
    );
    if (data != null) {
      await _registerDog(data);
    }
  }

  Future<void> _registerDog(Map<String, dynamic> data) async {
    try {
      const String url = 'http://192.168.0.4:3000/api/dogs';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(data),
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

  void _showDogDetail(Map<String, dynamic> dog) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.pets, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(dog['nombre'] ?? 'Sin nombre'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dogDetailRow(Icons.male, 'Género', dog['genero'] ?? '-'),
            _dogDetailRow(Icons.cake, 'Edad',
                '${dog['edadAnios'] ?? 0} años ${dog['edadMeses'] ?? 0} meses'),
            _dogDetailRow(Icons.pets, 'Raza', dog['raza'] ?? '-'),
            _dogDetailRow(
              dog['esterilizado'] == true ? Icons.check_circle : Icons.cancel,
              'Esterilizado',
              dog['esterilizado'] == true ? 'Sí' : 'No',
            ),
            if (dog['esterilizado'] == true &&
                dog['codigoEsterilizacion'] != null)
              _dogDetailRow(
                  Icons.tag, 'Código', dog['codigoEsterilizacion']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _dogDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
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
            title: Text(dog['nombre'] ?? 'Sin nombre'),
            subtitle: Text(
              'Raza: ${dog['raza'] ?? 'Desconocida'}\n'
              'Edad: ${dog['edadAnios'] ?? 0} años ${dog['edadMeses'] ?? 0} meses\n'
              'Género: ${dog['genero'] ?? '-'}',
            ),
            onTap: () => _showDogDetail(dog),
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
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => EditProfileSheet(token: widget.token),
                );
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
              onPressed: _showAddDogSheet,
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
