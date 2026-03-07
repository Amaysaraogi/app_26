import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';

class YoloHelper {
  final FlutterVision _vision = FlutterVision();
  bool _isLoaded = false;

  // Load the model
  Future<void> initModel() async {
    await _vision.loadYoloModel(
      modelPath: 'assets/assets/models/best_model_float32.tflite',
      labels: 'assets/assets/models/labels.txt',
      modelVersion: 'yolov8',
    );
    _isLoaded = true;
  }

  // The actual detection logic
  Future<List<Map<String, dynamic>>> detectObjects(CameraImage image) async {
    if (!_isLoaded) return [];

    return await _vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );
  }

  void dispose() {
    _vision.closeYoloModel();
  }
}