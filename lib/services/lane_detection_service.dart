import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/image_preprocessor.dart';

class LaneDetectionService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  // Model input size (adjust only if your model requires different values)
  static const int _inputWidth = 256;
  static const int _inputHeight = 256;

  // Lane departure tracking
  double _lastOffset = 0.0; 
  bool _laneDepartureDetected = false;
  DateTime? _lastDepartureTime;

  // Lane departure thresholds
  final double _departureDeltaThreshold = 0.20;
  final Duration _departureCooldown = Duration(seconds: 2);

  // Loads the TFLite model and prints input tensor shape/type
  Future<void> _initializeInterpreter() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/ml_models/lane_detection.tflite',
      );

      // Print input tensor info (important for verifying preprocessing)
      final shape = _interpreter!.getInputTensor(0).shape;
      final type = _interpreter!.getInputTensor(0).type;

      print("Lane Model Input Shape: $shape");
      print("Lane Model Input Type:  $type");

      _isInitialized = true;
      print('LaneDetectionService: model loaded successfully.');
    } catch (e, st) {
      print('Error initializing lane detection model: $e\n$st');
      _interpreter = null;
      _isInitialized = false;
    }
  }

  Future<void> initialize() async {
    await _initializeInterpreter();
  }

  // Main API: detects lane presence in a camera frame
  Future<bool> detectLanes(CameraImage image) async {
    await _initializeInterpreter();
    if (!_isInitialized || _interpreter == null) return false;

    final input = _preprocessImage(image);

    // Output tensor shape: [1, H, W, 1]
    final output = List.generate(
      1,
      (_) => List.generate(
        _inputHeight,
        (_) => List.generate(_inputWidth, (_) => [0.0]),
      ),
    );

    try {
      _interpreter!.run(input, output);
    } catch (e, st) {
      print('LaneDetectionService: inference error -> $e\n$st');
      return false;
    }

    return _postProcessOutputAndUpdateState(output);
  }

  // Converts camera frame into the model’s expected input format
  List<List<List<double>>> _preprocessImage(CameraImage image) {
    return ImagePreprocessor.yuv420ToRgbInput(
      image,
      _inputWidth,
      _inputHeight,
    );
  }

  // Extracts lane mask probability from output and detects lane departure
  bool _postProcessOutputAndUpdateState(
      List<List<List<List<double>>>> output) {
    final h = output[0].length;
    final w = output[0][0].length;

    final int startRow = (h * 0.6).toInt(); // process only lower 40%

    int lanePixels = 0;
    double weightedXSum = 0.0;

    for (int y = startRow; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final prob = output[0][y][x][0];
        if (prob > 0.45) {
          lanePixels++;
          weightedXSum += x * prob;
        }
      }
    }

    final int totalPixels = (h - startRow) * w;
    if (totalPixels == 0) {
      _laneDepartureDetected = false;
      _lastOffset = 0.0;
      return false;
    }

    final double laneRatio = lanePixels / totalPixels;
    final bool lanesPresent = laneRatio > 0.01;

    if (lanePixels > 0) {
      final double centroidX = weightedXSum / lanePixels;
      final double normalizedOffset = (centroidX / (w - 1)) * 2 - 1;

      final double delta = (normalizedOffset - _lastOffset).abs();
      final now = DateTime.now();
      final bool cooledDown = _lastDepartureTime == null ||
          now.difference(_lastDepartureTime!) > _departureCooldown;

      if (delta > _departureDeltaThreshold && cooledDown) {
        _laneDepartureDetected = true;
        _lastDepartureTime = now;
        print(
            'Lane departure detected. Δ=${delta.toStringAsFixed(3)}, offset=${normalizedOffset.toStringAsFixed(3)}');
      } else {
        _laneDepartureDetected = false;
      }

      _lastOffset = normalizedOffset;
    } else {
      _laneDepartureDetected = false;
      _lastOffset = 0.0;
    }

    return lanesPresent;
  }

  // Public getters
  bool get laneDepartureDetected => _laneDepartureDetected;
  double get lastOffset => _lastOffset;

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
