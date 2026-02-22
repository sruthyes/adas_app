import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';


// Existing services
import '../services/lane_detection_service.dart';
import '../services/collision_warning_service.dart';
import '../services/drowsiness_detection_service.dart';
import '../services/traffic_sign_service.dart';
import '../services/pothole_detection_service.dart';
import '../helpers/nearby_restaurant_helper.dart';

// YOLO
import '../services/yolo_service.dart';
import '../widgets/yolo_painter.dart';
import '../widgets/adas_overlay.dart';
import '../utils/yolo_postprocessor.dart';

class ADASCameraScreen extends StatefulWidget {
  const ADASCameraScreen({super.key});

  @override
  State<ADASCameraScreen> createState() => _ADASCameraScreenState();
}

class _ADASCameraScreenState extends State<ADASCameraScreen>
    with WidgetsBindingObserver {


  // ---------------- YOLO ----------------
  final YoloService _yoloService = YoloService();
  List<Detection> _yoloResults = [];

  // ---------------- CAMERA ----------------
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isFrontCamera = false;
  bool _isProcessing = false;

  // ---------------- AUDIO ----------------
  late final AudioPlayer _audioPlayer;
  late final FlutterTts _flutterTts;

  // ---------------- SERVICES STATUS ----------------
  bool _servicesInitialized = false;
  bool _isCameraInitialized = false;

  // ---------------- THROTTLING ----------------
  DateTime? _lastInferenceTime;
  final Duration _minInferenceInterval =
      const Duration(milliseconds: 200);
  DateTime? _lastDrowsyAlertTime;

  // ---------------- ADAS RESULTS ----------------
  bool _laneDetected = false;
  bool _laneDepartureDetected = false;
  double _laneOffset = 0.0;

  CollisionWarningResult _collisionWarningResult =
      CollisionWarningResult(
    level: CollisionWarningLevel.none,
    estimatedDistance: double.infinity,
    timeToCollision: double.infinity,
  );

  bool _drowsinessDetected = false;
  String? _trafficSignDetected;
  bool _potholeDetected = false;

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _audioPlayer = AudioPlayer();
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.45);
    _flutterTts.setPitch(1.0);

    Future.microtask(() async {
      await _initializeServices();
      await _yoloService.loadModel();   // Load YOLO once
      await _initializeCamera();
    });
  }

  Future<void> _initializeServices() async {
    try {
      final laneService = context.read<LaneDetectionService>();
      final collisionService = context.read<CollisionWarningService>();
      final drowsinessService = context.read<DrowsinessDetectionService>();
      final trafficSignService = context.read<TrafficSignService>();
      final potholeService = context.read<PotholeDetectionService>();

      await Future.wait([
        laneService.initialize(),
        collisionService.initialize(),
        drowsinessService.initialize(),
        trafficSignService.initialize(),
        potholeService.initialize(),
      ]);

      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
      }
    } catch (e) {
      print("Service init error: $e");
    }
  }

  // ================= CAMERA =================

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    final index = _isFrontCamera ? 1 : 0;
    final actualIndex = index < _cameras!.length ? index : 0;

    _cameraController = CameraController(
      _cameras![actualIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });

      if (_servicesInitialized) {
        _startImageStream();
      }
    }
  }

  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) {
      if (_isProcessing) return;

      final now = DateTime.now();
      if (_lastInferenceTime != null &&
          now.difference(_lastInferenceTime!) <
              _minInferenceInterval) {
        return;
      }

      _lastInferenceTime = now;
      _isProcessing = true;

      _processFrame(image).whenComplete(() {
        _isProcessing = false;
      });
    });
  }

  // ================= IMAGE CONVERSION =================

  img.Image _convertCameraImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final image = img.Image(width: width, height: height);
    final plane = cameraImage.planes[0].bytes;

    int index = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = plane[index++];
        image.setPixelRgb(x, y, pixel, pixel, pixel);
      }
    }

    return image;
  }

  // ================= MAIN FRAME PROCESSING =================

  Future<void> _processFrame(CameraImage image) async {
    if (!_servicesInitialized) return;

    final laneService = context.read<LaneDetectionService>();
    final collisionService = context.read<CollisionWarningService>();
    final drowsinessService =
        context.read<DrowsinessDetectionService>();
    final trafficSignService =
        context.read<TrafficSignService>();
    final potholeService =
        context.read<PotholeDetectionService>();

    if (_isFrontCamera) {
        final result =
            await drowsinessService.detectDrowsiness(image);

        if (mounted) {
          setState(() => _drowsinessDetected = result);
        }

        if (result) {
        await _playBeep();

        if (_lastDrowsyAlertTime == null ||
            DateTime.now().difference(_lastDrowsyAlertTime!) >
                const Duration(minutes: 10)) {

          _showDrowsyDialog();
          _lastDrowsyAlertTime = DateTime.now();
        }
      } else {
      final laneResult =
          await laneService.detectLanes(image);

      final collisionResult =
          await collisionService.detectCollision(image);

      final trafficSignResult =
          await trafficSignService.detectTrafficSigns(image);

      final potholeResult =
          await potholeService.detectPotholes(image);

      // ---------------- YOLO DETECTION ----------------
      if (_yoloService.isLoaded) {
        final img.Image rgbImage =
            _convertCameraImage(image);

        final detections =
            await _yoloService.detect(rgbImage);

        if (mounted) {
          setState(() {
            _yoloResults = detections;
          });
        }

        for (final det in detections) {
          if (det.score > 0.6 &&
              (det.classId == 2 ||
               det.classId == 5 ||
               det.classId == 7)) {
            print("YOLO: Vehicle detected");
            await _playBeep();
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _laneDetected = laneResult;
          _collisionWarningResult = collisionResult;
          _trafficSignDetected = trafficSignResult;
          _potholeDetected = potholeResult;
          _laneDepartureDetected =
              laneService.laneDepartureDetected;
          _laneOffset = laneService.lastOffset;
        });
      }

      if (_laneDepartureDetected) await _playBeep();
      if (collisionResult.level ==
          CollisionWarningLevel.high) {
        await _playBeep();
      }
    }
  }

  Future<void> _playBeep() async {
    await _audioPlayer.play(
      AssetSource("sounds/beep.mp3"),
    );
  }
    Future<void> _showDrowsyDialog() async {
        await _flutterTts.speak("You seem tired. Please consider taking a break.");

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Drowsiness Alert"),
            content: const Text(
              "You seem tired. Find nearby rest stops?",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("NO"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  NearbyRestaurantHelper.showNearby(context);
                },
                child: const Text("YES"),
              ),
            ],
          ),
        );
      }
  void _toggleCamera() async {
    _isFrontCamera = !_isFrontCamera;
    await _cameraController?.dispose();
    _isCameraInitialized = false;
    await _initializeCamera();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final isReady = _cameraController != null &&
        _isCameraInitialized &&
        _servicesInitialized;

    if (!isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController!),

          CustomPaint(
            painter: YoloPainter(_yoloResults),
          ),

          ADASOverlay(
            laneDetected: _laneDetected,
            collisionWarning: _collisionWarningResult,
            drowsinessDetected: _drowsinessDetected,
            trafficSignDetected: _trafficSignDetected,
            potholeDetected: _potholeDetected,
            isDriverFacing: _isFrontCamera,
          ),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "back",
                  onPressed: () =>
                      Navigator.pop(context),
                  child:
                      const Icon(Icons.arrow_back),
                ),
                FloatingActionButton(
                  heroTag: "switch",
                  onPressed: _toggleCamera,
                  child: const Icon(
                      Icons.switch_camera),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}