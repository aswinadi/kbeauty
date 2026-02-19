import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';
import '../../widgets/product_selector.dart';
import '../../theme/app_theme.dart';

class StockBalanceScreen extends StatefulWidget {
  const StockBalanceScreen({super.key});

  @override
  State<StockBalanceScreen> createState() => _StockBalanceScreenState();
}

class _StockBalanceScreenState extends State<StockBalanceScreen> {
  final _inventoryService = InventoryService();
  final _productService = ProductService();

  List<Product> _products = [];
  Product? _selectedProduct;
  Map<String, dynamic>? _balanceData;
  bool _isLoading = true;
  bool _isFetchingBalance = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productService.getProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _fetchBalance(Product product) async {
    setState(() {
      _selectedProduct = product;
      _isFetchingBalance = true;
    });

    final data = await _inventoryService.getStockBalance(product.id);
    
    setState(() {
      _balanceData = data;
      _isFetchingBalance = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Balance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ProductSelector(
                    products: _products,
                    selectedProduct: _selectedProduct,
                    onChanged: (p) {
                      if (p != null) _fetchBalance(p);
                    },
                  ),
                  const SizedBox(height: 32),
                  if (_isFetchingBalance)
                    const Center(child: CircularProgressIndicator())
                  else if (_balanceData != null) ...[
                    Text(
                      'Stock per Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_balanceData!['product_name']} (${_balanceData!['sku']})',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildBalanceList(),
                    ),
                  ] else if (_selectedProduct == null)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Select a product to see availability',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceList() {
    final balances = _balanceData!['balances'] as List;
    
    if (balances.isEmpty) {
      return const Center(
        child: Text('No stock found in any location'),
      );
    }

    return ListView.separated(
      itemCount: balances.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = balances[index];
        final balance = item['balance'] ?? 0;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item['location_name'],
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: balance > 0 
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$balance ${_selectedProduct?.unit ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance > 0 ? AppTheme.accentColor : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
