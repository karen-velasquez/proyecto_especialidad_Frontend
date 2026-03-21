import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_dog_sheet.dart';
import 'edit_profile_sheet.dart';
import 'app_colors.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.dark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dog['nombre'] ?? 'Sin nombre',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
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
            if (dog['esterilizado'] == true && dog['codigoEsterilizacion'] != null)
              _dogDetailRow(Icons.tag, 'Código', dog['codigoEsterilizacion']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.primary)),
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
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDogsTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (errorMsg != null) {
      return Center(
        child: Text(errorMsg!, style: const TextStyle(color: AppColors.highlight)),
      );
    }
    if (dogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 2),
              ),
              child: const Icon(Icons.pets, size: 48, color: AppColors.secondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes perros registrados',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Toca + para agregar tu primer perro',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: dogs.length,
      itemBuilder: (context, index) {
        final dog = dogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets, size: 26, color: AppColors.primary),
            ),
            title: Text(
              dog['nombre'] ?? 'Sin nombre',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
                fontSize: 15,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${dog['raza'] ?? 'Raza desconocida'} · '
                '${dog['edadAnios'] ?? 0}a ${dog['edadMeses'] ?? 0}m · '
                '${dog['genero'] ?? '-'}',
                style: const TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.secondary),
            onTap: () => _showDogDetail(dog),
          ),
        );
      },
    );
  }

  Widget _buildScanTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary, width: 2),
            ),
            child: const Text('🐽', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Escanear huella',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Próximamente disponible',
            style: TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F5),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.dark, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondary, width: 2),
                    ),
                    child: const Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mi perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primary),
                    title: const Text(
                      'Editar perfil',
                      style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => EditProfileSheet(token: widget.token),
                      );
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.highlight),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppColors.highlight, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: cerrar sesión
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.pets, color: AppColors.secondary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Dog Biometric',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.secondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.pets), text: 'Mis Perros'),
            Tab(icon: Text('🐽', style: TextStyle(fontSize: 20)), text: 'Escanear'),
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
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
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
