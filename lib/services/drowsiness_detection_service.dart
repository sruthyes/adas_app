import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/image_preprocessor.dart';

class DrowsinessDetectionService {
  Interpreter? _interpreter;
  bool _initialized = false;

  // Callback to notify UI when drowsiness detected
  Function()? onDrowsinessDetected;

  // Adjust to match your model input
  static const int _inputSize = 128;

  // Sliding window of recent drowsiness probabilities
  final List<double> _recentDrowsyScores = [];
  static const int _windowSize = 30; // ~last N frames
  static const double _frameThreshold = 0.7; // per-frame
  static const double _windowThreshold = 0.6; // average over window

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _interpreter ??= await Interpreter.fromAsset(
        'assets/ml_models/drowsiness.tflite',
      );
      _initialized = true;
    } catch (e) {
      print('Error initializing drowsiness model: $e');
      _initialized = false;
    }
  }

  /// Returns true if the driver is likely drowsy based on recent frames.
  Future<bool> detectDrowsiness(CameraImage image) async {
    await initialize();
    if (!_initialized || _interpreter == null) {
      return false;
    }

    // 1. Preprocess camera frame -> [1, _inputSize, _inputSize, 3]
    final input = ImagePreprocessor.yuv420ToRgbInput(
      image,
      _inputSize,
      _inputSize,
    );

    // 2. Model output [awake, drowsy]
    final output = List.generate(1, (_) => List.filled(2, 0.0));

    // 3. Run inference
    _interpreter!.run(input, output);

    final probAwake = output[0][0];
    final probDrowsy = output[0][1];

    // 4. Keep only drowsy probability
    _addDrowsyScore(probDrowsy);

    // 5. Decide drowsiness based on:
    //    - current frame high drowsy prob
    //    - AND average drowsy prob in recent window high
    final avgDrowsy = _averageDrowsyScore();
    final isDrowsyNow =
        probDrowsy > probAwake && probDrowsy > _frameThreshold;

    final isDrowsy = isDrowsyNow && avgDrowsy > _windowThreshold;

      if (isDrowsy) {
        onDrowsinessDetected?.call();
      }

      return isDrowsy;
  }

  void _addDrowsyScore(double score) {
    _recentDrowsyScores.add(score.clamp(0.0, 1.0));
    if (_recentDrowsyScores.length > _windowSize) {
      _recentDrowsyScores.removeAt(0);
    }
  }

  double _averageDrowsyScore() {
    if (_recentDrowsyScores.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in _recentDrowsyScores) {
      sum += s;
    }
    return sum / _recentDrowsyScores.length;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _recentDrowsyScores.clear();
  }
}
