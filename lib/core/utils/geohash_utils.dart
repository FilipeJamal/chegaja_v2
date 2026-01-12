// lib/core/utils/geohash_utils.dart
//
// Gerador de Geohash (base32) compatível com GeoFire / geofire-common.
//
// Motivo: o pacote geoflutterfire2 ficou preso a versões antigas do
// cloud_firestore, causando conflitos de dependências com FlutterFire v4+.
// Aqui geramos manualmente:
//   {
//     "geohash": "...",
//     "geopoint": GeoPoint(lat, lng)
//   }
//
// Assim, as Cloud Functions podem continuar a fazer matching por
// `geo.geohash` e `geo.geopoint`.

import 'package:cloud_firestore/cloud_firestore.dart';

class GeoHashUtils {
  GeoHashUtils._();

  /// Alfabeto base32 usado pelo geohash “standard”.
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Codifica latitude/longitude num geohash.
  ///
  /// [precision] é o tamanho do hash (número de caracteres). GeoFire / geofire-common
  /// usa 10 por padrão (≈ resolução ~1m).
  static String encode(
    double latitude,
    double longitude, {
    int precision = 10,
  }) {
    // Garantias mínimas (evita NaN/infinito e coordenadas fora do intervalo).
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ArgumentError('Latitude/Longitude inválidas.');
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

  /// Formato compatível com GeoFire/Firestore:
  ///
  /// - geo.geohash  → String
  /// - geo.geopoint → GeoPoint
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
}
