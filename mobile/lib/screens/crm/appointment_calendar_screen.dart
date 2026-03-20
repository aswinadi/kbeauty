import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/pos_service.dart';
import 'add_appointment_screen.dart';
import 'add_customer_portfolio_screen.dart';
import '../../config/app_config.dart';
import 'package:intl/intl.dart';

class AppointmentCalendarScreen extends StatefulWidget {
  const AppointmentCalendarScreen({super.key});

  @override
  State<AppointmentCalendarScreen> createState() => _AppointmentCalendarScreenState();
}

class _AppointmentCalendarScreenState extends State<AppointmentCalendarScreen> {
  final PosService _posService = PosService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    final appointments = await _posService.getAppointments();
    
    final Map<DateTime, List<Map<String, dynamic>>> newEvents = {};
    for (var appt in appointments) {
      final date = DateTime.parse(appt['appointment_date']);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (newEvents[normalizedDate] == null) {
        newEvents[normalizedDate] = [];
      }
      newEvents[normalizedDate]!.add(appt);
    }

    setState(() {
      _events = newEvents;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAppointments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.pink.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: _buildEventList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddAppointmentScreen(initialDate: _selectedDay),
            ),
          );
          if (result == true) {
            _fetchAppointments();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return const Center(
        child: Text('No appointments for this day'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final customer = event['customer'];
        final time = event['appointment_time'];
        final treatment = event['treatment_name'];
        final isPaid = event['is_paid'] ?? false;
        final status = event['status'] ?? 'scheduled';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              customer != null ? customer['full_name'] : 'Unknown Customer',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('$time - $treatment (Pax: ${event['pax'] ?? 1})'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusBadge(status),
                    const SizedBox(width: 8),
                    if (isPaid)
                      const Icon(Icons.check_circle, color: Colors.green, size: 16)
                    else
                      const Icon(Icons.pending, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      isPaid ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPaid ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _buildAppointmentPhotos(event['portfolios'] ?? []),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_a_photo, color: Colors.pink, size: 20),
                  onPressed: () async {
                    if (customer == null) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCustomerPortfolioScreen(
                          customerId: customer['id'],
                          appointmentId: event['id'],
                        ),
                      ),
                    );
                    _fetchAppointments();
                  },
                ),
              ],
            ),
            onTap: () {
              // TODO: Show details
            },
          ),
        );
      },
    );
  }

  Widget _buildAppointmentPhotos(List portfolios) {
    if (portfolios.isEmpty) return const SizedBox();
    
    List<dynamic> allMedia = [];
    for (var p in portfolios) {
      final media = p['media'] as List? ?? [];
      allMedia.addAll(media);
    }

    if (allMedia.isEmpty) return const SizedBox();

    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allMedia.length,
        itemBuilder: (context, idx) {
          final m = allMedia[idx];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(m['original_url']),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'no-show':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
