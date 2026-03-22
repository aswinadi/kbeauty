import 'package:flutter/material.dart';
import '../../services/pos_service.dart';

class ServiceCategoryListScreen extends StatefulWidget {
  const ServiceCategoryListScreen({super.key});

  @override
  State<ServiceCategoryListScreen> createState() => _ServiceCategoryListScreenState();
}

class _ServiceCategoryListScreenState extends State<ServiceCategoryListScreen> {
  final _posService = PosService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    final results = await _posService.getServiceCategories();
    setState(() {
      _categories = results;
      _isLoading = false;
    });
  }

  Future<void> _showCategoryDialog({Map<String, dynamic>? category}) async {
    final nameController = TextEditingController(text: category?['name'] ?? '');
    bool isActive = category?['is_active'] == 1 || category?['is_active'] == true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active Status'),
                value: isActive,
                onChanged: (val) => setDialogState(() => isActive = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final data = {
                  'name': nameController.text,
                  'is_active': isActive,
                };
                final result = await _posService.saveServiceCategory(data, id: category?['id']);
                if (result != null) {
                  _fetchCategories();
                  Navigator.pop(context);
                }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Treatment Categories')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text('No categories found.'))
              : ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final bool isActive = cat['is_active'] == 1 || cat['is_active'] == true;
                    return ListTile(
                      title: Text(cat['name']),
                      subtitle: Text('Status: ${isActive ? 'Active' : 'Inactive'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${cat['services_count'] ?? 0} Treatments', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _showCategoryDialog(category: cat),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
