import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';
import '../../widgets/product_selector.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/adaptive_split_layout.dart';

class StockBalanceScreen extends StatefulWidget {
  const StockBalanceScreen({super.key});

  @override
  State<StockBalanceScreen> createState() => _StockBalanceScreenState();
}

class _StockBalanceScreenState extends State<StockBalanceScreen> {
  final _inventoryService = InventoryService();
  final _productService = ProductService();

  List<Product> _products = [];
  List<Category> _categories = [];
  Product? _selectedProduct;
  Map<String, dynamic>? _balanceData;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isFetchingBalance = false;

  final _searchController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
    });

    final results = await Future.wait([
      _productService.getProducts(),
      _productService.getCategories(),
    ]);

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _products = results[0] as List<Product>;
          _categories = results[1] as List<Category>;
          _isLoading = false;
          
          if (Responsive.isTablet(context) && _products.isNotEmpty && _selectedProduct == null) {
            _selectedProduct = _products.first;
            _fetchBalance(_selectedProduct!);
          }
        });
      }
    });
  }

  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchesCategory = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      final matchesSearch = _searchController.text.isEmpty ||
          p.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      final filtered = _filteredProducts;
      if (Responsive.isTablet(context) && filtered.isNotEmpty) {
        if (_selectedProduct == null || !filtered.any((p) => p.id == _selectedProduct!.id)) {
          _selectedProduct = filtered.first;
          _fetchBalance(_selectedProduct!);
        }
      }
    });
  }

  Future<void> _fetchBalance(Product product) async {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedProduct = product;
          _isFetchingBalance = true;
          _balanceData = null;
          _errorMessage = null;
        });
      }
    });

    try {
      final data = await _inventoryService.getStockBalance(product.id);
      
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            if (data == null) {
              _errorMessage = 'Failed to fetch stock data. Please ensure backend is updated.';
            } else {
              _balanceData = data;
            }
            _isFetchingBalance = false;
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorMessage = 'An error occurred: $e';
            _isFetchingBalance = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    final masterWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Search products or SKU...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        if (mounted) {
                          _applyFilters();
                        }
                      },
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip(null, 'All');
              }
              final category = _categories[index - 1];
              return _buildCategoryChip(category.id, category.name);
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              final isSelected = _selectedProduct?.id == product.id;
              
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.pink[50] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.pink[200]! : Colors.grey[200]!),
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        _selectedProduct = product;
                      });
                      _fetchBalance(product);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${product.sku} • ${product.categoryName ?? 'Uncategorized'}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );

    final detailWidget = Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: _isFetchingBalance
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildStatusView(
                  icon: Icons.error_outline,
                  color: Colors.red,
                  message: _errorMessage!,
                  subMessage: 'Try pulling the latest code on the server.',
                )
              : _balanceData != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock per Location',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_balanceData!['product_name']} (${_balanceData!['sku']})',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildBalanceList(),
                        ),
                      ],
                    )
                  : _buildStatusView(
                      icon: Icons.inventory_2_outlined,
                      color: Colors.grey,
                      message: 'Please select a product first',
                    ),
    );

    final mobileWidget = SafeArea(
      child: Padding(
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
                    : () {
                        if (mounted) {
                          _fetchBalance(_selectedProduct!);
                        }
                      },
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Balance', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AdaptiveSplitLayout(
              master: isTablet ? masterWidget : mobileWidget,
              detail: isTablet ? detailWidget : null,
            ),
    );
  }

  Widget _buildCategoryChip(int? id, String label) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedCategoryId = selected ? id : null);
              _applyFilters();
            }
          });
        },
        selectedColor: AppTheme.accentColor.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.accentColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            Icon(icon, size: 64, color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: balance > 0 
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$balance ${_selectedProduct?.unit ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: balance > 0 ? AppTheme.accentColor : Colors.red,
                      ),
                    ),
                    if (_selectedProduct?.secondaryUnitName != null && (_selectedProduct?.conversionRatio ?? 0) > 0 && balance > 0)
                      Builder(
                        builder: (context) {
                          final double ratio = _selectedProduct!.conversionRatio!;
                          final int secondaryPart = (balance / ratio).floor();
                          final int primaryPart = (balance % ratio).toInt();
                          
                          if (secondaryPart == 0 && primaryPart == 0) return const SizedBox.shrink();
                          
                          return Text(
                            '(${secondaryPart > 0 ? '$secondaryPart ${_selectedProduct?.secondaryUnitName} ' : ''}$primaryPart ${_selectedProduct?.unit})',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
