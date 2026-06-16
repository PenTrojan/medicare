import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class LocationPickerSheet extends StatefulWidget {
  final GeoPoint? initialLocation;

  const LocationPickerSheet({super.key, this.initialLocation});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  GoogleMapController? _mapController;
  late CameraPosition _currentCameraPosition;
  bool _isLocating = false;

  // Default fallback camera coordinates (e.g., Colombo/Moratuwa regional center)
  static const LatLng _fallbackCenter = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();

    double initialLat =
        widget.initialLocation?.latitude ?? _fallbackCenter.latitude;
    double initialLng =
        widget.initialLocation?.longitude ?? _fallbackCenter.longitude;

    _currentCameraPosition = CameraPosition(
      target: LatLng(initialLat, initialLng),
      zoom: 14.5,
    );
  }

  /// Explicit permission and hardware capture pipeline execution
  Future<void> _moveToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    setState(() => _isLocating = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLatLng, zoom: 16.0),
        ),
      );
    } catch (e) {
      debugPrint("Map location streaming error: $e");
    } finally {
      setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            // 1. Interactive Map Stream Layer Widget
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  // default to center of sri lanka
                  widget.initialLocation?.latitude ?? 7.4863,
                  widget.initialLocation?.longitude ?? 80.3647,
                ),
                zoom: 15,
              ),

              // This forces the map framework to eagerly intercept all gestures
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },

              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                // If no initial location was passed, automatically snap to their location
                if (widget.initialLocation == null) {
                  _moveToCurrentLocation();
                }
              },
              onCameraMove: (position) {
                _currentCameraPosition = position;
              },
            ),

            // 2. Static Centered Pin Dropper Overlay
            Center(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 36.0,
                ), // Adjust for pin asset layout base alignment
                child: Icon(
                  Icons.location_on,
                  size: 44,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),

            // 3. Header Action Control bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton.small(
                    heroTag: "close_map",
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                  const Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        "Pan map to adjust position pin",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance alignment constraints
                ],
              ),
            ),

            // 4. Floating 'Snap to My GPS Location' Control Button
            Positioned(
              right: 16,
              bottom: 100,
              child: FloatingActionButton(
                heroTag: "my_gps_location",
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3B82F6),
                onPressed: _isLocating ? null : _moveToCurrentLocation,
                child: _isLocating
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.my_location),
              ),
            ),

            // 5. Global Selection Finalization Call-to-Action Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Transform map camera state data back into standard cloud document coordinates
                  final target = _currentCameraPosition.target;
                  final selectedPoint = GeoPoint(
                    target.latitude,
                    target.longitude,
                  );
                  Navigator.pop(context, selectedPoint);
                },
                child: const Text(
                  "Confirm Selected Position Location",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
