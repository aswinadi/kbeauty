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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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

    bool hasPermission(String permission) {
      if (_user?.roles.any((r) => r.toLowerCase() == 'super_admin') ?? false) return true;
      return _user?.permissions.contains(permission) ?? false;
    }

    final hasAnyAttendance = hasPermission('ViewAny:Attendance');
    final hasAnyPOS = hasPermission('Create:PosTransaction') || hasPermission('ViewAny:PosTransaction') || hasPermission('ViewAny:Customer') || hasPermission('ViewAny:Appointment');
    final hasAnyMaster = hasPermission('ViewAny:ServiceCategory') || hasPermission('ViewAny:Service');
    final hasAnyInventory = hasPermission('ViewAny:Product') || hasPermission('ViewAny:InventoryTransaction') || hasPermission('ViewAny:InventoryMovement') || hasPermission('ViewAny:StockOpname');

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
        child: Responsive.isTablet(context)
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatCard('Products', _stats['total_products']?.toString() ?? '0', Icons.inventory_2),
                              const SizedBox(width: 8),
                              _buildStatCard('Movements', _stats['total_movements']?.toString() ?? '0', Icons.swap_vert),
                            ],
                          ),
                          _buildMenus(hasPermission, hasAnyPOS, hasAnyMaster, hasAnyInventory),
                          const SizedBox(height: 24),
                          Center(
                            child: Text('v$_appVersion (${AppConfig.env.toUpperCase()})', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: Colors.grey[200]),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 20),
                          Card(
                            elevation: 0,
                            color: Colors.grey[50],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Quick Access', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  ListTile(
                                    leading: const Icon(Icons.location_on_outlined, color: AppTheme.accentColor),
                                    title: const Text('Check In/Out', style: TextStyle(fontSize: 13)),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen())),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.front_hand_outlined, color: AppTheme.accentColor),
                                    title: const Text('Izin Absen', style: TextStyle(fontSize: 13)),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsentFormScreen())),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
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
                    _buildMenus(hasPermission, hasAnyPOS, hasAnyMaster, hasAnyInventory),
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

  Widget _buildMenus(
    bool Function(String) hasPermission,
    bool hasAnyPOS,
    bool hasAnyMaster,
    bool hasAnyInventory,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Attendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.extent(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          maxCrossAxisExtent: Responsive.isTablet(context) ? 130 : 110,
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
            if (hasPermission('ViewAny:Attendance'))
              _buildActionCard('History', Icons.history, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()));
              }),
          ],
        ),
        if (hasAnyPOS) ...[
          const SizedBox(height: 12),
          const Text('Point of Sales', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.extent(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            maxCrossAxisExtent: Responsive.isTablet(context) ? 130 : 110,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: [
              if (hasPermission('Create:PosTransaction'))
                _buildActionCard('POS', Icons.point_of_sale, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PosCheckoutScreen()));
                }),
              _buildActionCard('Comm', Icons.account_balance_wallet_outlined, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NailistPerformanceScreen()));
              }),
              if (hasPermission('ViewAny:Customer'))
                _buildActionCard('CRM', Icons.group_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen()));
                }),
              if (hasPermission('ViewAny:Appointment'))
                _buildActionCard('Appt', Icons.calendar_month_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentCalendarScreen()));
                }),
              if (hasPermission('ViewAny:PosTransaction'))
                _buildActionCard('History', Icons.receipt_long, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()));
                }),
            ],
          ),
        ],
        if (hasAnyMaster) ...[
          const SizedBox(height: 12),
          const Text('Master Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.extent(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            maxCrossAxisExtent: Responsive.isTablet(context) ? 130 : 110,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: [
              if (hasPermission('ViewAny:ServiceCategory'))
                _buildActionCard('Tr. Category', Icons.category, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceCategoryListScreen()));
                }),
              if (hasPermission('ViewAny:Service'))
                _buildActionCard('Treatments', Icons.spa, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceTreatmentListScreen()));
                }),
            ],
          ),
        ],
        if (hasAnyInventory) ...[
          const SizedBox(height: 12),
          const Text('Inventory', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.extent(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            maxCrossAxisExtent: Responsive.isTablet(context) ? 130 : 110,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: [
              if (hasPermission('ViewAny:Product'))
                _buildActionCard('Catalog', Icons.grid_view, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductBrowserScreen()));
                }),
              if (hasPermission('ViewAny:InventoryTransaction')) ...[
                _buildActionCard('In', Icons.add_circle_outline, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryTransactionScreen(type: 'in')));
                }),
                _buildActionCard('Out', Icons.remove_circle_outline, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryTransactionScreen(type: 'out')));
                }),
              ],
              if (hasPermission('ViewAny:InventoryMovement'))
                _buildActionCard('Move', Icons.swap_horiz, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StockMovementScreen()));
                }),
              if (hasPermission('ViewAny:StockOpname'))
                _buildActionCard('Opname', Icons.fact_check_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOpnameScreen()));
                }),
              if (hasPermission('ViewAny:Product'))
                _buildActionCard('Balance', Icons.account_balance, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StockBalanceScreen()));
                }),
            ],
          ),
        ],
      ],
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
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white70),
            onPressed: _showNotificationsBottomSheet,
          ),
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

  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        final notifications = [
          {
            'title': 'Daily Attendance Reminder',
            'body': 'Don\'t forget to check in/out today to keep your logs accurate.',
            'time': 'Just now',
            'icon': Icons.access_alarm,
            'color': Colors.orange,
          },
          {
            'title': 'System Layout Upgrade',
            'body': '2-pane split layouts are now live for Catalog, Stock Balance, and Treatments on tablet devices.',
            'time': '1 hour ago',
            'icon': Icons.tablet_android,
            'color': Colors.blue,
          },
          {
            'title': 'Loyalty Rewards Active',
            'body': 'Check-in loyalty tier settings for customers are now fully integrated.',
            'time': '1 day ago',
            'icon': Icons.card_membership,
            'color': Colors.pink,
          },
        ];

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: AppTheme.accentColor),
                  SizedBox(width: 12),
                  Text(
                    'System Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D0026),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: item['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      item['time'] as String,
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['body'] as String,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
