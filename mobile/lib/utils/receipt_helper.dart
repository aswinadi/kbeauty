import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/pos_service.dart';

class ReceiptHelper {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<bool> printReceipt(Map<String, dynamic> transaction, {bool isDraft = false}) async {
    final settings = await PosService().getSettings();
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) return false;

    final storeName = settings?['store_name'] ?? "K-BEAUTY HOUSE";
    final storeAddress = settings?['store_address'] ?? "Nail Salon & Beauty";
    final storePhone = settings?['store_phone'] ?? "";

    bluetooth.printCustom(storeName, 2, 1);
    bluetooth.printCustom(storeAddress, 1, 1);
    if (storePhone.isNotEmpty) {
      bluetooth.printCustom("Tel: $storePhone", 1, 1);
    }
    bluetooth.write("--------------------------------\n");
    
    if (isDraft) {
      bluetooth.write("Type: DRAFT (Check Items)\n");
    } else {
      bluetooth.write("No: ${transaction['transaction_number']}\n");
    }
    
    final dateStr = transaction['created_at'] != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['created_at']))
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    bluetooth.write("Date: $dateStr\n");
    bluetooth.write("Customer: ${transaction['customer']?['name'] ?? 'Guest'}\n");
    if (transaction['employee'] != null) {
      bluetooth.write("Cashier: ${transaction['employee']['name']}\n");
    }
    bluetooth.write("--------------------------------\n");

    for (var item in transaction['items']) {
      final name = item['item'] != null ? (item['item']['name'] ?? 'Item') : (item['name'] ?? 'Item');
      bluetooth.write("$name\n");
      
      final employees = (item['employees'] as List?)?.map((e) => e['name']).join(', ') ?? '';
      if (employees.isNotEmpty) {
        bluetooth.write(" ($employees)\n");
      }

      final qtyPrice = "${item['quantity']} x ${_currencyFormat.format(double.parse(item['price'].toString()))}";
      final subtotalValue = item['subtotal'] ?? (double.parse(item['price'].toString()) * (item['quantity'] ?? 1));
      final subtotal = _currencyFormat.format(double.parse(subtotalValue.toString()));
      bluetooth.write(_alignRow(qtyPrice, subtotal) + "\n");
    }

    bluetooth.write("--------------------------------\n");
    bluetooth.write(_alignRow("Total:", _currencyFormat.format(double.parse(transaction['total_amount'].toString()))) + "\n");
    bluetooth.write(_alignRow("Discount:", _currencyFormat.format(double.parse(transaction['discount_amount'].toString()))) + "\n");
    bluetooth.printCustom(_alignRow("Grand Total:", _currencyFormat.format(double.parse(transaction['final_amount'].toString()))), 1, 1);
    bluetooth.write("--------------------------------\n");
    
    if (isDraft) {
      bluetooth.printCustom("PLEASE PAY AT CASHIER", 1, 1);
    } else {
      bluetooth.printCustom("Thank You for Visiting!", 1, 1);
    }
    bluetooth.write("\n\n\n");
    return true;
  }

  String _alignRow(String left, String right, {int width = 32}) {
    int total = width - left.length - right.length;
    if (total < 1) return left + " " + right;
    return left + (" " * total) + right;
  }

  Future<String?> shareViaWhatsApp(Map<String, dynamic> transaction) async {
    final phone = transaction['customer']?['phone'];
    if (phone == null || phone.isEmpty) return 'Customer phone number is missing';

    String message = "*K-BEAUTY HOUSE RECEIPT*\n\n";
    if (transaction['transaction_number'] != null) {
      message += "No: ${transaction['transaction_number']}\n";
    } else {
      message += "Type: DRAFT (Check Items)\n";
    }
    
    final dateStr = transaction['created_at'] != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(transaction['created_at']))
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
        
    message += "Date: $dateStr\n";
    message += "--------------------------------\n";
    
    for (var item in transaction['items']) {
      final name = item['item'] != null ? (item['item']['name'] ?? 'Item') : (item['name'] ?? 'Item');
      final subtotal = item['subtotal'] ?? (double.parse(item['price'].toString()) * (item['quantity'] ?? 1));
      
      final employees = (item['employees'] as List?)?.map((e) => e['name']).join(', ') ?? '';
      String itemLine = "$name x ${item['quantity']}";
      if (employees.isNotEmpty) itemLine += " ($employees)";
      message += "$itemLine\n";
      message += "${_currencyFormat.format(double.parse(subtotal.toString()))}\n";
    }
    
    message += "--------------------------------\n";
    message += "*Grand Total: ${_currencyFormat.format(double.parse(transaction['final_amount'].toString()))}*\n\n";
    message += "Thank you for visiting us!";

    final url = "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}";
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return null;
      } else {
        // Fallback to web link if app not installed
        final webUrl = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
        return null;
      }
    } catch (e) {
      return 'Could not launch WhatsApp: $e';
    }
  }
}
