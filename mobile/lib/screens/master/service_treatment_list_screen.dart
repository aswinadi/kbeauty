import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import '../../theme/app_theme.dart';
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
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _posService.getMasterServices(),
      _posService.getServiceCategories(),
    ]);
    setState(() {
      _services = results[0];
      _categories = results[1].where((c) => c['is_active'] == 1 || c['is_active'] == true).toList();
      _isLoading = false;
    });
  }

  Future<void> _showServiceDialog({Map<String, dynamic>? service}) async {
    final nameController = TextEditingController(text: service?['name'] ?? '');
    final priceController = TextEditingController(text: service?['price']?.toString() ?? '');
    final commValueController = TextEditingController(text: service?['commission_value']?.toString() ?? '');
    
    int? selectedCategoryId = service?['service_category_id'] ?? _selectedCategoryId;
    String? commissionType = service?['commission_type'];
    bool isActive = service?['is_active'] == 1 || service?['is_active'] == true;
    bool deductStock = service?['deduct_stock'] == 1 || service?['deduct_stock'] == true;
    List<Map<String, dynamic>> variants = service?['variants'] != null 
        ? List<Map<String, dynamic>>.from(service!['variants'])
        : [];
    
    if (service == null) {
      isActive = true;
      deductStock = false;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service == null ? 'Add Treatment' : 'Edit Treatment', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile(
                          title: const Text('Active Status'),
                          value: isActive,
                          onChanged: (val) => setDialogState(() => isActive = val),
                          dense: true,
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
                          decoration: const InputDecoration(labelText: 'Service Category'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Name *'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Price (Rp) *'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text('Commission & Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: commissionType,
                          hint: const Text('Commission type'),
                          items: const [
                            DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                            DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                          ],
                          onChanged: (val) => setDialogState(() => commissionType = val),
                          decoration: const InputDecoration(labelText: 'Commission type'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: commValueController,
                          decoration: const InputDecoration(labelText: 'Commission (Rp/%)'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Deduct Stock from Inventory'),
                          value: deductStock,
                          onChanged: (val) => setDialogState(() => deductStock = val),
                          dense: true,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Variants', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            TextButton.icon(
                              onPressed: () => _showAddVariantDialog(setDialogState, variants),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Variant'),
                            ),
                          ],
                        ),
                        if (variants.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('No variants added.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        ...variants.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final v = entry.value;
                          return ListTile(
                            title: Text(v['name']),
                            subtitle: Text(_currencyFormat.format(double.parse(v['price'].toString()))),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => setDialogState(() => variants.removeAt(idx)),
                            ),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty || priceController.text.isEmpty || selectedCategoryId == null) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all mandatory fields (*)')));
                           return;
                        }
                        final data = {
                          'name': nameController.text,
                          'price': double.parse(priceController.text),
                          'service_category_id': selectedCategoryId,
                          'is_active': isActive,
                           if (commissionType != null) 'commission_type': commissionType,
                           if (commValueController.text.isNotEmpty) 'commission_value': double.parse(commValueController.text),
                          'deduct_stock': deductStock,
                          'variants': variants,
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
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Future<void> _showAddVariantDialog(StateSetter setDialogState, List<Map<String, dynamic>> variants) async {
    final vNameController = TextEditingController();
    final vPriceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Variant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: vNameController, decoration: const InputDecoration(labelText: 'Variant Name (e.g. 10 Fingers)')),
            const SizedBox(height: 16),
            TextField(controller: vPriceController, decoration: const InputDecoration(labelText: 'Price (Rp)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (vNameController.text.isNotEmpty && vPriceController.text.isNotEmpty) {
                setDialogState(() {
                  variants.add({
                    'name': vNameController.text,
                    'price': double.parse(vPriceController.text),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = _selectedCategoryId == null 
        ? _services 
        : _services.where((s) => s['service_category_id'] == _selectedCategoryId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Service Treatments'), elevation: 0),
      body: Column(
        children: [
          if (!_isLoading && _categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final category = isAll ? null : _categories[index - 1];
                  final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == category!['id'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(isAll ? 'All' : category!['name']),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedCategoryId = isAll ? null : category!['id'];
                        });
                      },
                      selectedColor: AppTheme.accentColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.accentColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredServices.isEmpty
                    ? const Center(child: Text('No treatments found.'))
                    : ListView.builder(
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final s = filteredServices[index];
                          final bool isActive = s['is_active'] == 1 || s['is_active'] == true;
                          return ListTile(
                            title: Text(s['name']),
                            subtitle: Text('${s['service_category']?['name'] ?? 'N/A'} • ${isActive ? 'Active' : 'Inactive'}'),
                            trailing: Text(
                              _currencyFormat.format(double.parse(s['price'].toString())),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                            ),
                            onTap: () => _showServiceDialog(service: s),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
