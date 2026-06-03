import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../utils/receipt_helper.dart';
import '../crm/add_customer_portfolio_screen.dart';
import '../../widgets/customer_selection_dialog.dart';
import '../../utils/date_helper.dart';
import '../../utils/responsive.dart';
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
  Map<String, dynamic>? _selectedEmployee;
  final _searchController = TextEditingController();
  Map<String, dynamic>? _settings;

  List<Map<String, dynamic>> _discounts = [];
  Map<String, dynamic>? _selectedDiscount;
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String _searchQuery = '';
  // double _discountAmount = 0; // Removed in favor of computed logic
  String _posItemLayout = 'grid';

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
      _posService.getSettings(),
      _posService.getDiscounts(),
      AuthService().getUser(),
    ]);
    setState(() {
      _allItems = (results[0] as List).map((e) => e as Map<String, dynamic>).where((item) => item['type'] == 'service').toList();
      _employees = (results[1] as List).map((e) => e as Map<String, dynamic>).toList();
      _discounts = (results[3] as List).map((e) => e as Map<String, dynamic>).toList();
      _filteredItems = _allItems;
      
      _settings = results[2] as Map<String, dynamic>?;
      if (_settings != null) {
        _posItemLayout = _settings!['pos_item_layout'] ?? 'grid';
      }

      final cats = _allItems.map((e) => (e['category'] ?? 'Uncategorized').toString()).toSet().toList();
      cats.sort();
      _categories = ['All', ...cats];

      final user = results[4] as User?;
      if (user != null && user.employee != null) {
        // Find matching employee in _employees list to ensure correct format
        final loggedInEmp = _employees.firstWhere(
          (e) => e['id'] == user.employee!.id,
          orElse: () => {
            'id': user.employee!.id,
            'name': user.employee!.fullName ?? user.name,
          },
        );
        _selectedEmployee = loggedInEmp;
      }
      
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

  Future<void> _addToCart(Map<String, dynamic> item, {Map<String, dynamic>? variant}) async {
    // If item is a service with variable price, and we haven't prompted yet
    if (item['type'] == 'service' && 
        item['is_variable_price'] == true && 
        item['price_manually_set'] != true) {
      
      final double? manualPrice = await _showPriceInputDialog(item['name']);
      if (manualPrice == null) return; // User cancelled
      
      return _addToCart({
        ...item, 
        'price': manualPrice, 
        'price_manually_set': true
      }, variant: variant);
    }

    // If item is a service and has variants, and no variant is selected yet, show picker
    if (item['type'] == 'service' && item['variants'] != null && (item['variants'] as List).isNotEmpty && variant == null) {
      FocusScope.of(context).unfocus();
      _showVariantPicker(item);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          final itemId = item['id'];
          final itemType = item['type'];
          final variantId = variant?['id'];
          
          final existingIndex = _cart.indexWhere((cartItem) => 
            cartItem['id'] == itemId && 
            cartItem['type'] == itemType && 
            cartItem['service_variant_id'] == variantId &&
            cartItem['price'] == (variant != null ? variant['price'] : item['price'])
          );

          if (existingIndex >= 0 && item['is_variable_price'] != true) {
            _cart[existingIndex]['quantity']++;
          } else {
            _cart.add({
              ...item,
              'price': variant != null ? variant['price'] : item['price'],
              'name': variant != null ? "${item['name']} - ${variant['name']}" : item['name'],
              'service_variant_id': variantId,
              'quantity': 1,
              'employee_ids': _selectedEmployee != null ? [_selectedEmployee!['id']] : [],
              'employees': _selectedEmployee != null ? [_selectedEmployee!] : [],
            });
          }
        });
      }
    });
  }

  Future<double?> _showPriceInputDialog(String itemName) async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Price for $itemName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Price (Rp)', hintText: '0'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(controller.text) ?? 0;
              Navigator.pop(context, price);
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: variants.length,
              itemBuilder: (context, index) {
                final v = variants[index];
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _addToCart(item, variant: v);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(_currencyFormat.format(double.parse(v['price'].toString())), style: const TextStyle(fontSize: 11, color: AppTheme.accentColor)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeFromCart(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (_cart[index]['quantity'] > 1) {
            _cart[index]['quantity']--;
          } else {
            _cart.removeAt(index);
          }
        });
      }
    });
  }

  double get _totalBeforeDiscount {
    return _cart.fold(0, (sum, item) => sum + (double.parse(item['price'].toString()) * item['quantity']));
  }

  double get _discountAmount {
    if (_selectedDiscount == null) return 0;
    if (_selectedDiscount!['type'] == 'percentage') {
      return (_totalBeforeDiscount * (double.parse(_selectedDiscount!['value'].toString()) / 100));
    }
    return double.parse(_selectedDiscount!['value'].toString());
  }

  double get _totalAfterDiscount {
    final total = _totalBeforeDiscount - _discountAmount;
    return total < 0 ? 0 : total;
  }

  Future<void> _syncEmployees() async {
    final employees = await _posService.getEmployees();
    if (mounted) {
      setState(() {
        _employees = employees;
      });
    }
  }

  Future<void> _selectEmployee() async {
    await _syncEmployees();
    if (!mounted) return;
    final employee = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Designated Employee'),
        content: SizedBox(
          width: double.maxFinite,
          child: _employees.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No active employees found', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _loadData();
                        _selectEmployee();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh List'),
                    ),
                  ],
                )
              : GridView.builder(
// ... rest same
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _employees.length,
            itemBuilder: (context, i) => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor.withOpacity(0.05),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, _employees[i]),
              child: Text(_employees[i]['name'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
    if (employee != null) {
      setState(() => _selectedEmployee = employee);
      // Automatically assign this employee to all items in cart if they don't have one
      setState(() {
        for (var i = 0; i < _cart.length; i++) {
          if (_cart[i]['employee_ids'] == null || (_cart[i]['employee_ids'] as List).isEmpty) {
            _cart[i]['employee_ids'] = [employee['id']];
          }
        }
      });
    }
  }

  void _selectEmployeesForItem(int index) async {
    await _syncEmployees();
    if (!mounted) return;
    
    final item = _cart[index];
    final List<int> selectedIds = List<int>.from(item['employee_ids'] ?? []);
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Nailists'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: _employees.isEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No active employees found', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () async {
                            await _loadData();
                            setDialogState(() {});
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh List'),
                        ),
                      ],
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _employees.length,
                      itemBuilder: (context, i) {
                        final e = _employees[i];
                        final isSelected = selectedIds.contains(e['id']);
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                selectedIds.remove(e['id']);
                              } else {
                                selectedIds.add(e['id']);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.accentColor : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                e['name'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() => _cart[index]['employee_ids'] = selectedIds);
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processCheckout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    // Show payment method dialog
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Method'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _paymentButton(context, 'Tunai', Icons.money, Colors.green),
                _paymentButton(context, 'Debit Card', Icons.credit_card, Colors.blue),
                _paymentButton(context, 'Credit Card', Icons.credit_score, Colors.indigo),
                _paymentButton(context, 'QRIS', Icons.qr_code_scanner, Colors.purple),
              ],
            ),
          ),
        ),
      ),
    );

    if (paymentMethod == null) return;

    double moneyReceived = _totalAfterDiscount;
    double changeAmount = 0;

    if (paymentMethod == 'Tunai') {
      final input = await showDialog<double>(
        context: context,
        builder: (context) {
          double amount = _totalAfterDiscount;
          final controller = TextEditingController(text: _totalAfterDiscount.toStringAsFixed(0));
          
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Money Received'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total to pay: ${_currencyFormat.format(_totalAfterDiscount)}'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount Received',
                          prefixText: 'Rp ',
                        ),
                        onChanged: (value) {
                          amount = double.tryParse(value) ?? 0;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (amount > _totalAfterDiscount)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Change:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                              Text(_currencyFormat.format(amount - _totalAfterDiscount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Clear Button
                          ActionChip(
                            label: const Text('Clear'),
                            onPressed: () {
                              setDialogState(() {
                                amount = 0;
                                controller.text = '0';
                              });
                            },
                          ),
                          // Exact Money Button
                          ActionChip(
                            label: const Text('Exact Amount'),
                            backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                            onPressed: () {
                              setDialogState(() {
                                amount = _totalAfterDiscount;
                                controller.text = amount.toStringAsFixed(0);
                              });
                            },
                          ),
                          // Denominations
                          ...[100000, 50000, 20000, 10000, 5000, 2000, 1000].map((pecahan) {
                            return ActionChip(
                              label: Text(_currencyFormat.format(pecahan)),
                              onPressed: () {
                                setDialogState(() {
                                  amount += pecahan.toDouble();
                                  controller.text = amount.toStringAsFixed(0);
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, amount), 
                    child: const Text('Process Payment'),
                  ),
                ],
              );
            }
          );
        },
      );

      if (input == null) return;
      moneyReceived = input;
      changeAmount = moneyReceived - _totalAfterDiscount;
      if (changeAmount < 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Amount received is less than total')));
        return;
      }
    }

    try {
      if (_selectedCustomer == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a customer first')));
        return;
      }

      int? transactionEmployeeId = _selectedEmployee?['id'];
      if (transactionEmployeeId == null) {
        // Fallback: Check if there is an employee assigned to any item in the cart
        final itemWithEmployee = _cart.firstWhere(
          (item) => item['employee_ids'] != null && (item['employee_ids'] as List).isNotEmpty,
          orElse: () => <String, dynamic>{},
        );
        if (itemWithEmployee.isNotEmpty) {
          transactionEmployeeId = (itemWithEmployee['employee_ids'] as List).first as int;
        }
      }

      if (transactionEmployeeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an employee first')));
        return;
      }

      final transactionData = {
        'customer_id': _selectedCustomer?['id'],
        'employee_id': transactionEmployeeId,
        'items': _cart.map((item) => {
          'item_id': item['id'],
          'item_type': item['type'],
          'price': item['price'],
          'service_variant_id': item['service_variant_id'],
          'employee_ids': item['employee_ids'],
          'quantity': item['quantity'],
        }).toList(),
        'total_amount': _totalBeforeDiscount,
        'discount_amount': _discountAmount,
        'discount_id': _selectedDiscount?['id'],
        'final_amount': _totalAfterDiscount,
        'payments': [
          {
            'payment_method': paymentMethod,
            'amount': _totalAfterDiscount,
            'money_received': moneyReceived,
            'change_amount': changeAmount,
          }
        ],
      };

      final response = await _posService.submitTransaction(transactionData);
      
      if (response != null) {
        if (!Responsive.isTablet(context)) {
          Navigator.of(context).pop(); // Close the mobile bottom sheet if open
        }
        setState(() {
          _cart.clear();
          _selectedCustomer = null;
          _selectedEmployee = null;
          _selectedDiscount = null;
        });
        _showSuccessDialog(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            if (transaction['payments'] != null && (transaction['payments'] as List).isNotEmpty)
              ... (transaction['payments'] as List).where((p) => double.parse((p['change_amount'] ?? 0).toString()) > 0).map((p) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Change: ${_currencyFormat.format(double.parse(p['change_amount'].toString()))}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
                  ),
                );
              }).toList(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.print,
                  label: 'Print',
                  onTap: () async {
                    final success = await ReceiptHelper().printReceipt(transaction);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Printer not connected.')),
                      );
                    }
                  },
                ),
                _buildActionButton(
                    icon: Icons.share,
                    label: 'WhatsApp',
                    onTap: () async {
                      final error = await ReceiptHelper().shareViaWhatsApp(transaction);
                      if (error != null && mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.add_a_photo,
                    label: 'Photo',
                    color: Colors.pink,
                    onTap: () {
                      if (transaction['customer_id'] == null) {
                        ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Guest checkout. No photo linkable.')));
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

  void _printDraftBill() async {
    _showBillPreview();
  }

  void _showBillPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bill Preview (Draft)'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text(_settings?['store_name'] ?? 'K-BEAUTY HOUSE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
              Center(child: Text(_settings?['store_address'] ?? 'Nail Salon & Beauty', style: const TextStyle(fontSize: 12))),
              if (_settings?['store_phone'] != null && _settings?['store_phone'] != '-')
                Center(child: Text('Phone: ${_settings?['store_phone']}', style: const TextStyle(fontSize: 12))),
              const Divider(),
              Text('Date: ${DateHelper.formatDateTimeReceipt(DateTime.now().toUtc().toIso8601String())}'),
              Text('Customer: ${_selectedCustomer?['name'] ?? 'Guest'}'),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: _cart.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name']),
                                  if (item['employees'] != null && (item['employees'] as List).isNotEmpty)
                                    Text(
                                      '(${(item['employees'] as List).map((e) => (e['full_name'] ?? e['name'] ?? 'Staff').toString()).join(', ')})',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                            Text('${item['quantity']} x ${_currencyFormat.format(double.parse(item['price'].toString()))}'),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:'),
                  Text(_currencyFormat.format(_totalBeforeDiscount)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount:'),
                  Text("- ${_currencyFormat.format(_discountAmount)}"),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_currencyFormat.format(_totalAfterDiscount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                ],
              ),
              const Divider(),
              Center(
                child: Text(
                  _settings?['bill_footer'] ?? 'Thank you for visiting us!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final draftData = {
                'customer': _selectedCustomer,
                'items': _cart,
                'total_amount': _totalBeforeDiscount,
                'discount_amount': _discountAmount,
                'final_amount': _totalAfterDiscount,
              };
              final bool success = await ReceiptHelper().printReceipt(draftData, isDraft: true);
              if (!success && mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Printer not connected.')),
                );
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Draft'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (color ?? AppTheme.accentColor).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color ?? AppTheme.accentColor),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showMobileCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: _buildCartView(scrollController: scrollController),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('POS Checkout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Select/Add Customer',
            onPressed: () => _selectCustomer(),
          ),
          if (_selectedCustomer != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Chip(
                  label: Text(_selectedCustomer!['name'], style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                ),
              ),
            ),
          IconButton(
            icon: Icon(_posItemLayout == 'grid' ? Icons.view_list : Icons.grid_view),
            tooltip: 'Toggle Layout',
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _posItemLayout = _posItemLayout == 'grid' ? 'list' : 'grid';
                  });
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.badge),
            tooltip: 'General Designated Employee',
            onPressed: () => _selectEmployee(),
          ),
          if (_selectedEmployee != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Chip(
                  label: Text(_selectedEmployee!['name'], style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.blue.withOpacity(0.1),
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
                        if (isTablet)
                          Expanded(
                            flex: 2,
                            child: _buildCartView(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: (!isTablet && _cart.isNotEmpty)
          ? InkWell(
              onTap: _showMobileCartSheet,
              child: Container(
                color: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            '${_cart.fold(0, (sum, item) => sum + (item['quantity'] as int))} Items',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Text(
                        _currencyFormat.format(_totalAfterDiscount),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: const [
                          Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }


  Widget _paymentButton(BuildContext context, String label, IconData icon, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.05),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: () => Navigator.pop(context, label),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
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
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedCategory = cat;
                        _filterItems(_searchQuery);
                      });
                    }
                  });
                }
              },
              selectedColor: AppTheme.accentColor.withOpacity(0.2),
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
    if (_posItemLayout == 'list') {
      return Expanded(
        flex: 3,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredItems.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final item = _filteredItems[index];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _addToCart(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(item['category'] ?? 'No Category', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                    Text(
                      _currencyFormat.format(double.parse(item['price'].toString())),
                      style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    final isTablet = Responsive.isTablet(context);
    return Expanded(
      flex: 3,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 4 : 2,
          childAspectRatio: isTablet ? 0.8 : 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _addToCart(item),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
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
                        Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(_currencyFormat.format(double.parse(item['price'].toString())), style: const TextStyle(color: AppTheme.accentColor, fontSize: 13)),
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

  Widget _buildCartView({ScrollController? scrollController}) {
    return Container(
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
                controller: scrollController,
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  return ListTile(
                    title: Text(item['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_currencyFormat.format(double.parse(item['price'].toString()))} x ${item['quantity']}'),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectEmployeesForItem(index),
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
                                  (item['employee_ids'] as List).isEmpty
                                      ? 'Assign'
                                      : _employees
                                          .where((e) => (item['employee_ids'] as List).contains(e['id']))
                                          .map((e) => e['name'])
                                          .join(', '),
                                  style: const TextStyle(fontSize: 11),
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
      );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount'),
              InkWell(
                onTap: _showDiscountDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedDiscount == null ? 'Apply' : _selectedDiscount!['name'],
                        style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.accentColor, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_selectedDiscount != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "- ${_currencyFormat.format(_discountAmount)}",
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
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

  void _showDiscountDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Discount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _discountItem(null), // None
                ..._discounts.map((d) => _discountItem(d)).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _discountItem(Map<String, dynamic>? discount) {
    final isSelected = _selectedDiscount?['id'] == discount?['id'];
    return InkWell(
      onTap: () {
        setState(() => _selectedDiscount = discount);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          discount == null 
              ? 'None' 
              : "${discount['name']} (${discount['type'] == 'percentage' ? '${discount['value']}%' : _currencyFormat.format(double.parse(discount['value'].toString()))})",
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
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


