import 'package:image/image.dart' as img;
import '../models/traffic_sign_detection.dart';

class TrafficSignService {

  TrafficSignDetection? detectTrafficSign(img.Image image) {

    int minX = image.width;
    int minY = image.height;
    int maxX = 0;
    int maxY = 0;

    int colorPixelCount = 0;
    String label = "";

    for (int y = 0; y < image.height; y += 3) {
      for (int x = 0; x < image.width; x += 3) {

        final pixel = image.getPixel(x, y);

        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        bool detectedColor = false;

        if (_isRed(r, g, b)) {
          label = "STOP / PROHIBITION";
          detectedColor = true;
        } 
        else if (_isYellow(r, g, b)) {
          label = "WARNING SIGN";
          detectedColor = true;
        } 
        else if (_isBlue(r, g, b)) {
          label = "INFORMATION SIGN";
          detectedColor = true;
        }

        if (detectedColor) {

          colorPixelCount++;

          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (colorPixelCount > 200) {

      return TrafficSignDetection(
        x: minX.toDouble(),
        y: minY.toDouble(),
        width: (maxX - minX).toDouble(),
        height: (maxY - minY).toDouble(),
        label: label,
      );
    }

    return null;
  }

  bool _isRed(int r, int g, int b) {
    return r > 180 && g < 100 && b < 100;
  }

  bool _isYellow(int r, int g, int b) {
    return r > 180 && g > 180 && b < 100;
  }

  bool _isBlue(int r, int g, int b) {
    return b > 150 && r < 120 && g < 120;
  }
}