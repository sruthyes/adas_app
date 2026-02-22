import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
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
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // TODO: your background work here
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print(' Firebase initialized successfully');
    
    // Run Firebase diagnostics
    FirebaseTest.printDiagnostics();
    
    // Run detailed Firebase debug test
    await FirebaseDebug.testFirebaseConnection();
    await FirebaseDebug.testAuthWithDummyData();
  } catch (e) {
    print('Firebase initialization error: $e');
    print('Please check your Firebase configuration files');
    // Continue with app initialization even if Firebase fails
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<LaneDetectionService>(
          create: (_) => LaneDetectionService(),
        ),
        Provider<CollisionWarningService>(
          create: (_) => CollisionWarningService(),
        ),
        Provider<DrowsinessDetectionService>(
          create: (_) => DrowsinessDetectionService(),
        ),
        Provider<TrafficSignService>(
          create: (_) => TrafficSignService(),
        ),
        Provider<PotholeDetectionService>(
          create: (_) => PotholeDetectionService(),
        ),
        Provider<TripService>(
          create: (_) => TripService(),
        ),
      ],
      child: MaterialApp(
        title: 'ADAS App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
