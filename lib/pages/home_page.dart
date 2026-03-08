import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:app_26/services/yolo_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Instance of our AI "Brain"
  final YoloHelper _yoloHelper = YoloHelper();
  
  CameraController? cameraController;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupCameraController();
  }

  @override
  void dispose() {
    // Clean up both the camera and the AI model when closing the app
    cameraController?.dispose();
    _yoloHelper.dispose();
    super.dispose();
  }

  /// 1. Initialize the Camera and the AI Model
  Future<void> _setupCameraController() async {
    List<CameraDescription> cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      // Use the first camera (usually the back camera)
      cameraController = CameraController(cameras.first, ResolutionPreset.high);
      
      await cameraController!.initialize();
      // Load the YOLO model once the camera is ready
      await _yoloHelper.initModel();
      
      if (mounted) setState(() {});
    }
  }

  /// 2. Capture a picture and process it immediately
  Future<void> _captureAndProcess() async {
    if (cameraController == null || !cameraController!.value.isInitialized || isProcessing) return;

    setState(() => isProcessing = true);

    try {
      // Step A: Take the physical picture
      XFile picture = await cameraController!.takePicture();
      File imageFile = File(picture.path);

      // Step B: Send the picture file to our YOLO helper for processing
      final results = await _yoloHelper.detectInImage(imageFile);

      if (results.isNotEmpty) {
        // Step C: Get the name of the object (e.g., "Plastic bottle")
        String detectedLabel = results[0]['tag'];
        
        // Step D: Get the bin suggestion from our helper logic
        String suggestion = _yoloHelper.getDisposalSuggestion(detectedLabel);

        // Step E: Show the result to the user
        _showResultDialog(detectedLabel, suggestion);
      } else {
        _showResultDialog("Unknown", "We couldn't identify this. Please try again or place in Landfill.");
      }
    } catch (e) {
      print("Error during capture: $e");
    } finally {
      setState(() => isProcessing = false);
    }
  }

  /// 3. Show a pop-up with the detection result and suggestion
  void _showResultDialog(String item, String suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Detected: $item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sorting Suggestion:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(suggestion, style: const TextStyle(fontSize: 18, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Waste Sorter AI")),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera Viewport
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.50,
                child: CameraPreview(cameraController!),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Capture Button
          isProcessing 
            ? const CircularProgressIndicator() 
            : IconButton(
                onPressed: _captureAndProcess,
                iconSize: 80,
                icon: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
          
          const Text("Tap to identify waste", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}