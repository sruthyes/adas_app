import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'pothole_detection_service.dart';
import 'trip_service.dart';

// Task names
const backgroundMonitoringTask = "backgroundMonitoringTask";
const periodicMonitoringTask = "periodicMonitoringTask";

// Initialize background tasks
void initializeBackgroundTasks() {
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Register one-time task
  Workmanager().registerOneOffTask(
    "backgroundStartup",
    backgroundMonitoringTask,
    initialDelay: const Duration(seconds: 5),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  // Register periodic task
  Workmanager().registerPeriodicTask(
    "periodicMonitoring",
    periodicMonitoringTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}

// The callback dispatcher for background tasks
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case backgroundMonitoringTask:
        await performBackgroundMonitoring();
        break;
      case periodicMonitoringTask:
        await performPeriodicMonitoring();
        break;
      default:
        print("Unknown task: $task");
    }
    return Future.value(true);
  });
}

// Background monitoring logic
Future<void> performBackgroundMonitoring() async {
  final prefs = await SharedPreferences.getInstance();
  final isADASEnabled = prefs.getBool('adas_enabled') ?? false;
  
  if (!isADASEnabled) return;

  // Check for nearby potholes and send notifications
  try {
    final position = await Geolocator.getCurrentPosition();
    final potholeService = PotholeDetectionService();
    final nearbyPotholes = await potholeService.getNearbyPotholes(
      position.latitude, 
      position.longitude, 
      500 // 500 meters radius
    );
    
    if (nearbyPotholes.isNotEmpty) {
      await _showNotification(
        'Pothole Alert', 
        'There are ${nearbyPotholes.length} potholes nearby. Drive carefully.'
      );
    }
  } catch (e) {
    print('Error in background monitoring: $e');
  }
}

// Periodic monitoring logic
Future<void> performPeriodicMonitoring() async {
  final prefs = await SharedPreferences.getInstance();
  final isADASEnabled = prefs.getBool('adas_enabled') ?? false;
  final isActiveTrip = prefs.getBool('active_trip') ?? false;
  
  if (!isADASEnabled) return;

  // If there's an active trip, update trip data
  if (isActiveTrip) {
    try {
      final tripId = prefs.getString('current_trip_id');
      if (tripId != null) {
        final position = await Geolocator.getCurrentPosition();
        final tripService = TripService();
        
        // Update trip with current location
        await tripService.updateTripLocation(
          tripId, 
          position.latitude, 
          position.longitude
        );
      }
    } catch (e) {
      print('Error updating trip in background: $e');
    }
  }
}

// Show a notification
Future<void> _showNotification(String title, String body) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'adas_channel',
    'ADAS Alerts',
    channelDescription: 'Notifications for ADAS alerts',
    importance: Importance.high,
    priority: Priority.high,
  );
  
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
      
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}