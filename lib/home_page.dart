import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'add_dog_sheet.dart';
import 'edit_profile_sheet.dart';
import 'app_colors.dart';
import 'breed_classifier.dart';
import 'dog_detector.dart';

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

  File? _scanImage;
  bool _scanAnalizando = false;
  List<BreedResult> _scanRazas = [];
  final _picker = ImagePicker();

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
      final request = http.MultipartRequest('POST', Uri.parse(url));

      if (widget.token != null) {
        request.headers['Authorization'] = 'Bearer ${widget.token}';
      }

      // Campos de texto
      request.fields['nombre'] = data['nombre'] ?? '';
      request.fields['genero'] = data['genero'] ?? '';
      request.fields['edadAnios'] = data['edadAnios'].toString();
      request.fields['edadMeses'] = data['edadMeses'].toString();
      request.fields['raza'] = data['raza'] ?? '';
      request.fields['esterilizado'] = data['esterilizado'].toString();
      if (data['codigoEsterilizacion'] != null) {
        request.fields['codigoEsterilizacion'] = data['codigoEsterilizacion'];
      }

      // Razas detectadas por el modelo
      if (data['razasDetectadas'] != null) {
        request.fields['razasDetectadas'] = jsonEncode(data['razasDetectadas']);
      }

      // Foto si fue seleccionada
      if (data['fotoPath'] != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', data['fotoPath']));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

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
                child: const Icon(
                  Icons.pets,
                  color: AppColors.secondary,
                  size: 22,
                ),
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
            if (dog['foto'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    dog['foto'],
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            _dogDetailRow(Icons.male, 'Género', dog['genero'] ?? '-'),
            _dogDetailRow(
              Icons.cake,
              'Edad',
              '${dog['edadAnios'] ?? 0} años ${dog['edadMeses'] ?? 0} meses',
            ),
            _dogDetailRow(Icons.pets, 'Raza', dog['raza'] ?? '-'),
            _dogDetailRow(
              dog['esterilizado'] == true ? Icons.check_circle : Icons.cancel,
              'Esterilizado',
              dog['esterilizado'] == true ? 'Sí' : 'No',
            ),
            if (dog['esterilizado'] == true &&
                dog['codigoEsterilizacion'] != null)
              _dogDetailRow(Icons.tag, 'Código', dog['codigoEsterilizacion']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dogAvatarFallback() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.pets, size: 26, color: AppColors.primary),
    );
  }

  Widget _dogDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
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
        child: Text(
          errorMsg!,
          style: const TextStyle(color: AppColors.highlight),
        ),
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
              child: const Icon(
                Icons.pets,
                size: 48,
                color: AppColors.secondary,
              ),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: dog['foto'] != null
                  ? Image.network(
                      dog['foto'],
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _dogAvatarFallback(),
                    )
                  : _dogAvatarFallback(),
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
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.secondary,
            ),
            onTap: () => _showDogDetail(dog),
          ),
        );
      },
    );
  }

  Future<void> _pickScanImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _scanAnalizando = true;
      _scanImage = File(picked.path);
      _scanRazas = [];
    });

    // 1. Detectar si hay perro
    final detector = DogDetector();
    bool hayPerro = false;
    try {
      await detector.load();
      hayPerro = await detector.containsDog(picked.path);
    } finally {
      detector.dispose();
    }

    if (!mounted) return;

    if (!hayPerro) {
      setState(() {
        _scanAnalizando = false;
        _scanImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se detectó un perro en la imagen. Intenta de nuevo.')),
      );
      return;
    }

    // 2. Clasificar razas
    final razas = await BreedClassifier().classify(picked.path);
    if (!mounted) return;
    setState(() {
      _scanAnalizando = false;
      _scanRazas = razas;
    });

    // 3. Buscar coincidencias con la raza principal (>60%)
    if (razas.isNotEmpty) {
      await _buscarCoincidencias(razas.first);
    }
  }

  Future<void> _buscarCoincidencias(BreedResult razaPrincipal) async {
    try {
      final uri = Uri.parse(
        'http://192.168.0.4:3000/api/dogs/search-by-breed'
        '?raza=${Uri.encodeComponent(razaPrincipal.breed)}&minConfianza=0.6',
      );
      final response = await http.get(
        uri,
        headers: widget.token != null ? {'Authorization': 'Bearer ${widget.token}'} : {},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> dogs = jsonDecode(response.body);
        _mostrarCoincidencias(razaPrincipal, dogs);
      }
    } catch (_) {}
  }

  void _mostrarCoincidencias(BreedResult razaPrincipal, List<dynamic> dogs) {
    final pct = (razaPrincipal.confidence * 100).toStringAsFixed(1);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.search, color: AppColors.accent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Coincidencias encontradas',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${razaPrincipal.breed} · $pct% de coincidencia',
                style: const TextStyle(color: AppColors.secondary, fontSize: 12),
              ),
            ],
          ),
        ),
        content: dogs.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No se encontraron perros con más del 60% de esta raza en la base de datos.',
                  style: TextStyle(color: AppColors.dark),
                ),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dogs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final dog = dogs[i];
                    final owner = dog['owner'];
                    final ownerName = owner != null
                        ? '${owner['nombres'] ?? ''} ${owner['apellidos'] ?? ''}'.trim()
                        : 'Desconocido';
                    // Confianza de la raza buscada en este perro
                    final razaMatch = (dog['razasDetectadas'] as List?)
                        ?.firstWhere(
                          (r) => r['raza'] == razaPrincipal.breed,
                          orElse: () => null,
                        );
                    final matchPct = razaMatch != null
                        ? '${((razaMatch['confianza'] as num) * 100).toStringAsFixed(1)}%'
                        : '-';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      leading: dog['foto'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                dog['foto'],
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _dogAvatarFallback(),
                              ),
                            )
                          : _dogAvatarFallback(),
                      title: Text(
                        dog['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dog['raza'] ?? '-',
                            style: const TextStyle(color: AppColors.primary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 12, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ownerName,
                                  style: const TextStyle(color: AppColors.secondary, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          matchPct,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
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

  Widget _buildScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // Ícono principal
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
            'Escanear huella nasal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toma o sube una foto de la nariz del perro',
            style: TextStyle(color: AppColors.primary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: _ScanOptionButton(
                  icon: Icons.camera_alt,
                  label: 'Sacar foto',
                  onTap: () => _pickScanImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ScanOptionButton(
                  icon: Icons.photo_library,
                  label: 'Subir imagen',
                  onTap: () => _pickScanImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Estado de análisis
          if (_scanAnalizando) ...[
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'Analizando imagen...',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],

          // Preview de imagen
          if (_scanImage != null && !_scanAnalizando) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _scanImage!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),

            // Razas detectadas
            if (_scanRazas.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dark.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Razas detectadas',
                          style: TextStyle(
                            color: AppColors.dark,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._scanRazas.map((r) {
                      final pct = (r.confidence * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.breed,
                                  style: const TextStyle(
                                    color: AppColors.dark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: r.confidence,
                                backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: () => _buscarCoincidencias(_scanRazas.first),
                  icon: const Icon(Icons.search),
                  label: const Text(
                    'Buscar coincidencias',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() {
                    _scanImage = null;
                    _scanRazas = [];
                  }),
                  icon: const Icon(Icons.delete_outline, color: AppColors.highlight, size: 18),
                  label: const Text('Eliminar', style: TextStyle(color: AppColors.highlight)),
                ),
                TextButton.icon(
                  onPressed: () => _pickScanImage(ImageSource.camera),
                  icon: const Icon(Icons.refresh, color: AppColors.primary, size: 18),
                  label: const Text('Cambiar', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ],
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
                    child: const Icon(
                      Icons.person,
                      size: 36,
                      color: Colors.white,
                    ),
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
                      style: TextStyle(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => EditProfileSheet(token: widget.token),
                      );
                    },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.highlight,
                    ),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: AppColors.highlight,
                        fontWeight: FontWeight.w500,
                      ),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.secondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.pets), text: 'Mis Perros'),
            Tab(
              icon: Text('🐽', style: TextStyle(fontSize: 20)),
              text: 'Escanear',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDogsTab(), _buildScanTab()],
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

class _ScanOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ScanOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
