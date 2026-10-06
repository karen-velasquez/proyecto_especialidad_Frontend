import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:convert';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../widgets/auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _totalSteps = 3;

  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _carnetController = TextEditingController();
  final _fechaController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();

  int _step = 0;
  String nombres = '';
  String apellidos = '';
  String carnet = '';
  String fechaNacimiento = '';
  String telefono = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  bool isLoading = false;
  bool _success = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _upperCaseFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) => newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    ),
  );

  @override
  void dispose() {
    _pageController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _carnetController.dispose();
    _fechaController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  // --- Validez individual de cada campo (para los checks verdes) ---
  bool get _nombresOk => nombres.trim().length >= 3;
  bool get _apellidosOk => apellidos.trim().length >= 3;
  bool get _carnetOk => carnet.trim().length >= 5;
  bool get _fechaOk => fechaNacimiento.isNotEmpty;
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  bool get _emailOk => email.isEmpty || _emailRegex.hasMatch(email);

  /// Feedback progresivo mientras se escribe el correo (null = sin problema que mostrar).
  String? get _emailHint {
    if (email.isEmpty) return null;
    if (!email.contains('@')) return 'Falta el @';
    final dominio = email.split('@').last;
    if (dominio.isEmpty) return 'Falta el dominio, ej: gmail.com';
    if (!dominio.contains('.')) return 'Falta la extensión, ej: .com';
    if (dominio.endsWith('.')) return 'Completa la extensión, ej: .com';
    if (_emailOk) return null;
    return 'Correo inválido';
  }
  bool get _telefonoOk => telefono.trim().length > 6; // sin verificación OTP
  bool get _passwordOk => password.length >= 6;
  bool get _confirmOk => confirmPassword.isNotEmpty && confirmPassword == password;

  bool get _step1Ok => _nombresOk && _apellidosOk && _carnetOk && _fechaOk;
  bool get _step2Ok => _emailOk && _telefonoOk;
  bool get _canSubmit => _step1Ok && _step2Ok && _passwordOk && _confirmOk;

  void _nextStep() {
    final formKey = switch (_step) {
      0 => _step1FormKey,
      1 => _step2FormKey,
      _ => _step3FormKey,
    };
    if (!formKey.currentState!.validate()) return;
    if (_step == 0 && !_step1Ok) return;
    if (_step == 1 && !_step2Ok) return;

    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _register();
    }
  }

  void _previousStep() {
    if (_step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _step--);
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _register() async {
    if (!_step3FormKey.currentState!.validate()) return;
    if (!_confirmOk) {
      _showError('Las contraseñas no coinciden');
      return;
    }
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.authUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombres': nombres,
          'apellidos': apellidos,
          'carnet': carnet,
          'fechaNacimiento': fechaNacimiento,
          'telefono': telefono,
          'email': email,
          'password': password,
        }),
      );
      if (!mounted) return;
      try {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Pequeña pausa para que se aprecie el overlay "Creando cuenta".
          await Future.delayed(const Duration(milliseconds: 900));
          if (!mounted) return;
          setState(() {
            isLoading = false;
            _success = true; // -> pantalla de éxito con confetti
          });
        } else {
          setState(() => isLoading = false);
          final msg = data['error'] ?? data['message'] ?? 'Error al registrar';
          _showError(msg);
        }
      } catch (e) {
        setState(() => isLoading = false);
        _showError('Respuesta inesperada del servidor');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Error de conexión. Verifica tu red.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Decoración dark para el campo de teléfono (IntlPhoneField no usa GlassInput).
  InputDecoration _phoneDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      suffixIcon: _telefonoOk
          ? const Padding(
              padding: EdgeInsets.only(right: 8),
              child: ValidCheck(visible: true),
            )
          : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.turquoise, width: 1.6),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.turquoise,
            onPrimary: AppColors.bgDeep,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final today = DateTime.now();
      final age = today.year -
          picked.year -
          ((today.month < picked.month ||
                  (today.month == picked.month && today.day < picked.day))
              ? 1
              : 0);
      if (!mounted) return;
      if (age < 18) {
        _showError('Debes tener al menos 18 años para registrarte');
        return;
      }
      setState(() {
        fechaNacimiento = '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
        _fechaController.text = fechaNacimiento;
      });
    }
  }

  // Sufijo de un GlassInput: check verde si es válido, o un widget opcional.
  Widget? _check(bool ok, {Widget? otherwise}) {
    if (ok) {
      return const Padding(
        padding: EdgeInsets.only(right: 8),
        child: ValidCheck(visible: true),
      );
    }
    return otherwise;
  }

  void _finishRegistration() {
    // Vuelve al login para que el usuario inicie sesión con su nueva cuenta.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla final: cuenta creada con éxito (confetti + acciones).
    if (_success) {
      return SuccessScreen(onContinue: _finishRegistration);
    }

    return Scaffold(
      body: Stack(
        children: [
          AuroraBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                          onPressed: _previousStep,
                        ),
                        const Expanded(
                          child: Text(
                            'Crear cuenta',
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

                  // Barra de progreso por pasos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: (_step + 1) / _totalSteps),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: const AlwaysStoppedAnimation(AppColors.turquoise),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paso ${_step + 1} de $_totalSteps',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // Hero + título
                  const GlowingPawLogo(size: 56),
                  const SizedBox(height: 10),
                  Text(
                    switch (_step) {
                      0 => 'Información personal',
                      1 => 'Datos de contacto',
                      _ => 'Información de acceso',
                    },
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pasos del formulario
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                        _buildStep3(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay "Creando cuenta"
          if (isLoading) const Positioned.fill(child: CreatingAccountOverlay()),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _step1FormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Nombre y documento'),
              GlassInput(
                controller: _nombresController,
                label: 'Nombres',
                icon: Icons.person_outline,
                inputFormatters: [_upperCaseFormatter],
                maxLength: 50,
                suffix: _check(_nombresOk),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  return v.trim().length >= 3 ? null : 'Mínimo 3 caracteres';
                },
                onChanged: (v) => setState(() => nombres = v),
              ),
              const SizedBox(height: 14),
              GlassInput(
                controller: _apellidosController,
                label: 'Apellidos',
                icon: Icons.person_outline,
                inputFormatters: [_upperCaseFormatter],
                maxLength: 50,
                suffix: _check(_apellidosOk),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  return v.trim().length >= 3 ? null : 'Mínimo 3 caracteres';
                },
                onChanged: (v) => setState(() => apellidos = v),
              ),
              const SizedBox(height: 14),
              GlassInput(
                controller: _carnetController,
                label: 'Carnet de identidad',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                maxLength: 15,
                suffix: _check(_carnetOk),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Carnet requerido';
                  return v.length >= 5 ? null : 'Mínimo 5 caracteres';
                },
                onChanged: (v) => setState(() => carnet = v),
              ),
              const SizedBox(height: 14),
              GlassInput(
                controller: _fechaController,
                label: 'Fecha de nacimiento',
                icon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickDate,
                suffix: _check(
                  _fechaOk,
                  otherwise: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                ),
                validator: (_) => fechaNacimiento.isNotEmpty ? null : 'Fecha requerida',
              ),
              const SizedBox(height: 28),
              GradientButton(label: 'Siguiente', icon: Icons.arrow_forward, onPressed: _nextStep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _step2FormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Cómo contactarte'),
              GlassInput(
                controller: _emailController,
                label: 'Correo electrónico (opcional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                maxLength: 254,
                suffix: email.isNotEmpty ? _check(_emailOk) : null,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  return _emailOk ? null : 'Correo inválido';
                },
                onChanged: (v) => setState(() => email = v),
              ),
              if (_emailHint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    _emailHint!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 14),
              IntlPhoneField(
                controller: _telefonoController,
                style: const TextStyle(color: AppColors.textPrimary),
                dropdownTextStyle: const TextStyle(color: AppColors.textPrimary),
                showCountryFlag: true,
                decoration: _phoneDecoration('Teléfono'),
                initialCountryCode: 'BO',
                keyboardType: TextInputType.phone,
                onChanged: (phone) => setState(() => telefono = phone.completeNumber),
              ),
              const SizedBox(height: 28),
              GradientButton(label: 'Siguiente', icon: Icons.arrow_forward, onPressed: _nextStep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _step3FormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Protege tu cuenta'),
              GlassInput(
                label: 'Contraseña',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                maxLength: 72,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
                onChanged: (v) => setState(() => password = v),
              ),
              PasswordStrengthBar(strength: evaluatePassword(password)),
              const SizedBox(height: 14),
              GlassInput(
                label: 'Confirmar contraseña',
                icon: Icons.lock_reset_outlined,
                obscure: _obscureConfirm,
                maxLength: 72,
                suffix: _confirmOk
                    ? _check(true)
                    : IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                validator: (v) => v == password ? null : 'No coincide',
                onChanged: (v) => setState(() => confirmPassword = v),
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: 'Crear cuenta',
                loading: isLoading,
                onPressed: _canSubmit ? _nextStep : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
