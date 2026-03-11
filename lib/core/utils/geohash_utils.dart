// lib/core/utils/geohash_utils.dart
//
// Gerador de Geohash (base32) compativel com GeoFire / geofire-common.
// Implementa calculo de vizinhos para queries de raio eficientes.
//
// Referência: https://github.com/firebase/geofire-common

import 'package:cloud_firestore/cloud_firestore.dart';

class GeoHashUtils {
  GeoHashUtils._();

  /// Alfabeto base32 usado pelo geohash "standard".
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Codifica latitude/longitude num geohash.
  static String encode(
    double latitude,
    double longitude, {
    int precision = 10,
  }) {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ArgumentError('Latitude/Longitude invalidas.');
    }
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude fora do intervalo [-90, 90].');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude fora do intervalo [-180, 180].');
    }

    final int prec = precision.clamp(1, 22);

    double latMin = -90.0, latMax = 90.0;
    double lonMin = -180.0, lonMax = 180.0;

    bool isEven = true;
    int bit = 0;
    int ch = 0;

    final out = StringBuffer();

    while (out.length < prec) {
      if (isEven) {
        final mid = (lonMin + lonMax) / 2.0;
        if (longitude >= mid) {
          ch = (ch << 1) | 1;
          lonMin = mid;
        } else {
          ch = (ch << 1);
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2.0;
        if (latitude >= mid) {
          ch = (ch << 1) | 1;
          latMin = mid;
        } else {
          ch = (ch << 1);
          latMax = mid;
        }
      }

      isEven = !isEven;
      bit++;

      if (bit == 5) {
        out.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return out.toString();
  }

  /// Formato compativel com GeoFire/Firestore:
  static Map<String, dynamic> toGeoData({
    required double latitude,
    required double longitude,
    int precision = 10,
  }) {
    return {
      'geohash': encode(latitude, longitude, precision: precision),
      'geopoint': GeoPoint(latitude, longitude),
    };
  }

  // --- LOGICA DE VIZINHOS (NEIGHBORS) ---

  // Tabelas de vizinhos para Geohash
  static const Map<String, List<String>> _neighborsTable = {
    // Parity: Even (0) vs Odd (1)
    // Direction: Top, Bottom, Right, Left
    // [Even/Odd][Dir] -> Map of chars

    // Top (North)
    'top': [
      'p0r21436x8zb9dcf5h7kjnmqesgutwvy', // Even
      'bc01fg45238967deuvhjyznpkmstqrwx', // Odd
    ],
    // Bottom (South)
    'bottom': [
      '14365h7k9dcfesgujnmqp0r2twvyx8zb', // Even
      '238967debc01fg45kmstqrwxuvhjyznp', // Odd
    ],
    // Right (East)
    'right': [
      'bc01fg45238967deuvhjyznpkmstqrwx', // Even
      'p0r21436x8zb9dcf5h7kjnmqesgutwvy', // Odd
    ],
    // Left (West)
    'left': [
      '238967debc01fg45kmstqrwxuvhjyznp', // Even
      '14365h7k9dcfesgujnmqp0r2twvyx8zb', // Odd
    ],
  };

  static const Map<String, List<String>> _bordersTable = {
    // Top
    'top': [
      'prxz', // Even
      'bcfguvyz', // Odd
    ],
    // Bottom
    'bottom': [
      '028b',
      '0145hjnp',
    ],
    // Right
    'right': [
      'bcfguvyz',
      'prxz',
    ],
    // Left
    'left': [
      '0145hjnp',
      '028b',
    ],
  };

  /// Calcula o geohash vizinho na direcao especificada.
  static String adjacent(String geohash, String direction) {
    if (geohash.isEmpty) return '';

    final lastCh = geohash[geohash.length - 1];
    String parent = geohash.substring(0, geohash.length - 1);

    final type =
        (geohash.length % 2) == 1 ? 1 : 0; // Odd=1, Even=0 (Length base)

    final borders = _bordersTable[direction]![type];

    if (borders.contains(lastCh) && parent.isNotEmpty) {
      parent = adjacent(parent, direction);
    }

    // Lookup neighbor char
    final neighbors = _neighborsTable[direction]![type];
    final index = _base32.indexOf(lastCh);
    if (index == -1) return geohash; // Error

    final neighborChar = neighbors[index];

    return parent + neighborChar;
  }

  /// Retorna os 8 vizinhos + o proprio centro.
  static List<String> neighbors(String geohash) {
    if (geohash.isEmpty) return [];

    final n = adjacent(geohash, 'top');
    final s = adjacent(geohash, 'bottom');
    final e = adjacent(geohash, 'right');
    final w = adjacent(geohash, 'left');

    final ne = adjacent(n, 'right');
    final nw = adjacent(n, 'left');
    final se = adjacent(s, 'right');
    final sw = adjacent(s, 'left');

    return [geohash, n, s, e, w, ne, nw, se, sw];
  }

  /// Calcula o conjunto de prefixos de geohash para cobrir uma area circular.
  static List<String> getGeohashesForRadius(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    // 1. Estimar a precisao
    int precision = 4;

    if (radiusKm <= 0.05) {
      precision = 8; // ~19m
    } else if (radiusKm <= 0.3) {
      precision = 7; // ~76m
    } else if (radiusKm <= 2) {
      precision = 6; // ~600m
    } else if (radiusKm <= 10) {
      precision = 5; // ~2.4km
    } else if (radiusKm <= 50) {
      precision = 4; // ~20km
    } else if (radiusKm <= 200) {
      precision = 3; // ~78km
    } else {
      precision = 2;
    }

    final centerHash = encode(latitude, longitude, precision: precision);
    final allHashes = neighbors(centerHash);

    // Remove duplicados e vazios
    return allHashes.toSet().where((h) => h.isNotEmpty).toList();
  }

  // Retorna os parametros para query (startAt, endAt) para um dado prefixo
  static Map<String, String> getGeohashRange(String geohash) {
    return {
      'start': geohash,
      'end': '$geohash~',
    };
  }
}
