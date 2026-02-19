import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_thumbnail.dart';

class StockMovementScreen extends StatefulWidget {
  const StockMovementScreen({super.key});

  @override
  State<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  final _inventoryService = InventoryService();
  final _productService = ProductService();
  final _qtyController = TextEditingController();

  List<Category> _locations = [];
  List<Product> _products = [];
  int? _fromLocationId;
  int? _toLocationId;
  Product? _selectedProduct;
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

  void _submit() async {
    if (_fromLocationId == null || _toLocationId == null || _selectedProduct == null || _qtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_fromLocationId == _toLocationId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and To locations must be different')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await _inventoryService.recordTransfer(
      _selectedProduct!.id,
      _fromLocationId!,
      _toLocationId!,
      double.parse(_qtyController.text),
    );
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock Transfer recorded successfully!')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record transfer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Move Stock', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'From Location'),
                    value: _fromLocationId,
                    items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                    onChanged: (id) => setState(() => _fromLocationId = id),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'To Location'),
                    value: _toLocationId,
                    items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                    onChanged: (id) => setState(() => _toLocationId = id),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<Product>(
                    decoration: const InputDecoration(labelText: 'Product'),
                    value: _selectedProduct,
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
                  const SizedBox(height: 24),
                  TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      suffixText: _selectedProduct?.unit ?? '',
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('CONFIRM TRANSFER'),
                  ),
                ],
              ),
            ),
    );
  }
}
