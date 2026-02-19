import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _searchController = TextEditingController();
  
  List<Category> _locations = [];
  List<Product> _allProducts = []; 
  List<Product> _filteredProducts = [];
  
  // State
  Map<int, double> _actualQuantities = {};
  Set<int> _checkedItems = {}; 
  
  int? _selectedLocationId;
  bool _isLoading = true;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _inventoryService.getLocations(),
        _inventoryService.getOpnameProducts(),
      ]);
      
      _locations = results[0] as List<Category>;
      _allProducts = results[1] as List<Product>;
      _filteredProducts = List.from(_allProducts);

      await _loadSavedState(); 
      
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading data: $e');
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(_allProducts);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredProducts = _allProducts.where((p) => 
          p.name.toLowerCase().contains(lowerQuery) || 
          p.sku.toLowerCase().contains(lowerQuery)
        ).toList();
      }
    });
  }

  // Debounced Save
  void _triggerSave() {
    if (_saveDebounce?.isActive ?? false) _saveDebounce!.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1000), _saveState);
  }

  Future<void> _saveState() async {
    if (_selectedLocationId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'opname_draft_$_selectedLocationId';
      
      final data = {
        'quantities': _actualQuantities.map((k, v) => MapEntry(k.toString(), v)),
        'checked': _checkedItems.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(key, jsonEncode(data));
      debugPrint('Draft saved locally.');
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  Future<void> _loadSavedState() async {
    if (_selectedLocationId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'opname_draft_$_selectedLocationId';
      final jsonStr = prefs.getString(key);

      if (jsonStr != null) {
        final data = jsonDecode(jsonStr);
        final quantities = (data['quantities'] as Map<String, dynamic>);
        final checked = (data['checked'] as List<dynamic>);

        setState(() {
          _actualQuantities = quantities.map((k, v) => MapEntry(int.parse(k), v.toDouble()));
          _checkedItems = checked.map((e) => e as int).toSet();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Draft restored from local storage'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error parsing saved state: $e');
    }
  }

  Future<void> _clearSavedState() async {
    if (_selectedLocationId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('opname_draft_$_selectedLocationId');
  }

  void _submitOpname() async {
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    // Submit all items
    final items = _allProducts.map((p) => StockOpnameItem(
      productId: p.id,
      productName: p.name,
      systemQty: 0, 
      actualQty: _actualQuantities[p.id] ?? 0,
    )).toList();

    setState(() => _isLoading = true);
    final success = await _inventoryService.submitStockOpname(_selectedLocationId!, items);
    setState(() => _isLoading = false);

    if (success) {
      await _clearSavedState();
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
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        initialValue: _selectedLocationId,
                        items: _locations.map((l) {
                          return DropdownMenuItem(value: l.id, child: Text(l.name));
                        }).toList(),
                        onChanged: (id) {
                          setState(() {
                            _selectedLocationId = id;
                            _actualQuantities.clear();
                            _checkedItems.clear();
                          });
                          _loadSavedState(); 
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: _filterProducts,
                        decoration: InputDecoration(
                          hintText: 'Search products by Name or SKU...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterProducts('');
                                },
                              )
                            : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final isChecked = _checkedItems.contains(product.id);
                      final qty = _actualQuantities[product.id];
                      
                      return StockOpnameTile(
                        key: ValueKey(product.id),
                        product: product,
                        isChecked: isChecked,
                        initialQty: qty,
                        onCheckChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _checkedItems.add(product.id);
                            } else {
                              _checkedItems.remove(product.id);
                            }
                          });
                          _triggerSave();
                        },
                        onQtyChanged: (val) {
                          setState(() {
                            if (val == null) {
                              _actualQuantities.remove(product.id);
                            } else {
                              _actualQuantities[product.id] = val;
                              if (val > 0) {
                                _checkedItems.add(product.id);
                              }
                            }
                          });
                          _triggerSave();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class StockOpnameTile extends StatefulWidget {
  final Product product;
  final bool isChecked;
  final double? initialQty;
  final ValueChanged<bool?> onCheckChanged;
  final ValueChanged<double?> onQtyChanged;

  const StockOpnameTile({
    super.key,
    required this.product,
    required this.isChecked,
    this.initialQty,
    required this.onCheckChanged,
    required this.onQtyChanged,
  });

  @override
  State<StockOpnameTile> createState() => _StockOpnameTileState();
}

class _StockOpnameTileState extends State<StockOpnameTile> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.initialQty != null && widget.initialQty! > 0 
          ? (widget.initialQty! % 1 == 0 ? widget.initialQty!.toInt().toString() : widget.initialQty.toString())
          : ''
    );
  }

  @override
  void didUpdateWidget(StockOpnameTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update text if the value actually changed from outside (e.g. search filter reset or data reload)
    // and DOES NOT match current text (to avoid cursor jump on loopback)
    if (widget.initialQty != oldWidget.initialQty) {
       final newText = widget.initialQty != null && widget.initialQty! > 0 
          ? (widget.initialQty! % 1 == 0 ? widget.initialQty!.toInt().toString() : widget.initialQty.toString())
          : '';
       
       if (_qtyController.text != newText) {
          // Check if difference is just parsing (e.g. 1.0 vs 1)
          double? currentVal = double.tryParse(_qtyController.text);
          if (currentVal != widget.initialQty) {
             _qtyController.text = newText;
             _qtyController.selection = TextSelection.collapsed(offset: _qtyController.text.length);
          }
       }
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isChecked ? Colors.green.withOpacity(0.05) : Colors.white,
      child: ListTile(
        leading: Checkbox(
          value: widget.isChecked,
          activeColor: AppTheme.primaryColor,
          onChanged: widget.onCheckChanged,
        ),
        title: Text(
          widget.product.name, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: widget.isChecked ? Colors.black : Colors.black87,
          )
        ),
        subtitle: Text(
          'SKU: ${widget.product.sku} • Unit: ${widget.product.unit}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: SizedBox(
          width: 70,
          child: TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) {
              if (val.isEmpty) {
                widget.onQtyChanged(null);
              } else {
                widget.onQtyChanged(double.tryParse(val));
              }
            },
          ),
        ),
        onTap: () => widget.onCheckChanged(!widget.isChecked),
      ),
    );
  }
}

