import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';
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

    final qty = double.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) return;

    setState(() {
      // Check if product already in list
      final existingIndex = _transactionItems.indexWhere((item) => item['product_id'] == _selectedProduct!.id);
      if (existingIndex >= 0) {
        _transactionItems[existingIndex]['qty'] += qty;
      } else {
        _transactionItems.add({
          'product_id': _selectedProduct!.id,
          'product_name': _selectedProduct!.name,
          'qty': qty,
          'unit': _selectedProduct!.unit,
        });
      }
      _qtyController.clear();
      _selectedProduct = null;
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
        'qty': item['qty'],
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
                          disabledHint: Text(_locations.firstWhere((l) => l.id == _selectedLocationId).name),
                        ),
                        if (_transactionItems.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Location locked after adding items', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        const SizedBox(height: 32),
                        const Text('Add Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Product>(
                          decoration: const InputDecoration(labelText: 'Product'),
                          initialValue: _selectedProduct,
                          items: _products.map((p) => DropdownMenuItem(
                            value: p, 
                            child: Row(
                              children: [
                                ProductThumbnail(imageUrl: p.imageUrl, size: 30),
                                const SizedBox(width: 12),
                                Text('${p.name} (${p.sku})'),
                              ],
                            )
                          )).toList(),
                          onChanged: (p) => setState(() => _selectedProduct = p),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Quantity',
                                  suffixText: _selectedProduct?.unit ?? '',
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
                                subtitle: Text('${item['qty']} ${item['unit']}'),
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
