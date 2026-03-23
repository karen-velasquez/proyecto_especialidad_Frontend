import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// Razas de perro en ImageNet (indices del modelo yolov8n-cls)
// Solo las clases que son razas de perro
const Map<int, String> kImageNetDogBreeds = {
  151: 'Chihuahua',
  152: 'Japanese Spaniel',
  153: 'Maltese Dog',
  154: 'Pekinese',
  155: 'Shih Tzu',
  156: 'Blenheim Spaniel',
  157: 'Papillon',
  158: 'Toy Terrier',
  159: 'Rhodesian Ridgeback',
  160: 'Afghan Hound',
  161: 'Basset',
  162: 'Beagle',
  163: 'Bloodhound',
  164: 'Bluetick',
  165: 'Black And Tan Coonhound',
  166: 'Walker Hound',
  167: 'English Foxhound',
  168: 'Redbone',
  169: 'Borzoi',
  170: 'Irish Wolfhound',
  171: 'Italian Greyhound',
  172: 'Whippet',
  173: 'Ibizan Hound',
  174: 'Norwegian Elkhound',
  175: 'Otterhound',
  176: 'Saluki',
  177: 'Scottish Deerhound',
  178: 'Weimaraner',
  179: 'Staffordshire Bullterrier',
  180: 'American Staffordshire Terrier',
  181: 'Bedlington Terrier',
  182: 'Border Terrier',
  183: 'Kerry Blue Terrier',
  184: 'Irish Terrier',
  185: 'Norfolk Terrier',
  186: 'Norwich Terrier',
  187: 'Yorkshire Terrier',
  188: 'Wire Haired Fox Terrier',
  189: 'Lakeland Terrier',
  190: 'Sealyham Terrier',
  191: 'Airedale',
  192: 'Cairn',
  193: 'Australian Terrier',
  194: 'Dandie Dinmont',
  195: 'Boston Bull',
  196: 'Miniature Schnauzer',
  197: 'Giant Schnauzer',
  198: 'Standard Schnauzer',
  199: 'Scotch Terrier',
  200: 'Tibetan Terrier',
  201: 'Silky Terrier',
  202: 'Soft Coated Wheaten Terrier',
  203: 'West Highland White Terrier',
  204: 'Lhasa',
  205: 'Flat Coated Retriever',
  206: 'Curly Coated Retriever',
  207: 'Golden Retriever',
  208: 'Labrador Retriever',
  209: 'Chesapeake Bay Retriever',
  210: 'German Short Haired Pointer',
  211: 'Vizsla',
  212: 'English Setter',
  213: 'Irish Setter',
  214: 'Gordon Setter',
  215: 'Brittany Spaniel',
  216: 'Clumber',
  217: 'English Springer',
  218: 'Welsh Springer Spaniel',
  219: 'Cocker Spaniel',
  220: 'Sussex Spaniel',
  221: 'Irish Water Spaniel',
  222: 'Kuvasz',
  223: 'Schipperke',
  224: 'Groenendael',
  225: 'Malinois',
  226: 'Briard',
  227: 'Kelpie',
  228: 'Komondor',
  229: 'Old English Sheepdog',
  230: 'Shetland Sheepdog',
  231: 'Collie',
  232: 'Border Collie',
  233: 'Bouvier Des Flandres',
  234: 'Rottweiler',
  235: 'German Shepherd',
  236: 'Doberman',
  237: 'Miniature Pinscher',
  238: 'Greater Swiss Mountain Dog',
  239: 'Bernese Mountain Dog',
  240: 'Appenzeller',
  241: 'Entlebucher',
  242: 'Boxer',
  243: 'Bull Mastiff',
  244: 'Tibetan Mastiff',
  245: 'French Bulldog',
  246: 'Great Dane',
  247: 'Saint Bernard',
  248: 'Eskimo Dog',
  249: 'Malamute',
  250: 'Siberian Husky',
  251: 'Affenpinscher',
  252: 'Basenji',
  253: 'Pug',
  254: 'Leonberg',
  255: 'Newfoundland',
  256: 'Great Pyrenees',
  257: 'Samoyed',
  258: 'Pomeranian',
  259: 'Chow',
  260: 'Keeshond',
  261: 'Brabancon Griffon',
  262: 'Pembroke',
  263: 'Cardigan',
  264: 'Toy Poodle',
  265: 'Miniature Poodle',
  266: 'Standard Poodle',
  267: 'Mexican Hairless',
  268: 'Dingo',
  269: 'Dhole',
  270: 'African Hunting Dog',
};

// Mapeo de nombres ImageNet → nombres de razas en la app
const Map<String, String> kBreedNameMap = {
  'Chihuahua': 'Chihuahua',
  'Shih Tzu': 'Shih Tzu',
  'Beagle': 'Beagle',
  'Rhodesian Ridgeback': 'Dálmata',
  'Golden Retriever': 'Golden Retriever',
  'Labrador Retriever': 'Labrador Retriever',
  'Weimaraner': 'Weimaraner',
  'Yorkshire Terrier': 'Yorkshire Terrier',
  'Miniature Schnauzer': 'Schnauzer',
  'Giant Schnauzer': 'Schnauzer',
  'Standard Schnauzer': 'Schnauzer',
  'Flat Coated Retriever': 'Golden Retriever',
  'Curly Coated Retriever': 'Labrador Retriever',
  'Cocker Spaniel': 'Cocker Spaniel',
  'Border Collie': 'Border Collie',
  'Rottweiler': 'Rottweiler',
  'German Shepherd': 'Pastor Alemán',
  'Doberman': 'Dobermann',
  'Bernese Mountain Dog': 'Bernese Mountain Dog',
  'Boxer': 'Boxer',
  'French Bulldog': 'Bulldog Francés',
  'Great Dane': 'Gran Danés',
  'Siberian Husky': 'Siberian Husky',
  'Pug': 'Pug',
  'Samoyed': 'Samoyedo',
  'Pomeranian': 'Pomerania',
  'Chow': 'Chow Chow',
  'Toy Poodle': 'Poodle',
  'Miniature Poodle': 'Poodle',
  'Standard Poodle': 'Poodle',
  'Basset': 'Basset Hound',
  'Maltese Dog': 'Maltés',
  'Akita': 'Akita',
  'Pitbull': 'Pitbull',
  'Dálmata': 'Dálmata',
};

class BreedResult {
  final String breed;
  final double confidence;
  BreedResult(this.breed, this.confidence);
}

class BreedClassifier {
  static const String _modelPath = 'assets/models/yolov8n-cls_float32.tflite';
  static const int _inputSize = 224;
  static const int _topK = 3;

  Interpreter? _interpreter;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset(_modelPath);
  }

  Future<List<BreedResult>> classify(String imagePath) async {
    _interpreter ??= await Interpreter.fromAsset(_modelPath);

    // Preprocesar imagen
    final bytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(Uint8List.fromList(bytes));
    if (original == null) return [];

    final resized = img.copyResize(original, width: _inputSize, height: _inputSize);

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) => [
            resized.getPixel(x, y).r / 255.0,
            resized.getPixel(x, y).g / 255.0,
            resized.getPixel(x, y).b / 255.0,
          ],
        ),
      ),
    );

    // Output: [1, 1000] — 1000 clases ImageNet
    final output = List.generate(1, (_) => List.filled(1000, 0.0));
    _interpreter!.run(input, output);

    final scores = output[0];

    // Softmax
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final expScores = scores.map((s) => (s - maxScore).abs() < 100 ? s : 0.0).toList();
    final sumExp = expScores.fold(0.0, (a, b) => a + b);

    // Filtrar solo clases de razas de perro y ordenar por confianza
    final dogResults = <BreedResult>[];
    for (final entry in kImageNetDogBreeds.entries) {
      final idx = entry.key;
      if (idx < scores.length) {
        final confidence = sumExp > 0 ? expScores[idx] / sumExp : 0.0;
        final appBreedName = kBreedNameMap[entry.value] ?? entry.value;
        dogResults.add(BreedResult(appBreedName, confidence));
      }
    }

    // Ordenar y tomar top-3 únicos por nombre
    dogResults.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Deduplicar por nombre de raza
    final seen = <String>{};
    final top3 = <BreedResult>[];
    for (final r in dogResults) {
      if (!seen.contains(r.breed)) {
        seen.add(r.breed);
        top3.add(r);
        if (top3.length == _topK) break;
      }
    }

    return top3;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
