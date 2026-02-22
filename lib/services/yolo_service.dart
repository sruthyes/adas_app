import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/yolo_preprocessor.dart';
import '../utils/yolo_postprocessor.dart';

class YoloService {
  late Interpreter _interpreter;
  bool _loaded = false;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      "assets/ml_models/yolov8n_int8.tflite",
    );
    _loaded = true;
    print("YOLO model loaded");
  }

  bool get isLoaded => _loaded;

  Future<List<Detection>> detect(img.Image image) async {
    if (!_loaded) return [];

    final input = YoloPreprocessor.process(image);

    var output =
        List.generate(1, (_) => List.generate(8400, (_) => List.filled(84, 0.0)));

    _interpreter.run(input, output);

    return YoloPostProcessor.process(
      output[0],
      image.width,
      image.height,
    );
  }
}