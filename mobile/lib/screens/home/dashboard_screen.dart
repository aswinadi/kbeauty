import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/inventory_service.dart';
import 'product_browser_screen.dart';
import 'stock_opname_screen.dart';
import 'inventory_transaction_screen.dart';
import 'stock_movement_screen.dart';
import 'stock_balance_screen.dart';
import 'profile_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../config/app_config.dart';
import '../../utils/responsive.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/absent_form_screen.dart';
import '../attendance/attendance_history_screen.dart';
import '../pos/pos_checkout_screen.dart';
import '../pos/nailist_performance_screen.dart';
import '../crm/customer_list_screen.dart';
import '../crm/appointment_calendar_screen.dart';
import '../pos/transaction_history_screen.dart';
import '../master/service_category_list_screen.dart';
import '../master/service_treatment_list_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _inventoryService = InventoryService();
  final _authService = AuthService();
  Map<String, dynamic> _stats = {};
  User? _user;
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
      _loadUser(),
    ]);
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _loadUser() async {
    final user = await _authService.getUser();
    setState(() {
      _user = user;
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

    final isNailist = _user?.roles.contains('nailist') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('K-Beauty House', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.accentColor),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.accentColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 12),
              const Text('Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatCard('Products', _stats['total_products']?.toString() ?? '0', Icons.inventory_2),
                  const SizedBox(width: 8),
                  _buildStatCard('Movements', _stats['total_movements']?.toString() ?? '0', Icons.swap_vert),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Attendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.extent(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                maxCrossAxisExtent: 110,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
                children: [
                  _buildActionCard('Izin', Icons.front_hand_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsentFormScreen()));
                  }),
                  _buildActionCard('Check In/Out', Icons.location_on_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
                  }),
                  _buildActionCard('History', Icons.history, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Point of Sales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.extent(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                maxCrossAxisExtent: 110,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
                children: [
                  _buildActionCard('POS', Icons.point_of_sale, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PosCheckoutScreen()));
                  }),
                  _buildActionCard('Comm', Icons.account_balance_wallet_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NailistPerformanceScreen()));
                  }),
                  _buildActionCard('CRM', Icons.group_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen()));
                  }),
                  _buildActionCard('Appt', Icons.calendar_month_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentCalendarScreen()));
                  }),
                  _buildActionCard('History', Icons.receipt_long, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Master Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.extent(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                maxCrossAxisExtent: 110,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
                children: [
                   _buildActionCard('Categories', Icons.category, () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceCategoryListScreen()));
                   }),
                   _buildActionCard('Treatments', Icons.spa, () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceTreatmentListScreen()));
                   }),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Inventory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.extent(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                maxCrossAxisExtent: 110,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
                children: [
                  _buildActionCard('Catalog', Icons.grid_view, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductBrowserScreen()));
                  }),
                  _buildActionCard('In', Icons.add_circle_outline, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryTransactionScreen(type: 'in')));
                  }),
                  _buildActionCard('Out', Icons.remove_circle_outline, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryTransactionScreen(type: 'out')));
                  }),
                  _buildActionCard('Move', Icons.swap_horiz, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StockMovementScreen()));
                  }),
                  _buildActionCard('Opname', Icons.fact_check_outlined, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOpnameScreen()));
                  }),
                  if (!isNailist)
                    _buildActionCard('Balance', Icons.account_balance, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StockBalanceScreen()));
                    }),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('v$_appVersion (${AppConfig.env.toUpperCase()})', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = _user?.employee?.fullName ?? _user?.name ?? 'Admin';
    final hour = DateTime.now().hour;
    String greeting = 'Selamat Pagi';
    if (hour >= 11 && hour < 15) greeting = 'Selamat Siang';
    else if (hour >= 15 && hour < 18) greeting = 'Selamat Sore';
    else if (hour >= 18 || hour < 4) greeting = 'Selamat Malam';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.notifications, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppTheme.accentColor),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppTheme.accentColor),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildActionListItem(String title, IconData icon, VoidCallback onTap) {
     return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.accentColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
