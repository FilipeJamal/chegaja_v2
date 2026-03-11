import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/services/locale_service.dart';
import 'package:chegaja_v2/firebase_options.dart';

enum PlaceSearchType { city, region, address }

class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String? secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    this.secondaryText,
  });

  String get label =>
      secondaryText == null || secondaryText!.trim().isEmpty
          ? mainText
          : '$mainText, $secondaryText';
}

class GooglePlacesService {
  GooglePlacesService._();

  static String? get _apiKey => AppConfig.googlePlacesApiKey;

  static bool get isConfigured {
    final key = _apiKey;
    return key != null && key.trim().isNotEmpty;
  }

  static bool get isAvailable => isConfigured || _canUseProxy();

  static bool _canUseProxy() {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return projectId.trim().isNotEmpty;
  }

  static Uri _buildRequestUri(Map<String, String> params) {
    return _proxyUri(params);
  }

  static Uri _proxyUri(Map<String, String> params) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    final region = AppConfig.functionsRegion;
    if (AppConfig.useFirebaseEmulators) {
      final host = AppConfig.emulatorHost;
      return Uri.http(
        '$host:5001',
        '/$projectId/$region/places_autocomplete',
        params,
      );
    }
    return Uri.https(
      '$region-$projectId.cloudfunctions.net',
      '/places_autocomplete',
      params,
    );
  }

  static String _typesForSearch(PlaceSearchType type) {
    switch (type) {
      case PlaceSearchType.city:
        return '(cities)';
      case PlaceSearchType.region:
        return '(regions)';
      case PlaceSearchType.address:
        return 'address';
    }
  }

  static String createSessionToken() {
    final rng = Random();
    final now = DateTime.now().microsecondsSinceEpoch;
    return '$now-${rng.nextInt(1 << 32)}';
  }

  static Future<List<PlaceSuggestion>> autocomplete({
    required String query,
    required PlaceSearchType type,
    String? countryCode,
    String? sessionToken,
  }) async {
    if (!isConfigured && !_canUseProxy()) return const <PlaceSuggestion>[];

    final trimmed = query.trim();
    if (trimmed.length < 2) return const <PlaceSuggestion>[];

    final language = LocaleService.instance.locale.languageCode;
    final types = _typesForSearch(type);
    final params = <String, String>{
      'input': trimmed,
      'language': language,
      'types': types,
    };

    if (countryCode != null && countryCode.trim().isNotEmpty) {
      params['components'] = 'country:${countryCode.trim().toLowerCase()}';
    }
    if (sessionToken != null && sessionToken.trim().isNotEmpty) {
      params['sessiontoken'] = sessionToken.trim();
    }

    final uri = _buildRequestUri(params);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('[GooglePlaces] HTTP ${response.statusCode}');
        }
        return const <PlaceSuggestion>[];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? '';
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        if (kDebugMode) {
          final err = data['error_message']?.toString() ?? status;
          print('[GooglePlaces] $err');
        }
        return const <PlaceSuggestion>[];
      }

      final predictions = data['predictions'] as List? ?? const [];
      return predictions.map((p) {
        final map = p as Map<String, dynamic>;
        final formatting = map['structured_formatting'] as Map<String, dynamic>?;
        final mainText = formatting?['main_text']?.toString() ??
            map['description']?.toString() ??
            '';
        final secondaryText =
            formatting?['secondary_text']?.toString();
        return PlaceSuggestion(
          placeId: map['place_id']?.toString() ?? '',
          mainText: mainText,
          secondaryText: secondaryText,
        );
      }).where((s) => s.mainText.trim().isNotEmpty).toList();
    } catch (e) {
      if (kDebugMode) {
        print('[GooglePlaces] Error: $e');
      }
      return const <PlaceSuggestion>[];
    }
  }

  static Future<PlaceDetails?> placeDetails({
    required String placeId,
    String? sessionToken,
    String? language,
  }) async {
    if (!isAvailable) return null;
    final id = placeId.trim();
    if (id.isEmpty) return null;

    final params = <String, String>{
      'place_id': id,
      'fields': 'geometry,formatted_address,name',
      'language': language ?? LocaleService.instance.locale.languageCode,
    };
    if (sessionToken != null && sessionToken.trim().isNotEmpty) {
      params['sessiontoken'] = sessionToken.trim();
    }

    final uri = _buildDetailsUri(params);
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('[GooglePlaces] Details HTTP ${response.statusCode}');
        }
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status']?.toString() ?? '';
      if (status != 'OK') {
        if (kDebugMode) {
          final err = data['error_message']?.toString() ?? status;
          print('[GooglePlaces] Details $err');
        }
        return null;
      }

      final result = data['result'] as Map<String, dynamic>? ?? {};
      final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
      final location = geometry['location'] as Map<String, dynamic>? ?? {};
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;

      return PlaceDetails(
        lat: lat,
        lng: lng,
        formattedAddress: result['formatted_address']?.toString(),
        name: result['name']?.toString(),
        raw: result,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[GooglePlaces] Details error: $e');
      }
      return null;
    }
  }

  static Uri _buildDetailsUri(Map<String, String> params) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    final region = AppConfig.functionsRegion;
    if (AppConfig.useFirebaseEmulators) {
      final host = AppConfig.emulatorHost;
      return Uri.http(
        '$host:5001',
        '/$projectId/$region/places_details',
        params,
      );
    }
    return Uri.https(
      '$region-$projectId.cloudfunctions.net',
      '/places_details',
      params,
    );
  }
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String? formattedAddress;
  final String? name;
  final Map<String, dynamic> raw;

  const PlaceDetails({
    required this.lat,
    required this.lng,
    required this.raw,
    this.formattedAddress,
    this.name,
  });
}
