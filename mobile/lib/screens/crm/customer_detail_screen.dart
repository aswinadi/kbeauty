import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/pos_service.dart';
import '../../config/app_config.dart';
import 'add_customer_portfolio_screen.dart';
import '../../utils/date_helper.dart';
import '../../utils/responsive.dart';



class CustomerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _posService = PosService();
  final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'Rp ', decimalDigits: 0);
  Map<String, dynamic>? _fullDetails;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  // Local mutable copy of customer name for AppBar
  late String _customerName;

  @override
  void initState() {
    super.initState();
    _customerName = widget.customer['name'] ?? '';
    _tabController = TabController(length: 4, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _posService.getCustomerDetails(widget.customer['id']),
      _posService.getCustomerHistory(widget.customer['id']),
    ]);
    setState(() {
      _fullDetails = (results[0] as Map<String, dynamic>?);
      _history = (results[1] as List).cast<Map<String, dynamic>>();
      if (_fullDetails != null) {
        _customerName = _fullDetails!['name'] ?? _customerName;
      }
      _isLoading = false;
    });
  }

  // ─── Edit Bottom Sheet ────────────────────────────────────────────────────

  void _openEditSheet() {
    final nameCtrl = TextEditingController(text: _fullDetails?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: _fullDetails?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: _fullDetails?['email'] ?? '');
    final notesCtrl = TextEditingController(
      text: (_fullDetails?['metadata'] as Map?)?['notes']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setSheetState(() => isSaving = true);

            final result = await _posService.updateCustomer(
              widget.customer['id'],
              {
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              },
            );

            if (!mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            final nav = Navigator.of(ctx);
            nav.pop();

            if (result != null) {
              setState(() {
                _fullDetails = result;
                _customerName = result['name'] ?? _customerName;
              });
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Customer updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Failed to update customer. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE4EC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_outlined, color: Color(0xFFE91E63), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Edit Customer Info',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D0026),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Name field
                    TextFormField(
                      controller: nameCtrl,
                      decoration: _inputDecoration('Full Name', Icons.person),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Phone field
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: _inputDecoration('Phone Number', Icons.phone),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    // Email field
                    TextFormField(
                      controller: emailCtrl,
                      decoration: _inputDecoration('Email Address', Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Notes / Preferences field
                    TextFormField(
                      controller: notesCtrl,
                      decoration: _inputDecoration('Preferences / Notes', Icons.notes),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFE91E63), size: 20),
      filled: true,
      fillColor: const Color(0xFFFCE4EC).withValues(alpha: 0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.pink.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.grey),
      floatingLabelStyle: const TextStyle(color: Color(0xFFE91E63)),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final phone = _fullDetails?['phone'] ?? widget.customer['phone'];
    final displayTitle = phone != null && phone.toString().isNotEmpty
        ? '$_customerName ($phone)'
        : _customerName;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !Responsive.isTablet(context),
        title: Text(displayTitle),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Customer',
              onPressed: _openEditSheet,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: !Responsive.isTablet(context),
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
    final notes = metadata['notes']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.phone, 'Phone', _fullDetails?['phone'] ?? '-'),
          _buildInfoRow(Icons.email, 'Email', _fullDetails?['email'] ?? '-'),
          _buildInfoRow(Icons.star, 'Loyalty Points',
              _fullDetails?['loyalty_points']?.toString() ?? '0'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preferences / Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton.icon(
                onPressed: _openEditSheet,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFE91E63)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (notes != null && notes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Text(notes, style: const TextStyle(fontSize: 14)),
            )
          else
            const Text('No preferences recorded.',
                style: TextStyle(color: Colors.grey)),
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
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
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
                  title: Text(m['type'].toString().toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Balance: ${_currencyFormat.format(double.tryParse(m['balance'].toString()) ?? 0.0)}'),
                  trailing: Text(
                      'Expires: ${m['expires_at']?.split('T')[0] ?? '-'}'),
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
                final imageUrl = AppConfig.formatUrl(
                    (media != null && media.isNotEmpty)
                        ? media[0]['original_url'].toString()
                        : '${AppConfig.apiBaseUrl.replaceAll('/api', '')}/storage/${p['image_path']}');

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
                              errorBuilder: (context, error, stack) => const Center(
                                  child: Icon(Icons.broken_image, size: 100)),
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
                          errorBuilder: (context, error, stack) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image)),
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
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
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
              builder: (context) =>
                  AddCustomerPortfolioScreen(customerId: widget.customer['id']),
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
              final date = DateHelper.formatDate(tx['created_at']);
              final items = tx['items'] as List? ?? [];
              final portfolios = tx['portfolios'] as List? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(tx['transaction_number'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(date),
                      trailing: Text(
                          _currencyFormat.format(double.tryParse(tx['final_amount'].toString()) ?? 0.0),
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Items:',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          ...items.map((it) {
                            final name = it['item'] != null
                                ? (it['item']['name'] ?? 'Item')
                                : (it['name'] ?? 'Item');
                            final employeesList = it['employees'] as List? ?? [];
                            final employees = employeesList.map((e) {
                              if (e is Map) {
                                return e['full_name'] ?? e['name'] ?? 'Staff';
                              }
                              return e?.toString() ?? 'Staff';
                            }).join(', ');
                            final qty = double.tryParse(it['quantity'].toString()) ?? 1.0;
                            final qtyString = qty == qty.toInt() ? qty.toInt().toString() : qty.toString();
                            final nailistText = employees.isNotEmpty ? ' (Nailist: $employees)' : '';
                            return Text('• $name x$qtyString$nailistText');
                          }),
                          const SizedBox(height: 8),
                          if (portfolios.isNotEmpty) ...[
                            const Text('Photos from this visit:',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.pink)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: portfolios.length,
                                itemBuilder: (context, pIdx) {
                                  final p = portfolios[pIdx];
                                  final media =
                                      p['media'] as List? ?? [];
                                  if (media.isEmpty) return const SizedBox();

                                  return Row(
                                    children: media
                                        .map((m) => Container(
                                              margin: const EdgeInsets.only(
                                                  right: 8),
                                              width: 100,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      AppConfig.formatUrl(
                                                          m['original_url'])),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ))
                                        .toList(),
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
