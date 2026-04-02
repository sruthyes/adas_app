import 'package:image/image.dart' as img;

class LightCollisionService {

  int _collisionFrameCount = 0;

  bool detectCollision(img.Image image) {

    // Narrow detection region (center lane)
    int centerStartX = (image.width * 0.42).toInt();
    int centerEndX = (image.width * 0.58).toInt();

    int obstaclePixels = 0;

    // Only analyze bottom road region
    for (int y = (image.height * 0.55).toInt(); y < image.height; y += 3) {
      for (int x = centerStartX; x < centerEndX; x += 3) {

        final pixel = image.getPixel(x, y);

        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        int brightness = (r + g + b) ~/ 3;

        // Detect dark object pixels
        if (brightness < 85 && r < 120 && g < 120 && b < 120) {
          obstaclePixels++;
        }
      }
    }

    // Large object threshold
    bool detected = obstaclePixels > 750;

    // Frame stability logic (prevents flicker)
    if (detected) {
      _collisionFrameCount++;
    } else {
      _collisionFrameCount = 0;
    }

    // Require multiple frames to confirm collision risk
    return _collisionFrameCount >= 3;
  }
}