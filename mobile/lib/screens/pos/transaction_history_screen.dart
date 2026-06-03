import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import 'package:intl/intl.dart';
import '../crm/add_customer_portfolio_screen.dart';
import '../../utils/receipt_helper.dart';
import '../../config/app_config.dart';
import '../../utils/date_helper.dart';
import '../../theme/app_theme.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _posService = PosService();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  bool _isFetching = false;
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  double _safeParse(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 && !_isLoading && _hasMore) {
      _fetchTransactions();
    }
  }

  Future<void> _fetchTransactions() async {
    if (_isFetching || !_hasMore) return;
    _isFetching = true;

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
    });

    try {
      final response = await _posService.getAllTransactions(page: _currentPage);
      final List data = response['data'] ?? [];
      
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _transactions.addAll(data.cast<Map<String, dynamic>>());
            _isLoading = false;
            _isFetching = false;
            if (data.length < 20) {
              _hasMore = false;
            } else {
              _currentPage++;
            }
          });
        }
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isFetching = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listWidget = _transactions.isEmpty && _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _transactions.isEmpty
            ? const Center(child: Text('No transactions found.'))
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _transactions.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  try {
                    if (index == _transactions.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                    }
                    
                    final tx = _transactions[index];
                    final portfolios = tx['portfolios'] is List ? (tx['portfolios'] as List) : [];
                    
                    final customer = tx['customer'] is Map ? (tx['customer'] as Map) : null;
                    final customerName = customer?['name'] ?? (tx['customer'] is String ? tx['customer'] as String : 'Guest');
                    final customerPhone = customer?['phone'];
                    final displayCustomer = customerPhone != null && customerPhone.toString().isNotEmpty
                        ? '$customerName ($customerPhone)'
                        : customerName;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showTransactionDetail(tx),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx['transaction_number'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateHelper.formatDateTime(tx['created_at']),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(_safeParse(tx['final_amount'])),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer: $displayCustomer',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (portfolios.isNotEmpty) ...[
                                    const Text(
                                      'Treatment Photos:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: portfolios.length,
                                        itemBuilder: (context, pIdx) {
                                          final p = portfolios[pIdx];
                                          final media = p['media'] as List? ?? [];
                                          if (media.isEmpty) return const SizedBox();
                                          
                                          return Row(
                                            children: media.map((m) {
                                              final url = m is Map ? (m['original_url']?.toString() ?? '') : '';
                                              return Container(
                                                margin: const EdgeInsets.only(right: 8),
                                                width: 100,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: Colors.grey[200],
                                                  image: url.isNotEmpty
                                                      ? DecorationImage(
                                                          image: NetworkImage(AppConfig.formatUrl(url)),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                child: url.isEmpty
                                                    ? const Icon(Icons.broken_image, color: Colors.grey)
                                                    : null,
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ),
                                  ] else ...[
                                    TextButton.icon(
                                      onPressed: () async {
                                        if (tx['customer_id'] == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot add photos to Guest transactions.')));
                                          return;
                                        }
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddCustomerPortfolioScreen(
                                              customerId: tx['customer_id'],
                                              posTransactionId: tx['id'],
                                            ),
                                          ),
                                        );
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) {
                                            setState(() {
                                              _transactions = [];
                                              _currentPage = 1;
                                              _hasMore = true;
                                              _isFetching = false;
                                            });
                                            _fetchTransactions();
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.add_a_photo, size: 16),
                                      label: const Text('Add Result Photo'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.accentColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  } catch (e, stackTrace) {
                    print('Error rendering item at index $index: $e');
                    print(stackTrace);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading transaction: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }
                },
              );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _transactions = [];
                    _currentPage = 1;
                    _hasMore = true;
                    _isFetching = false;
                  });
                  _fetchTransactions();
                }
              });
            },
          ),
        ],
      ),
      body: listWidget,
    );
  }

  void _showTransactionDetail(Map<String, dynamic> tx) {
    final customer = tx['customer'] is Map ? (tx['customer'] as Map) : null;
    final customerName = customer?['name'] ?? (tx['customer'] is String ? tx['customer'] as String : 'Guest');
    final customerPhone = customer?['phone'];
    final displayCustomer = customerPhone != null && customerPhone.toString().isNotEmpty
        ? '$customerName ($customerPhone)'
        : customerName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Number: ${tx['transaction_number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Date: ${DateHelper.formatDateTime(tx['created_at'])}'),
                Text('Customer: $displayCustomer'),
                const Divider(height: 24),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(tx['items'] as List? ?? []).map((item) {
                   final name = item['item'] != null ? (item['item']['name'] ?? 'Item') : (item['name'] ?? 'Item');
                   final employeesList = item['employees'] as List? ?? [];
                   final employees = employeesList.map((e) {
                      if (e is Map) {
                        return e['full_name'] ?? e['name'] ?? 'Staff';
                      }
                      return e?.toString() ?? 'Staff';
                   }).join(', ');
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 12),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                             Text('${item['quantity']} x ${_currencyFormat.format(_safeParse(item['price']))}'),
                           ],
                         ),
                         if (employees.isNotEmpty)
                           Text('Nailist: $employees', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                         Align(
                           alignment: Alignment.centerRight,
                           child: Text(
                             _currencyFormat.format(_safeParse(item['subtotal'])),
                             style: const TextStyle(fontWeight: FontWeight.bold),
                           ),
                         ),
                       ],
                     ),
                   );
                }).toList(),
                const Divider(height: 24),
                _buildSummaryRow('Total:', _currencyFormat.format(_safeParse(tx['total_amount']))),
                _buildSummaryRow('Discount:', '- ${_currencyFormat.format(_safeParse(tx['discount_amount']))}'),
                _buildSummaryRow('Grand Total:', _currencyFormat.format(_safeParse(tx['final_amount'])), isBold: true),
                if ((tx['portfolios'] as List? ?? []).isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Result Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (tx['portfolios'] as List).length,
                      itemBuilder: (context, pIdx) {
                        final p = (tx['portfolios'] as List)[pIdx];
                        final media = p['media'] as List? ?? [];
                        return Row(
                           children: media.map((m) {
                              final url = m is Map ? (m['original_url']?.toString() ?? '') : '';
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: url.isNotEmpty
                                      ? Image.network(
                                          AppConfig.formatUrl(url),
                                          height: 120,
                                          width: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 120,
                                            width: 120,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          height: 120,
                                          width: 120,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                ),
                              );
                           }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              final customer = tx['customer'] is Map ? (tx['customer'] as Map) : null;
              final phoneVal = customer?['phone'];
              final phone = phoneVal?.toString();
              if (phone == null || phone.trim().isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Customer phone not found.')));
                return;
              }
              await ReceiptHelper().shareViaWhatsApp(tx, phone);
            },
            icon: const Icon(Icons.share),
            label: const Text('WhatsApp'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final success = await ReceiptHelper().printReceipt(tx);
              if (success && mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Receipt printed.')));
              } else if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Printer not connected.')));
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('Reprint'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? Colors.green : null)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
