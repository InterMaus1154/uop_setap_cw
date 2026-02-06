import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/category.dart';
import '../models/pin_form_data.dart';

class PinCreationSheet extends StatefulWidget {
  final LatLng location;
  final Function(PinFormData) onSubmit;

  const PinCreationSheet({
    super.key,
    required this.location,
    required this.onSubmit,
  });

  @override
  State<PinCreationSheet> createState() => _PinCreationSheetState();
}

class _PinCreationSheetState extends State<PinCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Hardcoded for now — will fetch from API later
  final List<CategoryLevel> _categoryLevels = [
    CategoryLevel(catLevelId: 1, catLevelName: 'Danger', catLevelTtlMins: 60),
    CategoryLevel(
      catLevelId: 2,
      catLevelName: 'Information',
      catLevelTtlMins: 120,
    ),
    CategoryLevel(catLevelId: 3, catLevelName: 'Level 3', catLevelTtlMins: 180),
  ];

  final List<Category> _categories = [
    Category(catId: 1, catLevelId: 1, catName: 'Theft'),
    Category(catId: 2, catLevelId: 2, catName: 'Anti-Social Behaviour'),
    Category(catId: 3, catLevelId: 3, catName: 'Assault'),
  ];

  final List<SubCategory> _subCategories = [
    SubCategory(subCatId: 1, catId: 1, subCatName: 'Burglary'),
    SubCategory(subCatId: 2, catId: 1, subCatName: 'Mugging'),
    SubCategory(subCatId: 3, catId: 2, subCatName: 'Street'),
    SubCategory(subCatId: 4, catId: 2, subCatName: 'Park'),
    SubCategory(subCatId: 5, catId: 3, subCatName: 'Physical'),
    SubCategory(subCatId: 6, catId: 3, subCatName: 'Verbal'),
  ];

  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;

  List<SubCategory> get _filteredSubCategories {
    if (_selectedCategory == null) return [];
    return _subCategories
        .where((sub) => sub.catId == _selectedCategory!.catId)
        .toList();
  }

  int? get _ttlMinutes {
    if (_selectedCategory == null) return null;
    try {
      final level = _categoryLevels.firstWhere(
        (l) => l.catLevelId == _selectedCategory!.catLevelId,
      );
      return level.catLevelTtlMins;
    } catch (e) {
      // No matching level found — data inconsistency
      return null;
    }
  }

  String get _expiryText {
    final ttl = _ttlMinutes;
    if (ttl == null) return '';
    if (ttl >= 60) {
      final hours = ttl ~/ 60;
      final mins = ttl % 60;
      if (mins == 0) return 'Expires in $hours hour${hours > 1 ? 's' : ''}';
      return 'Expires in $hours hr $mins min';
    }
    return 'Expires in $ttl minutes';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final formData = PinFormData(
        catId: _selectedCategory!.catId,
        subCatId: _selectedSubCategory?.subCatId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        ttlMinutes: _ttlMinutes!,
      );
      widget.onSubmit(formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Create Pin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: ${widget.location.latitude.toStringAsFixed(5)}, ${widget.location.longitude.toStringAsFixed(5)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Category dropdown
              DropdownButtonFormField<Category>(
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.catName));
                }).toList(),
                onChanged: (cat) {
                  setState(() {
                    _selectedCategory = cat;
                    _selectedSubCategory = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // Subcategory dropdown (only if category selected)
              if (_filteredSubCategories.isNotEmpty) ...[
                DropdownButtonFormField<SubCategory>(
                  key: ValueKey(_selectedCategory?.catId),
                  decoration: const InputDecoration(
                    labelText: 'Subcategory (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _filteredSubCategories.map((sub) {
                    return DropdownMenuItem(
                      value: sub,
                      child: Text(sub.subCatName),
                    );
                  }).toList(),
                  onChanged: (sub) =>
                      setState(() => _selectedSubCategory = sub),
                ),
                const SizedBox(height: 16),
              ],

              // Expiry info
              if (_selectedCategory != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        _expiryText,
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Title field
              TextFormField(
                controller: _titleController,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  hintText: 'Brief description of the incident',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLength: 300,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add more details...',
                ),
              ),
              const SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Create Pin', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
