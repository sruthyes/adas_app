import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/yolo_decoder.dart';

enum CollisionLevel { safe, warning, danger }

class CollisionLogicService extends ChangeNotifier {

  CollisionLevel _level = CollisionLevel.safe;
  final AudioPlayer _player = AudioPlayer();

  CollisionLevel get level => _level;

  void process(
      List<Detection> detections,
      double frameWidth,
      double frameHeight) {

    CollisionLevel newLevel = CollisionLevel.safe;

    for (var det in detections) {

      if (!_isRelevantClass(det.label)) continue;
      if (!_isInCenter(det.x, frameWidth)) continue;

      double areaRatio =
          (det.w * det.h) / (frameWidth * frameHeight);

      if (det.label == "person") {
        if (areaRatio > 0.08) {
          newLevel = CollisionLevel.danger;
        } else if (areaRatio > 0.04) {
          newLevel = CollisionLevel.warning;
        }
      } else {
        if (areaRatio > 0.18) {
          newLevel = CollisionLevel.danger;
        } else if (areaRatio > 0.10) {
          newLevel = CollisionLevel.warning;
        }
      }
    }

    if (newLevel != _level) {
      _level = newLevel;
      notifyListeners();
      _playSound();
    }
  }

  bool _isRelevantClass(String label) {
    return label == "person" ||
        label == "car" ||
        label == "truck" ||
        label == "bus" ||
        label == "motorcycle";
  }

  bool _isInCenter(double x, double width) {
    return x > width * 0.3 && x < width * 0.7;
  }

  void _playSound() async {
    if (_level == CollisionLevel.danger) {
      await _player.play(AssetSource("sounds/alert.mp3"));
    }
  }
}