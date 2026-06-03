import 'package:flutter/material.dart';
import '../../services/pos_service.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../../utils/responsive.dart';
import '../../widgets/adaptive_split_layout.dart';

int? _safeParseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double _safeParseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

class ServiceTreatmentListScreen extends StatefulWidget {
  const ServiceTreatmentListScreen({super.key});

  @override
  State<ServiceTreatmentListScreen> createState() => _ServiceTreatmentListScreenState();
}

class _ServiceTreatmentListScreenState extends State<ServiceTreatmentListScreen> {
  final _posService = PosService();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  int? _selectedCategoryId;

  Map<String, dynamic>? _selectedService;
  bool _isAddingService = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
    });

    final results = await Future.wait([
      _posService.getMasterServices(),
      _posService.getServiceCategories(),
    ]);

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _services = results[0];
          _categories = results[1].where((c) => c['is_active'] == 1 || c['is_active'] == true).toList();
          _isLoading = false;
          
          if (Responsive.isTablet(context) && _services.isNotEmpty) {
            final filtered = _selectedCategoryId == null 
                ? _services 
                : _services.where((s) => _safeParseInt(s['service_category_id']) == _selectedCategoryId).toList();
            
            if (filtered.isNotEmpty) {
              if (!_isAddingService && _selectedService == null) {
                _selectedService = filtered.first;
              } else if (_selectedService != null) {
                final index = filtered.indexWhere((s) => s['id'] == _selectedService!['id']);
                if (index != -1) {
                  _selectedService = filtered[index];
                } else {
                  _selectedService = filtered.first;
                }
              }
            }
          }
        });
      }
    });
  }

  Future<void> _saveMasterService(Map<String, dynamic> data, {int? id}) async {
    final result = await _posService.saveMasterService(data, id: id);
    if (result != null) {
      if (Responsive.isTablet(context)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treatment saved successfully', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isAddingService = false;
            });
            _loadData();
          }
        });
      } else {
        _loadData();
      }
    }
  }

  Future<void> _showServiceDialog({Map<String, dynamic>? service}) async {
    final nameController = TextEditingController(text: service?['name'] ?? '');
    final priceController = TextEditingController(text: service?['price']?.toString() ?? '');
    
    int? selectedCategoryId = _safeParseInt(service?['service_category_id'] ?? _selectedCategoryId);
    bool isActive = service?['is_active'] == 1 || service?['is_active'] == true;
    bool isVariablePrice = service?['is_variable_price'] == 1 || service?['is_variable_price'] == true;
    
    if (service == null) {
      isActive = true;
      isVariablePrice = false;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(service == null ? 'Add Treatment' : 'Edit Treatment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                SwitchListTile(
                  title: const Text('Active Status'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                  dense: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _categories.any((c) => c['id'] == selectedCategoryId) ? selectedCategoryId : null,
                  hint: const Text('Select Category'),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c['id'] as int,
                    child: Text(c['name']),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                  decoration: const InputDecoration(labelText: 'Treatment Category'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 16),
                if (!isVariablePrice)
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price (Rp) *'),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Variable Price'),
                  subtitle: const Text('User will input price at POS'),
                  value: isVariablePrice,
                  onChanged: (val) => setDialogState(() => isVariablePrice = val),
                  dense: true,
                ),
              ],
            ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || (priceController.text.isEmpty && !isVariablePrice) || selectedCategoryId == null) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all mandatory fields (*)')));
                   return;
                }
                final data = {
                  'name': nameController.text,
                  'price': isVariablePrice ? 0 : _safeParseDouble(priceController.text),
                  'service_category_id': selectedCategoryId,
                  'is_active': isActive,
                  'is_variable_price': isVariablePrice,
                };
                await _saveMasterService(data, id: service?['id']);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    final filteredServices = _selectedCategoryId == null 
        ? _services 
        : _services.where((s) => _safeParseInt(s['service_category_id']) == _selectedCategoryId).toList();

    final listWidget = Column(
      children: [
        if (!_isLoading && _categories.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final category = isAll ? null : _categories[index - 1];
                final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == category!['id'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(isAll ? 'All' : category!['name']),
                    selected: isSelected,
                    onSelected: (val) {
                      if (mounted) {
                        setState(() {
                          _selectedCategoryId = isAll ? null : category!['id'];
                          
                          if (isTablet) {
                            final freshFiltered = _selectedCategoryId == null 
                                ? _services 
                                : _services.where((s) => _safeParseInt(s['service_category_id']) == _selectedCategoryId).toList();
                            if (freshFiltered.isNotEmpty) {
                              _selectedService = freshFiltered.first;
                              _isAddingService = false;
                            } else {
                              _selectedService = null;
                            }
                          }
                        });
                      }
                    },
                    selectedColor: AppTheme.accentColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.accentColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredServices.isEmpty
                  ? const Center(child: Text('No treatments found.'))
                  : ListView.builder(
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final s = filteredServices[index];
                        final bool isActive = s['is_active'] == 1 || s['is_active'] == true;
                        final isSelected = _selectedService != null && _selectedService!['id'] == s['id'] && !_isAddingService;

                        return Container(
                          color: (isTablet && isSelected) ? Colors.pink[50] : null,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (isTablet) {
                                if (mounted) {
                                  setState(() {
                                    _selectedService = s;
                                    _isAddingService = false;
                                  });
                                }
                              } else {
                                _showServiceDialog(service: s);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('${s['service_category']?['name'] ?? 'N/A'} • ${isActive ? 'Active' : 'Inactive'}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(_safeParseDouble(s['price'])),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );

    Widget? detailWidget;
    if (_isAddingService) {
      detailWidget = KeyedSubtree(
        key: const ValueKey('add_service_pane'),
        child: _TreatmentDetailPane(
          categories: _categories,
          onSave: (data, {id}) => _saveMasterService(data, id: id),
          onCancel: () {
            if (mounted) {
              setState(() {
                _isAddingService = false;
                if (filteredServices.isNotEmpty) {
                  _selectedService = filteredServices.first;
                }
              });
            }
          },
        ),
      );
    } else if (_selectedService != null) {
      detailWidget = KeyedSubtree(
        key: ValueKey('view_service_${_selectedService!['id']}'),
        child: _TreatmentDetailPane(
          service: _selectedService,
          categories: _categories,
          onSave: (data, {id}) => _saveMasterService(data, id: id),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Treatments'), elevation: 0),
      body: AdaptiveSplitLayout(
        master: listWidget,
        detail: isTablet ? detailWidget : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isTablet) {
            if (mounted) {
              setState(() {
                _selectedService = null;
                _isAddingService = true;
              });
            }
          } else {
            _showServiceDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TreatmentDetailPane extends StatefulWidget {
  final Map<String, dynamic>? service;
  final List<Map<String, dynamic>> categories;
  final Future<void> Function(Map<String, dynamic> data, {int? id}) onSave;
  final VoidCallback? onCancel;

  const _TreatmentDetailPane({
    super.key,
    this.service,
    required this.categories,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<_TreatmentDetailPane> createState() => _TreatmentDetailPaneState();
}

class _TreatmentDetailPaneState extends State<_TreatmentDetailPane> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  bool _controllersInitialized = false;
  
  int? _selectedCategoryId;
  bool _isActive = true;
  bool _isVariablePrice = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  @override
  void didUpdateWidget(covariant _TreatmentDetailPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service?['id'] != widget.service?['id']) {
      _initFields();
    }
  }

  void _initFields() {
    final nameText = widget.service?['name'] ?? '';
    final priceText = widget.service?['price']?.toString() ?? '';

    if (_controllersInitialized) {
      _nameController.text = nameText;
      _priceController.text = priceText;
    } else {
      _nameController = TextEditingController(text: nameText);
      _priceController = TextEditingController(text: priceText);
      _controllersInitialized = true;
    }

    final categoryId = _safeParseInt(widget.service?['service_category_id']);
    _selectedCategoryId = widget.categories.any((c) => c['id'] == categoryId) ? categoryId : null;

    _isActive = widget.service?['is_active'] == 1 || widget.service?['is_active'] == true;
    _isVariablePrice = widget.service?['is_variable_price'] == 1 || widget.service?['is_variable_price'] == true;
    
    if (widget.service == null) {
      _isActive = true;
      _isVariablePrice = false;
    }
  }

  @override
  void dispose() {
    if (_controllersInitialized) {
      _nameController.dispose();
      _priceController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service == null ? 'Add New Treatment' : 'Edit Treatment Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D0026),
                  ),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Active Status'),
                  subtitle: const Text('Active treatments will show up in checkout'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: AppTheme.accentColor,
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(height: 24),
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  hint: const Text('Select Category'),
                  items: widget.categories.map((c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['name']),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  decoration: const InputDecoration(
                    labelText: 'Treatment Category *',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (val) => val == null ? 'Category is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Treatment Name *',
                    hintText: 'e.g., Pedicure Signature',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                if (!_isVariablePrice)
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price (Rp) *',
                      hintText: 'e.g., 50000',
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Price is required';
                      if (double.tryParse(value) == null) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Is Variable Price'),
                  subtitle: const Text('Price will be specified at POS check out'),
                  value: _isVariablePrice,
                  onChanged: (val) => setState(() => _isVariablePrice = val),
                  activeColor: AppTheme.accentColor,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (widget.onCancel != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onCancel,
                          child: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('SAVE TREATMENT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        'name': _nameController.text.trim(),
        'price': _isVariablePrice ? 0 : _safeParseDouble(_priceController.text),
        'service_category_id': _selectedCategoryId,
        'is_active': _isActive,
        'is_variable_price': _isVariablePrice,
      };
      await widget.onSave(data, id: widget.service?['id']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
