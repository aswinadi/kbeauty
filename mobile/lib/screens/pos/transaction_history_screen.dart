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
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
