import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';

/// Barra de navegación inferior dark premium con 3 destinos:
/// Inicio · (patita central elevada = escaneo) · Perfil.
///
/// - [currentIndex]: 0 = Inicio, 1 = Perfil (la patita no es un índice, es acción).
/// - [onTabSelected]: notifica Inicio(0) o Perfil(1).
/// - [onPawTap]: acción del botón central (abrir escaneo).
class DogBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onPawTap;

  const DogBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onPawTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Barra base
          Container(
            height: 72,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Inicio',
                    selected: currentIndex == 0,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTabSelected(0);
                    },
                  ),
                ),
                const SizedBox(width: 72), // hueco para la patita central
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Perfil',
                    selected: currentIndex == 1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTabSelected(1);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Botón central elevado (patita -> escaneo)
          Positioned(
            bottom: 36,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onPawTap();
              },
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.ctaGradient,
                  border: Border.all(color: AppColors.bgDeep, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.turquoise.withValues(alpha: 0.55),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.45),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.pets, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.turquoise : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.turquoise.withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                    ]
                  : [],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
