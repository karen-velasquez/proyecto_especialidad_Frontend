import 'package:shared_preferences/shared_preferences.dart';

/// Persiste el JWT entre sesiones. El registro de un perro ahora es un flujo
/// de varias pantallas con red de por medio (datos, foto perfil, 4 fotos de
/// trufa, 2 de rostro); perder el token a mitad de camino sería muy costoso.
class AuthStorage {
  static const _key = 'jwt_token';

  static Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> leerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> borrarToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
