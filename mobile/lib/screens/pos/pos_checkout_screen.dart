import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/receipt_helper.dart';
import '../crm/add_customer_portfolio_screen.dart';
import 'package:intl/intl.dart';

class PosCheckoutScreen extends StatefulWidget {
  const PosCheckoutScreen({super.key});

  @override
  State<PosCheckoutScreen> createState() => _PosCheckoutScreenState();
}

class _PosCheckoutScreenState extends State<PosCheckoutScreen> {
  final _posService = PosService();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _cart = [];
  Map<String, dynamic>? _selectedCustomer;
  final _searchController = TextEditingController();

  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String _searchQuery = '';
  double _discountAmount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _posService.getItems(),
      _posService.getEmployees(),
    ]);
    setState(() {
      _allItems = results[0];
      _employees = results[1];
      _filteredItems = _allItems;
      
      final cats = _allItems.map((e) => (e['category'] ?? 'Uncategorized').toString()).toSet().toList();
      cats.sort();
      _categories = ['All', ...cats];
      
      _isLoading = false;
    });
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      _filteredItems = _allItems.where((item) {
        final name = item['name'].toString().toLowerCase();
        final nameMatches = name.contains(query.toLowerCase());
        final categoryMatches = _selectedCategory == 'All' || item['category'] == _selectedCategory;
        return nameMatches && categoryMatches;
      }).toList();
    });
  }

  void _addToCart(Map<String, dynamic> item, {Map<String, dynamic>? variant}) {
    // If item is a service and has variants, and no variant is selected yet, show picker
    if (item['type'] == 'service' && item['variants'] != null && (item['variants'] as List).isNotEmpty && variant == null) {
      FocusScope.of(context).unfocus();
      _showVariantPicker(item);
      return;
    }

    setState(() {
      final itemId = item['id'];
      final itemType = item['type'];
      final variantId = variant?['id'];
      
      final existingIndex = _cart.indexWhere((cartItem) => 
        cartItem['id'] == itemId && 
        cartItem['type'] == itemType && 
        cartItem['service_variant_id'] == variantId
      );

      if (existingIndex >= 0) {
        _cart[existingIndex]['quantity']++;
      } else {
        _cart.add({
          ...item,
          'price': variant != null ? variant['price'] : item['price'],
          'name': variant != null ? "${item['name']} - ${variant['name']}" : item['name'],
          'service_variant_id': variantId,
          'quantity': 1,
          'employee_id': _employees.isNotEmpty ? _employees[0]['id'] : null,
        });
      }
    });
  }

  void _showVariantPicker(Map<String, dynamic> item) {
    final List variants = item['variants'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Variant for ${item['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: variants.length,
                itemBuilder: (context, index) {
                  final v = variants[index];
                  return ListTile(
                    title: Text(v['name']),
                    trailing: Text(_currencyFormat.format(double.parse(v['price'].toString())), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                    onTap: () {
                      Navigator.pop(context);
                      _addToCart(item, variant: v);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index]['quantity'] > 1) {
        _cart[index]['quantity']--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  double get _totalBeforeDiscount {
    return _cart.fold(0, (sum, item) => sum + (double.parse(item['price'].toString()) * item['quantity']));
  }

  double get _totalAfterDiscount {
    return _totalBeforeDiscount - _discountAmount;
  }

  Future<void> _processCheckout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    // Show payment method dialog
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Payment Method'),
        children: ['Cash', 'Debit', 'QRIS', 'Transfer'].map((method) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, method.toLowerCase()),
          child: Text(method),
        )).toList(),
      ),
    );

    if (paymentMethod == null) return;

    try {
      final transactionData = {
        'customer_id': _selectedCustomer?['id'],
        'items': _cart.map((item) => {
          'item_id': item['id'],
          'item_type': item['type'],
          'service_variant_id': item['service_variant_id'],
          'employee_id': item['employee_id'],
          'quantity': item['quantity'],
        }).toList(),
        'discount_amount': _discountAmount,
        'payments': [
          {
            'payment_method': paymentMethod,
            'amount': _totalAfterDiscount,
          }
        ],
      };

      final response = await _posService.submitTransaction(transactionData);
      
      if (!mounted) return;
      if (response != null) {
        setState(() {
          _cart.clear();
          _selectedCustomer = null;
          _discountAmount = 0;
        });
        _showSuccessDialog(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 60)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Transaction Successful!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Number: ${transaction['transaction_number']}'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.print,
                  label: 'Print',
                  onTap: () => ReceiptHelper().printReceipt(transaction),
                ),
                _buildActionButton(
                    icon: Icons.share,
                    label: 'WhatsApp',
                    onTap: () => ReceiptHelper().shareViaWhatsApp(transaction),
                  ),
                  _buildActionButton(
                    icon: Icons.add_a_photo,
                    label: 'Photo',
                    color: Colors.pink,
                    onTap: () {
                      if (transaction['customer_id'] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guest checkout. No photo linkable.')));
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddCustomerPortfolioScreen(
                            customerId: transaction['customer_id'],
                            posTransactionId: transaction['id'],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  void _printDraftBill() {
    final draftData = {
      'customer': _selectedCustomer,
      'items': _cart,
      'total_amount': _totalBeforeDiscount,
      'discount_amount': _discountAmount,
      'final_amount': _totalAfterDiscount,
    };
    ReceiptHelper().printReceipt(draftData, isDraft: true);
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (color ?? AppTheme.accentColor).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color ?? AppTheme.accentColor),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Checkout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: () => _selectCustomer(),
          ),
          if (_selectedCustomer != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  _selectedCustomer!['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FocusScope(
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildCategoryTabs(),
                  Expanded(
                    child: Row(
                      children: [
                        _buildItemGrid(),
                        _buildCartView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      key: const ValueKey('pos_search_bar_container'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        key: const ValueKey('pos_search_field'),
        controller: _searchController,
        onChanged: _filterItems,
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      key: const ValueKey('pos_category_tabs_container'),
      height: 50,
      child: ListView.builder(
        key: const ValueKey('pos_category_tabs_list'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat;
                    _filterItems(_searchQuery);
                  });
                }
              },
              selectedColor: AppTheme.accentColor.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.accentColor : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemGrid() {
    return Expanded(
      flex: 3,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return InkWell(
            onTap: () => _addToCart(item),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Icon(
                          item['type'] == 'service' ? Icons.spa : (item['type'] == 'bundle' ? Icons.auto_awesome : Icons.shopping_bag),
                          size: 40,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                        Text(_currencyFormat.format(double.parse(item['price'].toString())), style: const TextStyle(color: AppTheme.accentColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartView() {
    return Expanded(
      flex: 2,
      child: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.print, color: AppTheme.accentColor),
                    tooltip: 'Print Draft Bill',
                    onPressed: _cart.isEmpty ? null : () => _printDraftBill(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  return ListTile(
                    title: Text(item['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_currencyFormat.format(double.parse(item['price'].toString()))} x ${item['quantity']}'),
                        PopupMenuButton<int>(
                          initialValue: item['employee_id'],
                          itemBuilder: (context) => _employees.map((e) => PopupMenuItem(
                            value: e['id'] as int,
                            child: Text(e['name']),
                          )).toList(),
                          onSelected: (val) => setState(() => _cart[index]['employee_id'] = val),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _employees.firstWhere((e) => e['id'] == item['employee_id'], orElse: () => {'name': 'Assign'})['name'],
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _removeFromCart(index)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addToCart(item)),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildSummarySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total'),
              Text(_currencyFormat.format(_totalBeforeDiscount)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount'),
              SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() => _discountAmount = double.tryParse(val) ?? 0),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(hintText: '0', isDense: true),
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_currencyFormat.format(_totalAfterDiscount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CHECKOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectCustomer() async {
    final customer = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CustomerSelectionDialog(),
    );
    if (customer != null) {
      setState(() => _selectedCustomer = customer);
    }
  }
}

class CustomerSelectionDialog extends StatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  State<CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  final _posService = PosService();
  String _query = '';
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = false;

  void _search(String q) async {
    setState(() {
      _query = q;
      _isLoading = true;
    });
    final results = await _posService.getCustomers(search: q);
    setState(() {
      _customers = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Customer'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            TextField(
              onChanged: _search,
              decoration: const InputDecoration(hintText: 'Search by name or phone...', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _customers.length,
                      itemBuilder: (context, index) {
                        final c = _customers[index];
                        return ListTile(
                          title: Text(c['name']),
                          subtitle: Text(c['phone'] ?? ''),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
            ElevatedButton(
              onPressed: () => _addNewCustomer(),
              child: const Text('Add New Customer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewCustomer() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final newCustomer = await _posService.registerCustomer({
        'name': nameController.text,
        'phone': phoneController.text,
      });
      if (newCustomer != null && mounted) {
        Navigator.pop(context, newCustomer);
      }
    }
  }
}
