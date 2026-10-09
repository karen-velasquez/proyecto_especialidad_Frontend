import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import 'auth_widgets.dart';

/// Datos recolectados por el formulario de extravío. Todos opcionales salvo
/// fechaExtravio; se envían como body del PATCH /api/dogs/:id/estado.
class DatosExtravio {
  final String fechaExtravio; // ISO yyyy-MM-dd
  final String? localidadId;
  final String? lugarDescripcion;
  final String? accesorios;
  final String? enfermedad;
  final bool gratificacion;
  final double? montoGratificacion;
  final String? caracteristicasEspeciales;

  DatosExtravio({
    required this.fechaExtravio,
    this.localidadId,
    this.lugarDescripcion,
    this.accesorios,
    this.enfermedad,
    required this.gratificacion,
    this.montoGratificacion,
    this.caracteristicasEspeciales,
  });

  Map<String, dynamic> toJson() => {
        'fechaExtravio': fechaExtravio,
        if (localidadId != null) 'localidad': localidadId,
        if (lugarDescripcion != null && lugarDescripcion!.isNotEmpty)
          'lugarDescripcion': lugarDescripcion,
        if (accesorios != null && accesorios!.isNotEmpty) 'accesorios': accesorios,
        if (enfermedad != null && enfermedad!.isNotEmpty) 'enfermedad': enfermedad,
        'gratificacion': gratificacion,
        if (gratificacion && montoGratificacion != null) 'montoGratificacion': montoGratificacion,
        if (caracteristicasEspeciales != null && caracteristicasEspeciales!.isNotEmpty)
          'caracteristicasEspeciales': caracteristicasEspeciales,
      };
}

/// Pide los datos del extravío antes de marcar al perro como 'extraviado', o
/// los deja editar si se pasa [extravioExistente] (el registro vigente, tal
/// como lo devuelve GET /api/dogs/:id/extravio-vigente ya populado).
/// Devuelve null si el usuario cancela.
Future<DatosExtravio?> showExtravioFormDialog(
  BuildContext context, {
  required String token,
  Map<String, dynamic>? extravioExistente,
}) {
  return showDialog<DatosExtravio>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ExtravioFormDialog(token: token, extravioExistente: extravioExistente),
  );
}

class _ExtravioFormDialog extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? extravioExistente;
  const _ExtravioFormDialog({required this.token, this.extravioExistente});

  @override
  State<_ExtravioFormDialog> createState() => _ExtravioFormDialogState();
}

class _ExtravioFormDialogState extends State<_ExtravioFormDialog> {
  DateTime _fecha = DateTime.now();
  final _lugarCtrl = TextEditingController();
  final _accesoriosCtrl = TextEditingController();
  final _enfermedadCtrl = TextEditingController();
  final _caracteristicasCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  bool _gratificacion = false;

  List<Map<String, dynamic>> _paises = [];
  List<Map<String, dynamic>> _departamentos = [];
  List<Map<String, dynamic>> _localidades = [];
  String? _paisId;
  String? _departamentoId;
  String? _localidadId;
  bool _cargandoUbicacion = true;

  bool get _esEdicion => widget.extravioExistente != null;

  @override
  void initState() {
    super.initState();
    final existente = widget.extravioExistente;
    if (existente != null) {
      _fecha = DateTime.tryParse(existente['fechaExtravio'] ?? '') ?? DateTime.now();
      _lugarCtrl.text = existente['lugarDescripcion'] ?? '';
      _accesoriosCtrl.text = existente['accesorios'] ?? '';
      _enfermedadCtrl.text = existente['enfermedad'] ?? '';
      _caracteristicasCtrl.text = existente['caracteristicasEspeciales'] ?? '';
      _gratificacion = existente['gratificacion'] == true;
      if (existente['montoGratificacion'] != null) {
        _montoCtrl.text = existente['montoGratificacion'].toString();
      }
    }
    _cargarPaises(precargarDesdeExistente: existente != null);
  }

  @override
  void dispose() {
    _lugarCtrl.dispose();
    _accesoriosCtrl.dispose();
    _enfermedadCtrl.dispose();
    _caracteristicasCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPaises({bool precargarDesdeExistente = false}) async {
    try {
      final paises = await fetchPaises(widget.token);
      if (!mounted) return;
      setState(() {
        _paises = paises;
        _cargandoUbicacion = false;
      });

      if (precargarDesdeExistente) {
        final localidad = widget.extravioExistente?['localidad'] as Map<String, dynamic>?;
        final departamento = localidad?['departamento'] as Map<String, dynamic>?;
        final pais = departamento?['pais'] as Map<String, dynamic>?;
        if (pais != null) {
          setState(() => _paisId = pais['_id']);
          await _cargarDepartamentos(pais['_id']);
          if (!mounted) return;
          setState(() => _departamentoId = departamento!['_id']);
          await _cargarLocalidades(departamento!['_id']);
          if (!mounted) return;
          setState(() => _localidadId = localidad!['_id']);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoUbicacion = false);
    }
  }

  Future<void> _cargarDepartamentos(String paisId) async {
    try {
      final departamentos = await fetchDepartamentos(widget.token, paisId);
      if (!mounted) return;
      setState(() => _departamentos = departamentos);
    } catch (_) {}
  }

  Future<void> _cargarLocalidades(String departamentoId) async {
    try {
      final localidades = await fetchLocalidades(widget.token, departamentoId);
      if (!mounted) return;
      setState(() => _localidades = localidades);
    } catch (_) {}
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
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
    if (picked != null) setState(() => _fecha = picked);
  }

  void _enviar() {
    final iso = '${_fecha.year.toString().padLeft(4, '0')}-'
        '${_fecha.month.toString().padLeft(2, '0')}-'
        '${_fecha.day.toString().padLeft(2, '0')}';
    Navigator.pop(
      context,
      DatosExtravio(
        fechaExtravio: iso,
        localidadId: _localidadId,
        lugarDescripcion: _lugarCtrl.text.trim(),
        accesorios: _accesoriosCtrl.text.trim(),
        enfermedad: _enfermedadCtrl.text.trim(),
        gratificacion: _gratificacion,
        montoGratificacion: _gratificacion ? double.tryParse(_montoCtrl.text.trim()) : null,
        caracteristicasEspeciales: _caracteristicasCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _esEdicion ? 'Editar datos del extravío' : 'Datos del extravío',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Fecha en que se perdió',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickFecha,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.turquoise, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Lugar aproximado',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              if (_cargandoUbicacion)
                const Center(child: CircularProgressIndicator(color: AppColors.turquoise))
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: _paisId,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'País', isDense: true),
                  items: [
                    for (final p in _paises)
                      DropdownMenuItem(value: p['_id'] as String, child: Text(p['nombre'])),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _paisId = value;
                      _departamentos = [];
                      _localidades = [];
                      _departamentoId = null;
                      _localidadId = null;
                    });
                    _cargarDepartamentos(value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _departamentoId,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Departamento', isDense: true),
                  items: [
                    for (final d in _departamentos)
                      DropdownMenuItem(value: d['_id'] as String, child: Text(d['nombre'])),
                  ],
                  onChanged: _departamentos.isEmpty
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _departamentoId = value;
                            _localidades = [];
                            _localidadId = null;
                          });
                          _cargarLocalidades(value);
                        },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _localidadId,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Localidad', isDense: true),
                  items: [
                    for (final l in _localidades)
                      DropdownMenuItem(value: l['_id'] as String, child: Text(l['nombre'])),
                  ],
                  onChanged: _localidades.isEmpty
                      ? null
                      : (value) => setState(() => _localidadId = value),
                ),
              ],
              const SizedBox(height: 10),
              GlassInput(
                label: 'Precisar lugar (ej. cerca del mercado X)',
                icon: Icons.location_on_outlined,
                controller: _lugarCtrl,
                maxLength: 200,
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              const Text('Detalles que ayuden a identificarlo',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              GlassInput(
                label: 'Accesorios que llevaba (collar, placa, correa...)',
                icon: Icons.pets,
                controller: _accesoriosCtrl,
                maxLength: 200,
                onChanged: (_) {},
              ),
              const SizedBox(height: 10),
              GlassInput(
                label: 'Enfermedad o condición médica',
                icon: Icons.healing_outlined,
                controller: _enfermedadCtrl,
                maxLength: 200,
                onChanged: (_) {},
              ),
              const SizedBox(height: 10),
              GlassInput(
                label: 'Señas particulares (manchas, comportamiento...)',
                icon: Icons.visibility_outlined,
                controller: _caracteristicasCtrl,
                maxLength: 300,
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('¿Ofreces gratificación?',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    Switch(
                      value: _gratificacion,
                      activeThumbColor: AppColors.turquoise,
                      onChanged: (v) => setState(() => _gratificacion = v),
                    ),
                  ],
                ),
              ),
              if (_gratificacion) ...[
                const SizedBox(height: 10),
                GlassInput(
                  label: 'Monto de la gratificación',
                  icon: Icons.attach_money,
                  controller: _montoCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {},
                ),
              ],
              const SizedBox(height: 24),
              GradientButton(
                label: _esEdicion ? 'Guardar cambios' : 'Continuar',
                icon: Icons.check,
                onPressed: _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
