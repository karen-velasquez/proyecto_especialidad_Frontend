class ApiConstants {
  static const String baseUrl = 'http://192.168.0.15:3000';
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

/// Razas seleccionables manualmente por el usuario (dato descriptivo, ver D5
/// del documento de diseño) — no hay clasificación automática por IA.
const List<String> kRazas = [
  'Mestizo',
  'Akita',
  'Australian Shepherd',
  'Basset Hound',
  'Beagle',
  'Bernese Mountain Dog',
  'Bichón Frisé',
  'Border Collie',
  'Boxer',
  'Bulldog Francés',
  'Bulldog Inglés',
  'Chihuahua',
  'Chow Chow',
  'Cocker Spaniel',
  'Dachshund',
  'Dálmata',
  'Dobermann',
  'Golden Retriever',
  'Gran Danés',
  'Labrador Retriever',
  'Maltés',
  'Pastor Alemán',
  'Pitbull',
  'Pomerania',
  'Poodle',
  'Pug',
  'Rottweiler',
  'Samoyedo',
  'Schnauzer',
  'Shar Pei',
  'Shiba Inu',
  'Shih Tzu',
  'Siberian Husky',
  'Weimaraner',
  'Yorkshire Terrier',
];
