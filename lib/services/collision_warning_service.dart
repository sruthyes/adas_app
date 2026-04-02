import 'package:tflite_flutter/tflite_flutter.dart';

class CollisionModelService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/yolov8s_int8.tflite',
      options: InterpreterOptions()..threads = 4,
    );
  }

  Interpreter get interpreter => _interpreter;
}