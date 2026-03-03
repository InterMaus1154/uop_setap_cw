import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/pin_form_data.dart';
import '../models/pin.dart';
import '../providers/friend_provider.dart';
import '../providers/location_provider.dart';
import '../services/api_service.dart';
import '../widgets/pin_creation_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();

  // Hold a reference so we can safely call stopPolling() in dispose
  // (context.read is not safe after the widget is deactivated)
  late final LocationProvider _locationProvider;

  // Pins from API
  List<Pin> _pins = [];
  bool _isLoadingPins = true;

  @override
  void initState() {
    super.initState();
    _loadPins();
    _loadCategories();

    // Initialise location provider and start polling for friend positions
    // Use addPostFrameCallback to avoid notifyListeners() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationProvider = context.read<LocationProvider>();
      _locationProvider.init();
      _locationProvider.startPolling();
    });
  }

  Future<void> _loadPins({
    List<int>? catIds,
    List<int>? catLevelIds,
    DateTime? pinExpireAt,
  }) async {
    try {
      final results = await _apiService.getPins(
        catIds: catIds,
        catLevelIds: catLevelIds,
        pinExpireAt: pinExpireAt,
      );
      if (!mounted) return;
      setState(() {
        _pins = results;
        _isLoadingPins = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isLoadingPins = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load pins: $e')));
      }
    }
  }

  void _showPinDetails(Pin pin) {
    // Don't open details while placing a new pin
    if (_isPlacingPin) return;

    // Look up category and subcategory names
    final catName = _categories
        .where((c) => c.catId == pin.catId)
        .map((c) => c.catName)
        .firstOrNull;
    final subCatName = pin.subCatId != null
        ? _subCategories
              .where((s) => s.subCatId == pin.subCatId)
              .map((s) => s.subCatName)
              .firstOrNull
        : null;

    // Track state outside the builder so it persists across rebuilds
    final pinIndex = _pins.indexWhere((p) => p.pinId == pin.pinId);
    int? reaction = pin.userReaction;
    int likes = pin.pinLikes;
    int dislikes = pin.pinDislikes;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> handleReaction(int value) async {
            try {
              if (reaction == value) {
                // Remove reaction
                await _apiService.deletePinReaction(pin.pinId);
                setModalState(() {
                  if (value == 1) likes--;
                  if (value == -1) dislikes--;
                  reaction = null;
                });
              } else {
                await _apiService.reactToPin(pin.pinId, value);
                setModalState(() {
                  if (reaction == 1) likes--;
                  if (reaction == -1) dislikes--;
                  if (value == 1) likes++;
                  if (value == -1) dislikes++;
                  reaction = value;
                });
              }
              // Sync updated state back to the _pins list
              if (pinIndex != -1) {
                setState(() {
                  _pins[pinIndex] = Pin(
                    pinId: pin.pinId,
                    catId: pin.catId,
                    subCatId: pin.subCatId,
                    userId: pin.userId,
                    pinTitle: pin.pinTitle,
                    pinDescription: pin.pinDescription,
                    pinPicturePath: pin.pinPicturePath,
                    pinLatitude: pin.pinLatitude,
                    pinLongitude: pin.pinLongitude,
                    pinIsActive: pin.pinIsActive,
                    pinExpireAt: pin.pinExpireAt,
                    createdAt: pin.createdAt,
                    pinColorHex: pin.pinColorHex,
                    pinAuthorName: pin.pinAuthorName,
                    pinLikes: likes,
                    pinDislikes: dislikes,
                    userReaction: reaction,
                  );
                });
              }
            } on ApiException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reaction failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  pin.pinTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (catName != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          catName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: pin.pinColor.withAlpha(30),
                        side: BorderSide(color: pin.pinColor.withAlpha(80)),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (subCatName != null)
                        Chip(
                          label: Text(
                            subCatName,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey[100],
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                if (catName != null) const SizedBox(height: 8),
                if (pin.pinDescription != null &&
                    pin.pinDescription!.isNotEmpty)
                  Text(
                    pin.pinDescription!,
                    style: const TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Posted by ${pin.pinAuthorName ?? 'Unknown'}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatExpiry(pin.pinExpireAt),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Like/Dislike stats and buttons
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up,
                        color: reaction == 1 ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () => handleReaction(1),
                    ),
                    Text('$likes'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        Icons.thumb_down,
                        color: reaction == -1 ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => handleReaction(-1),
                    ),
                    Text('$dislikes'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatExpiry(DateTime expireAt) {
    final now = DateTime.now();
    final diff = expireAt.difference(now);
    if (diff.isNegative) return 'Expired';
    if (diff.inMinutes < 60) return 'Expires in ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      final mins = diff.inMinutes % 60;
      if (mins == 0) return 'Expires in ${diff.inHours} hr';
      return 'Expires in ${diff.inHours} hr $mins min';
    }
    return 'Expires in ${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
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

  // Active filter selections
  List<int> _activeCategoryIds = [];
  List<int> _activeCategoryLevelIds = [];
  DateTime? _activeExpiryDate;

  String _formatFilterDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  // Track which friend marker is tapped to show their name tooltip
  int? _selectedFriendUserId;

  @override
  void dispose() {
    // Stop polling when leaving the map screen
    _locationProvider.stopPolling();
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
    // Dismiss any open friend tooltip
    if (_selectedFriendUserId != null) {
      setState(() => _selectedFriendUserId = null);
    }
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
    // Watch location provider so the map rebuilds when friend positions update
    final locationProvider = context.watch<LocationProvider>();
    final friendProvider = context.read<FriendProvider>();

    // Build friend markers from the polled locations
    final friendMarkers = <Marker>[];
    for (final loc in locationProvider.friendLocations) {
      if (!loc.isEnabled) continue;

      // Resolve the friend's name from the cache (or fetch it)
      final cachedUser = friendProvider.userCache[loc.userId];
      final displayName = cachedUser != null
          ? (cachedUser.displayName ?? cachedUser.firstName)
          : '?';
      final initial = displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : '?';

      // Kick off a background resolve if we don't have this user cached yet
      if (cachedUser == null) {
        friendProvider.resolveUser(loc.userId).then((_) {
          if (mounted) setState(() {});
        });
      }

      friendMarkers.add(
        Marker(
          point: LatLng(loc.latitude, loc.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              setState(() {
                // Toggle tooltip: tap again to dismiss
                _selectedFriendUserId = _selectedFriendUserId == loc.userId
                    ? null
                    : loc.userId;
              });
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Friend avatar circle with their initial
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.teal,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Tooltip popup showing the friend's name
                if (_selectedFriendUserId == loc.userId)
                  Positioned(
                    bottom: 40,
                    left: -30,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

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
                  for (final pin in _pins.where(
                    (p) => p.pinExpireAt.isAfter(DateTime.now()),
                  ))
                    Marker(
                      point: LatLng(pin.pinLatitude, pin.pinLongitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showPinDetails(pin),
                        child: Icon(
                          Icons.location_on,
                          color: pin.pinColor, // implemented colour by cat
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
              // Friend location markers — separate layer so they render on top of pins
              if (friendMarkers.isNotEmpty) MarkerLayer(markers: friendMarkers),
            ],
          ),

          // Loading indicator for pins
          if (_isLoadingPins)
            const Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: Colors.blue),
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
            // Location sharing toggle (bottom-left)
            Positioned(
              bottom: 32,
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 'shareLocation',
                backgroundColor: locationProvider.isSharingEnabled
                    ? Colors.teal
                    : Colors.white,
                onPressed: () async {
                  await locationProvider.toggleSharing();
                  if (context.mounted && locationProvider.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(locationProvider.error!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                tooltip: locationProvider.isSharingEnabled
                    ? 'Stop sharing location'
                    : 'Share my location',
                child: Icon(
                  locationProvider.isSharingEnabled
                      ? Icons.location_on
                      : Icons.location_off,
                  color: locationProvider.isSharingEnabled
                      ? Colors.white
                      : Colors.grey,
                ),
              ),
            ),
            //Pin Filter button
            Positioned(
              top: 60,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'filter',
                backgroundColor: Colors.white,
                onPressed: () {
                  _showPinFilterDialog();
                },
                child: const Icon(Icons.filter_list, color: Colors.blue),
              ),
            ),
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

  void _showPinFilterDialog() {
    // Initialize with current active filters
    List<int> selectedCategoryIds = List.from(_activeCategoryIds);
    List<int> selectedCategoryLevelIds = List.from(_activeCategoryLevelIds);
    DateTime? selectedExpiryDate = _activeExpiryDate;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 600,
                ),
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Filter Pins',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Categories',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_categories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No categories available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ...(_categories.map((cat) {
                            final isSelected = selectedCategoryIds.contains(
                              cat.catId,
                            );
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                cat.catName,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedCategoryIds.add(cat.catId);
                                  } else {
                                    selectedCategoryIds.remove(cat.catId);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          })),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Maximum Expiry Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: selectedExpiryDate ?? now,
                                    firstDate: DateTime(now.year - 1),
                                    lastDate: DateTime(now.year + 10),
                                  );
                                  if (pickedDate != null) {
                                    setDialogState(() {
                                      selectedExpiryDate = pickedDate;
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                ),
                                label: Text(
                                  selectedExpiryDate == null
                                      ? 'Show pins expiring on/before...'
                                      : 'On/before ${_formatFilterDate(selectedExpiryDate!)}',
                                ),
                              ),
                            ),
                            if (selectedExpiryDate != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Clear date',
                                onPressed: () {
                                  setDialogState(() {
                                    selectedExpiryDate = null;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Select Category Levels',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_categoryLevels.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No category levels available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ...(_categoryLevels.map((level) {
                            final isSelected = selectedCategoryLevelIds
                                .contains(level.catLevelId);
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                level.catLevelName,
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedCategoryLevelIds.add(
                                      level.catLevelId,
                                    );
                                  } else {
                                    selectedCategoryLevelIds.remove(
                                      level.catLevelId,
                                    );
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          })),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // Clear all filters
                        _applyFilters(null, null, null);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _applyFilters(
                          selectedCategoryIds.isEmpty
                              ? null
                              : selectedCategoryIds,
                          selectedCategoryLevelIds.isEmpty
                              ? null
                              : selectedCategoryLevelIds,
                          selectedExpiryDate,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _applyFilters(
    List<int>? categoryIds,
    List<int>? categoryLevelIds,
    DateTime? expiryDate,
  ) {
    setState(() {
      _isLoadingPins = true;
      // Store the active filters
      _activeCategoryIds = categoryIds ?? [];
      _activeCategoryLevelIds = categoryLevelIds ?? [];
      _activeExpiryDate = expiryDate;
    });
    _loadPins(
      catIds: categoryIds,
      catLevelIds: categoryLevelIds,
      pinExpireAt: expiryDate,
    );
  }
}
