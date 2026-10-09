import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Traduce una excepción de red/HTTP a un mensaje legible para el usuario,
/// en vez del texto técnico crudo (ClientException, SocketException, etc.).
/// Usar en los catch de llamadas a la API: `_error = mensajeDeError(e);`
String mensajeDeError(Object e) {
  if (e is SocketException || e.toString().contains('No route to host')) {
    return 'No se pudo conectar al servidor. Verifica que tu celular esté '
        'conectado a la misma red Wi-Fi que el servidor.';
  }
  if (e.toString().contains('TimeoutException')) {
    return 'El servidor no respondió a tiempo. Intenta de nuevo.';
  }
  if (e is FormatException || e.toString().contains('FormatException')) {
    return 'El servidor respondió con datos inesperados. Intenta de nuevo.';
  }
  return 'Ocurrió un problema de conexión. Intenta de nuevo.';
}

/// Extrae el mensaje legible de una respuesta HTTP de error (body JSON tipo
/// {"error": "..."}), en vez de mostrar el JSON crudo en pantalla.
/// Si el body no es JSON válido, cae a un mensaje genérico.
String mensajeDeRespuesta(http.Response response) {
  try {
    final data = jsonDecode(response.body);
    if (data is Map && data['error'] != null) return data['error'].toString();
  } catch (_) {
    // Body no era JSON; usar el mensaje genérico de abajo.
  }
  return 'El servidor respondió con un error (${response.statusCode}). Intenta de nuevo.';
}

class ApiConstants {
  static const String baseUrl = 'http://192.168.0.15:3000';
  static const String authUrl = '$baseUrl/api/auth';
  static const String usersUrl = '$baseUrl/api/users';
  static const String dogsUrl = '$baseUrl/api/dogs';
  static const String identifyUrl = '$baseUrl/api/identify';
  static const String breedsUrl = '$baseUrl/api/breeds';
  static const String notificacionesUrl = '$baseUrl/api/notificaciones';
  static const String ubicacionUrl = '$baseUrl/api/ubicacion';
}

/// Reglas de identificación biométrica por trufa nasal (ver documento de diseño).
class BiometricConstants {
  static const int minFotosTrufa = 4;
  static const int maxFotosRostro = 2;
  static const int topK = 10;
}

/// Mensajes rápidos para notificar al dueño de un perro.
class NotificacionConstants {
  static const int maxCaracteres = 200;

  /// Perro no extraviado: probablemente el dueño no sabe que anda suelto.
  static const List<String> mensajesPredeterminados = [
    'He visto a tu perro.',
    '¿Tu perro está extraviado? Porque acabo de verlo.',
    'Creo que tu perro anda suelto por la zona.',
  ];

  /// Perro ya marcado como extraviado: el dueño ya lo sabe, esto es solo
  /// un respaldo por si no contesta el teléfono.
  static const List<String> mensajesPredeterminadosExtraviado = [
    'Vi a tu perro, ¿cómo te contacto?',
    'Creo que encontré a tu perro extraviado.',
    'Avísame si todavía estás buscando a tu perro, lo vi.',
  ];
}

/// Razas seleccionables manualmente por el usuario (dato descriptivo, ver D5
/// del documento de diseño) — no hay clasificación automática por IA.
/// Vienen de la colección Breed en el backend, no de una lista fija, para
/// poder agregar razas nuevas sin tocar código (ver /api/breeds).
Future<List<String>> fetchRazas(String token) async {
  final response = await http.get(
    Uri.parse(ApiConstants.breedsUrl),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) {
    throw Exception('No se pudo cargar la lista de razas');
  }
  return List<String>.from(jsonDecode(response.body));
}

/// Catálogo jerárquico de ubicación (Pais -> Departamento -> Localidad),
/// usado por el selector de ubicación en el perfil del usuario. Cada item
/// es {'_id': ..., 'nombre': ...}.
Future<List<Map<String, dynamic>>> fetchPaises(String token) async {
  final response = await http.get(
    Uri.parse('${ApiConstants.ubicacionUrl}/paises'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) {
    throw Exception('No se pudo cargar la lista de países');
  }
  return List<Map<String, dynamic>>.from(jsonDecode(response.body));
}

Future<List<Map<String, dynamic>>> fetchDepartamentos(String token, String paisId) async {
  final response = await http.get(
    Uri.parse('${ApiConstants.ubicacionUrl}/departamentos?pais=$paisId'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) {
    throw Exception('No se pudo cargar la lista de departamentos');
  }
  return List<Map<String, dynamic>>.from(jsonDecode(response.body));
}

Future<List<Map<String, dynamic>>> fetchLocalidades(String token, String departamentoId) async {
  final response = await http.get(
    Uri.parse('${ApiConstants.ubicacionUrl}/localidades?departamento=$departamentoId'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) {
    throw Exception('No se pudo cargar la lista de localidades');
  }
  return List<Map<String, dynamic>>.from(jsonDecode(response.body));
}
