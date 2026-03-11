import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../theme/app_theme.dart';

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
  String? _errorMessage;

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
        setState(() {
          _errorMessage = 'Wajah tidak terdeteksi. Pastikan pencahayaan cukup dan wajah terlihat jelas.';
        });
      } else {
        setState(() => _errorMessage = null);
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

    final size = MediaQuery.of(context).size;
    var scale = 1 / (_controller!.value.aspectRatio * size.aspectRatio);
    if (scale < 1) scale = 1 / scale;

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Transform.scale(
                  scale: scale,
                  child: Center(
                    child: CameraPreview(_controller!),
                  ),
                ),
              ),
              // Face Frame Overlay
              Container(
                decoration: ShapeDecoration(
                  shape: CircleBorder(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
                width: 250,
                height: 250,
              ),
              // Hint or Error text overlay
              Positioned(
                bottom: 20,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: (_errorMessage != null ? Colors.red : Colors.black).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _errorMessage ?? 'Posisikan wajah di dalam lingkaran',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 12, 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: IconButton.filled(
            onPressed: _isProcessing ? null : _capture,
            iconSize: 64,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
            icon: _isProcessing 
              ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white))
              : const Icon(Icons.camera_front),
          ),
        ),
      ],
    );
  }
}
