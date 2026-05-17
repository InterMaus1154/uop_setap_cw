import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/category.dart';
import '../models/pin_form_data.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';

class PinCreationSheet extends StatefulWidget {
  final LatLng location;
  final List<Category> categories;
  final List<CategoryLevel> categoryLevels;
  final List<SubCategory> subCategories;
  final Function(PinFormData, XFile?) onSubmit;

  // Optional: if a pinId is passed, the sheet is in "view" mode and can report
  final int? pinId;

  const PinCreationSheet({
    super.key,
    required this.location,
    required this.categories,
    required this.categoryLevels,
    required this.subCategories,
    required this.onSubmit,
    this.pinId,
  });

  @override
  State<PinCreationSheet> createState() => _PinCreationSheetState();
}

class _PinCreationSheetState extends State<PinCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  XFile? _selectedImage;
  DateTime? _customExpiry;
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _fetchLocationName();
  }

  Future<void> _fetchLocationName() async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${widget.location.latitude}&lon=${widget.location.longitude}&format=json',
      );
      final response = await http.get(uri, headers: {'User-Agent': 'campus_connect'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null && mounted) {
          final street = addr['road'] as String?;
          final city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county']) as String?;
          setState(() {
            _locationName = [street, city]
              .where((s) => s != null && s!.isNotEmpty)
              .join(', ');
          });
        }
      }
    } catch (_) {}
  }

  // Report type labels shown in the menu mapped to backend values
  static const Map<String, String> _reportTypes = {
    'Inaccurate': 'inaccurate',
    'Resolved': 'resolved',
    'Duplicate': 'duplicate',
  };

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
        customExpiry: _customExpiry,
      );
      widget.onSubmit(formData, _selectedImage);
    }
  }

  /// Show a dialog letting the user pick a report type then send to backend
  Future<void> _showReportDialog() async {
    final pinId = widget.pinId;
    if (pinId == null) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Report Pin'),
        children: _reportTypes.entries.map((entry) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, entry.value),
            child: Text(entry.key),
          );
        }).toList(),
      ),
    );

    if (selected == null || !mounted) return;

    try {
      await _apiService.reportPin(pinId, selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pin reported successfully')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickCustomExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate:
          _customExpiry ?? now.add(Duration(minutes: _ttlMinutes ?? 60)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: TimeOfDay.fromDateTime(
        _customExpiry ?? now.add(Duration(minutes: _ttlMinutes ?? 60)),
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _customExpiry = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

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

  Widget _buildImagePicker() {
    if (_selectedImage != null) {
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
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
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
              // Top bar with drag handle and ... menu
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
                  // Only show the ... menu for logged-in users viewing an existing pin
                  if (isLoggedIn && widget.pinId != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'report') {
                          _showReportDialog();
                        }
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
                'Location: ${_locationName ?? '${widget.location.latitude.toStringAsFixed(5)}, ${widget.location.longitude.toStringAsFixed(5)}'}',
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
                    _customExpiry = null;
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

              // Expiry row
              if (_selectedCategory != null && _ttlMinutes != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            _customExpiry != null
                                ? 'Expires: ${_customExpiry!.day}/${_customExpiry!.month}/${_customExpiry!.year} '
                                      '${_customExpiry!.hour.toString().padLeft(2, '0')}:${_customExpiry!.minute.toString().padLeft(2, '0')}'
                                : 'Default: ${(_ttlMinutes! / 60).round()} hrs',
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _pickCustomExpiry,
                        child: Text(
                          _customExpiry != null ? 'Change' : 'Set date & time',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

              // Image picker
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
