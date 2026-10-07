import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'captura_rostro_screen.dart';
import 'captura_trufa_screen.dart';
import 'editar_datos_perro_screen.dart';
import 'login_page.dart';
import 'registro_datos_screen.dart';
import '../core/app_colors.dart';
import '../core/auth_storage.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/home_widgets.dart';

class HomePage extends StatefulWidget {
  final String? token;
  final ValueChanged<int>? onDogCountChanged;
  final VoidCallback? onHistorialTap;
  const HomePage({super.key, this.token, this.onDogCountChanged, this.onHistorialTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<dynamic> dogs = [];
  bool isLoading = true;
  String? errorMsg;

  Map<String, dynamic>? _userProfile;
  late final TabController _tabController;
  static const _estadosTabs = ['conmigo', 'extraviado', 'fallecido'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _estadosTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    fetchDogs();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _verFotoDog(String foto) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                foto,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dog['fotoPerfil'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => _verFotoDog(dog['fotoPerfil']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      dog['fotoPerfil'],
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            _dogDetailRow(
              Icons.info_outline,
              'Estado',
              _estadoMascotaLabel(dog['estadoMascota']),
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
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          if (dog['estadoMascota'] != 'fallecido') ...[
            IconButton(
              tooltip: 'Editar datos',
              icon: const Icon(Icons.edit_outlined, color: AppColors.turquoise),
              onPressed: () {
                Navigator.pop(context);
                _editarDatos(dog);
              },
            ),
            // No disponible mientras el perro está extraviado: no hay cómo
            // volver a fotografiarlo. "Encontrado" ya está contigo de nuevo.
            if (dog['estadoMascota'] != 'extraviado')
              IconButton(
                tooltip: 'Actualizar datos biométricos',
                icon: const Icon(Icons.fingerprint, color: AppColors.turquoise),
                onPressed: () {
                  Navigator.pop(context);
                  _actualizarBiometria(dog);
                },
              ),
            IconButton(
              tooltip: 'Actualizar estado',
              icon: const Icon(Icons.info_outline, color: AppColors.turquoise),
              onPressed: () {
                Navigator.pop(context);
                _actualizarEstadoMascota(dog);
              },
            ),
          ],
          IconButton(
            tooltip: 'Eliminar mascota',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              _eliminarMascota(dog);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editarDatos(Map<String, dynamic> dog) async {
    if (widget.token == null) return;
    final actualizado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarDatosPerroScreen(token: widget.token!, dog: dog),
      ),
    );
    if (actualizado == true) fetchDogs();
  }

  Future<void> _actualizarBiometria(Map<String, dynamic> dog) async {
    if (widget.token == null) return;
    final confirmado = await showConfirmDialog(
      context,
      title: 'Actualizar datos biométricos',
      message: 'Esto borrará las fotos de trufa y rostro actuales de '
          '${dog['nombre'] ?? 'este perro'} y deberás volver a capturarlas. ¿Continuar?',
      confirmLabel: 'Continuar',
      danger: true,
      icon: Icons.fingerprint,
    );
    if (!confirmado || !mounted) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.dogsUrl}/${dog['_id']}/reiniciar-biometria'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
        return;
      }
      final dogId = dog['_id'] as String;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CapturaTrufaScreen(
            token: widget.token!,
            dogId: dogId,
            onCompleto: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CapturaRostroScreen(
                    token: widget.token!,
                    dogId: dogId,
                    onCompleto: (_) => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                ),
              );
            },
          ),
        ),
      );
      fetchDogs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar: $e')),
      );
    }
  }

  String _tituloSeccionMascotas(String estado) {
    switch (estado) {
      case 'extraviado':
        return 'Mis Mascotas Extraviadas';
      case 'fallecido':
        return 'Mis Mascotas Fallecidas';
      default:
        return 'Mis Mascotas';
    }
  }

  String _estadoMascotaLabel(String? estado) {
    switch (estado) {
      case 'extraviado':
        return 'Extraviado';
      case 'encontrado':
        return 'Encontrada recientemente';
      case 'fallecido':
        return 'Fallecido';
      default:
        return 'Conmigo';
    }
  }

  Future<void> _actualizarEstadoMascota(Map<String, dynamic> dog) async {
    if (widget.token == null) return;
    final estadoActual = dog['estadoMascota'] ?? 'conmigo';
    final opciones = <Widget>[
      if (estadoActual == 'conmigo') ...[
        _opcionEstado(context, 'extraviado', 'Extraviado', Icons.error_outline, AppColors.error),
        _opcionEstado(context, 'fallecido', 'Fallecido', Icons.favorite_border, AppColors.textSecondary),
      ] else if (estadoActual == 'extraviado') ...[
        _opcionEstado(context, 'encontrado', 'Encontrada', Icons.home_outlined, AppColors.success),
        _opcionEstado(context, 'fallecido', 'Fallecido', Icons.favorite_border, AppColors.textSecondary),
      ] else if (estadoActual == 'encontrado') ...[
        _opcionEstado(context, 'fallecido', 'Fallecido', Icons.favorite_border, AppColors.textSecondary),
      ],
    ];
    final nuevoEstado = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Estado de ${dog['nombre'] ?? 'la mascota'}',
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Su estado actual es: ${_estadoMascotaLabel(estadoActual)}. ¿Quieres actualizarlo?',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          ...opciones,
        ],
      ),
    );
    if (nuevoEstado == null || !mounted) return;

    if (nuevoEstado == 'extraviado') {
      final confirmado = await showConfirmDialog(
        context,
        title: 'Marcar como extraviado',
        message: 'Una vez marques a ${dog['nombre'] ?? 'tu mascota'} como extraviado se '
            'enviarán alertas a personas cercanas y no podrás actualizar sus datos '
            'biométricos hasta que vuelva contigo. ¿Estás seguro?',
        confirmLabel: 'Sí, marcar',
        danger: true,
        icon: Icons.error_outline,
      );
      if (!confirmado || !mounted) return;
    }

    if (nuevoEstado == 'fallecido') {
      final confirmado = await showConfirmDialog(
        context,
        title: 'Marcar como fallecido',
        message: 'Esta acción es permanente: una vez marques a ${dog['nombre'] ?? 'tu mascota'} '
            'como fallecido, ya no podrás volver a cambiar su estado a conmigo o extraviado. '
            '¿Estás seguro?',
        confirmLabel: 'Sí, marcar',
        danger: true,
        icon: Icons.favorite_border,
      );
      if (!confirmado || !mounted) return;
    }

    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.dogsUrl}/${dog['_id']}/estado'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'estadoMascota': nuevoEstado}),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        fetchDogs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar estado: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar: $e')),
      );
    }
  }

  Widget _opcionEstado(BuildContext context, String valor, String label, IconData icon, Color color) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, valor),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Future<void> _eliminarMascota(Map<String, dynamic> dog) async {
    if (widget.token == null) return;
    final confirmado = await showConfirmDialog(
      context,
      title: 'Eliminar mascota',
      message: '¿Seguro que quieres eliminar a ${dog['nombre'] ?? 'esta mascota'}? '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      danger: true,
      icon: Icons.delete_outline,
    );
    if (!confirmado || !mounted) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.dogsUrl}/${dog['_id']}'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        fetchDogs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar: $e')),
      );
    }
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
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: isLoading
                  ? const HomeSkeleton()
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              if (dogs.isEmpty)
                                FloatingHeroCard(
                                  title: 'Protege a tus mascotas con IA',
                                  description:
                                      'Registra nuevos perros y gestiona su información biométrica.',
                                  ctaLabel: 'Registrar Perro',
                                  onCta: _showAddDogSheet,
                                ),
                              const SizedBox(height: 26),
                              if (errorMsg == null && dogs.isNotEmpty) _buildSeccionHeader(),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            color: AppColors.turquoise,
                            backgroundColor: AppColors.surface,
                            onRefresh: () async {
                              await fetchDogs();
                              await _loadUserProfile();
                            },
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                              children: [
                                _buildMyDogsSection(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          if (!isLoading && dogs.isNotEmpty)
            Positioned(
              right: 20,
              bottom: 100,
              child: GradientFab(onPressed: _showAddDogSheet, icon: Icons.add),
            ),
        ],
      ),
    );
  }

  // ---- Sección 1: Header ----
  Widget _buildHeader() {
    final hasName = _firstName.isNotEmpty;
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
          child: Text(
            hasName ? 'Hola, $_firstName 👋' : 'Hola 👋',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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

  // ---- Sección: Mis Mascotas (título + tabs, fijo) ----
  Widget _buildSeccionHeader() {
    final estadoActivo = _estadosTabs[_tabController.index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tituloSeccionMascotas(estadoActivo),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            dividerColor: Colors.transparent,
            labelColor: AppColors.turquoise,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(icon: Icon(Icons.home_outlined), iconMargin: EdgeInsets.zero),
              Tab(icon: Icon(Icons.error_outline), iconMargin: EdgeInsets.zero),
              Tab(icon: Icon(Icons.local_florist_outlined), iconMargin: EdgeInsets.zero),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // ---- Sección: Mis Mascotas (lista de cards, scrollable) ----
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
    final estadoActivo = _estadosTabs[_tabController.index];
    final filtrados = dogs.where((d) {
      var estado = d['estadoMascota'] ?? 'conmigo';
      if (estado == 'encontrado') estado = 'conmigo'; // "encontrado" se ve en la pestaña "conmigo"
      return estado == estadoActivo;
    }).toList();

    if (filtrados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No hay mascotas en esta categoría',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < filtrados.length; i++)
          StaggeredItem(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DogCard(
                dog: filtrados[i],
                onTap: () => _showDogDetail(filtrados[i]),
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
              child: dog['fotoPerfil'] != null
                  ? Image.network(
                      dog['fotoPerfil'],
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
                      if (dog['estadoMascota'] == 'extraviado')
                        _chip('Extraviado', Icons.error_outline,
                            color: AppColors.error),
                      if (dog['estadoMascota'] == 'encontrado')
                        _chip('Encontrada recientemente', Icons.check_circle_outline,
                            color: AppColors.success),
                      if (dog['estadoMascota'] == 'fallecido')
                        _chip('Fallecido', Icons.favorite_border,
                            color: AppColors.textSecondary),
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
