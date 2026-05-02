import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;

  const ProductDetailScreen({super.key, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _productService = ProductService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _conversionRatioController;
  
  int? _selectedCategoryId;
  int? _selectedUnitId;
  int? _selectedSecondaryUnitId;
  File? _imageFile;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSuperAdmin = false;
  bool _isActive = true;

  List<Category> _categories = [];
  List<Unit> _units = [];

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _conversionRatioController = TextEditingController(
      text: widget.product?.conversionRatio?.toString() ?? ''
    );
    _selectedCategoryId = widget.product?.categoryId;
    _selectedUnitId = widget.product?.unitId;
    _selectedSecondaryUnitId = widget.product?.secondaryUnitId;
    _isActive = widget.product?.isActive ?? true;
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoading = true);
    final results = await Future.wait<dynamic>([
      _productService.getCategories(),
      _productService.getUnits(),
      AuthService().getUser(),
    ]);
    setState(() {
      _categories = results[0] as List<Category>;
      _units = results[1] as List<Unit>;
      final user = results[2] as User?;
      _isSuperAdmin = user?.roles.contains('Super Admin') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 1000,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Category and Unit')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    bool success;
    if (_isEditMode) {
      success = await _productService.updateProduct(
        id: widget.product!.id,
        name: _nameController.text,
        sku: _skuController.text,
        price: _isSuperAdmin ? (double.tryParse(_priceController.text) ?? 0) : null,
        categoryId: _selectedCategoryId!,
        unitId: _selectedUnitId!,
        secondaryUnitId: _selectedSecondaryUnitId,
        conversionRatio: double.tryParse(_conversionRatioController.text),
        imageFile: _imageFile,
        isActive: _isActive,
      );
    } else {
      success = await _productService.createProduct(
        name: _nameController.text,
        sku: _skuController.text.isNotEmpty ? _skuController.text : null,
        price: _isSuperAdmin ? (double.tryParse(_priceController.text) ?? 0) : null,
        categoryId: _selectedCategoryId!,
        unitId: _selectedUnitId!,
        secondaryUnitId: _selectedSecondaryUnitId,
        conversionRatio: double.tryParse(_conversionRatioController.text),
        imageFile: _imageFile,
        isActive: _isActive,
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product ${_isEditMode ? 'updated' : 'created'} successfully')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${_isEditMode ? 'update' : 'create'} product')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Product' : 'New Product', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _saveProduct,
              child: const Text('Save', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo Section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                                  )
                                : widget.product?.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(widget.product!.imageUrl!, fit: BoxFit.cover),
                                      )
                                    : Icon(Icons.inventory_2, size: 56, color: Colors.grey[300]),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: AppTheme.accentColor,
                              shape: const CircleBorder(),
                              elevation: 4,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                onPressed: _showImagePickerOptions,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader('General Information'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Product Name', hintText: 'Enter name'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _skuController,
                      readOnly: _isEditMode,
                      decoration: InputDecoration(
                        labelText: 'SKU',
                        hintText: _isEditMode ? 'SKU (Locked)' : 'Enter SKU (optional)',
                        fillColor: _isEditMode ? Colors.grey[100] : Colors.white,
                        suffixIcon: _isEditMode ? const Icon(Icons.lock_outline, size: 16) : null,
                      ),
                      style: TextStyle(color: _isEditMode ? Colors.grey[600] : Colors.black),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Produk Aktif', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: const Text('Matikan jika produk tidak lagi tersedia', style: TextStyle(fontSize: 12)),
                      value: _isActive,
                      activeColor: AppTheme.accentColor,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isSuperAdmin) ...[
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price', prefixText: 'Rp '),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && double.tryParse(value) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 32),
                    _buildSectionHeader('Unit of Measure'),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<int>(
                      value: _selectedUnitId,
                      items: _units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                      onChanged: (val) => setState(() => _selectedUnitId = val),
                      decoration: const InputDecoration(
                        labelText: 'Primary Unit',
                        helperText: 'Satuan terkecil (misal: Pcs)',
                      ),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int>(
                            value: _selectedSecondaryUnitId,
                            items: [
                              const DropdownMenuItem<int>(value: null, child: Text('Tidak ada')),
                              ..._units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
                            ],
                            onChanged: (val) => setState(() => _selectedSecondaryUnitId = val),
                            decoration: const InputDecoration(labelText: 'Satuan Sekunder'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _conversionRatioController,
                            decoration: const InputDecoration(
                              labelText: 'Rasio', 
                              hintText: 'misal: 12',
                              helperText: 'Isi per Satuan Sekunder',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            enabled: _selectedSecondaryUnitId != null,
                            onChanged: (val) => setState(() {}),
                            validator: (value) {
                              if (_selectedSecondaryUnitId != null) {
                                if (value == null || value.isEmpty) return 'Wajib diisi';
                                if (double.tryParse(value) == null) return 'Angka tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_selectedSecondaryUnitId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aturan Konversi:',
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.blue[800]
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1 ${_units.firstWhere((u) => u.id == _selectedSecondaryUnitId).name} = ${_conversionRatioController.text.isEmpty ? '?' : _conversionRatioController.text} ${_selectedUnitId != null ? _units.firstWhere((u) => u.id == _selectedUnitId).name : 'satuan utama'}',
                                style: TextStyle(fontSize: 13, color: Colors.blue[900], fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Contoh: Jika Anda membeli dalam Dus dan setiap Dus berisi 12 Pcs, pilih Pcs sebagai Satuan Utama dan Dus sebagai Satuan Sekunder, lalu isi 12 sebagai rasio.',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title, 
      style: TextStyle(
        color: AppTheme.primaryColor, 
        fontWeight: FontWeight.bold, 
        fontSize: 13,
        letterSpacing: 0.5
      )
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _conversionRatioController.dispose();
    super.dispose();
  }
}
