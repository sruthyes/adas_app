import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/image_preprocessor.dart';

class TrafficSignService {
  Interpreter? _interpreter;
  bool _initialized = false;
  late List<String> _labels;

  static const int inputSize = 640;
  static const double confidenceThreshold = 0.4;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/ml_models/traffic_signs.tflite',
      );

      final labelData =
          await rootBundle.loadString('assets/labels/traffic_sign_labels.txt');

      _labels = labelData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      _initialized = true;
      print('TrafficSignService initialized');
    } catch (e) {
      print('TrafficSignService init error: $e');
      _initialized = false;
    }
  }

  Future<String?> detectTrafficSigns(CameraImage image) async {
    if (!_initialized || _interpreter == null) return null;

    /// 1️⃣ Convert CameraImage → YOLO input tensor
    final input = ImagePreprocessor.yuv420ToRgbInput4D(
      image,
      inputSize,
      inputSize,
    ); // shape: [1, 640, 640, 3]

    /// 2️⃣ YOLO output tensor: [1, 22, 8400]
    final output = List.generate(
      1,
      (_) => List.generate(22, (_) => List.filled(8400, 0.0)),
    );

    /// 3️⃣ Run inference
    _interpreter!.run(input, output);

    /// 4️⃣ Decode detections
    double bestScore = 0.0;
    int bestClass = -1;

    for (int i = 0; i < 8400; i++) {
      final objectness = output[0][4][i];
      if (objectness < confidenceThreshold) continue;

      for (int c = 5; c < 22; c++) {
        final score = objectness * output[0][c][i];
        if (score > bestScore) {
          bestScore = score;
          bestClass = c - 5;
        }
      }
    }

    if (bestClass >= 0 && bestClass < _labels.length) {
      final label = _labels[bestClass];
      print('Traffic sign detected: $label ($bestScore)');
      return label;
    }

    return null;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
