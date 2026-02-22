import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/image_preprocessor.dart';

class PotholeDetectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Interpreter? _interpreter;
  bool _initialized = false;

  // Adjust to match your model input size
  static const int _inputSize = 224;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _interpreter ??= await Interpreter.fromAsset(
        'assets/ml_models/pothole_detection.tflite',
      );
      _initialized = true;
    } catch (e) {
      print('Error loading pothole model: $e');
      _initialized = false;
    }
  }

  /// Returns true if the model detects a pothole in the camera frame.
  Future<bool> detectPotholes(CameraImage image) async {
    await initialize();
    if (!_initialized || _interpreter == null) {
      return false;
    }

    // 1. Preprocess image
    final input = ImagePreprocessor.yuv420ToRgbInput(
      image,
      _inputSize,
      _inputSize,
    );

    // 2. Output buffer: [no, yes]
    final output = List.generate(1, (_) => List.filled(2, 0.0));

    // 3. Run inference
    _interpreter!.run(input, output);

    // 4. Interpret result
    final probNo = output[0][0];
    final probYes = output[0][1];
    final detected = probYes > probNo && probYes > 0.7;

    if (detected) {
      await _savePotholeLocation();
    }

    return detected;
  }

  Future<void> _savePotholeLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      await _firestore.collection('potholes').add({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving pothole location: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNearbyPotholes(
      double latitude, double longitude, double radiusKm) async {
    try {
      final snapshot = await _firestore.collection('potholes').get();
      return snapshot.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'latitude': d['latitude'],
          'longitude': d['longitude'],
          'timestamp': d['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('Error getting potholes: $e');
      return [];
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
