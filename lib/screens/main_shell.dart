import 'package:flutter/material.dart';
import 'home_page.dart';
import 'historial_screen.dart';
import 'profile_page.dart';
import 'busqueda_esterilizacion_screen.dart';
import 'scan_screen.dart';
import '../core/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

/// Contenedor principal tras el login. Aloja la barra inferior con 3 destinos:
/// Inicio · (patita central = escaneo) · Búsqueda. El perfil ya no vive en la
/// barra: se accede desde el menú de Inicio (ver HomePage.onVerPerfilTap).
class MainShell extends StatefulWidget {
  final String token;
  const MainShell({super.key, required this.token});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _dogCount = 0;

  void _onPawTap() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => ScanScreen(token: widget.token),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estando en un tab distinto de Inicio, el botón atrás del celular vuelve
    // a Inicio en vez de cerrar la app (no hay ruta que desapilar: los tabs
    // viven en un IndexedStack, no en el Navigator).
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDeep,
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: [
            HomePage(
              token: widget.token,
              onDogCountChanged: (c) {
                if (c != _dogCount) setState(() => _dogCount = c);
              },
              onHistorialTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistorialScreen(token: widget.token),
                ),
              ),
              onVerPerfilTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfilePage(token: widget.token, dogCount: _dogCount),
                ),
              ),
            ),
            BusquedaEsterilizacionScreen(
              token: widget.token,
              mostrarBackButton: false,
            ),
          ],
        ),
        bottomNavigationBar: DogBottomNavBar(
          currentIndex: _index,
          onTabSelected: (i) => setState(() => _index = i),
          onPawTap: _onPawTap,
        ),
      ),
    );
  }
}
