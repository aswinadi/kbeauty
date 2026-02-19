import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'product_thumbnail.dart';

class ProductSelector extends StatelessWidget {
  final List<Product> products;
  final Product? selectedProduct;
  final ValueChanged<Product> onChanged;
  final String label;

  const ProductSelector({
    super.key,
    required this.products,
    required this.selectedProduct,
    required this.onChanged,
    this.label = 'Product',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSelectionSheet(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: selectedProduct != null
            ? Row(
                children: [
                  ProductThumbnail(imageUrl: selectedProduct!.imageUrl, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${selectedProduct!.name} (${selectedProduct!.sku}) • ${selectedProduct!.unit}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              )
            : const Text(
                'Select Product',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
      ),
    );
  }

  void _showSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ProductSelectionSheet(
        products: products,
        onSelect: (product) {
          onChanged(product);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ProductSelectionSheet extends StatefulWidget {
  final List<Product> products;
  final ValueChanged<Product> onSelect;

  const _ProductSelectionSheet({
    required this.products,
    required this.onSelect,
  });

  @override
  State<_ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<_ProductSelectionSheet> {
  final _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        final lower = query.toLowerCase();
        _filteredProducts = widget.products.where((p) {
          return p.name.toLowerCase().contains(lower) ||
              p.sku.toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: _filter,
                  decoration: InputDecoration(
                    hintText: 'Search Product or SKU...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredProducts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ListTile(
                  leading: ProductThumbnail(imageUrl: product.imageUrl, size: 40),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(product.sku),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.unit,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  onTap: () => widget.onSelect(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
