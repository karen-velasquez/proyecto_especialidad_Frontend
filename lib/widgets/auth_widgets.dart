import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';

/// ---------------------------------------------------------------------------
/// Fondo premium: gradiente azul marino + orbes de luz difuminados (glow).
/// Usado como capa base de todas las pantallas de autenticación.
/// ---------------------------------------------------------------------------
class AuroraBackground extends StatelessWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: Stack(
        children: [
          // Orbe turquesa arriba-izquierda
          Positioned(
            top: -120,
            left: -100,
            child: _GlowOrb(color: AppColors.turquoise, size: 320),
          ),
          // Orbe morado abajo-derecha
          Positioned(
            bottom: -140,
            right: -120,
            child: _GlowOrb(color: AppColors.purple, size: 360),
          ),
          // Orbe azul centro-derecha, más sutil
          Positioned(
            top: 220,
            right: -80,
            child: _GlowOrb(color: AppColors.blue, size: 220, opacity: 0.35),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _GlowOrb({required this.color, required this.size, this.opacity = 0.5});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Logo: huella de perro dentro de un círculo luminoso con glow pulsante.
/// ---------------------------------------------------------------------------
class GlowingPawLogo extends StatefulWidget {
  final double size;
  const GlowingPawLogo({super.key, this.size = 96});

  @override
  State<GlowingPawLogo> createState() => _GlowingPawLogoState();
}

class _GlowingPawLogoState extends State<GlowingPawLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final glow = 0.35 + _c.value * 0.45; // pulso del resplandor
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0x3300D9D9), Color(0x338B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.turquoise.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.turquoise.withValues(alpha: glow * 0.6),
                blurRadius: 30,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.purple.withValues(alpha: glow * 0.5),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(
            Icons.pets,
            size: widget.size * 0.5,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tarjeta de cristal (glassmorphism): blur + borde translúcido + glow suave.
/// ---------------------------------------------------------------------------
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Input de cristal con focus glow turquesa y elevación suave al enfocar.
/// ---------------------------------------------------------------------------
class GlassInput extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  const GlassInput({
    super.key,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.controller,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() => setState(() => _focused = _node.hasFocus));
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _focused ? -2 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.turquoise.withValues(alpha: 0.30),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        focusNode: _node,
        controller: widget.controller,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        validator: widget.validator,
        onChanged: widget.onChanged,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        cursorColor: AppColors.turquoise,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _focused ? AppColors.turquoise : AppColors.textSecondary,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: _focused ? AppColors.turquoise : AppColors.textSecondary,
          ),
          suffixIcon: widget.suffix,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.turquoise, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.error, width: 1.6),
          ),
          errorStyle: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Botón principal con gradiente morado->turquesa, glow y escala al presionar.
/// ---------------------------------------------------------------------------
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: AppColors.turquoise.withValues(alpha: 0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Overlay de carga elegante: huella girando + glow pulsante con textos.
/// ---------------------------------------------------------------------------
class LoadingOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  const LoadingOverlay({
    super.key,
    this.title = 'Verificando credenciales',
    this.subtitle = 'Conectando con DogBiometría',
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep.withValues(alpha: 0.78),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final pulse = 0.4 + (math.sin(_c.value * math.pi * 2) + 1) / 2 * 0.5;
                  return Transform.rotate(
                    angle: _c.value * 2 * math.pi,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.turquoise.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.turquoise.withValues(alpha: pulse * 0.7),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.pets,
                          color: Colors.white, size: 36),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Indicador de fuerza de contraseña: barra animada (débil/media/fuerte).
/// ---------------------------------------------------------------------------
enum PasswordStrength { none, weak, medium, strong }

PasswordStrength evaluatePassword(String value) {
  if (value.isEmpty) return PasswordStrength.none;
  int score = 0;
  if (value.length >= 6) score++;
  if (value.length >= 10) score++;
  if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
    score++;
  }
  if (RegExp(r'[0-9]').hasMatch(value)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
  if (score <= 2) return PasswordStrength.weak;
  if (score <= 3) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

class PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  const PasswordStrengthBar({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    final config = switch (strength) {
      PasswordStrength.none => (0.0, AppColors.textSecondary, ''),
      PasswordStrength.weak => (0.33, AppColors.error, 'Débil'),
      PasswordStrength.medium => (0.66, const Color(0xFFFACC15), 'Media'),
      PasswordStrength.strong => (1.0, AppColors.success, 'Fuerte'),
    };
    if (strength == PasswordStrength.none) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: config.$1),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(config.$2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            config.$3,
            style: TextStyle(
              color: config.$2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Check verde animado que aparece en un campo cuando su valor es válido.
/// ---------------------------------------------------------------------------
class ValidCheck extends StatelessWidget {
  final bool visible;
  const ValidCheck({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: const Icon(Icons.check_circle, color: AppColors.success, size: 22),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Overlay "Creando cuenta": huella girando + partículas + barra infinita.
/// ---------------------------------------------------------------------------
class CreatingAccountOverlay extends StatelessWidget {
  const CreatingAccountOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDeep.withValues(alpha: 0.85),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 110, height: 110, child: _SpinningPaw()),
              const SizedBox(height: 30),
              const Text(
                'Estamos creando tu cuenta',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preparando todo para ti y tu mascota',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.turquoise),
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

class _SpinningPaw extends StatefulWidget {
  const _SpinningPaw();

  @override
  State<_SpinningPaw> createState() => _SpinningPawState();
}

class _SpinningPawState extends State<_SpinningPaw>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pulse = 0.4 + (math.sin(_c.value * math.pi * 2) + 1) / 2 * 0.5;
        return Transform.rotate(
          angle: _c.value * 2 * math.pi,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0x3300D9D9), Color(0x338B5CF6)],
              ),
              border: Border.all(
                color: AppColors.turquoise.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.turquoise.withValues(alpha: pulse * 0.7),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: pulse * 0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.pets, color: Colors.white, size: 44),
            ),
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Pantalla de éxito: confetti + check con glow verde + botones de acción.
/// ---------------------------------------------------------------------------
class SuccessScreen extends StatefulWidget {
  final VoidCallback onContinue;
  const SuccessScreen({super.key, required this.onContinue});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _checkCtrl;
  late final List<_Confetti> _pieces;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    final colors = [
      AppColors.turquoise,
      AppColors.blue,
      AppColors.purple,
      AppColors.success,
      const Color(0xFFFACC15),
    ];
    _pieces = List.generate(80, (i) {
      return _Confetti(
        x: rnd.nextDouble(),
        startY: -0.2 - rnd.nextDouble() * 0.4,
        speed: 0.4 + rnd.nextDouble() * 0.8,
        size: 6 + rnd.nextDouble() * 8,
        color: colors[rnd.nextInt(colors.length)],
        drift: (rnd.nextDouble() - 0.5) * 0.3,
        rotationSpeed: (rnd.nextDouble() - 0.5) * 8,
      );
    });
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..forward();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: Stack(
          children: [
            // Confetti
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(_pieces, _confettiCtrl.value),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: CurvedAnimation(
                          parent: _checkCtrl, curve: Curves.elasticOut),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(alpha: 0.15),
                          border: Border.all(
                              color: AppColors.success, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.success.withValues(alpha: 0.6),
                              blurRadius: 50,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: AppColors.success, size: 72),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '¡Cuenta creada con éxito!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ya puedes registrar y gestionar la información '
                      'de tus mascotas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    GradientButton(
                      label: 'Continuar',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: widget.onContinue,
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: widget.onContinue,
                      child: const Text(
                        'Ir al inicio',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Confetti {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double drift;
  final double rotationSpeed;
  _Confetti({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.drift,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final progress = p.startY + p.speed * t * 1.6;
      if (progress < -0.2 || progress > 1.2) continue;
      final dx = (p.x + p.drift * t) * size.width;
      final dy = progress * size.height;
      final paint = Paint()..color = p.color.withValues(alpha: 0.9);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotationSpeed * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
