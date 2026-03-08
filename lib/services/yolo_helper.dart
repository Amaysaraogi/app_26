import 'dart:typed_data';
import 'package:flutter_vision/flutter_vision.dart';
import 'dart:io';

/// This class acts as the "Brain" of the app.
/// It handles loading the AI model and interpreting the images.
class YoloHelper {
  final FlutterVision _vision = FlutterVision();
  bool _isLoaded = false;

  /// 1. Initialize the YOLOv8 model using the files defined in pubspec.yaml.
  Future<void> initModel() async {
    if (_isLoaded) return; // Don't reload if already active
    await _vision.loadYoloModel(
      modelPath: 'assets/assets/models/best_model_float32.tflite',
      labels: 'assets/assets/models/labels.txt',
      modelVersion: 'yolov8',
    );
    _isLoaded = true;
  }

  /// 2. Process a captured photo file.
  /// This takes the photo you just took and runs it through the AI.
  Future<List<Map<String, dynamic>>> detectInImage(File imageFile) async {
    if (!_isLoaded) await initModel();

    // Convert the file into bytes that the AI can read
    Uint8List byteList = await imageFile.readAsBytes();

    // Run the detection
    return await _vision.yoloOnImage(
      bytesList: byteList,
      imageHeight: 640, // YOLOv8 standard size
      imageWidth: 640,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );
  }

  /// 3. The Logic Engine: Suggests a bin based on the detected label.
  /// You can add more labels here based on what your model was trained to see.
  String getDisposalSuggestion(String label) {
    // Normalize text to lowercase to prevent matching errors
    String item = label.toLowerCase();

    // Mapping Logic
    if (item.contains('plastic') || 
        item.contains('paper') || 
        item.contains('metal') || 
        item.contains('glass') ||
        item.contains('bottle')) {
      return "Recycle Bin ♻️";
    } else if (item.contains('food') || 
               item.contains('leaf') || 
               item.contains('organic') ||
               item.contains('banana')) {
      return "Compost Bin 🌿";
    } else {
      // If it doesn't fit the above, or is 'trash/waste', it goes to landfill
      return "Landfill (General Trash) 🗑️";
    }
  }

  /// 4. Clean up memory when the app or page is closed.
  void dispose() {
    _vision.closeYoloModel();
  }
}