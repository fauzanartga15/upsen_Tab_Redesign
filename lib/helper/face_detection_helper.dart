// todo-01-init-02: create a service class
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceDetectionHelper {
  // todo-01-init-03: add property and constructor class
  final FaceDetector _faceDetector;

  FaceDetectionHelper([FaceDetector? faceDetector])
    : _faceDetector =
          faceDetector ??
          FaceDetector(
            options: FaceDetectorOptions(
              enableContours: false,
              enableLandmarks: false,
            ),
          );

  // todo-01-init-04: run the inference and close it
  Future<List<Face>> runDetectingFaces(InputImage inputImage) async {
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    return faces;
  }

  Future<void> close() {
    return _faceDetector.close();
  }
}
