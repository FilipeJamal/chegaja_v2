import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/services/locale_service.dart';
import 'package:chegaja_v2/firebase_options.dart';

class RoutingResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  RoutingResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RoutingService {
  RoutingService._();
  static final RoutingService instance = RoutingService._();

  /// Obtem a rota de conducao entre dois pontos usando Google Directions
  /// (via proxy). Faz fallback para OSRM se necessario.
  Future<RoutingResult?> getRoute(LatLng start, LatLng end) async {
    final google = await _getGoogleRoute(start, end);
    if (google != null) return google;
    return _getOsrmRoute(start, end);
  }

  static bool _canUseProxy() {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return projectId.trim().isNotEmpty;
  }

  Uri _buildDirectionsUri({
    required LatLng start,
    required LatLng end,
  }) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    final region = AppConfig.functionsRegion;
    final params = <String, String>{
      'origin': '${start.latitude},${start.longitude}',
      'destination': '${end.latitude},${end.longitude}',
      'mode': 'driving',
      'language': LocaleService.instance.locale.languageCode,
    };

    if (AppConfig.useFirebaseEmulators) {
      final host = AppConfig.emulatorHost;
      return Uri.http(
        '$host:5001',
        '/$projectId/$region/directions_route',
        params,
      );
    }
    return Uri.https(
      '$region-$projectId.cloudfunctions.net',
      '/directions_route',
      params,
    );
  }

  Future<RoutingResult?> _getGoogleRoute(LatLng start, LatLng end) async {
    if (!_canUseProxy()) return null;

    try {
      final uri = _buildDirectionsUri(start: start, end: end);
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('[RoutingService] Directions HTTP ${response.statusCode}');
        }
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? '';
      if (status != 'OK') {
        if (kDebugMode) {
          final err = data['error_message']?.toString() ?? status;
          print('[RoutingService] Directions $err');
        }
        return null;
      }

      final routes = data['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final overview = route['overview_polyline'] as Map<String, dynamic>? ?? {};
      final pointsEncoded = overview['points']?.toString() ?? '';
      if (pointsEncoded.isEmpty) return null;

      final legs = route['legs'] as List<dynamic>? ?? const [];
      if (legs.isEmpty) return null;
      final leg = legs.first as Map<String, dynamic>;
      final distance = leg['distance'] as Map<String, dynamic>? ?? {};
      final duration = leg['duration'] as Map<String, dynamic>? ?? {};
      final distanceMeters = (distance['value'] as num?)?.toDouble() ?? 0;
      final durationSeconds = (duration['value'] as num?)?.toDouble() ?? 0;

      final decoded = _decodePolyline(pointsEncoded);
      if (decoded.isEmpty) return null;

      return RoutingResult(
        points: decoded,
        distanceKm: distanceMeters / 1000,
        durationMinutes: durationSeconds / 60,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[RoutingService] Directions error: $e');
      }
      return null;
    }
  }

  Future<RoutingResult?> _getOsrmRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>;
        if (routes.isEmpty) return null;

        final route = routes.first as Map<String, dynamic>;
        final geometry = route['geometry'] as Map<String, dynamic>;
        final coords = geometry['coordinates'] as List<dynamic>;

        // OSRM retorna [lon, lat]
        final points = coords.map((c) {
          final list = c as List<dynamic>;
          return LatLng(list[1].toDouble(), list[0].toDouble());
        }).toList();

        final distanceMeters = (route['distance'] as num).toDouble();
        final durationSeconds = (route['duration'] as num).toDouble();

        return RoutingResult(
          points: points,
          distanceKm: distanceMeters / 1000,
          durationMinutes: durationSeconds / 60,
        );
      } else {
        if (kDebugMode) {
          print('Erro OSRM: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter rota: $e');
      }
      return null;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
