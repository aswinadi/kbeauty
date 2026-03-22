import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import 'package:intl/intl.dart';
import '../crm/add_customer_portfolio_screen.dart';

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
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

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
    setState(() => _isLoading = true);
    final response = await _posService.getAllTransactions(page: _currentPage);
    
    final List data = response['data'] ?? [];
    setState(() {
      _transactions.addAll(data.cast<Map<String, dynamic>>());
      _isLoading = false;
      if (data.length < 20) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _transactions = [];
                _currentPage = 1;
                _hasMore = true;
              });
              _fetchTransactions();
            },
          ),
        ],
      ),
      body: _transactions.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('No transactions found.'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _transactions.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                    }
                    
                    final tx = _transactions[index];
                    final date = DateTime.parse(tx['created_at']);
                    final portfolios = tx['portfolios'] as List? ?? [];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _showTransactionDetail(tx),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(tx['transaction_number'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(date)),
                              trailing: Text(
                                _currencyFormat.format(double.parse(tx['final_amount'].toString())),
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Customer: ${tx['customer']?['name'] ?? 'Guest'}', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  if (portfolios.isNotEmpty) ...[
                                    const Text('Treatment Photos:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                                            children: media.map((m) => Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              width: 100,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: NetworkImage(m['original_url']),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            )).toList(),
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
                                        // Refresh list
                                        setState(() {
                                           _transactions = [];
                                           _currentPage = 1;
                                           _hasMore = true;
                                        });
                                        _fetchTransactions();
                                      },
                                      icon: const Icon(Icons.add_a_photo, size: 16),
                                      label: const Text('Add Result Photo'),
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
                  },
                ),
    );
  }

  void _showTransactionDetail(Map<String, dynamic> tx) {
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
                Text('Date: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tx['created_at']))}'),
                Text('Customer: ${tx['customer']?['name'] ?? 'Guest'}'),
                const Divider(height: 24),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...(tx['items'] as List? ?? []).map((item) {
                   final name = item['item'] != null ? (item['item']['name'] ?? 'Item') : (item['name'] ?? 'Item');
                   final employees = (item['employees'] as List?)?.map((e) => e['name']).join(', ') ?? '';
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 12),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                             Text('${item['quantity']} x ${_currencyFormat.format(double.parse(item['price'].toString()))}'),
                           ],
                         ),
                         if (employees.isNotEmpty)
                           Text('Nailist: $employees', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                         Align(
                           alignment: Alignment.centerRight,
                           child: Text(
                             _currencyFormat.format(double.parse((item['subtotal'] ?? 0).toString())),
                             style: const TextStyle(fontWeight: FontWeight.bold),
                           ),
                         ),
                       ],
                     ),
                   );
                }).toList(),
                const Divider(height: 24),
                _buildSummaryRow('Total:', _currencyFormat.format(double.parse(tx['total_amount'].toString()))),
                _buildSummaryRow('Discount:', '- ${_currencyFormat.format(double.parse(tx['discount_amount'].toString()))}'),
                _buildSummaryRow('Grand Total:', _currencyFormat.format(double.parse(tx['final_amount'].toString())), isBold: true),
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
                          children: media.map((m) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(m['original_url'], height: 120, width: 120, fit: BoxFit.cover),
                            ),
                          )).toList(),
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
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
