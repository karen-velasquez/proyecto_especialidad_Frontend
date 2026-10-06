import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'registro_datos_screen.dart';
import '../core/app_colors.dart';
import '../core/auth_storage.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/home_widgets.dart';

class HomePage extends StatefulWidget {
  final String? token;
  final ValueChanged<int>? onDogCountChanged;
  final VoidCallback? onHistorialTap;
  const HomePage({super.key, this.token, this.onDogCountChanged, this.onHistorialTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> dogs = [];
  bool isLoading = true;
  String? errorMsg;

  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    fetchDogs();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.usersUrl}/me'),
        headers: widget.token != null
            ? {'Authorization': 'Bearer ${widget.token}'}
            : {},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() => _userProfile = jsonDecode(response.body));
      }
    } catch (_) {}
  }

  void _showAddDogSheet() async {
    HapticFeedback.selectionClick();
    if (widget.token == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegistroDatosScreen(token: widget.token!)),
    );
    fetchDogs();
  }

  Future<void> fetchDogs() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.dogsUrl),
        headers: widget.token != null
            ? {'Authorization': 'Bearer ${widget.token}'}
            : {},
      );
      if (response.statusCode == 200) {
        setState(() {
          dogs = jsonDecode(response.body);
          isLoading = false;
        });
        widget.onDogCountChanged?.call(dogs.length);
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

  void _logout() async {
    await AuthStorage.borrarToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  String get _firstName {
    final n = _userProfile?['nombres'];
    if (n is String && n.trim().isNotEmpty) {
      return n.trim().split(' ').first;
    }
    return '';
  }

  // -------------------------------------------------------------------------
  // Detalle de un perro propio (dark premium).
  // -------------------------------------------------------------------------
  void _showDogDetail(Map<String, dynamic> dog) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            gradient: AppColors.ctaGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, color: Colors.white, size: 22),
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
            child: const Text('Cerrar',
                style: TextStyle(color: AppColors.turquoise)),
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
          Icon(icon, size: 18, color: AppColors.turquoise),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: SafeArea(
        bottom: false,
        child: isLoading
              ? const HomeSkeleton()
              : RefreshIndicator(
                  color: AppColors.turquoise,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async {
                    await fetchDogs();
                    await _loadUserProfile();
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      FloatingHeroCard(
                        title: 'Protege a tus mascotas con IA',
                        description:
                            'Registra nuevos perros y gestiona su información biométrica.',
                        ctaLabel: 'Registrar Perro',
                        onCta: _showAddDogSheet,
                      ),
                      const SizedBox(height: 26),
                      _buildMyDogsSection(),
                    ],
                  ),
                ),
      ),
    );
  }

  // ---- Sección 1: Header ----
  Widget _buildHeader() {
    final hasName = _firstName.isNotEmpty;
    final count = dogs.length;
    return Row(
      children: [
        GestureDetector(
          onTap: _openProfileMenu,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.turquoise.withValues(alpha: 0.4),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasName ? 'Hola, $_firstName 👋' : 'Hola 👋',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count == 0
                    ? 'Aún no tienes mascotas registradas'
                    : 'Tienes $count mascota${count == 1 ? '' : 's'} registrada${count == 1 ? '' : 's'}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        _circleIconButton(Icons.person_outline, _openProfileMenu),
        const SizedBox(width: 8),
        _circleIconButton(Icons.history, widget.onHistorialTap ?? () {}),
      ],
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap,
      {bool badge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          if (badge)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.turquoise,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---- Sección: Mis Mascotas ----
  Widget _buildMyDogsSection() {
    if (errorMsg != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
          child: Text(errorMsg!,
              style: const TextStyle(color: AppColors.error)),
        ),
      );
    }
    if (dogs.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis Mascotas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < dogs.length; i++)
          StaggeredItem(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DogCard(
                dog: dogs[i],
                onTap: () => _showDogDetail(dogs[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 24),
        child: Column(
          children: [
            const GlowingPawLogo(size: 90),
            const SizedBox(height: 22),
            const Text(
              'Aún no registraste ninguna mascota',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Empieza registrando tu primer perro y crea su perfil biométrico.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Menú de perfil (bottom sheet con acciones) ----
  void _openProfileMenu() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userProfile != null
                              ? '${_userProfile!['nombres'] ?? ''} ${_userProfile!['apellidos'] ?? ''}'
                                  .trim()
                              : 'Mi perfil',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_userProfile?['email'] != null &&
                            (_userProfile!['email'] as String).isNotEmpty)
                          Text(
                            _userProfile!['email'],
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _profileTile(Icons.logout, 'Cerrar sesión', () {
                Navigator.pop(context);
                _logout();
              }, danger: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileTile(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: danger ? AppColors.error : AppColors.turquoise),
      title: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta moderna de mascota (glass, foto grande, glow sutil).
/// ---------------------------------------------------------------------------
class _DogCard extends StatelessWidget {
  final Map<String, dynamic> dog;
  final VoidCallback onTap;
  const _DogCard({required this.dog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final esterilizado = dog['esterilizado'] == true;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto grande
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: dog['foto'] != null
                  ? Image.network(
                      dog['foto'],
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dog['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dog['raza'] ?? 'Raza desconocida',
                    style: const TextStyle(
                        color: AppColors.turquoise, fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(
                        '${dog['edadAnios'] ?? 0}a ${dog['edadMeses'] ?? 0}m',
                        Icons.cake_outlined,
                      ),
                      _chip(dog['genero'] ?? '-', Icons.transgender),
                      if (esterilizado)
                        _chip('Esterilizado', Icons.check_circle,
                            color: AppColors.success),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.turquoise.withValues(alpha: 0.12),
      child: const Icon(Icons.pets, size: 32, color: AppColors.turquoise),
    );
  }

  Widget _chip(String text, IconData icon, {Color? color}) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: c, fontSize: 11)),
        ],
      ),
    );
  }
}
