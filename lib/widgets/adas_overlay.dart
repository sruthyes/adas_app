import 'package:flutter/material.dart';
import '../services/collision_warning_service.dart';

class ADASOverlay extends StatelessWidget {
  final CollisionWarningResult? collisionWarning;
  final bool laneDetected;
  final bool drowsinessDetected;
  final String? trafficSignDetected;
  final bool potholeDetected;
  final bool isDriverFacing;

  const ADASOverlay({
    super.key,
    required this.laneDetected,
    this.collisionWarning,
    required this.drowsinessDetected,
    this.trafficSignDetected,
    required this.potholeDetected,
    required this.isDriverFacing,
  });

  // Helper methods for collision warning display
  Color _getCollisionWarningColor() {
    if (collisionWarning == null) return Colors.transparent;
    
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
  }

  String _getCollisionWarningText(CollisionWarningLevel level) {
    switch (level) {
      case CollisionWarningLevel.low:
        return 'Vehicle Ahead';
      case CollisionWarningLevel.medium:
        return 'WARNING: GETTING CLOSER';
      case CollisionWarningLevel.high:
        return 'COLLISION WARNING!';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Lane Detection Indicator
        if (laneDetected)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.7),
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

        // Collision Warning
        if (collisionWarning != null && collisionWarning!.level != CollisionWarningLevel.none)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _getCollisionWarningColor(),
                width: collisionWarning!.level == CollisionWarningLevel.high ? 10.0 : 5.0,
              ),
            ),
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _getCollisionWarningColor().withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getCollisionWarningText(collisionWarning!.level),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: collisionWarning!.level == CollisionWarningLevel.high ? 24 : 20,
                      ),
                    ),
                    if (collisionWarning!.level != CollisionWarningLevel.low)
                      Text(
                        'Distance: ${collisionWarning!.estimatedDistance.toStringAsFixed(1)}m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (collisionWarning!.level == CollisionWarningLevel.high)
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
          ),

        // Drowsiness Detection
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

        // Traffic Sign Detection
        if (trafficSignDetected != null)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.7),
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

        // Pothole Detection
        if (potholeDetected)
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pothole Detected!',
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