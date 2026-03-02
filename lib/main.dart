import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'services/auth_service.dart';
import 'services/lane_detection_service.dart';
import 'services/collision_warning_service.dart';
import 'services/drowsiness_detection_service.dart';
import 'services/traffic_sign_service.dart';
import 'services/pothole_detection_service.dart';
import 'services/trip_service.dart';
import 'utils/firebase_test.dart';
import 'utils/firebase_debug.dart';
import 'providers/adas_state.dart';

/// Background task dispatcher
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Background task executed: $task");
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize WorkManager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );

  /// Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('✅ Firebase initialized successfully');

    /// Optional: Debug / Diagnostics
    FirebaseTest.printDiagnostics();
    await FirebaseDebug.testFirebaseConnection();
    await FirebaseDebug.testAuthWithDummyData();
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint('App will continue without Firebase.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        //modified for the problem of navigation
        ChangeNotifierProvider<AdasState>(
          create: (_) => AdasState(),
        ),

        /// Authentication
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),

        /// Lane Detection (OpenCV)
        Provider<LaneDetectionService>(
          create: (_) => LaneDetectionService(),
        ),

        /// Collision Warning (Object Detection Based)
        Provider<CollisionWarningService>(
          create: (_) => CollisionWarningService(),
        ),

        /// Driver Drowsiness Detection
        Provider<DrowsinessDetectionService>(
          create: (_) => DrowsinessDetectionService(),
        ),

        /// Traffic Sign Detection (YOLO TFLite)
        Provider<TrafficSignService>(
          create: (_) => TrafficSignService(),
        ),

        /// Pothole Detection
        Provider<PotholeDetectionService>(
          create: (_) => PotholeDetectionService(),
        ),

        /// Trip Logging / Analytics
        Provider<TripService>(
          create: (_) => TripService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ADAS App',

        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),

        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),

        themeMode: ThemeMode.system,

        home: const AuthWrapper(),
      ),
    );
  }
}