class ApiConstants {
  static const String baseUrl = 'http://192.168.0.13:3000';
  static const String authUrl = '$baseUrl/api/auth';
  static const String usersUrl = '$baseUrl/api/users';
  static const String dogsUrl = '$baseUrl/api/dogs';
  static const String identifyUrl = '$baseUrl/api/identify';
}

/// Reglas de identificación biométrica por trufa nasal (ver documento de diseño).
class BiometricConstants {
  static const int minFotosTrufa = 4;
  static const int maxFotosRostro = 2;
  static const int topK = 10;
}
