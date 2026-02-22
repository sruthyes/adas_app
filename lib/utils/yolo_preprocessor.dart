import 'package:image/image.dart' as img;

class YoloPreprocessor {
  static const int inputSize = 640;

  static List<List<List<List<double>>>> process(img.Image image) {
    img.Image resized =
        img.copyResize(image, width: inputSize, height: inputSize);

    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        });
      })
    ];
  }
}