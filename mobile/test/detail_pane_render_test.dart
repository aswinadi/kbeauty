import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

double _safeParse(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
}

Widget buildDetailPane(Map<String, dynamic> tx) {
  try {
    final customer = tx['customer'] is Map ? (tx['customer'] as Map) : null;
    final customerName = customer?['name'] ?? (tx['customer'] is String ? tx['customer'] as String : 'Guest');
    final customerPhone = customer?['phone'];
    final displayCustomer = customerPhone != null && customerPhone.toString().isNotEmpty
        ? '$customerName ($customerPhone)'
        : customerName;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['transaction_number'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D0026),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            tx['created_at'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Customer: $displayCustomer',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Purchased Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D0026),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(tx['items'] as List? ?? []).map((item) {
                    final name = item['item'] != null ? (item['item']['name'] ?? 'Item') : (item['name'] ?? 'Item');
                    final employeesList = item['employees'] as List? ?? [];
                    final employees = employeesList.map((e) {
                      if (e is Map) {
                        return e['full_name'] ?? e['name'] ?? 'Staff';
                      }
                      return e?.toString() ?? 'Staff';
                    }).join(', ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  '${item['quantity']} x ${_currencyFormat.format(_safeParse(item['price']))}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            if (employees.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Nailist: $employees',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  _currencyFormat.format(_safeParse(item['subtotal'])),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const Divider(height: 32),
                  _buildSummaryRow('Total:', _currencyFormat.format(_safeParse(tx['total_amount']))),
                  _buildSummaryRow('Discount:', '- ${_currencyFormat.format(_safeParse(tx['discount_amount']))}'),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    'Grand Total:',
                    _currencyFormat.format(_safeParse(tx['final_amount'])),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  } catch (e, stackTrace) {
    return Center(
      child: SelectableText('Error: $e\n$stackTrace'),
    );
  }
}

void main() {
  testWidgets('Test rendering detail pane with normal data', (WidgetTester tester) async {
    final mockTx = {
      'transaction_number': 'POS-20260602123850-GPNN',
      'created_at': '2026-06-02 12:38',
      'final_amount': 85000,
      'total_amount': 85000,
      'discount_amount': 0,
      'customer': {
        'name': 'kak dhita',
        'phone': '6281333659909',
      },
      'items': [
        {
          'item': {'name': 'Treatment 1'},
          'quantity': 1,
          'price': 85000,
          'subtotal': 85000,
          'employees': [
            {'full_name': 'Nailist 1'}
          ]
        }
      ],
      'portfolios': []
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: buildDetailPane(mockTx),
      ),
    ));

    expect(find.text('POS-20260602123850-GPNN'), findsOneWidget);
    expect(find.text('Customer: kak dhita (6281333659909)'), findsOneWidget);
  });

  testWidgets('Test rendering detail pane with string customer and nested map mismatch', (WidgetTester tester) async {
    final mockTx = {
      'transaction_number': 'POS-20260602123850-GPNN',
      'created_at': '2026-06-02 12:38',
      'final_amount': 85000,
      'total_amount': 85000,
      'discount_amount': 0,
      'customer': 'Guest', // customer is a string!
      'items': [
        {
          'item': {'name': 'Treatment 1'},
          'quantity': 1,
          'price': 85000,
          'subtotal': 85000,
          'employees': [
            {'full_name': 'Nailist 1'}
          ]
        }
      ],
      'portfolios': []
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: buildDetailPane(mockTx),
      ),
    ));

    // The exception should be handled and no crash happens!
    expect(tester.takeException(), isNull);
    expect(find.text('Customer: Guest'), findsOneWidget);
  });
}
