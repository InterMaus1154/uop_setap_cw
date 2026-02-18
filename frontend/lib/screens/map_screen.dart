import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/pin_form_data.dart';
import '../models/pin.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/pin_creation_sheet.dart';
import 'user_selection_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();

  // Pins from API
  List<Pin> _pins = [];
  bool _pinsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    try {
      final results = await _apiService.getPins();
      if (!mounted) return;
      setState(() {
        _pins = results;
        _pinsLoaded = true;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load pins: $e')));
      }
    }
  }

  void _showPinDetails(Pin pin) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pin.pinTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (pin.pinDescription != null) Text(pin.pinDescription!),
            const SizedBox(height: 8),
            Text('Posted by user ${pin.userId}'),
            const SizedBox(height: 8),
            Text('Expires: ${pin.pinExpireAt.toLocal()}'),
          ],
        ),
      ),
    );
  }

  // University of Portsmouth campus coordinates
  static const LatLng _campusCenter = LatLng(50.797864, -1.098353);
  static const double _defaultZoom = 16.0;

  bool _isPlacingPin = false;
  LatLng? _selectedLocation;

  // Category data from API
  List<Category> _categories = [];
  List<CategoryLevel> _categoryLevels = [];
  List<SubCategory> _subCategories = [];
  bool _categoriesLoaded = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Fetch categories, levels, and subcategories from API
  Future<void> _loadCategories() async {
    if (_categoriesLoaded) return;
    try {
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getCategoryLevels(),
        _apiService.getSubCategories(),
      ]);
      setState(() {
        _categories = results[0] as List<Category>;
        _categoryLevels = results[1] as List<CategoryLevel>;
        _subCategories = results[2] as List<SubCategory>;
        _categoriesLoaded = true;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  void _enterPinPlacementMode() {
    setState(() {
      _isPlacingPin = true;
      _selectedLocation = null;
    });
  }

  void _exitPinPlacementMode() {
    setState(() {
      _isPlacingPin = false;
      _selectedLocation = null;
    });
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    if (_isPlacingPin) {
      setState(() => _selectedLocation = location);
    }
  }

  Future<void> _confirmLocationAndShowForm() async {
    if (_selectedLocation == null) return;

    // Load categories if not already loaded
    await _loadCategories();
    if (!_categoriesLoaded || !mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinCreationSheet(
        location: _selectedLocation!,
        categories: _categories,
        categoryLevels: _categoryLevels,
        subCategories: _subCategories,
        onSubmit: _handlePinSubmit,
      ),
    );
  }

  Future<void> _handlePinSubmit(PinFormData formData) async {
    // Close the bottom sheet
    Navigator.pop(context);

    try {
      await _apiService.createPin(formData);
      await _loadPins();

      if (mounted) {
        _exitPinPlacementMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pin "${formData.title}" created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create pin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _campusCenter,
              initialZoom: _defaultZoom,
              minZoom: 10,
              maxZoom: 18,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusconnect.app',
              ),
              // Show API pins and selected location during placement
              MarkerLayer(
                markers: [
                  for (final pin in _pins)
                    Marker(
                      point: LatLng(pin.pinLatitude, pin.pinLongitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showPinDetails(pin),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 36,
                        ),
                      ),
                    ),
                  if (_selectedLocation != null)
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top bar with user info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(150), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Welcome, ${user?.firstName ?? "User"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      await context.read<UserProvider>().logout();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserSelectionScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Pin placement mode UI
          if (_isPlacingPin) ...[
            // Instruction banner
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap on the map to place your pin',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cancel button
            Positioned(
              bottom: 100,
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 'cancelPin',
                backgroundColor: Colors.white,
                onPressed: _exitPinPlacementMode,
                child: const Icon(Icons.close, color: Colors.red),
              ),
            ),

            // Confirm button (only if location selected)
            if (_selectedLocation != null)
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: _confirmLocationAndShowForm,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],

          // Normal mode buttons (hidden during pin placement)
          if (!_isPlacingPin) ...[
            // Recenter button
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: Colors.white,
                onPressed: () {
                  _mapController.move(_campusCenter, _defaultZoom);
                },
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),
            // Add pin button
            Positioned(
              bottom: 32,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'addPin',
                backgroundColor: Colors.blue,
                onPressed: _enterPinPlacementMode,
                child: const Icon(Icons.add_location_alt, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
