import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/stock_opname.dart';
import '../../services/inventory_service.dart';
import '../../theme/app_theme.dart';

class StockOpnameScreen extends StatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  State<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends State<StockOpnameScreen> {
  final _inventoryService = InventoryService();
  List<Category> _locations = [];
  List<Product> _products = [];
  Map<int, double> _actualQuantities = {};
  int? _selectedLocationId;
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
      _inventoryService.getOpnameProducts(),
    ]);
    setState(() {
      _locations = results[0] as List<Category>;
      _products = results[1] as List<Product>;
      _isLoading = false;
    });
  }

  void _submitOpname() async {
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    final items = _products.map((p) => StockOpnameItem(
      productId: p.id,
      productName: p.name,
      systemQty: 0, // In this demo, system qty is 0, we track actuals
      actualQty: _actualQuantities[p.id] ?? 0,
    )).toList();

    setState(() => _isLoading = true);
    final success = await _inventoryService.submitStockOpname(_selectedLocationId!, items);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock Opname submitted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit Stock Opname.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Opname', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.accentColor),
            onPressed: _submitOpname,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Location'),
                    initialValue: _selectedLocationId,
                    items: _locations.map((l) {
                      return DropdownMenuItem(value: l.id, child: Text(l.name));
                    }).toList(),
                    onChanged: (id) => setState(() => _selectedLocationId = id),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return ListTile(
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('SKU: ${product.sku}'),
                        trailing: SizedBox(
                          width: 80,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '0',
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) {
                              _actualQuantities[product.id] = double.tryParse(val) ?? 0.0;
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
