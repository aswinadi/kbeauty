import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_selector.dart';
import '../../widgets/product_thumbnail.dart';

class InventoryTransactionScreen extends StatefulWidget {
  final String type; // 'in' or 'out'
  const InventoryTransactionScreen({super.key, required this.type});

  @override
  State<InventoryTransactionScreen> createState() => _InventoryTransactionScreenState();
}

class _InventoryTransactionScreenState extends State<InventoryTransactionScreen> {
  final _inventoryService = InventoryService();
  final _productService = ProductService();
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();

  List<Category> _locations = [];
  List<Product> _products = [];
  int? _selectedLocationId;
  Product? _selectedProduct;
  bool _useSecondaryUnit = false;
  
  // List to hold pending items
  final List<Map<String, dynamic>> _transactionItems = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _inventoryService.getLocations(),
      _productService.getProducts(),
    ]);
    setState(() {
      _locations = results[0] as List<Category>;
      _products = results[1] as List<Product>;
      _isLoading = false;
    });
  }

  void _addItem() {
    if (_selectedProduct == null || _qtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product and enter quantity')),
      );
      return;
    }

    final inputQty = double.tryParse(_qtyController.text) ?? 0;
    if (inputQty <= 0) return;

    // Convert to base quantity if secondary unit is used
    double qty = inputQty;
    String unitName = _selectedProduct!.unit;
    
    if (_useSecondaryUnit && _selectedProduct!.secondaryUnitName != null) {
      final ratio = _selectedProduct!.conversionRatio ?? 1.0;
      qty = inputQty * ratio;
      unitName = _selectedProduct!.secondaryUnitName!;
    }

    setState(() {
      // Check if product already in list (with same unit to be safe, or just merge)
      // For simplicity, we merge into base quantity
      final existingIndex = _transactionItems.indexWhere((item) => item['product_id'] == _selectedProduct!.id);
      if (existingIndex >= 0) {
        _transactionItems[existingIndex]['qty'] += qty;
      } else {
        _transactionItems.add({
          'product_id': _selectedProduct!.id,
          'product_name': _selectedProduct!.name,
          'qty': qty,
          'display_qty': inputQty,
          'unit': unitName,
          'base_unit': _selectedProduct!.unit,
        });
      }
      _qtyController.clear();
      _selectedProduct = null;
      _useSecondaryUnit = false;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _transactionItems.removeAt(index);
    });
  }

  void _submit() async {
    if (_selectedLocationId == null || _transactionItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select location and add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await _inventoryService.recordBulkTransaction(
      type: widget.type,
      locationId: _selectedLocationId!,
      items: _transactionItems.map((item) => {
        'product_id': item['product_id'],
        'qty': item['qty'], // Always send base quantity
      }).toList(),
      notes: _notesController.text,
    );
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bulk ${widget.type.toUpperCase()} recorded successfully!')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record transaction')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock ${widget.type == 'in' ? 'In' : 'Out'}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Store / Location'),
                          initialValue: _selectedLocationId,
                          items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                          onChanged: _transactionItems.isEmpty ? (id) => setState(() => _selectedLocationId = id) : null,
                          hint: const Text('Select Location'),
                          disabledHint: _selectedLocationId != null 
                              ? Text(_locations.firstWhere(
                                  (l) => l.id == _selectedLocationId, 
                                  orElse: () => _locations.isNotEmpty ? _locations.first : Category(id: 0, name: 'Unknown')
                                ).name)
                              : null,
                        ),
                        if (_transactionItems.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Location locked after adding items', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        const SizedBox(height: 32),
                        const Text('Add Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ProductSelector(
                          products: _products,
                          selectedProduct: _selectedProduct,
                          onChanged: (p) => setState(() {
                            _selectedProduct = p;
                            _useSecondaryUnit = false;
                          }),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedProduct != null && _selectedProduct!.secondaryUnitName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                const Text('Unit: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text(_selectedProduct!.unit),
                                  selected: !_useSecondaryUnit,
                                  onSelected: (val) => setState(() => _useSecondaryUnit = !val),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text(_selectedProduct!.secondaryUnitName!),
                                  selected: _useSecondaryUnit,
                                  onSelected: (val) => setState(() => _useSecondaryUnit = val),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _qtyController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Quantity',
                                  suffixText: _selectedProduct != null 
                                    ? (_useSecondaryUnit ? _selectedProduct!.secondaryUnitName : _selectedProduct!.unit)
                                    : '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _addItem,
                                style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                                child: const Text('ADD'),
                              ),
                            ),
                          ],
                        ),
                        if (_useSecondaryUnit && _selectedProduct != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Converts to: ${(double.tryParse(_qtyController.text) ?? 0) * (_selectedProduct!.conversionRatio ?? 1.0)} ${_selectedProduct!.unit}',
                              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(height: 32),
                        if (_transactionItems.isNotEmpty) ...[
                          const Text('Items List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactionItems.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = _transactionItems[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item['product_name']),
                                subtitle: Text('${item['qty']} ${item['base_unit']}'), // Show total base quantity
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeItem(index),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 32),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            hintText: 'e.g. Bulk restock from supplier X',
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _transactionItems.isEmpty ? null : _submit,
                      child: Text('SUBMIT STOCK ${widget.type.toUpperCase()} (${_transactionItems.length} ITEMS)'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
