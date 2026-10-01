import 'package:flutter/material.dart';

/// Paleta "Dark Premium" para DogBiometría.
/// Inspiración: pet-tech futurista (turquesa eléctrico, azul, morado neón)
/// sobre fondos azul marino profundo con glassmorphism y soft glow.
class AppColors {
  // ---- Fondos ----
  static const bgDeep = Color(0xFF07111F); // azul marino profundo
  static const bgNight = Color(0xFF0B1020); // negro azulado
  static const surface = Color(0xFF111A2E); // superficie de tarjetas sólidas

  // ---- Colores de marca / acento ----
  static const turquoise = Color(0xFF00D9D9); // turquesa eléctrico
  static const blue = Color(0xFF3B82F6); // azul brillante
  static const purple = Color(0xFF8B5CF6); // morado neón

  // ---- Texto ----
  static const textPrimary = Color(0xFFF1F5FF);
  static const textSecondary = Color(0xFF9AA8C7);

  // ---- Estados ----
  static const error = Color(0xFFFF5C7A);
  static const success = Color(0xFF2EE6A8);

  // ---- Gradiente del CTA: morado -> turquesa ----
  static const ctaGradient = LinearGradient(
    colors: [purple, turquoise],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ---- Gradiente de marca (logo / acentos) ----
  static const brandGradient = LinearGradient(
    colors: [turquoise, blue, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---- Gradiente de fondo de pantalla ----
  static const bgGradient = LinearGradient(
    colors: [bgNight, bgDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ---------------------------------------------------------------
  // Alias de compatibilidad: pantallas antiguas (home, perfil, etc.)
  // siguen referenciando estos nombres. Se mapean a la nueva paleta.
  // ---------------------------------------------------------------
  static const primary = turquoise;
  static const dark = bgDeep;
  static const secondary = blue;
  static const accent = purple;
  static const highlight = turquoise;
}
