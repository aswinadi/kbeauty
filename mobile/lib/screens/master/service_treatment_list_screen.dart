import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import 'package:intl/intl.dart';

class ServiceTreatmentListScreen extends StatefulWidget {
  const ServiceTreatmentListScreen({super.key});

  @override
  State<ServiceTreatmentListScreen> createState() => _ServiceTreatmentListScreenState();
}

class _ServiceTreatmentListScreenState extends State<ServiceTreatmentListScreen> {
  final _posService = PosService();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _posService.getMasterServices(),
      _posService.getServiceCategories(),
    ]);
    setState(() {
      _services = results[0];
      _categories = results[1].where((c) => c['is_active']).toList();
      _isLoading = false;
    });
  }

  Future<void> _showServiceDialog({Map<String, dynamic>? service}) async {
    final nameController = TextEditingController(text: service?['name'] ?? '');
    final priceController = TextEditingController(text: service?['price']?.toString() ?? '');
    int? selectedCategoryId = service?['service_category_id'];
    bool isActive = service?['is_active'] ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(service == null ? 'Add Treatment' : 'Edit Treatment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Treatment Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (Rp)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  hint: const Text('Select Category'),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c['id'] as int,
                    child: Text(c['name']),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active Status'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || priceController.text.isEmpty || selectedCategoryId == null) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                   return;
                }
                final data = {
                  'name': nameController.text,
                  'price': double.parse(priceController.text),
                  'service_category_id': selectedCategoryId,
                  'is_active': isActive,
                };
                final result = await _posService.saveMasterService(data, id: service?['id']);
                if (result != null) {
                  _loadData();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Treatments')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text('No treatments found.'))
              : ListView.builder(
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final s = _services[index];
                    return ListTile(
                      title: Text(s['name']),
                      subtitle: Text('${s['service_category']?['name'] ?? 'N/A'} • ${s['is_active'] ? 'Active' : 'Inactive'}'),
                      trailing: Text(
                        _currencyFormat.format(double.parse(s['price'].toString())),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                      ),
                      onTap: () => _showServiceDialog(service: s),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
