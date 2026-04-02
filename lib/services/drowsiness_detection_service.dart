import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class DrowsinessService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  int _closedEyeFrames = 0;
  final int thresholdFrames = 15;

  /// Detect faces
  Future<List<Face>> detectFaces(InputImage inputImage) async {
    print("Running ML Kit face detection...");
    return await _faceDetector.processImage(inputImage);
  }

  /// Check drowsiness
  bool checkDrowsiness(List<Face> faces) {
    if (faces.isEmpty) {
      _closedEyeFrames = 0;
      return false;
    }

    final face = faces.first;

    final left = face.leftEyeOpenProbability ?? 1.0;
    final right = face.rightEyeOpenProbability ?? 1.0;

    print("Left eye: $left");
    print("Right eye: $right");

    if (left < 0.4 && right < 0.4) {
      _closedEyeFrames++;
    } else {
      _closedEyeFrames = 0;
    }

    print("Closed frames: $_closedEyeFrames");

    return _closedEyeFrames > thresholdFrames;
  }

  void dispose() {
    _faceDetector.close();
  }
}