import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'register_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_shell.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String carnet = '';
  String password = '';
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _success = false;

  String? _token;

  // Animación de shake para el estado de error de credenciales.
  late final AnimationController _shakeController;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // Progreso de validación del formulario (barra superior).
  double get _formProgress {
    int filled = 0;
    if (carnet.isNotEmpty) filled++;
    if (password.length >= 6) filled++;
    return filled / 2;
  }

  bool get _canSubmit => carnet.isNotEmpty && password.length >= 6;

  void _triggerError(String msg) {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final String url = '${ApiConstants.authUrl}/login';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'carnet': carnet, 'password': password}),
      );
      if (!mounted) return;
      try {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['message'] == 'Login exitoso') {
          _token = data['token'];
          HapticFeedback.lightImpact();
          // Estado 4: login exitoso -> check animado y transición a Home.
          setState(() {
            isLoading = false;
            _success = true;
          });
          await Future.delayed(const Duration(milliseconds: 1000));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => MainShell(token: _token),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        } else {
          setState(() => isLoading = false);
          final msg =
              data['error'] ?? data['message'] ?? 'Error al iniciar sesión';
          _triggerError(msg);
        }
      } catch (e) {
        setState(() => isLoading = false);
        _triggerError('Respuesta inesperada del servidor');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _triggerError('Error de conexión. Verifica tu red.');
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const RegisterPage(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: FadeTransition(opacity: anim, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          AuroraBackground(
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  // Desplazamiento horizontal oscilante para el shake.
                  final dx = _shake.value == 0
                      ? 0.0
                      : (1 - _shake.value) *
                          12 *
                          (((_shakeController.value * 6).floor() % 2 == 0)
                              ? 1
                              : -1);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const GlowingPawLogo(size: 88),
                      const SizedBox(height: 22),
                      const Text(
                        'Bienvenido de nuevo',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Inicia sesión para continuar',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Estado 2: barra de progreso de validación.
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: _formProgress),
                                  duration: const Duration(milliseconds: 300),
                                  builder: (context, value, _) =>
                                      LinearProgressIndicator(
                                    value: value,
                                    minHeight: 4,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.08),
                                    valueColor: const AlwaysStoppedAnimation(
                                        AppColors.turquoise),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              GlassInput(
                                label: 'Correo o Carnet',
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.text,
                                validator: (v) => v != null && v.isNotEmpty
                                    ? null
                                    : 'Campo requerido',
                                onChanged: (v) => setState(() => carnet = v),
                              ),
                              const SizedBox(height: 16),
                              GlassInput(
                                label: 'Contraseña',
                                icon: Icons.lock_outline,
                                obscure: _obscurePassword,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) => v != null && v.length >= 6
                                    ? null
                                    : 'Mínimo 6 caracteres',
                                onChanged: (v) => setState(() => password = v),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(
                                          () => _rememberMe = v ?? false),
                                      activeColor: AppColors.turquoise,
                                      checkColor: AppColors.bgDeep,
                                      side: const BorderSide(
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recordarme',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Flexible(
                                    child: TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Función de recuperación próximamente'),
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      },
                                      child: const Text(
                                        '¿Olvidaste tu contraseña?',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: AppColors.turquoise,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              GradientButton(
                                label: 'Iniciar sesión',
                                loading: isLoading,
                                // Estado 1: CTA deshabilitado si el form está vacío.
                                onPressed: _canSubmit ? _login : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta? ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: _goToRegister,
                            child: const Text(
                              'Crear cuenta',
                              style: TextStyle(
                                color: AppColors.turquoise,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Estado 3: overlay de carga.
          if (isLoading) const Positioned.fill(child: LoadingOverlay()),

          // Estado 4: éxito (check animado + explosión luminosa suave).
          if (_success) const Positioned.fill(child: _SuccessOverlay()),
        ],
      ),
    );
  }
}

/// Overlay de login exitoso: check con escala elástica y halo luminoso.
class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay();

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep.withValues(alpha: 0.85),
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.ctaGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.7),
                  blurRadius: 50,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}
