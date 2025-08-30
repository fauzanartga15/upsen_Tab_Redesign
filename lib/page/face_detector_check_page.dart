import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:toastification/toastification.dart';
import 'package:upsen_tablet/repository/check_in_repository.dart';

import '../helpers/face_detector_painter.dart';
import '../helpers/recognizer.dart';
import 'camera_view_attendance_page.dart';
import 'success_confirmation_view.dart'; // Add this import

class FaceDetectorCheckPage extends StatefulWidget {
  const FaceDetectorCheckPage({super.key});

  @override
  State<FaceDetectorCheckPage> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorCheckPage> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(enableContours: false, enableLandmarks: false),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;

  late List<RecognitionEmbedding> recognitions = [];
  CameraImage? frame;

  late Recognizer recognizer;
  bool isTakePicture = false;

  @override
  void initState() {
    super.initState();
    recognizer = Recognizer();
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();

    log('dispose face detector check page');

    super.dispose();
  }

  void _takePicture(CameraImage cameraImage) async {
    if (mounted) {
      setState(() {
        frame = cameraImage;
        isTakePicture = true;
      });
    }
  }

  img.Image? image;
  Future<void> performFaceRecognition(List<Face> faces) async {
    try {
      recognitions.clear();

      image = convertNV21ToImage(frame!);
      image = img.copyRotate(
        image!,
        angle: _cameraLensDirection == CameraLensDirection.front ? 270 : 90,
      );

      for (Face face in faces) {
        Rect faceRect = face.boundingBox;

        img.Image croppedFace = img.copyCrop(
          image!,
          x: faceRect.left.toInt(),
          y: faceRect.top.toInt(),
          width: faceRect.width.toInt(),
          height: faceRect.height.toInt(),
        );

        RecognitionEmbedding recognition = recognizer.recognize(
          croppedFace,
          face.boundingBox,
        );

        recognitions.add(recognition);
        CheckInRepository checkInRepository = CheckInRepository();

        await checkInRepository.checkIn(recognition.embedding);

        // Dismiss any existing toasts
        toastification.dismissAll();

        // Show success toast
        toastification.show(
          type: ToastificationType.success,
          title: const Text('Berhasil melakukan absensi'),
          autoCloseDuration: const Duration(seconds: 3),
        );

        // Navigate to success page instead of just popping
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SuccessConfirmationPage(
                // You can pass actual data here from the API response
                employeeName: 'Sapri',
                employeePosition: 'Staff - HR Department',
                checkInTime: '08:15:32',
                status: 'ON TIME',
                location: 'MAIN OFFICE',
                nextAction: 'Check-out at 16:00',
                matchConfidence: 0.96,
              ),
            ),
          );
        }
      }
    } catch (e) {
      toastification.dismissAll();
      toastification.show(
        type: ToastificationType.error,
        title: const Text('Wajah tidak dikenali'),
        description: const Text('Silakan coba lagi atau gunakan manual entry'),
        autoCloseDuration: const Duration(seconds: 5),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  img.Image convertNV21ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    Uint8List nv21Bytes = cameraImage.planes[0].bytes;
    final image = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int yValue = nv21Bytes[y * width + x];

        var color = image.getColor(yValue, yValue, yValue);
        image.setPixel(x, y, color);
      }
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return CameraViewAttendancePage(
      customPaint: _customPaint,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
      onTakePicture: _takePicture,
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);

      if (isTakePicture) {
        await performFaceRecognition(faces);
      }
      isTakePicture = false;
    } else {
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
