import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final _authService = AuthService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _authService.getAttendanceHistory();
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupHistoryByMonth() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in _history) {
      final date = DateTime.parse(item['date']);
      final monthKey = DateFormat('MMMM yyyy').format(date);
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedHistory = _groupHistoryByMonth();
    final months = groupedHistory.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('No attendance history found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final items = groupedHistory[month]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                          child: Text(
                            month,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentColor,
                                ),
                          ),
                        ),
                        ...items.map((item) => _buildHistoryItem(item)).toList(),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final isAbsent = item['type'] == 'absent';
    final date = DateTime.parse(item['date']);
    final dayName = DateFormat('EEEE').format(date);
    final dayDate = DateFormat('dd').format(date);
    
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle_outline;
    String statusText = item['status']?.toString().toUpperCase() ?? 'UNK';

    if (isAbsent) {
      statusColor = Colors.orange;
      statusIcon = Icons.info_outline;
    } else if (item['status'] == 'absent') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(dayDate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                Text(dayName.substring(0, 3).toUpperCase(), style: const TextStyle(fontSize: 10, color: AppTheme.accentColor)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAbsent ? 'Izin / Absen' : 'Kehadiran',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!isAbsent && item['check_in'] != null)
                  Text(
                    'IN: ${item['check_in']} ${item['check_out'] != null ? '| OUT: ${item['check_out']}' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                if (isAbsent)
                  Text(
                    statusText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
