import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class DeliveryRouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final Duration duration;
  final bool isEstimated;
  final String sourceLabel;

  const DeliveryRouteResult({
    required this.points,
    required this.distanceKm,
    required this.duration,
    required this.isEstimated,
    required this.sourceLabel,
  });
}

class DeliveryRouteService {
  static const String _osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving';
  static const double _fallbackSpeedKph = 24;

  Future<DeliveryRouteResult> getRoute({
    required LatLng riderPoint,
    required LatLng clientPoint,
  }) async {
    final straightLineKm = Distance().as(
      LengthUnit.Kilometer,
      riderPoint,
      clientPoint,
    );

    try {
      final uri = Uri.parse(
        '$_osrmBaseUrl/${riderPoint.longitude},${riderPoint.latitude};${clientPoint.longitude},${clientPoint.latitude}?overview=full&geometries=geojson&alternatives=false&steps=false',
      );

      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>? ?? const [];

        if (routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coordinates =
              geometry?['coordinates'] as List<dynamic>? ?? const [];

          final points = coordinates
              .whereType<List<dynamic>>()
              .where((coordinate) => coordinate.length >= 2)
              .map(
                (coordinate) => LatLng(
                  (coordinate[1] as num).toDouble(),
                  (coordinate[0] as num).toDouble(),
                ),
              )
              .toList();

          final distanceMeters = (route['distance'] as num?)?.toDouble();
          final durationSeconds = (route['duration'] as num?)?.toDouble();

          if (distanceMeters != null && durationSeconds != null) {
            return DeliveryRouteResult(
              points: points.isNotEmpty ? points : [riderPoint, clientPoint],
              distanceKm: distanceMeters / 1000,
              duration: Duration(seconds: durationSeconds.round()),
              isEstimated: false,
              sourceLabel: 'Live road route',
            );
          }
        }
      }
    } catch (_) {
      // Fall back to a simple estimate when the routing service is unavailable.
    }

    final estimatedMinutes = math.max(
      2,
      ((straightLineKm / _fallbackSpeedKph) * 60).round(),
    );

    return DeliveryRouteResult(
      points: [riderPoint, clientPoint],
      distanceKm: straightLineKm,
      duration: Duration(minutes: estimatedMinutes),
      isEstimated: true,
      sourceLabel: 'Estimated ETA',
    );
  }
}
