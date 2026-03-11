import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import '../../services/attendance_service.dart';
import '../../models/office.dart';
import '../../theme/app_theme.dart';
import 'face_recognition_view.dart';
import 'dart:async';
import 'dart:io';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _attendanceService = AttendanceService();
  Office? _selectedOffice;
  List<Office> _offices = [];
  bool _isLoading = true;
  Position? _currentPosition;
  String _status = 'Mencari lokasi...';
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  double? _distanceInMeters;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _attendanceService.getOffices(),
        _attendanceService.getStatus(),
        _getCurrentLocation(),
      ]);

      final offices = results[0] as List<Office>;
      final status = results[1] as Map<String, dynamic>;

      setState(() {
        _offices = offices;
        _isCheckedIn = status['checked_in'] ?? false;
        _isCheckedOut = status['checked_out'] ?? false;
        
        _updateSelectedOfficeAndDistance();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _updateSelectedOfficeAndDistance() {
    if (_currentPosition == null || _offices.isEmpty) return;

    // Find nearest office
    Office? nearest;
    double minDistance = double.infinity;

    for (var office in _offices) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        office.latitude,
        office.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = office;
      }
    }

    if (nearest != null) {
      _selectedOffice = nearest;
      _distanceInMeters = minDistance;
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = 'GPS dinonaktifkan');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _status = 'Izin lokasi ditolak');
        return;
      }
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _status = 'Lokasi ditemukan';
      _updateSelectedOfficeAndDistance();
    });
  }

  Future<XFile?> _showFaceRecognitionModal() async {
    return await showModalBottomSheet<XFile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Verifikasi Wajah', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan ambil foto wajah untuk verifikasi',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(child: FaceRecognitionView(onFaceCaptured: (img) => Navigator.pop(context, img))),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckIn() async {
    if (_selectedOffice == null || _currentPosition == null) return;

    if (_distanceInMeters != null && _distanceInMeters! > _selectedOffice!.radius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda berada di luar radius kantor (${_distanceInMeters!.round()}m)')),
      );
      return;
    }

    // Show Face Recognition Dialog
    final XFile? capturedFace = await _showFaceRecognitionModal();
    if (capturedFace == null) return;

    setState(() => _isLoading = true);
    try {
      await _attendanceService.checkIn(
        officeId: _selectedOffice!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        faceImage: File(capturedFace.path),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in berhasil')),
      );
      _loadData(); // Refresh status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in gagal: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckOut() async {
    if (_currentPosition == null) return;

    // Show Face Recognition Dialog for Check Out as well
    final XFile? capturedFace = await _showFaceRecognitionModal();
    if (capturedFace == null) return;

    setState(() => _isLoading = true);
    try {
      await _attendanceService.checkOut(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        faceImage: File(capturedFace.path),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out berhasil')),
      );
      _loadData(); // Refresh status
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-out gagal: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool isWithinRadius = _distanceInMeters != null && _selectedOffice != null && _distanceInMeters! <= _selectedOffice!.radius;
    bool canCheckIn = !_isCheckedIn && !_isCheckedOut && isWithinRadius;
    bool canCheckOut = _isCheckedIn && !_isCheckedOut && isWithinRadius;

    return Scaffold(
      appBar: AppBar(title: const Text('Presensi')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        _isCheckedOut ? Icons.check_circle : Icons.location_on, 
                        size: 48, 
                        color: _isCheckedOut ? Colors.green : AppTheme.accentColor
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isCheckedOut ? 'Sudah Selesai Kerja' : (_isCheckedIn ? 'Sedang Bekerja' : _status), 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      if (_currentPosition != null && !_isCheckedOut) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (_distanceInMeters != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Jarak ke kantor: ${_distanceInMeters!.round()} meter',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _distanceInMeters! <= (_selectedOffice?.radius ?? 0) ? Colors.green : Colors.red
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!_isCheckedOut) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canCheckIn ? _handleCheckIn : (canCheckOut ? _handleCheckOut : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canCheckIn ? Colors.green : (canCheckOut ? Colors.orange : Colors.grey),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      canCheckIn ? 'Check In' : (canCheckOut ? 'Check Out' : (isWithinRadius ? 'Sudah Presensi' : 'Terlalu Jauh')),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else 
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text(
                      'Terima kasih telah bekerja hari ini!',
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
