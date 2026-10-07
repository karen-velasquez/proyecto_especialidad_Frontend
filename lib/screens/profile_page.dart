import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'edit_profile_sheet.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';

/// Pantalla de perfil del usuario (dark premium): datos personales y editar
/// perfil. Cerrar sesión vive en el menú del header de HomePage.
class ProfilePage extends StatefulWidget {
  final String? token;
  final int dogCount;
  const ProfilePage({super.key, this.token, this.dogCount = 0});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.usersUrl}/me'),
        headers: widget.token != null
            ? {'Authorization': 'Bearer ${widget.token}'}
            : {},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _profile = jsonDecode(response.body);
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _subiendoFoto = false;

  void _verFotoPerfil() {
    final foto = _profile?['foto'];
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
              child: foto != null
                  ? Image.network(
                      foto,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _fotoPlaceholder(),
                    )
                  : _fotoPlaceholder(),
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

  Widget _fotoPlaceholder() {
    return Container(
      width: 220,
      height: 220,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
      child: const Icon(Icons.person, color: Colors.white, size: 100),
    );
  }

  Future<void> _cambiarFoto() async {
    if (widget.token == null) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.turquoise),
              title: const Text('Tomar foto', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.turquoise),
              title: const Text('Elegir de galería', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _subiendoFoto = true);
    try {
      final request = http.MultipartRequest('PUT', Uri.parse('${ApiConstants.usersUrl}/me/foto'));
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.files.add(await http.MultipartFile.fromPath('foto', picked.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (!mounted) return;

      if (response.statusCode == 200) {
        await _load();
        if (mounted) setState(() => _subiendoFoto = false);
      } else {
        setState(() => _subiendoFoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la foto: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _subiendoFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar: $e')),
      );
    }
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditProfileSheet(token: widget.token),
    ).then((_) => _load());
  }

  String get _fullName {
    if (_profile == null) return 'Mi perfil';
    final n = '${_profile!['nombres'] ?? ''} ${_profile!['apellidos'] ?? ''}'
        .trim();
    return n.isEmpty ? 'Mi perfil' : n;
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.turquoise),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mi perfil',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _editProfile,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                          ),
                          child: const Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar + nombre
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _subiendoFoto ? null : _verFotoPerfil,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.brandGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.turquoise.withValues(alpha: 0.45),
                                      blurRadius: 26,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: _subiendoFoto
                                    ? const Center(
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : (_profile?['foto'] != null
                                        ? ClipOval(
                                            child: Image.network(
                                              _profile!['foto'],
                                              width: 140,
                                              height: 140,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.person, color: Colors.white, size: 68),
                                            ),
                                          )
                                        : const Icon(Icons.person, color: Colors.white, size: 68)),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _subiendoFoto ? null : _cambiarFoto,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.bgDeep, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: AppColors.turquoise, size: 26),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.dogCount} mascota${widget.dogCount == 1 ? '' : 's'} registrada${widget.dogCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Datos personales
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información personal',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _infoRow(Icons.badge_outlined, 'Carnet',
                            _profile?['carnet']?.toString()),
                        _infoRow(Icons.email_outlined, 'Correo',
                            _profile?['email']),
                        _infoRow(Icons.phone_outlined, 'Teléfono',
                            _profile?['telefono']),
                        _infoRow(
                          Icons.cake_outlined,
                          'Nacimiento',
                          _profile?['fechaNacimiento'] is String
                              ? (_profile!['fechaNacimiento'] as String)
                                  .substring(0, 10)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                ],
              ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    final shown = (value == null || value.isEmpty) ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.turquoise, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              shown,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
