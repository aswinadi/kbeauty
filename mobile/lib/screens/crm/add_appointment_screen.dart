import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/customer_selection_dialog.dart';

class AddAppointmentScreen extends StatefulWidget {
  final DateTime? initialDate;
  const AddAppointmentScreen({super.key, this.initialDate});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final PosService _posService = PosService();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Map<String, dynamic>? _selectedCustomer;
  
  final _treatmentController = TextEditingController();
  final _paxController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  bool _isPaid = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }



  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCustomer == null) {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final String timeString = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';
    final String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final data = {
      'customer_id': _selectedCustomer!['id'],
      'appointment_date': dateString,
      'appointment_time': timeString,
      'treatment_name': _treatmentController.text,
      'pax': int.tryParse(_paxController.text) ?? 1,
      'is_paid': _isPaid,
      'notes': _notesController.text,
    };

    final result = await _posService.addAppointment(data);
    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save appointment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Appointment'),
      ),
      body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.search),
                    ),
                    controller: TextEditingController(
                      text: _selectedCustomer != null 
                          ? (_selectedCustomer!['full_name'] ?? _selectedCustomer!['name'] ?? '') 
                          : '',
                    ),
                    onTap: () async {
                      final customer = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => const CustomerSelectionDialog(),
                      );
                      if (customer != null) {
                        setState(() => _selectedCustomer = customer);
                      }
                    },
                    validator: (val) => _selectedCustomer == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('EEEE, d MMMM y').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Time'),
                    subtitle: Text(_selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _selectTime(context),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _treatmentController,
                    decoration: const InputDecoration(
                      labelText: 'Treatment Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _paxController,
                    decoration: const InputDecoration(
                      labelText: 'Pax (Number of People)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (int.tryParse(val) == null) return 'Must be a number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Paid'),
                    subtitle: const Text('Has the customer paid for this booking?'),
                    value: _isPaid,
                    onChanged: (val) => setState(() => _isPaid = val),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Book Appointment'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
