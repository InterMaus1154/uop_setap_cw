import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/category.dart';
import '../models/pin_form_data.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class PinCreationSheet extends StatefulWidget {
  final LatLng location;
  final List<Category> categories;
  final List<CategoryLevel> categoryLevels;
  final List<SubCategory> subCategories;
  final Function(PinFormData, XFile?) onSubmit;

  const PinCreationSheet({
    super.key,
    required this.location,
    required this.categories,
    required this.categoryLevels,
    required this.subCategories,
    required this.onSubmit,
  });

  @override
  State<PinCreationSheet> createState() => _PinCreationSheetState();
}

class _PinCreationSheetState extends State<PinCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  XFile? _selectedImage;

  List<SubCategory> get _filteredSubCategories {
    if (_selectedCategory == null) return [];
    return widget.subCategories
        .where((sub) => sub.catId == _selectedCategory!.catId)
        .toList();
  }

  int? get _ttlMinutes {
    if (_selectedCategory == null) return null;
    try {
      final level = widget.categoryLevels.firstWhere(
        (l) => l.catLevelId == _selectedCategory!.catLevelId,
      );
      return level.catLevelTtlMins;
    } catch (e) {
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
      final ttl = _ttlMinutes;
      if (ttl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine pin expiry time')),
        );
        return;
      }
      final formData = PinFormData(
        catId: _selectedCategory!.catId,
        subCatId: _selectedSubCategory?.subCatId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        ttlMinutes: ttl,
      );
      widget.onSubmit(formData, _selectedImage);
    }
  }

  /// Show a bottom sheet letting the user pick from gallery or camera
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            // Camera option — not available on web
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  /// Build the image picker button and preview
  Widget _buildImagePicker() {
    if (_selectedImage != null) {
      // Show preview with a remove button
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attached Photo',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                // Read bytes from XFile — works on both web and mobile
                child: FutureBuilder<Uint8List>(
                  future: _selectedImage!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 160,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return Image.memory(
                      snapshot.data!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              // Remove image button
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImage = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // No image selected — show the add photo button
    return OutlinedButton.icon(
      onPressed: _showImageSourcePicker,
      icon: const Icon(Icons.add_a_photo),
      label: const Text('Add Photo (optional)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[700],
        side: BorderSide(color: Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = Provider.of<UserProvider>(
      context,
      listen: false,
    ).isLoggedIn;
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
              // Top bar with drag handle and menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                  if (isLoggedIn)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        // TODO: Handle menu actions (report, etc.)
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Text('Report'),
                        ),
                      ],
                    ),
                ],
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
                items: widget.categories.map((cat) {
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

              // Subcategory dropdown
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
              const SizedBox(height: 16),

              // Image picker — browse gallery or take a photo
              _buildImagePicker(),
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
