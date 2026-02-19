import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/inventory_service.dart';
import 'product_browser_screen.dart';
import 'stock_opname_screen.dart';
import 'inventory_transaction_screen.dart';
import 'stock_movement_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/app_config.dart';
import '../../utils/responsive.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _inventoryService = InventoryService();
  Map<String, dynamic> _stats = {};
  String _appVersion = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadStats(),
      _loadVersion(),
    ]);
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _loadStats() async {
    final stats = await _inventoryService.getStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('K-Beauty House', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard('Products', _stats['total_products']?.toString() ?? '0', Icons.inventory_2),
                  const SizedBox(width: 16),
                  _buildStatCard('Movements', _stats['total_movements']?.toString() ?? '0', Icons.swap_vert),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: Responsive.isTablet(context) 
                  ? (Responsive.isLandscape(context) ? 5 : 4) 
                  : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: Responsive.isTablet(context) ? 1.2 : 1.1,
                children: [
                  _buildActionCard('Catalog', Icons.grid_view, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductBrowserScreen()));
                  }),
                  _buildActionCard('Stock In', Icons.add_circle_outline, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryTransactionScreen(type: 'in')));
                  }),
                  _buildActionCard('Stock Out', Icons.remove_circle_outline, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryTransactionScreen(type: 'out')));
                  }),
                  _buildActionCard('Stock Move', Icons.swap_horiz, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StockMovementScreen()));
                  }),
                  _buildActionCard('Stock Opname', Icons.fact_check_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOpnameScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Text(
                      'v$_appVersion (${AppConfig.env.toUpperCase()})',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Server: ${AppConfig.apiBaseUrl}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accentColor),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppTheme.accentColor),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
