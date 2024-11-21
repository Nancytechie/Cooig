import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

Future<bool> _requestLocationPermission() async {
  var status = await Permission.location.request();
  if (status.isGranted) {
    return true; // Permission granted
  } else if (status.isDenied) {
    // Permission denied
    return false;
  } else if (status.isPermanentlyDenied) {
    // Permission permanently denied, open app settings
    await openAppSettings();
    return false;
  }
  return false;
}

Future<Position?> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, return null
    return null;
  }

  // Check location permission
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permission denied, return null
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, return null
    return null;
  }

  // Get the current position
  return await Geolocator.getCurrentPosition();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    bool hasPermission = await _requestLocationPermission();
    if (hasPermission) {
      Position? position = await _getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Location')),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 14.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: _currentLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: _currentLocation!,
                      ),
                    }
                  : {},
            ),
    );
  }
}
