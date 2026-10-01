import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';
import '../services/ml/breed_classifier.dart';
import '../services/ml/dog_detector.dart';

/// Pantalla de escaneo: toma/sube una foto, detecta perro (YOLOv8), clasifica
/// raza (TFLite) y busca coincidencias por raza en la base de datos.
class ScanScreen extends StatefulWidget {
  final String? token;
  const ScanScreen({super.key, this.token});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _scanImage;
  bool _scanAnalizando = false;
  List<BreedResult> _scanRazas = [];
  final _picker = ImagePicker();

  Future<void> _pickScanImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _scanAnalizando = true;
      _scanImage = File(picked.path);
      _scanRazas = [];
    });

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
        const SnackBar(
          content: Text('No se detectó un perro en la imagen. Intenta de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final razas = await BreedClassifier().classify(picked.path);
    if (!mounted) return;
    setState(() {
      _scanAnalizando = false;
      _scanRazas = razas;
    });

    if (razas.isNotEmpty) {
      await _buscarCoincidencias(razas.first);
    }
  }

  Future<void> _buscarCoincidencias(BreedResult razaPrincipal) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.dogsUrl}/search-by-breed'
        '?raza=${Uri.encodeComponent(razaPrincipal.breed)}&minConfianza=0.6',
      );
      final response = await http.get(
        uri,
        headers: widget.token != null
            ? {'Authorization': 'Bearer ${widget.token}'}
            : {},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> coincidencias = jsonDecode(response.body);
        _mostrarCoincidencias(razaPrincipal, coincidencias);
      }
    } catch (_) {}
  }

  /// Verifica la identidad biométrica del perro de la foto contra la base de datos.
  /// El backend hace la cascada rostro->trufa. Si soloMisPerros=true, compara solo
  /// con los perros del usuario ("confirmar mi perro"); si no, busca en toda la BD.
  Future<void> _verificarBiometrico({required bool soloMisPerros}) async {
    if (_scanImage == null) return;
    setState(() => _scanAnalizando = true);
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('${ApiConstants.dogsUrl}/verificar'));
      if (widget.token != null) {
        request.headers['Authorization'] = 'Bearer ${widget.token}';
      }
      request.fields['soloMisPerros'] = soloMisPerros.toString();
      request.files
          .add(await http.MultipartFile.fromPath('foto', _scanImage!.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (!mounted) return;
      setState(() => _scanAnalizando = false);

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body) as Map<String, dynamic>;
        _mostrarResultadoVerificacion(res, soloMisPerros);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanAnalizando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar: $e')),
      );
    }
  }

  void _mostrarResultadoVerificacion(
      Map<String, dynamic> res, bool soloMisPerros) {
    final bool coincide = res['coincide'] == true;
    final double similitud = (res['similitud'] as num?)?.toDouble() ?? 0;
    final String metodo = res['metodo'] ?? 'ninguno';
    final pct = (similitud * 100).clamp(0, 100).toStringAsFixed(1);

    if (coincide && res['match'] != null) {
      final dog = res['match'] as Map<String, dynamic>;
      final owner = dog['owner'];
      final ownerName = owner != null
          ? '${owner['nombres'] ?? ''} ${owner['apellidos'] ?? ''}'.trim()
          : 'Desconocido';
      final metodoTxt = metodo == 'facial' ? 'rostro' : 'trufa';
      _showMatchDetail(dog, ownerName, '$pct% · $metodoTxt');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.search_off, color: AppColors.error),
              SizedBox(width: 8),
              Text('Sin coincidencia',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            ],
          ),
          content: Text(
            soloMisPerros
                ? 'Ninguno de tus perros coincide con esta foto (mejor similitud $pct%).'
                : 'No hay ningún perro registrado que coincida con esta foto (mejor similitud $pct%).',
            style: const TextStyle(color: AppColors.textSecondary),
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
  }

  // ---- Helpers de UI compartidos (avatar fallback + fila de detalle) ----
  Widget _dogAvatarFallback() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.pets, size: 26, color: AppColors.turquoise),
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

  void _showMatchDetail(
      Map<String, dynamic> dog, String ownerName, String matchPct) {
    final owner = dog['owner'];
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  matchPct,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
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
              _dogDetailRow(Icons.pets, 'Raza', dog['raza'] ?? '-'),
              _dogDetailRow(Icons.male, 'Género', dog['genero'] ?? '-'),
              _dogDetailRow(
                Icons.cake,
                'Edad',
                '${dog['edadAnios'] ?? 0} años ${dog['edadMeses'] ?? 0} meses',
              ),
              _dogDetailRow(
                dog['esterilizado'] == true ? Icons.check_circle : Icons.cancel,
                'Esterilizado',
                dog['esterilizado'] == true ? 'Sí' : 'No',
              ),
              const Divider(height: 24, color: Colors.white24),
              const Row(
                children: [
                  Icon(Icons.person, color: AppColors.turquoise, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Información del dueño',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _dogDetailRow(Icons.person_outline, 'Nombre', ownerName),
              if (owner != null && owner['telefono'] != null)
                _dogDetailRow(Icons.phone, 'Teléfono', owner['telefono']),
              if (owner != null &&
                  owner['email'] != null &&
                  (owner['email'] as String).isNotEmpty)
                _dogDetailRow(Icons.email, 'Correo', owner['email']),
            ],
          ),
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

  void _mostrarCoincidencias(
      BreedResult razaPrincipal, List<dynamic> coincidencias) {
    final pct = (razaPrincipal.confidence * 100).toStringAsFixed(1);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.search, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Coincidencias encontradas',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${razaPrincipal.breed} · $pct% de coincidencia',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
              ),
            ],
          ),
        ),
        content: coincidencias.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No se encontraron perros con más del 60% de esta raza en la base de datos.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: coincidencias.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (_, i) {
                    final dog = coincidencias[i];
                    final owner = dog['owner'];
                    final ownerName = owner != null
                        ? '${owner['nombres'] ?? ''} ${owner['apellidos'] ?? ''}'
                            .trim()
                        : 'Desconocido';
                    final razaMatch = (dog['razasDetectadas'] as List?)
                        ?.firstWhere(
                          (r) => r['raza'] == razaPrincipal.breed,
                          orElse: () => null,
                        );
                    final matchPct = razaMatch != null
                        ? '${((razaMatch['confianza'] as num) * 100).toStringAsFixed(1)}%'
                        : '-';
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      leading: dog['foto'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(
                                dog['foto'],
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _dogAvatarFallback(),
                              ),
                            )
                          : _dogAvatarFallback(),
                      title: Text(
                        dog['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dog['raza'] ?? '-',
                            style: const TextStyle(
                                color: AppColors.turquoise, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ownerName,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.turquoise.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          matchPct,
                          style: const TextStyle(
                            color: AppColors.turquoise,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      onTap: () => _showMatchDetail(dog, ownerName, matchPct),
                    );
                  },
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Buscar por raza',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      if (_scanImage == null && !_scanAnalizando) ...[
                        const GlowingPawLogo(size: 96),
                        const SizedBox(height: 20),
                        const Text(
                          'Identificación por IA',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Toma o sube una foto del perro para detectar su raza '
                          'y buscar coincidencias.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                      ],
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
                      if (_scanAnalizando) ...[
                        const SizedBox(
                          width: 90,
                          height: 90,
                          child: GlowingPawLogo(size: 90),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Analizando imagen...',
                          style: TextStyle(
                              color: AppColors.turquoise, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_scanImage != null && !_scanAnalizando) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            _scanImage!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_scanRazas.isNotEmpty) ...[
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        color: AppColors.turquoise, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Razas detectadas',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ..._scanRazas.map((r) {
                                  final pct =
                                      (r.confidence * 100).toStringAsFixed(1);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              r.breed,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '$pct%',
                                              style: const TextStyle(
                                                color: AppColors.turquoise,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: r.confidence,
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.08),
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                                    AppColors.turquoise),
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
                          const SizedBox(height: 14),
                          GradientButton(
                            label: 'Buscar coincidencias',
                            icon: Icons.search,
                            onPressed: () =>
                                _buscarCoincidencias(_scanRazas.first),
                          ),
                        ],
                        // Verificación biométrica real (rostro->trufa), disponible
                        // en cuanto hay foto, aunque no se haya clasificado la raza.
                        const SizedBox(height: 14),
                        GradientButton(
                          label: 'Identificar dueño (biométrico)',
                          icon: Icons.fingerprint,
                          onPressed: () =>
                              _verificarBiometrico(soloMisPerros: false),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _verificarBiometrico(soloMisPerros: true),
                          icon: const Icon(Icons.verified_user,
                              color: AppColors.turquoise, size: 18),
                          label: const Text('Confirmar que es mi perro',
                              style: TextStyle(color: AppColors.turquoise)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: AppColors.turquoise),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => setState(() {
                                _scanImage = null;
                                _scanRazas = [];
                              }),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.error, size: 18),
                              label: const Text('Eliminar',
                                  style: TextStyle(color: AppColors.error)),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _pickScanImage(ImageSource.camera),
                              icon: const Icon(Icons.refresh,
                                  color: AppColors.turquoise, size: 18),
                              label: const Text('Cambiar',
                                  style:
                                      TextStyle(color: AppColors.turquoise)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: AppColors.ctaGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
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
