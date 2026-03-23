import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DogDetector {
  static const String _modelPath = 'assets/models/yolov8n_float16.tflite';
  static const int _inputSize = 320;
  // Índice de la clase "dog" en COCO dataset = 16
  static const int _dogClassIndex = 16;
  static const double _confidenceThreshold = 0.45;

  Interpreter? _interpreter;

  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset(_modelPath);
  }

  Future<bool> containsDog(String imagePath) async {
    _interpreter ??= await Interpreter.fromAsset(_modelPath);

    // Leer y redimensionar imagen a 320x320
    final bytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(Uint8List.fromList(bytes));
    if (original == null) return false;

    final resized = img.copyResize(original, width: _inputSize, height: _inputSize);

    // Normalizar a float16 → float32 (TFLite usa float32 internamente)
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // YOLOv8n output: [1, 84, 2100] — 84 = 4 bbox + 80 clases COCO
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );

    _interpreter!.run(input, output);

    // output[0] tiene shape [84, 2100]
    // Filas 0-3: bbox (cx, cy, w, h)
    // Filas 4-83: scores por clase
    final predictions = output[0]; // [84][2100]
    final numDetections = predictions[0].length;

    for (int i = 0; i < numDetections; i++) {
      // Score de la clase "dog" (índice 16 → fila 4+16 = 20)
      final dogScore = predictions[4 + _dogClassIndex][i];
      if (dogScore >= _confidenceThreshold) {
        return true;
      }
    }
    return false;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
