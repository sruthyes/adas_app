import 'package:flutter/material.dart';
//import '../services/collision_warning_service.dart';

class ADASOverlay extends StatelessWidget {
  final bool laneDetected;
  final bool laneDepartureDetected;
  final double laneOffset;
  //final CollisionWarningResult? collisionWarning;
  final bool drowsinessDetected;
  final String? trafficSignDetected;
  final bool potholeDetected;
  final bool isDriverFacing;

  const ADASOverlay({
    super.key,
    required this.laneDetected,
    required this.laneDepartureDetected,
    required this.laneOffset,
    //required this.collisionWarning,
    required this.drowsinessDetected,
    required this.trafficSignDetected,
    required this.potholeDetected,
    required this.isDriverFacing,
  });

  // ================= COLLISION HELPERS =================

  /*Color _getCollisionWarningColor() {
    if (collisionWarning == null) { //can remove after the complete implementation
    return Colors.transparent;
  }
    switch (collisionWarning!.level) {
      case CollisionWarningLevel.high:
        return Colors.red;
      case CollisionWarningLevel.medium:
        return Colors.orange;
      case CollisionWarningLevel.low:
        return Colors.yellow;
      case CollisionWarningLevel.none:
        return Colors.transparent;
    }
    // This guarantees Dart always gets a return value
  return Colors.transparent;
  }

  String _getCollisionWarningText() {
    switch (collisionWarning!.level) {
      case CollisionWarningLevel.low:
        return 'Vehicle Ahead';
      case CollisionWarningLevel.medium:
        return 'WARNING: GETTING CLOSER';
      case CollisionWarningLevel.high:
        return 'COLLISION WARNING!';
      default:
        return '';
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // ================= LANE DETECTED =================
        if (!isDriverFacing && laneDetected)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Lane Detected',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // ================= LANE DEPARTURE WARNING =================
        if (!isDriverFacing && laneDepartureDetected)
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.9),
              child: const Text(
                "⚠ LANE DEPARTURE!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // ================= LANE POSITION INDICATOR =================
        if (!isDriverFacing && laneDetected)
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  "Lane Position",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 220,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Align(
                    alignment: Alignment(
                      laneOffset.clamp(-1.0, 1.0),
                      0,
                    ),
                    child: Container(
                      width: 25,
                      height: 10,
                      decoration: BoxDecoration(
                        color: laneDepartureDetected
                            ? Colors.red
                            : Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Steering Suggestion
                if (laneDepartureDetected)
                  Text(
                    laneOffset < 0
                        ? "⬅ Steering Left"
                        : "➡ Steering Right",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

        // ================= COLLISION WARNING =================
      /*  if (collisionWarning != null &&
    collisionWarning!.level != CollisionWarningLevel.none)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _getCollisionWarningColor(),
                width: collisionWarning!.level ==
                        CollisionWarningLevel.high
                    ? 10.0
                    : 5.0,
              ),
            ),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _getCollisionWarningColor()
                      .withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getCollisionWarningText(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize:
                            collisionWarning!.level ==
                                    CollisionWarningLevel.high
                                ? 24
                                : 20,
                      ),
                    ),
                    if (collisionWarning!.level !=
                        CollisionWarningLevel.low)
                      Text(
                        'Distance: ${collisionWarning!.estimatedDistance.toStringAsFixed(1)}m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (collisionWarning!.level ==
                        CollisionWarningLevel.high)
                      Text(
                        'Time to collision: ${collisionWarning!.timeToCollision.toStringAsFixed(1)}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),*/

        // ================= DROWSINESS =================
        if (drowsinessDetected)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.orange,
                width: 10.0,
              ),
            ),
            child: const Center(
              child: Text(
                'DROWSINESS DETECTED!',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // ================= TRAFFIC SIGN =================
        if (trafficSignDetected != null)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Traffic Sign',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trafficSignDetected!,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ================= POTHOLE =================
        if (potholeDetected)
          Positioned(
            bottom: 220,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '⚠ Pothole Detected!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}