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
  String? _errorMessage;
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
      _balanceData = null;
      _errorMessage = null;
    });

    try {
      final data = await _inventoryService.getStockBalance(product.id);
      
      setState(() {
        if (data == null) {
          _errorMessage = 'Failed to fetch stock data. Please ensure backend is updated.';
        } else {
          _balanceData = data;
        }
        _isFetchingBalance = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isFetchingBalance = false;
      });
    }
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
                      setState(() {
                        _selectedProduct = p;
                        _balanceData = null;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedProduct == null || _isFetchingBalance) 
                          ? null 
                          : () => _fetchBalance(_selectedProduct!),
                      icon: _isFetchingBalance 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search),
                      label: const Text('CHECK STOCK'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null)
                    _buildStatusView(
                      icon: Icons.error_outline,
                      color: Colors.red,
                      message: _errorMessage!,
                      subMessage: 'Try pulling the latest code on the server.',
                    )
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
                  ] else if (_selectedProduct != null && !_isFetchingBalance)
                    _buildStatusView(
                      icon: Icons.info_outline,
                      color: Colors.blue,
                      message: 'Tap "Check Stock" to view data',
                    )
                  else if (_selectedProduct == null)
                    _buildStatusView(
                      icon: Icons.inventory_2_outlined,
                      color: Colors.grey,
                      message: 'Please select a product first',
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusView({required IconData icon, required Color color, required String message, String? subMessage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.w500),
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
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
