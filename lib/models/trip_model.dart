class TripModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final double startLatitude;
  final double startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final double distance;
  final int duration;
  final int speedWarnings;
  final int drowsinessWarnings;
  final int collisionWarnings;
  final int potholeDetections;
  final double safetyScore;

  TripModel({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.startLatitude,
    required this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    required this.distance,
    required this.duration,
    required this.speedWarnings,
    required this.drowsinessWarnings,
    required this.collisionWarnings,
    required this.potholeDetections,
    required this.safetyScore,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      userId: map['userId'] ?? '',
      startTime: map['startTime']?.toDate() ?? DateTime.now(),
      endTime: map['endTime']?.toDate(),
      startLatitude: map['startLatitude'] ?? 0.0,
      startLongitude: map['startLongitude'] ?? 0.0,
      endLatitude: map['endLatitude'],
      endLongitude: map['endLongitude'],
      distance: map['distance'] ?? 0.0,
      duration: map['duration'] ?? 0,
      speedWarnings: map['speedWarnings'] ?? 0,
      drowsinessWarnings: map['drowsinessWarnings'] ?? 0,
      collisionWarnings: map['collisionWarnings'] ?? 0,
      potholeDetections: map['potholeDetections'] ?? 0,
      safetyScore: map['safetyScore'] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': startTime,
      'endTime': endTime,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'distance': distance,
      'duration': duration,
      'speedWarnings': speedWarnings,
      'drowsinessWarnings': drowsinessWarnings,
      'collisionWarnings': collisionWarnings,
      'potholeDetections': potholeDetections,
      'safetyScore': safetyScore,
    };
  }
}