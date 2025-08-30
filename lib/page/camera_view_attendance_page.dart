import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:math' hide log;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../helper/recognizer.dart';

class CameraViewAttendancePage extends StatefulWidget {
  const CameraViewAttendancePage({
    super.key,
    required this.customPaint,
    required this.onImage,
    this.onCameraFeedReady,
    this.onCameraLensDirectionChanged,
    this.initialCameraLensDirection = CameraLensDirection.back,
    required this.onTakePicture,
  });

  final CustomPaint? customPaint;
  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final CameraLensDirection initialCameraLensDirection;
  final Function(CameraImage cameraImage) onTakePicture;

  @override
  State<CameraViewAttendancePage> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraViewAttendancePage>
    with TickerProviderStateMixin {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;

  late List<RecognitionEmbedding> recognitions = [];
  CameraImage? frame;
  CameraLensDirection camDirec = CameraLensDirection.front;
  late Recognizer recognizer;
  late FaceDetector detector;
  bool isFaceRegistered = false;
  String faceStatusMessage = 'Belum Terdaftar';
  bool _didCloseEyes = false;

  // Animation controllers
  late AnimationController _scanController;
  late AnimationController _confidenceController;
  late Animation<double> _scanAnimation;
  late Animation<double> _confidenceAnimation;

  // Mock confidence value
  double confidenceValue = 0.85;

  @override
  void initState() {
    super.initState();
    recognizer = Recognizer();
    detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: true,
      ),
    );

    _setupAnimations();

    if (mounted) {
      _initialize();
    }
  }

  void _setupAnimations() {
    _scanController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _confidenceController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _scanAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _confidenceAnimation = Tween<double>(begin: 0.0, end: confidenceValue)
        .animate(
          CurvedAnimation(parent: _confidenceController, curve: Curves.easeOut),
        );

    _confidenceController.forward();
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _confidenceController.dispose();
    _stopLiveFeed();
    log('Dispose terpanggil ');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _liveFeedBody());
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) return Container();
    if (_controller == null) return Container();
    if (_controller?.value.isInitialized == false) return Container();

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Camera Preview
        Center(
          child: AspectRatio(
            aspectRatio: 0.8,
            child: CameraPreview(_controller!, child: widget.customPaint),
          ),
        ),

        // Header
        _buildHeader(),

        // Face Detection Overlay
        _buildFaceDetectionOverlay(),

        // Confidence Indicator
        _buildConfidenceIndicator(),

        // Action Buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).padding.top + 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    'Face Recognition Active',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaceDetectionOverlay() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: MediaQuery.of(context).size.width * 0.2,
      right: MediaQuery.of(context).size.width * 0.2,
      bottom: MediaQuery.of(context).size.height * 0.4,
      child: AnimatedBuilder(
        animation: _scanAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(
                  0xFF00BCD4,
                ).withValues(alpha: _scanAnimation.value + 0.4),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF00BCD4,
                  ).withValues(alpha: _scanAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Detecting face...',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00BCD4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    return Positioned(
      bottom: 200,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(3),
              ),
              child: AnimatedBuilder(
                animation: _confidenceAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _confidenceAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Recognition Confidence: ${(confidenceValue * 100).toInt()}%',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: MaterialButton(
                onPressed: () {
                  // Settings functionality - placeholder
                },
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.settings, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B46C1).withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: MaterialButton(
                onPressed: () {
                  // Manual entry functionality - placeholder
                },
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Manual Entry',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Keep all the existing camera functionality methods unchanged
  Timer? timer;

  Future<void> _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }

      _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
        timer = Timer.periodic(const Duration(seconds: 16), (timer) async {
          if (_controller!.value.isStreamingImages) {
            // Timer functionality
          }
        });
      });

      setState(() {});
    });
  }

  Future<void> _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    timer?.cancel();
    _controller = null;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    frame = image;
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    widget.onImage(inputImage);
    if (mounted) {
      await _processImage(await detector.processImage(inputImage));
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _detect({required Face face}) async {
    const double blinkThreshold = 0.25;

    if ((face.leftEyeOpenProbability ?? 1.0) < (blinkThreshold) &&
        (face.rightEyeOpenProbability ?? 1.0) < (blinkThreshold)) {
      if (mounted) {
        setState(() => _didCloseEyes = true);
      }
    }
  }

  Future<void> _processImage(List<Face> faces) async {
    try {
      if (faces.isEmpty) return;
      final Face firstFace = faces.first;

      if (_didCloseEyes) {
        if ((faces.first.leftEyeOpenProbability ?? 1.0) < 0.75 &&
            (faces.first.rightEyeOpenProbability ?? 1.0) < 0.75) {
          widget.onTakePicture(frame!);
          if (mounted) {
            setState(() {
              _didCloseEyes = false;
            });
          }
        }
      }

      _detect(face: firstFace);
    } catch (e) {
      throw Exception(e);
    }
  }

  double calculateSymmetry(
    Point<int>? leftPosition,
    Point<int>? rightPosition,
  ) {
    if (leftPosition != null && rightPosition != null) {
      final double dx = (rightPosition.x - leftPosition.x).abs().toDouble();
      final double dy = (rightPosition.y - leftPosition.y).abs().toDouble();
      final distance = Offset(dx, dy).distance;

      return distance;
    }
    return 0.0;
  }
}
