import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class NailistPerformanceScreen extends StatefulWidget {
  const NailistPerformanceScreen({super.key});

  @override
  State<NailistPerformanceScreen> createState() => _NailistPerformanceScreenState();
}

class _NailistPerformanceScreenState extends State<NailistPerformanceScreen> {
  final _posService = PosService();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _posService.getPerformance(
      fromDate: DateFormat('Y-MM-dd').format(_fromDate),
      toDate: DateFormat('Y-MM-dd').format(_toDate),
    );
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 32),
                    const Text('Treatment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildHistoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final totalComm = double.parse((_data?['total_commission'] ?? 0).toString());
    final totalServices = _data?['total_services'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentColor, Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.accentColor.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Treatments', totalServices.toString(), Icons.spa),
              _buildMetric('Commissions', _currencyFormat.format(totalComm), Icons.account_balance_wallet),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Text(
            'Period: ${DateFormat('dd MMM').format(_fromDate)} - ${DateFormat('dd MMM yyyy').format(_toDate)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildHistoryList() {
    final List details = _data?['details'] ?? [];
    if (details.isEmpty) {
      return const Center(child: Text('No treatment history found for this period.'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = details[index];
        final date = DateTime.parse(item['date']);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(date)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_currencyFormat.format(double.parse(item['commission'].toString())), style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
              Text('Sub: ${_currencyFormat.format(double.parse(item['subtotal'].toString()))}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}
