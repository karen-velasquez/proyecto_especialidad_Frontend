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
  final _formKey = GlobalKey<FormState>();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _fechaController = TextEditingController();

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
    _nombresController.dispose();
    _apellidosController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  // --- Validez individual de cada campo (para los checks verdes) ---
  bool get _nombresOk => nombres.trim().isNotEmpty;
  bool get _apellidosOk => apellidos.trim().isNotEmpty;
  bool get _carnetOk => carnet.trim().isNotEmpty;
  bool get _fechaOk => fechaNacimiento.isNotEmpty;
  bool get _emailOk => email.isEmpty || email.contains('@');
  bool get _telefonoOk => telefono.trim().length > 6; // sin verificación OTP
  bool get _passwordOk => password.length >= 6;
  bool get _confirmOk => confirmPassword.isNotEmpty && confirmPassword == password;

  // Progreso del formulario (0..1) para la barra superior.
  double get _progress {
    final checks = [
      _nombresOk,
      _apellidosOk,
      _carnetOk,
      _fechaOk,
      _emailOk,
      _telefonoOk,
      _passwordOk,
      _confirmOk,
    ];
    final done = checks.where((c) => c).length;
    return done / checks.length;
  }

  bool get _canSubmit =>
      _nombresOk &&
      _apellidosOk &&
      _carnetOk &&
      _fechaOk &&
      _emailOk &&
      _telefonoOk &&
      _passwordOk &&
      _confirmOk;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
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
    // Pantalla 4: cuenta creada con éxito (confetti + acciones).
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: AppColors.textPrimary),
                          onPressed: () => Navigator.pop(context),
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

                  // Hero + título
                  const GlowingPawLogo(size: 70),
                  const SizedBox(height: 14),
                  const Text(
                    'Crea tu cuenta',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Registra tus datos para comenzar a proteger a tu mascota.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card con formulario
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: GlassCard(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Barra de progreso del formulario
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: _progress),
                                  duration: const Duration(milliseconds: 300),
                                  builder: (context, value, _) =>
                                      LinearProgressIndicator(
                                    value: value,
                                    minHeight: 5,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.08),
                                    valueColor: const AlwaysStoppedAnimation(
                                        AppColors.turquoise),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              _sectionTitle('Información personal'),

                              // Nombres y Apellidos
                              Row(
                                children: [
                                  Expanded(
                                    child: GlassInput(
                                      controller: _nombresController,
                                      label: 'Nombres',
                                      icon: Icons.person_outline,
                                      inputFormatters: [_upperCaseFormatter],
                                      suffix: _check(_nombresOk),
                                      validator: (v) => v != null &&
                                              v.isNotEmpty
                                          ? null
                                          : 'Requerido',
                                      onChanged: (v) =>
                                          setState(() => nombres = v),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GlassInput(
                                      controller: _apellidosController,
                                      label: 'Apellidos',
                                      icon: Icons.person_outline,
                                      inputFormatters: [_upperCaseFormatter],
                                      suffix: _check(_apellidosOk),
                                      validator: (v) => v != null &&
                                              v.isNotEmpty
                                          ? null
                                          : 'Requerido',
                                      onChanged: (v) =>
                                          setState(() => apellidos = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              GlassInput(
                                label: 'Carnet de identidad',
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.number,
                                suffix: _check(_carnetOk),
                                validator: (v) => v != null && v.isNotEmpty
                                    ? null
                                    : 'Carnet requerido',
                                onChanged: (v) => setState(() => carnet = v),
                              ),
                              const SizedBox(height: 14),

                              // Fecha de nacimiento
                              GlassInput(
                                controller: _fechaController,
                                label: 'Fecha de nacimiento',
                                icon: Icons.calendar_today_outlined,
                                readOnly: true,
                                onTap: _pickDate,
                                suffix: _check(
                                  _fechaOk,
                                  otherwise: const Icon(Icons.arrow_drop_down,
                                      color: AppColors.textSecondary),
                                ),
                                validator: (_) => fechaNacimiento.isNotEmpty
                                    ? null
                                    : 'Fecha requerida',
                              ),
                              const SizedBox(height: 14),

                              // Correo (opcional)
                              GlassInput(
                                label: 'Correo electrónico (opcional)',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                suffix: email.isNotEmpty
                                    ? _check(_emailOk)
                                    : null,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return null;
                                  return v.contains('@') ? null : 'Correo inválido';
                                },
                                onChanged: (v) => setState(() => email = v),
                              ),
                              const SizedBox(height: 14),

                              // Teléfono con bandera + código país (sin OTP)
                              IntlPhoneField(
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                                dropdownTextStyle: const TextStyle(
                                    color: AppColors.textPrimary),
                                showCountryFlag: true,
                                decoration: _phoneDecoration('Teléfono'),
                                initialCountryCode: 'BO',
                                keyboardType: TextInputType.phone,
                                disableLengthCheck: true,
                                onChanged: (phone) {
                                  setState(() {
                                    telefono = phone.completeNumber;
                                  });
                                },
                              ),
                              const SizedBox(height: 22),

                              _sectionTitle('Información de acceso'),

                              // Contraseña + medidor de fuerza
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
                              PasswordStrengthBar(
                                strength: evaluatePassword(password),
                              ),
                              const SizedBox(height: 14),

                              // Confirmar contraseña
                              GlassInput(
                                label: 'Confirmar contraseña',
                                icon: Icons.lock_reset_outlined,
                                obscure: _obscureConfirm,
                                suffix: _confirmOk
                                    ? _check(true)
                                    : IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscureConfirm = !_obscureConfirm),
                                      ),
                                validator: (v) =>
                                    v == password ? null : 'No coincide',
                                onChanged: (v) =>
                                    setState(() => confirmPassword = v),
                              ),
                              const SizedBox(height: 28),

                              GradientButton(
                                label: 'Crear cuenta',
                                loading: isLoading,
                                onPressed: _canSubmit ? _register : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay "Creando cuenta"
          if (isLoading)
            const Positioned.fill(child: CreatingAccountOverlay()),
        ],
      ),
    );
  }
}
