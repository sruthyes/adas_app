class Detection {
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double w;
  final double h;

  Detection(this.label, this.confidence, this.x, this.y, this.w, this.h);
}

class YoloDecoder {

  static List<String> cocoClasses = [
    "person", "bicycle", "car", "motorcycle", "airplane",
    "bus", "train", "truck", "boat", "traffic light",
    // remaining omitted for clarity
  ];

  static List<Detection> decode(
      List<List<double>> output,
      double confThreshold) {

    List<Detection> detections = [];

    for (var row in output) {
      List<double> scores = row.sublist(4);
      double maxScore = scores.reduce((a, b) => a > b ? a : b);
      int classIndex = scores.indexOf(maxScore);

      if (maxScore > confThreshold) {
        detections.add(
          Detection(
            cocoClasses[classIndex],
            maxScore,
            row[0],
            row[1],
            row[2],
            row[3],
          ),
        );
      }
    }

    return detections;
  }
}