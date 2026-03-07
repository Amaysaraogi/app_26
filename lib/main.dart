import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  // testing comment and nothing more

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  late ImageLabeler _imageLabeler;
  String _result = 'Tap the button to scan an item';

  @override
  void initState() {
    super.initState();
    _initializeML();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final firstCamera = cameras.first;
        _controller = CameraController(
          firstCamera,
          ResolutionPreset.medium,
        );
        _initializeControllerFuture = _controller!.initialize();
      } else {
        _initializeControllerFuture = Future.value(); // No camera, future completes immediately
        setState(() {
          _result = 'Camera not available on this device.';
        });
      }
    } catch (e) {
      _initializeControllerFuture = Future.value(); // Error, future completes
      setState(() {
        _result = 'Camera error: $e\nTry running on web, iOS, or Android.';
      });
    }
  }

  void _initializeML() {
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions());
  }

  @override
  void dispose() {
    _controller?.dispose();
    _imageLabeler.close();
    super.dispose();
  }

  void _scanItem() async {
    if (_controller?.value.isInitialized != true) {
      setState(() {
        _result = 'Camera not initialized. Please run on a supported device.';
      });
      return;
    }
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final labels = await _imageLabeler.processImage(inputImage);
      if (labels.isNotEmpty) {
        final label = labels.first;
        String bin = _getBinForLabel(label.label);
        setState(() {
          _result = 'Detected: ${label.label}\nConfidence: ${(label.confidence * 100).toStringAsFixed(1)}%\nBin: $bin';
        });
      } else {
        setState(() {
          _result = 'No items detected. Try again.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  String _getBinForLabel(String label) {
    // Simple mapping - in a real app, use a more sophisticated system
    if (label.toLowerCase().contains('plastic') || label.toLowerCase().contains('bottle') || label.toLowerCase().contains('can')) {
      return 'Recycle';
    } else if (label.toLowerCase().contains('food') || label.toLowerCase().contains('organic')) {
      return 'Compost';
    } else {
      return 'Landfill';
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _result,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanItem,
        tooltip: 'Scan Item',
        child: const Icon(Icons.camera),
      ),
    );
  }
}
