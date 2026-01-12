// lib/core/services/location_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/geohash_utils.dart';

/// Serviço simples de localização.
///
/// - Pede permissões
/// - Obtém posição atual
/// - Atualiza lastLocation do prestador em `prestadores/{uid}`
///
/// Nota: no iOS/Android precisas de adicionar permissões no Info.plist/AndroidManifest.
class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final ok = await _ensureLocationPermission();
    if (!ok) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _writePrestadorLocation({
    required String prestadorId,
    required bool isOnline,
    required Position pos,
  }) async {
    final ref =
        FirebaseFirestore.instance.collection('prestadores').doc(prestadorId);

    final geo = GeoHashUtils.toGeoData(
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    await ref.set(
      {
        'isOnline': isOnline,
        'lastLocation': {
          'lat': pos.latitude,
          'lng': pos.longitude,
        },
        // Novo formato (GeoPoint + geohash) para queries por raio (GeoFire)
        'geo': geo,
        'lastLocationAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updatePrestadorLastLocation({
    required String prestadorId,
    required bool isOnline,
  }) async {
    final pos = await getCurrentPosition();
    if (pos == null) {
      final ref =
          FirebaseFirestore.instance.collection('prestadores').doc(prestadorId);
      await ref.set(
        {
          'isOnline': isOnline,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    await _writePrestadorLocation(
      prestadorId: prestadorId,
      isOnline: isOnline,
      pos: pos,
    );
  }

  Future<StreamSubscription<Position>?> startPrestadorTracking({
    required String prestadorId,
    required bool isOnline,
    int distanceFilterMeters = 25,
  }) async {
    final ok = await _ensureLocationPermission();
    if (!ok) {
      return null;
    }

    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );

    return Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) async {
        try {
          await _writePrestadorLocation(
            prestadorId: prestadorId,
            isOnline: isOnline,
            pos: pos,
          );
        } catch (_) {
          // ignora erros pontuais de rede
        }
      },
    );
  }

  /// Calcula distância em KM entre 2 coordenadas.
  double distanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final meters = Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
    return meters / 1000.0;
  }
}
