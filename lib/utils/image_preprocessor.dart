import 'dart:typed_data';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ImagePreprocessor {
  /// ===============================
  /// OLD API (DO NOT BREAK SERVICES)
  /// ===============================

  /// Used by lane / collision / drowsiness / pothole models
  static List<List<List<double>>> yuv420ToRgbInput(
    CameraImage image,
    int width,
    int height,
  ) {
    final rgb = _yuv420ToRgb(image, width, height);

    return List.generate(
      height,
      (y) => List.generate(
        width,
        (x) {
          final pixel = rgb[y][x];
          return [
            pixel.red / 255.0,
            pixel.green / 255.0,
            pixel.blue / 255.0,
          ];
        },
      ),
    );
  }

  /// ===============================
  /// YOLO API (TRAFFIC SIGN MODEL)
  /// ===============================

  /// Output shape: [1, 640, 640, 3]
  static List<List<List<List<double>>>> yuv420ToRgbInput4D(
    CameraImage image,
    int width,
    int height,
  ) {
    return [
      yuv420ToRgbInput(image, width, height),
    ];
  }

  /// ===============================
  /// INTERNAL YUV → RGB
  /// ===============================

  static List<List<Color>> _yuv420ToRgb(
    CameraImage image,
    int width,
    int height,
  ) {
    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final rgb = List.generate(
      height,
      (_) => List.generate(width, (_) => Colors.black),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvIndex =
            (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final yp = yPlane[yIndex];
        final up = uPlane[uvIndex];
        final vp = vPlane[uvIndex];

        int r = (yp + 1.402 * (vp - 128)).round();
        int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round();
        int b = (yp + 1.772 * (up - 128)).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        rgb[y][x] = Color.fromARGB(255, r, g, b);
      }
    }

    return rgb;
  }
}
