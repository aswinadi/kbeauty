import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';
import '../../widgets/product_selector.dart';
import '../../utils/responsive.dart';
import '../../widgets/adaptive_split_layout.dart';

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

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.pink[700], size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    final formWidget = SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'From Location'),
            initialValue: _fromLocationId,
            items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
            onChanged: (id) => setState(() => _fromLocationId = id),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'To Location'),
            initialValue: _toLocationId,
            items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
            onChanged: (id) => setState(() => _toLocationId = id),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ProductSelector(
            products: _products,
            selectedProduct: _selectedProduct,
            onChanged: (p) => setState(() => _selectedProduct = p),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter quantity',
              labelText: 'Quantity',
              suffixText: _selectedProduct?.unit ?? '',
            ),
          ),
          const SizedBox(height: 48),
          if (!isTablet)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('CONFIRM TRANSFER'),
              ),
            ),
        ],
      ),
    );

    final summaryWidget = Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.swap_horiz, color: Colors.pink[700], size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Transfer Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D0026)),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  'From Location',
                  _fromLocationId != null
                      ? _locations.firstWhere((l) => l.id == _fromLocationId).name
                      : 'Not Selected',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Icon(Icons.arrow_downward, color: Colors.grey, size: 20),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  'To Location',
                  _toLocationId != null
                      ? _locations.firstWhere((l) => l.id == _toLocationId).name
                      : 'Not Selected',
                  Icons.location_on,
                ),
                const Divider(height: 32),
                _buildSummaryRow(
                  'Product',
                  _selectedProduct != null ? _selectedProduct!.name : 'Not Selected',
                  Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  'Quantity',
                  _qtyController.text.isNotEmpty
                      ? '${_qtyController.text} ${_selectedProduct?.unit ?? ""}'
                      : '0',
                  Icons.tag,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('CONFIRM TRANSFER'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Move Stock', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: AdaptiveSplitLayout(
                master: formWidget,
                detail: summaryWidget,
                masterFlex: 5.0,
                detailFlex: 5.0,
              ),
            ),
    );
  }
}
