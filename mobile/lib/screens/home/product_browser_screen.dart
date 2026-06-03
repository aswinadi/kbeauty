import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/adaptive_split_layout.dart';
import 'product_detail_screen.dart';

class ProductBrowserScreen extends StatefulWidget {
  const ProductBrowserScreen({super.key});

  @override
  State<ProductBrowserScreen> createState() => _ProductBrowserScreenState();
}

class _ProductBrowserScreenState extends State<ProductBrowserScreen> {
  final _productService = ProductService();
  final _searchController = TextEditingController();
  
  List<Product> _products = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = true;

  Product? _selectedProduct;
  bool _isAddingProduct = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
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
          
          if (Responsive.isTablet(context) && _products.isNotEmpty) {
            if (!_isAddingProduct && _selectedProduct == null) {
              _selectedProduct = _products.first;
            } else if (_selectedProduct != null) {
              final index = _products.indexWhere((p) => p.id == _selectedProduct!.id);
              if (index != -1) {
                _selectedProduct = _products[index];
              } else {
                _selectedProduct = _products.first;
              }
            }
          }
        });
      }
    });
  }

  Future<void> _filterProducts() async {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
    });

    final products = await _productService.getProducts(
      categoryId: _selectedCategoryId,
      search: _searchController.text,
    );

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          
          if (Responsive.isTablet(context) && _products.isNotEmpty) {
            if (!_isAddingProduct) {
              if (_selectedProduct == null || !_products.any((p) => p.id == _selectedProduct!.id)) {
                _selectedProduct = _products.first;
              } else {
                final index = _products.indexWhere((p) => p.id == _selectedProduct!.id);
                if (index != -1) {
                  _selectedProduct = _products[index];
                }
              }
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final listWidget = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => _filterProducts(),
            decoration: InputDecoration(
              hintText: 'Search products or SKU...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _filterProducts();
                          }
                        });
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No products found', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _filterProducts,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isSelected = _selectedProduct != null && _selectedProduct!.id == product.id && !_isAddingProduct;
                          return Opacity(
                            opacity: product.isActive ? 1.0 : 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: (Responsive.isTablet(context) && isSelected) ? Colors.pink[50] : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: (Responsive.isTablet(context) && isSelected) ? Colors.pink[200]! : Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  if (Responsive.isTablet(context)) {
                                    setState(() {
                                      _selectedProduct = product;
                                      _isAddingProduct = false;
                                    });
                                  } else {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailScreen(product: product),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadInitialData();
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Thumbnail Image
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            product.imageUrl != null && product.imageUrl!.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      product.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                                    ),
                                                  )
                                                : Icon(Icons.image, color: Colors.grey[400]),
                                            if (!product.isActive)
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.block, color: Colors.white, size: 24),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Product Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.categoryName ?? 'Uncategorized',
                                              style: TextStyle(
                                                color: AppTheme.accentColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  product.sku,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      if (product.secondaryUnitName != null && product.secondaryUnitName != product.unit)
                                                        Container(
                                                          margin: const EdgeInsets.only(right: 4),
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[100],
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: Colors.grey[300]!),
                                                          ),
                                                          child: Text(
                                                            product.secondaryUnitName!,
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      Text(
                                                        product.unit,
                                                        style: TextStyle(
                                                          color: AppTheme.accentColor,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );

    Widget? detailWidget;
    if (_isAddingProduct) {
      detailWidget = KeyedSubtree(
        key: const ValueKey('add_product_form'),
        child: ProductDetailScreen(
          onSaved: () {
            setState(() {
              _isAddingProduct = false;
            });
            _loadInitialData();
          },
        ),
      );
    } else if (_selectedProduct != null) {
      detailWidget = KeyedSubtree(
        key: ValueKey('view_product_${_selectedProduct!.id}'),
        child: ProductDetailScreen(
          product: _selectedProduct,
          onSaved: () {
            _loadInitialData();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: AdaptiveSplitLayout(
        master: listWidget,
        detail: detailWidget,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (Responsive.isTablet(context)) {
            setState(() {
              _selectedProduct = null;
              _isAddingProduct = true;
            });
          } else {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
            );
            if (result == true) {
              _loadInitialData();
            }
          }
        },
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildCategoryChip(int? id, String label) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (mounted) {
            setState(() => _selectedCategoryId = selected ? id : null);
            _filterProducts();
          }
        },
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: AppTheme.accentColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.accentColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
