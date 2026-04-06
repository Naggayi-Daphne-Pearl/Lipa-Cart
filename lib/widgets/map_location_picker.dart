import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_colors.dart';

/// A map-based location picker using OpenStreetMap + Leaflet (flutter_map).
/// User can search for a place, use GPS, or drag the map to position the pin.
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
  final double? accuracyMeters;

  MapPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.accuracyMeters,
  });
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _center;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLocatingUser = false;
  String? _addressPreview;
  double? _gpsAccuracyMeters;
  List<_SearchResult> _searchResults = [];
  Timer? _searchDebounce;
  Timer? _mapMoveDebounce;

  // Default to Kampala, Uganda
  static const _defaultLat = 0.3476;
  static const _defaultLng = 32.5825;
  static const _goodAccuracyMeters = 25.0;
  static const _weakAccuracyMeters = 80.0;

  @override
  void initState() {
    super.initState();
    _center = LatLng(
      widget.initialLat ?? _defaultLat,
      widget.initialLng ?? _defaultLng,
    );

    if (widget.initialLat == null || widget.initialLng == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryCenterOnCurrentLocation();
      });
    } else {
      _reverseGeocode(_center);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _mapMoveDebounce?.cancel();
    super.dispose();
  }

  /// Search for places using Nominatim (free, no API key)
  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Bias search towards Uganda/East Africa
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&countrycodes=ug,ke&limit=5&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'LipaCart/1.0'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _searchResults = data
              .map(
                (item) => _SearchResult(
                  displayName: item['display_name'] as String,
                  lat: double.parse(item['lat'] as String),
                  lng: double.parse(item['lon'] as String),
                  city:
                      (item['address'] as Map<String, dynamic>?)?['city'] ??
                      (item['address'] as Map<String, dynamic>?)?['town'] ??
                      (item['address'] as Map<String, dynamic>?)?['village'] ??
                      '',
                ),
              )
              .toList();
        });
      }
    } catch (_) {
      // Search failed silently
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  void _scheduleReverseGeocode(LatLng position) {
    _mapMoveDebounce?.cancel();
    _mapMoveDebounce = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        _reverseGeocode(position);
      }
    });
  }

  Future<LocationPermission> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<Position?> _getBestCurrentPosition() async {
    Position? bestPosition;

    for (var attempt = 0; attempt < 3; attempt++) {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (bestPosition == null || position.accuracy < bestPosition.accuracy) {
        bestPosition = position;
      }

      if (bestPosition.accuracy <= _goodAccuracyMeters) {
        break;
      }

      if (attempt < 2) {
        await Future.delayed(const Duration(milliseconds: 900));
      }
    }

    return bestPosition;
  }

  Future<void> _tryCenterOnCurrentLocation({bool showFeedback = false}) async {
    if (mounted) {
      setState(() => _isLocatingUser = true);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please turn on device location services first.'),
            ),
          );
        }
        return;
      }

      final permission = await _ensureLocationPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is needed for precise GPS pinning.',
              ),
            ),
          );
        }
        return;
      }

      final position = await _getBestCurrentPosition();
      if (position == null || !mounted) return;

      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = newCenter;
        _gpsAccuracyMeters = position.accuracy;
      });

      _mapController.move(
        newCenter,
        position.accuracy <= _goodAccuracyMeters ? 18 : 17,
      );
      await _reverseGeocode(newCenter, accuracyMeters: position.accuracy);

      if (showFeedback && mounted) {
        final accuracyText = position.accuracy.isFinite
            ? position.accuracy.toStringAsFixed(0)
            : 'unknown';
        final isWeak = position.accuracy > _weakAccuracyMeters;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isWeak
                  ? 'GPS accuracy is only about ±$accuracyText m. Zoom in and drag the pin to your exact gate/building.'
                  : 'Location captured with about ±$accuracyText m accuracy.',
            ),
            backgroundColor: isWeak ? Colors.orange : AppColors.primary,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get a precise GPS fix right now.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingUser = false);
      }
    }
  }

  void _selectSearchResult(_SearchResult result) {
    final newCenter = LatLng(result.lat, result.lng);
    setState(() {
      _center = newCenter;
      _searchResults = [];
      _searchController.text = '';
      _addressPreview = result.displayName;
    });
    _mapController.move(newCenter, 17);

    widget.onLocationSelected(
      MapPickerResult(
        latitude: result.lat,
        longitude: result.lng,
        address: result.displayName,
        city: result.city,
      ),
    );

    FocusScope.of(context).unfocus();
  }

  Future<void> _reverseGeocode(
    LatLng position, {
    double? accuracyMeters,
  }) async {
    setState(() {
      _isLoading = true;
      _gpsAccuracyMeters = accuracyMeters;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'LipaCart/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String?;
        final address = data['address'] as Map<String, dynamic>?;
        final city =
            address?['city'] ?? address?['town'] ?? address?['village'] ?? '';

        setState(() {
          _addressPreview = displayName;
        });

        widget.onLocationSelected(
          MapPickerResult(
            latitude: position.latitude,
            longitude: position.longitude,
            address: displayName,
            city: city,
            accuracyMeters: accuracyMeters,
          ),
        );
      }
    } catch (_) {
      widget.onLocationSelected(
        MapPickerResult(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: accuracyMeters,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search location (e.g. Nakasero Market)',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
            prefixIcon: Icon(
              Iconsax.search_normal_1,
              size: 18,
              color: Colors.grey[500],
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchResults = []);
                    },
                  )
                : (_isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null),
            filled: true,
            fillColor: Colors.grey[50],
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),

        // Search results dropdown
        if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return InkWell(
                  onTap: () => _selectSearchResult(result),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.displayName,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 8),

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
                  initialZoom: 17,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      final center = position.center;
                      setState(() => _center = center);
                      _scheduleReverseGeocode(center);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.lipacart.app',
                  ),
                ],
              ),

              // Center pin
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(
                    Iconsax.location5,
                    size: 36,
                    color: AppColors.error,
                  ),
                ),
              ),

              // Pin shadow
              Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
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
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
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
                  tooltip: 'Use my exact GPS location',
                  onPressed: () =>
                      _tryCenterOnCurrentLocation(showFeedback: true),
                  backgroundColor: Colors.white,
                  child: _isLocatingUser
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                          size: 20,
                        ),
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
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Iconsax.location,
                  size: 16,
                  color: AppColors.primary,
                ),
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

        if (_gpsAccuracyMeters != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color:
                  (_gpsAccuracyMeters! > _weakAccuracyMeters
                          ? Colors.orange
                          : AppColors.primary)
                      .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _gpsAccuracyMeters! > _weakAccuracyMeters
                  ? 'Current GPS accuracy is weak: about ±${_gpsAccuracyMeters!.toStringAsFixed(0)} m. Move outdoors or drag the pin manually for a better result.'
                  : 'GPS accuracy: about ±${_gpsAccuracyMeters!.toStringAsFixed(0)} m.',
              style: TextStyle(
                fontSize: 11,
                color: _gpsAccuracyMeters! > _weakAccuracyMeters
                    ? Colors.orange.shade900
                    : AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        const SizedBox(height: 4),
        Text(
          'For the best precision, tap GPS, wait for the accuracy message, then zoom in and place the pin on your exact gate or building.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SearchResult {
  final String displayName;
  final double lat;
  final double lng;
  final String city;

  _SearchResult({
    required this.displayName,
    required this.lat,
    required this.lng,
    required this.city,
  });
}
