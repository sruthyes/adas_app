import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/image_preprocessor.dart';

enum CollisionWarningLevel {
  none,
  low,
  medium,
  high,
}

class CollisionWarningResult {
  final CollisionWarningLevel level;
  final double estimatedDistance; // in meters
  final double timeToCollision;   // in seconds

  const CollisionWarningResult({
    required this.level,
    required this.estimatedDistance,
    required this.timeToCollision,
  });
}

class CollisionWarningService {
  // Distance thresholds in meters
  double _safeDistanceThreshold = 50.0;
  double _mediumWarningThreshold = 30.0;
  double _highWarningThreshold = 15.0;

  DateTime? _lastWarningTime;
  bool _isEnabled = true;

  Interpreter? _interpreter;

  // Model configuration
  static const int _modelInputSize = 320;
  static const int _numDetections = 10;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _isEnabled = prefs.getBool('collision_warning_enabled') ?? true;
    _safeDistanceThreshold =
        prefs.getDouble('safe_distance_threshold') ?? 50.0;
    _mediumWarningThreshold =
        prefs.getDouble('medium_warning_threshold') ?? 30.0;
    _highWarningThreshold =
        prefs.getDouble('high_warning_threshold') ?? 15.0;

    try {
      _interpreter ??= await Interpreter.fromAsset(
        'assets/ml_models/vehicle_detection.tflite',
      );
    } catch (e) {
      // If model fails to load, keep interpreter null and fail gracefully
      print('Error loading vehicle_detection.tflite: $e');
      _interpreter = null;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('collision_warning_enabled', enabled);
  }

  Future<void> updateThresholds({
    double? safeDistance,
    double? mediumWarning,
    double? highWarning,
  }) async {
    if (safeDistance != null) _safeDistanceThreshold = safeDistance;
    if (mediumWarning != null) _mediumWarningThreshold = mediumWarning;
    if (highWarning != null) _highWarningThreshold = highWarning;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
        'safe_distance_threshold', _safeDistanceThreshold);
    await prefs.setDouble(
        'medium_warning_threshold', _mediumWarningThreshold);
    await prefs.setDouble(
        'high_warning_threshold', _highWarningThreshold);
  }

  CollisionWarningResult _noCollisionResult() {
    return const CollisionWarningResult(
      level: CollisionWarningLevel.none,
      estimatedDistance: double.infinity,
      timeToCollision: double.infinity,
    );
  }

  Future<CollisionWarningResult> detectCollision(
      CameraImage? image) async {
    if (!_isEnabled || image == null) {
      return _noCollisionResult();
    }

    if (_interpreter == null) {
      print('ADAS: interpreter is null');
      return _noCollisionResult();
    }

    // 1. Preprocess camera frame to model input tensor
    final input = _preprocessImage(image);

    // 2. Prepare output buffers
    final outputLocations = List.generate(
      1,
      (_) => List.generate(
        _numDetections,
        (_) => List.filled(4, 0.0),
      ),
    ); // [1, N, 4]

    final outputClasses = List.generate(
      1,
      (_) => List.filled(_numDetections, 0.0),
    ); // [1, N]

    final outputScores = List.generate(
      1,
      (_) => List.filled(_numDetections, 0.0),
    ); // [1, N]

    final outputs = <int, Object>{
      0: outputLocations,
      1: outputClasses,
      2: outputScores,
    };

    // 3. Run inference
    _interpreter!.runForMultipleInputs([input], outputs);

    // 4. Post-process detections into a warning result
    return _postProcessOutput(
      locations: outputLocations,
      classes: outputClasses,
      scores: outputScores,
      imageWidth: image.width,
      imageHeight: image.height,
    );
  }

  List<List<List<double>>> _preprocessImage(CameraImage image) {
    return ImagePreprocessor.yuv420ToRgbInput(
      image,
      _modelInputSize,
      _modelInputSize,
    );
  }

  CollisionWarningResult _postProcessOutput({
    required List<List<List<double>>> locations,
    required List<List<double>> classes,
    required List<List<double>> scores,
    required int imageWidth,
    required int imageHeight,
  }) {
    const double scoreThreshold = 0.5;

    double bestScore = 0.0;
    List<double>? bestBox;

    // Find highest-score detection above threshold
    for (int i = 0; i < _numDetections; i++) {
      final score = scores[0][i];
      if (score > scoreThreshold && score > bestScore) {
        bestScore = score;
        bestBox = locations[0][i]; // [ymin, xmin, ymax, xmax] in 0–1
      }
    }

    if (bestBox == null) {
      return _noCollisionResult();
    }

    final ymin = bestBox[0];
    final xmin = bestBox[1];
    final ymax = bestBox[2];
    final xmax = bestBox[3];

    // Heuristic: distance inversely related to bounding box height
    final boxHeightNorm = (ymax - ymin).clamp(0.0, 1.0);
    final estimatedDistance =
        boxHeightNorm > 0.0 ? 5.0 / boxHeightNorm : 100.0;

    // Assume relative closing speed ~60 km/h (16.67 m/s)
    const double relativeSpeed = 60 / 3.6;
    final timeToCollision = estimatedDistance / relativeSpeed;

    CollisionWarningLevel level;
    if (estimatedDistance > _safeDistanceThreshold) {
      level = CollisionWarningLevel.none;
    } else if (estimatedDistance > _mediumWarningThreshold) {
      level = CollisionWarningLevel.low;
    } else if (estimatedDistance > _highWarningThreshold) {
      level = CollisionWarningLevel.medium;
    } else {
      level = CollisionWarningLevel.high;
    }

    return CollisionWarningResult(
      level: level,
      estimatedDistance: estimatedDistance,
      timeToCollision: timeToCollision,
    );
  }

  bool shouldThrottleWarning() {
    if (_lastWarningTime == null) {
      _lastWarningTime = DateTime.now();
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(_lastWarningTime!);

    if (difference.inSeconds < 3) {
      return true;
    }

    _lastWarningTime = now;
    return false;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
