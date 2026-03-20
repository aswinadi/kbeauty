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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final details = await _posService.getCustomerDetails(widget.customer['id']);
    setState(() {
      _fullDetails = details;
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
                return GestureDetector(
                  onTap: () {
                    // Show full image logic
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          '${AppConfig.apiBaseUrl.replaceAll('/api', '')}/storage/${p['image_path']}',
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
          ).then((_) => _fetchDetails());
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
