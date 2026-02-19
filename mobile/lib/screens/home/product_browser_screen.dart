import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _productService.getProducts(),
      _productService.getCategories(),
    ]);
    setState(() {
      _products = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
      _isLoading = false;
    });
  }

  Future<void> _filterProducts() async {
    setState(() => _isLoading = true);
    final products = await _productService.getProducts(
      categoryId: _selectedCategoryId,
      search: _searchController.text,
    );
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
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
                          _filterProducts();
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
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: _products[index],
                            onTap: () {
                              // TODO: Show Product Details
                            },
                          );
                        },
                      ),
          ),
        ],
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
          setState(() => _selectedCategoryId = selected ? id : null);
          _filterProducts();
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
