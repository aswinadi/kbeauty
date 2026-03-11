import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../theme/app_theme.dart';

class FaceRecognitionView extends StatefulWidget {
  final Function(XFile image) onFaceCaptured;
  final bool isExternalLoading;
  final String? externalErrorMessage;

  const FaceRecognitionView({
    super.key, 
    required this.onFaceCaptured,
    this.isExternalLoading = false,
    this.externalErrorMessage,
  });

  @override
  State<FaceRecognitionView> createState() => _FaceRecognitionViewState();
}

class _FaceRecognitionViewState extends State<FaceRecognitionView> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
    ),
  );
  bool _isProcessing = false;
  bool _isCameraReady = false;
  bool _isFaceDetected = false;
  String? _internalErrorMessage;
  DateTime? _lastDetectionTime;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    
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
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
        _startImageStream();
      }
    } catch (e) {
      print('Camera Error: $e');
    }
  }

  void _startImageStream() {
    _controller?.startImageStream((CameraImage image) async {
      if (_isProcessing || !mounted) return;
      
      final now = DateTime.now();
      if (_lastDetectionTime != null && now.difference(_lastDetectionTime!).inMilliseconds < 500) {
        return;
      }
      _lastDetectionTime = now;

      try {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
        final InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(_controller!.description.sensorOrientation) ?? InputImageRotation.rotation0deg;
        final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.yuv420;

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: imageSize,
            rotation: imageRotation,
            format: inputImageFormat,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
        final faces = await _faceDetector.processImage(inputImage);

        if (mounted) {
          setState(() {
            bool faceFound = false;
            if (faces.isNotEmpty) {
              final face = faces.first;
              
              // Ensure we have landmarks (eyes, nose, and mouth) to avoid "ceiling" false positives
              final hasEyes = face.landmarks[FaceLandmarkType.leftEye] != null && 
                             face.landmarks[FaceLandmarkType.rightEye] != null;
              final hasNose = face.landmarks[FaceLandmarkType.noseBase] != null;
              final hasMouth = face.landmarks[FaceLandmarkType.bottomMouth] != null;
              
              // Ensure face is upright and facing camera (Euler angles)
              final isFacingCamera = face.headEulerAngleX!.abs() < 15 &&
                                   face.headEulerAngleY!.abs() < 15 && 
                                   face.headEulerAngleZ!.abs() < 15;

              // Ensure face is reasonably large in frame
              final isCloseEnough = face.boundingBox.width > (image.width * 0.3);
              
              // Aspect ratio check: Human faces are usually taller than wide (approx 1.2 to 1.5 ratio)
              final aspectRatio = face.boundingBox.height / face.boundingBox.width;
              final isHumanProportion = aspectRatio > 1.0 && aspectRatio < 2.0;

              // Centering: Face center should be within the middle 60% of the frame
              final centerX = face.boundingBox.center.dx;
              final centerY = face.boundingBox.center.dy;
              final isCentered = centerX > (image.width * 0.25) && centerX < (image.width * 0.75) &&
                                centerY > (image.height * 0.2) && centerY < (image.height * 0.8);

              if (hasEyes && hasNose && hasMouth && isFacingCamera && isCloseEnough && isCentered && isHumanProportion) {
                faceFound = true;
                _internalErrorMessage = null;
              } else if (!isCloseEnough) {
                _internalErrorMessage = 'Dekatkan wajah Anda ke kamera';
              } else if (!isCentered) {
                _internalErrorMessage = 'Posisikan wajah di tengah lingkaran';
              } else if (!isHumanProportion || !isFacingCamera) {
                _internalErrorMessage = 'Arahkan wajah tegak ke kamera';
              } else {
                _internalErrorMessage = 'Pastikan wajah terlihat jelas (Mata, Hidung, Mulut)';
              }
            } else {
              _internalErrorMessage = 'Posisikan wajah di dalam lingkaran';
            }
            
            _isFaceDetected = faceFound;
          });
        }
      } catch (e) {
        print('In-stream detection error: $e');
      }
    });
  }

  Future<void> _capture() async {
    if (_isProcessing || _controller == null || !_isFaceDetected) return;
    
    setState(() {
      _isProcessing = true;
      _isFaceDetected = false; // Reset immediately so it's not "stuck" green
      _internalErrorMessage = null;
    });

    try {
      // Stop stream during capture to avoid interference
      if (_controller!.value.isStreamingImages) {
        await _controller?.stopImageStream();
      }

      final image = await _controller!.takePicture();
      widget.onFaceCaptured(image);
      
      // Note: We don't automatically restart here because the modal usually closes on success.
      // However, if the external process fails, AttendanceScreen will still have the modal open.
    } catch (e) {
      print('Capture error: $e');
      if (mounted) {
        setState(() => _internalErrorMessage = 'Gagal mengambil foto. Silakan coba lagi.');
        _startImageStream(); // Resume if failed
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Add a way to resume stream externally if needed
  void resumeScanning() {
    if (mounted && _controller != null && !_controller!.value.isStreamingImages) {
      _startImageStream();
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

    final String? displayError = widget.externalErrorMessage ?? _internalErrorMessage;
    final bool isSuccess = widget.externalErrorMessage?.toLowerCase().contains('berhasil') ?? false;

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
                      color: _isFaceDetected ? Colors.green.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.5),
                      width: 3,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (displayError != null 
                        ? (isSuccess ? Colors.green : Colors.red) 
                        : Colors.black).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayError ?? (_isFaceDetected ? 'Wajah terdeteksi! Klik tombol di bawah' : 'Posisikan wajah di dalam lingkaran'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 13, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Loading Overlay
              if (widget.isExternalLoading)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: IconButton.filled(
            onPressed: (_isProcessing || widget.isExternalLoading || !_isFaceDetected) ? null : _capture,
            iconSize: 64,
            style: IconButton.styleFrom(
              backgroundColor: _isFaceDetected ? AppTheme.accentColor : Colors.grey,
            ),
            icon: (_isProcessing || widget.isExternalLoading)
              ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white))
              : Icon(Icons.camera_front, color: _isFaceDetected ? Colors.white : Colors.white54),
          ),
        ),
      ],
    );
  }
}
