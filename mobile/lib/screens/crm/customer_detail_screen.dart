import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import '../../config/app_config.dart';
import 'add_customer_portfolio_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _posService = PosService();
  Map<String, dynamic>? _fullDetails;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    final results = await Future.wait([
      _posService.getCustomerDetails(widget.customer['id']),
      _posService.getCustomerHistory(widget.customer['id']),
    ]);
    setState(() {
      _fullDetails = (results[0] as Map<String, dynamic>);
      _history = (results[1] as List).cast<Map<String, dynamic>>();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer['name']),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Info'),
            Tab(icon: Icon(Icons.card_membership), text: 'Members'),
            Tab(icon: Icon(Icons.photo_library), text: 'Portfolio'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildMembershipTab(),
                _buildPortfolioTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildInfoTab() {
    final metadata = _fullDetails?['metadata'] as Map? ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.phone, 'Phone', _fullDetails?['phone'] ?? '-'),
          _buildInfoRow(Icons.email, 'Email', _fullDetails?['email'] ?? '-'),
          _buildInfoRow(Icons.star, 'Loyalty Points', _fullDetails?['loyalty_points']?.toString() ?? '0'),
          const Divider(height: 32),
          const Text('Preferences / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ...metadata.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('${e.key}: ${e.value}'),
              )),
          if (metadata.isEmpty) const Text('No preferences recorded.'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.pink),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipTab() {
    final memberships = _fullDetails?['memberships'] as List? ?? [];
    return memberships.isEmpty
        ? const Center(child: Text('No active memberships.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memberships.length,
            itemBuilder: (context, index) {
              final m = memberships[index];
              return Card(
                color: Colors.pink[50],
                child: ListTile(
                  title: Text(m['type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Balance: Rp ${m['balance']}'),
                  trailing: Text('Expires: ${m['expires_at']?.split('T')[0] ?? '-'}'),
                ),
              );
            },
          );
  }

  Widget _buildPortfolioTab() {
    final portfolios = _fullDetails?['portfolios'] as List? ?? [];
    return Scaffold(
      body: portfolios.isEmpty
          ? const Center(child: Text('No portfolio images yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: portfolios.length,
              itemBuilder: (context, index) {
                final p = portfolios[index];
                final media = p['media'] as List?;
                final imageUrl = (media != null && media.isNotEmpty)
                    ? media[0]['original_url'].toString()
                    : '${AppConfig.apiBaseUrl.replaceAll('/api', '')}/storage/${p['image_path']}';

                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 100)),
                            ),
                            if (p['notes'] != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(p['notes']),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            color: Colors.black54,
                            child: Text(
                              p['notes'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCustomerPortfolioScreen(customerId: widget.customer['id']),
            ),
          ).then((_) => _fetchData());
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _history.isEmpty
        ? const Center(child: Text('No transaction history.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final tx = _history[index];
              final date = tx['created_at'].split('T')[0];
              final items = tx['items'] as List? ?? [];
              final portfolios = tx['portfolios'] as List? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(tx['transaction_number'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(date),
                      trailing: Text('Rp ${tx['final_amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Items:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ...items.map((it) => Text('• ${it['item_name']} x${it['quantity']}')),
                          const SizedBox(height: 8),
                          if (portfolios.isNotEmpty) ...[
                            const Text('Photos from this visit:', style: TextStyle(fontSize: 12, color: Colors.pink)),
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
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
  }
}
