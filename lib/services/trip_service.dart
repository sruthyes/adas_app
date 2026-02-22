import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Interpreter? _safetyInterpreter;
  bool _safetyModelInitialized = false;

  // Assumed safety model: input [1, 7], output [1, 1]
  static const int _safetyInputLength = 7;

  Future<void> _initializeSafetyModel() async {
    if (_safetyModelInitialized) return;

    try {
      _safetyInterpreter ??= await Interpreter.fromAsset(
        'assets/models/safety_score.tflite',
      );
      _safetyModelInitialized = true;
    } catch (e) {
      // If the model fails to load, we’ll fall back to heuristic scoring
      print('Error loading safety_score.tflite: $e');
      _safetyInterpreter = null;
      _safetyModelInitialized = false;
    }
  }

  // Start a new trip
  Future<String> startTrip(double latitude, double longitude) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final docRef = await _firestore.collection('trips').add({
        'userId': user.uid,
        'startTime': FieldValue.serverTimestamp(),
        'startLatitude': latitude,
        'startLongitude': longitude,
        'distance': 0.0,
        'duration': 0,
        'speedWarnings': 0,
        'drowsinessWarnings': 0,
        'collisionWarnings': 0,
        'potholeDetections': 0,
        'safetyScore': 100.0,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_trip_id', docRef.id);
      await prefs.setBool('active_trip', true);

      return docRef.id;
    } catch (e) {
      print('Error starting trip: $e');
      rethrow;
    }
  }

  // End a trip and compute AI-based safety score (with heuristic fallback)
  Future<void> endTrip(
    String tripId,
    double latitude,
    double longitude,
    double distance, // meters or km – we normalize below
    int duration, // seconds – we normalize below
    int speedWarnings,
    int drowsinessWarnings,
    int collisionWarnings,
    int potholeDetections,
  ) 
  async {
    try {
      await _initializeSafetyModel();

      final safetyScore = await _calculateSafetyScore(
        distance: distance,
        durationSeconds: duration,
        speedWarnings: speedWarnings,
        drowsinessWarnings: drowsinessWarnings,
        collisionWarnings: collisionWarnings,
        potholeDetections: potholeDetections,
      );

      await _firestore.collection('trips').doc(tripId).update({
        'endTime': FieldValue.serverTimestamp(),
        'endLatitude': latitude,
        'endLongitude': longitude,
        'distance': distance,
        'duration': duration,
        'speedWarnings': speedWarnings,
        'drowsinessWarnings': drowsinessWarnings,
        'collisionWarnings': collisionWarnings,
        'potholeDetections': potholeDetections,
        'safetyScore': safetyScore,
      });

      await _updateGlobalHazards(tripId);


      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_trip_id');
      await prefs.setBool('active_trip', false);
    } catch (e) {
      print('Error ending trip: $e');
      rethrow;
    }
  }

  // AI + heuristic safety scoring
  Future<double> _calculateSafetyScore({
    required double distance,
    required int durationSeconds,
    required int speedWarnings,
    required int drowsinessWarnings,
    required int collisionWarnings,
    required int potholeDetections,
  }) async {
    final totalWarnings =
        speedWarnings + drowsinessWarnings + collisionWarnings;

    // Heuristic fallback (your original logic)
    double heuristicScore = 100.0;
    heuristicScore -= (totalWarnings * 5);
    heuristicScore -= (potholeDetections * 2);
    heuristicScore = heuristicScore.clamp(0.0, 100.0);

    // If model is not available, return heuristic
    if (!_safetyModelInitialized || _safetyInterpreter == null) {
      return heuristicScore;
    }

    // Normalize features for model (basic example – adjust per your training)
    final distanceKm = distance > 1000.0 ? distance / 1000.0 : distance;
    final durationMin = durationSeconds / 60.0;

    final features = <double>[
      distanceKm / 100.0, // assume typical trip <= 100 km
      durationMin / 180.0, // assume typical trip <= 3 hours
      speedWarnings / 50.0,
      drowsinessWarnings / 50.0,
      collisionWarnings / 50.0,
      potholeDetections / 50.0,
      totalWarnings / 50.0,
    ];

    final input = [features]; // [1, 7]
    final output = List.generate(1, (_) => List.filled(1, 0.0)); // [1, 1]

    try {
      _safetyInterpreter!.run(input, output);
      final modelScore = (output[0][0] * 100.0).clamp(0.0, 100.0);
      return modelScore.toDouble();
    } catch (e) {
      print('Error running safety model, using heuristic score: $e');
      return heuristicScore;
    }
  }

  // Increment warning counts during trip
      Future<void> updateTripWarnings(
      String tripId, {
      int? speedWarnings,
      int? drowsinessWarnings,
      int? collisionWarnings,
      int? potholeDetections,
      double? potholeLat,
      double? potholeLng,
    })async {
    try {
      final updates = <String, dynamic>{};

      if (speedWarnings != null) {
        updates['speedWarnings'] = FieldValue.increment(speedWarnings);
      }
      if (drowsinessWarnings != null) {
        updates['drowsinessWarnings'] =
            FieldValue.increment(drowsinessWarnings);
      }
      if (collisionWarnings != null) {
        updates['collisionWarnings'] =
            FieldValue.increment(collisionWarnings);
      }
      if (potholeDetections != null) {
        updates['potholeDetections'] =
            FieldValue.increment(potholeDetections);
      }
      if (potholeLat != null && potholeLng != null) {
        updates['potholeLocations'] = FieldValue.arrayUnion([
          {
            'lat': potholeLat,
            'lng': potholeLng,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('trips').doc(tripId).update(updates);
      }
    } catch (e) {
      print('Error updating trip warnings: $e');
    }
  }

  // Update current trip location
  Future<void> updateTripLocation(
      String tripId, double latitude, double longitude) async {
    try {
            await _firestore.collection('trips').doc(tripId).update({
        'currentLatitude': latitude,
        'currentLongitude': longitude,
        'path': FieldValue.arrayUnion([
          {
            'lat': latitude,
            'lng': longitude,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]),
      });
    } 
    catch (e) {
      print('Error updating trip location: $e');
    }
  }

  // Stream user's trip history
  Stream<List<TripModel>> getTripHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      // Return empty stream if not logged in
      return const Stream.empty();
    }

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: user.uid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TripModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get single trip details
  Future<TripModel?> getTripDetails(String tripId) async {
    try {
      final doc =
          await _firestore.collection('trips').doc(tripId).get();

      if (doc.exists) {
        return TripModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting trip details: $e');
      return null;
    }
  }

  // Get current active trip ID from shared prefs
  Future<String?> getCurrentTripId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_trip_id');
  }

  // Check if there is an active trip
  Future<bool> hasActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('active_trip') ?? false;
  }


  Future<void> _updateGlobalHazards(String tripId) async {
  final doc =
      await _firestore.collection('trips').doc(tripId).get();

  final potholes =
      doc.data()?['potholeLocations'] as List<dynamic>?;

  if (potholes == null) return;

      for (var p in potholes) {
        await _firestore.collection('potholes').add({
          'latitude': p['lat'],
          'longitude': p['lng'],
          'lastReported': FieldValue.serverTimestamp(),
          'reportCount': 1,
        });
      }
    }

  void dispose() {
    _safetyInterpreter?.close();
    _safetyInterpreter = null;
  }
}
