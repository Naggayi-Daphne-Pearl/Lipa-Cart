import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import '../core/theme/app_colors.dart';

/// A map-based location picker using OpenStreetMap + Leaflet (flutter_map).
/// User can drag the map to position the pin, then confirm.
class MapLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final ValueChanged<MapPickerResult> onLocationSelected;

  const MapLocationPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class MapPickerResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;

  MapPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
  });
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _center;
  final MapController _mapController = MapController();
  bool _isLoading = false;
  String? _addressPreview;

  // Default to Kampala, Uganda
  static const _defaultLat = 0.3476;
  static const _defaultLng = 32.5825;

  @override
  void initState() {
    super.initState();
    _center = LatLng(
      widget.initialLat ?? _defaultLat,
      widget.initialLng ?? _defaultLng,
    );
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'LipaCart/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String?;
        final address = data['address'] as Map<String, dynamic>?;
        final city = address?['city'] ?? address?['town'] ?? address?['village'] ?? '';

        setState(() {
          _addressPreview = displayName;
        });

        widget.onLocationSelected(MapPickerResult(
          latitude: position.latitude,
          longitude: position.longitude,
          address: displayName,
          city: city,
        ));
      }
    } catch (_) {
      // Geocoding failed — still return coordinates
      widget.onLocationSelected(MapPickerResult(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 15,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && position.center != null) {
                      setState(() => _center = position.center!);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.lipacart.app',
                  ),
                ],
              ),

              // Center pin (fixed, map moves behind it)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(Iconsax.location5, size: 36, color: AppColors.error),
                ),
              ),

              // Pin shadow
              Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Confirm button
              Positioned(
                bottom: 12,
                right: 12,
                child: FloatingActionButton.small(
                  onPressed: () => _reverseGeocode(_center),
                  backgroundColor: AppColors.primary,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),

              // My location button
              Positioned(
                bottom: 12,
                left: 12,
                child: FloatingActionButton.small(
                  heroTag: 'myLocation',
                  onPressed: () {
                    // Reset to Kampala center
                    _mapController.move(LatLng(_defaultLat, _defaultLng), 15);
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Iconsax.gps, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Address preview
        if (_addressPreview != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.location, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _addressPreview!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 4),
        Text(
          'Drag the map to position the pin on your location, then tap ✓',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
