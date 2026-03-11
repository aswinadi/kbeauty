import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceRecognitionView extends StatefulWidget {
  final Function(XFile image) onFaceCaptured;

  const FaceRecognitionView({super.key, required this.onFaceCaptured});

  @override
  State<FaceRecognitionView> createState() => _FaceRecognitionViewState();
}

class _FaceRecognitionViewState extends State<FaceRecognitionView> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );
  bool _isProcessing = false;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    
    // Find front camera
    CameraDescription? frontCamera;
    for (var cam in _cameras) {
      if (cam.lensDirection == CameraLensDirection.front) {
        frontCamera = cam;
        break;
      }
    }

    _controller = CameraController(
      frontCamera ?? _cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() => _isCameraReady = true);
    }
  }

  Future<void> _capture() async {
    if (_isProcessing || _controller == null) return;
    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      
      // Validate face existence
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wajah tidak terdeteksi, coba lagi')),
          );
        }
      } else {
        widget.onFaceCaptured(image);
      }
    } catch (e) {
      print('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 400,
            width: double.infinity,
            child: CameraPreview(_controller!),
          ),
        ),
        const SizedBox(height: 24),
        IconButton.filled(
          onPressed: _isProcessing ? null : _capture,
          iconSize: 64,
          icon: _isProcessing 
            ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white))
            : const Icon(Icons.camera_front),
        ),
        const SizedBox(height: 16),
        const Text('Posisikan wajah Anda di tengah kamera', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
