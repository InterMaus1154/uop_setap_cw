import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'user_selection_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // University of Portsmouth campus coordinates
  static const LatLng _campusCenter = LatLng(50.797864, -1.098353);
  static const double _defaultZoom = 16.0;

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
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusconnect.app',
              ),
              // Markers will go here when backend is ready
              const MarkerLayer(markers: []),
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
                    onPressed: () {
                      context.read<UserProvider>().logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
          // Add pin button (placeholder for now)
          Positioned(
            bottom: 32,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'addPin',
              backgroundColor: Colors.blue,
              onPressed: () {
                // TODO: Implement pin creation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pin creation coming soon!')),
                );
              },
              child: const Icon(Icons.add_location_alt, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
