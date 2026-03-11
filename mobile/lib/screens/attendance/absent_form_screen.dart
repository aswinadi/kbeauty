import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/attendance_service.dart';
import '../../models/office.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AbsentFormScreen extends StatefulWidget {
  const AbsentFormScreen({super.key});

  @override
  State<AbsentFormScreen> createState() => _AbsentFormScreenState();
}

class _AbsentFormScreenState extends State<AbsentFormScreen> {
  final _attendanceService = AttendanceService();
  final _reasonController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  Office? _selectedOffice;
  List<Office> _offices = [];
  String _selectedType = 'sick';
  DateTime _selectedDate = DateTime.now();
  List<File> _images = [];
  bool _isLoading = true;

  final Map<String, String> _types = {
    'sick': 'Sakit',
    'leave': 'Cuti',
    'late': 'Terlambat',
    'early_out': 'Pulang Awal',
  };

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    try {
      final offices = await _attendanceService.getOffices();
      setState(() {
        _offices = offices;
        if (offices.isNotEmpty) _selectedOffice = offices.first;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedOffice == null) return;
    if (_selectedType == 'sick' && _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti sakit wajib dilampirkan')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _attendanceService.submitAbsent(
        officeId: _selectedOffice!.id,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        type: _selectedType,
        reason: _reasonController.text,
        images: _images,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permohonan berhasil dikirim')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim: $e')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Form Izin / Sakit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Tipe Izin'),
              items: _types.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tanggal'),
                child: Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Alasan / Catatan'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text('Lampiran Foto (${_images.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.map((file) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _images.remove(file)),
                      ),
                    ),
                  )),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                      child: const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Kirim Permohonan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
