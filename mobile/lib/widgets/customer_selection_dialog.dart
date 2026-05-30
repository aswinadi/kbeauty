import 'package:flutter/material.dart';
import '../services/pos_service.dart';
import '../theme/app_theme.dart';

class CustomerSelectionDialog extends StatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  State<CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  final _posService = PosService();
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  void _search(String q) async {
    setState(() {
      _isLoading = true;
    });
    final results = await _posService.getCustomers(search: q);
    setState(() {
      _customers = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Customer'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            TextField(
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _customers.isEmpty
                      ? const Center(child: Text('No customers found.'))
                      : ListView.builder(
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final c = _customers[index];
                            final name = c['full_name'] ?? c['name'] ?? 'Unknown';
                            final phone = c['phone'] ?? '';
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.accentColor,
                                foregroundColor: Colors.white,
                                child: Icon(Icons.person),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: phone.isNotEmpty ? Text(phone) : null,
                              onTap: () => Navigator.pop(context, c),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () => _addNewCustomer(),
                icon: const Icon(Icons.person_add),
                label: const Text('Add New Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewCustomer() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final newCustomer = await _posService.registerCustomer({
        'name': nameController.text,
        'phone': phoneController.text,
      });
      if (newCustomer != null && mounted) {
        Navigator.pop(context, newCustomer);
      }
    }
  }
}
