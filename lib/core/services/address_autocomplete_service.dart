import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/google_places_service.dart';

class AddressResult {
  final String label;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? rawData;

  AddressResult({
    required this.label,
    required this.latitude,
    required this.longitude,
    this.rawData,
  });

  @override
  String toString() => '$label ($latitude, $longitude)';
}

class AddressAutocompleteService {
  AddressAutocompleteService._();
  static final AddressAutocompleteService instance = AddressAutocompleteService._();

  Future<List<AddressResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    String countryCode = 'pt';
    try {
      final region = await AuthService.getUserRegion();
      if (region != null && region.isNotEmpty) {
        countryCode = region.toLowerCase();
      }
    } catch (_) {}

    final googleResults = await _searchGooglePlaces(trimmed, countryCode);
    if (googleResults.isNotEmpty) return googleResults;

    return _searchNominatim(trimmed, countryCode);
  }

  Future<List<AddressResult>> _searchGooglePlaces(
    String query,
    String countryCode,
  ) async {
    if (!GooglePlacesService.isAvailable) {
      return const <AddressResult>[];
    }

    final sessionToken = GooglePlacesService.createSessionToken();
    final suggestions = await GooglePlacesService.autocomplete(
      query: query,
      type: PlaceSearchType.address,
      countryCode: countryCode,
      sessionToken: sessionToken,
    );
    if (suggestions.isEmpty) return const <AddressResult>[];

    final results = <AddressResult>[];
    final limited = suggestions.length > 5 ? suggestions.sublist(0, 5) : suggestions;
    for (final suggestion in limited) {
      final details = await GooglePlacesService.placeDetails(
        placeId: suggestion.placeId,
        sessionToken: sessionToken,
      );
      if (details == null) continue;
      final label =
          details.formattedAddress ?? details.name ?? suggestion.label;
      results.add(AddressResult(
        label: label,
        latitude: details.lat,
        longitude: details.lng,
        rawData: details.raw,
      ),);
    }

    return results;
  }

  Future<List<AddressResult>> _searchNominatim(
    String query,
    String countryCode,
  ) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '8',
        'countrycodes': countryCode,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'ChegaJaApp/1.0 (dev@chegaja.com)',
          'Accept-Language': 'pt-PT,pt;q=0.9',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      if (data is! List) return [];

      final results = <AddressResult>[];

      for (final item in data) {
        if (item is! Map) continue;

        final label = item['display_name']?.toString() ?? '';
        final lat = double.tryParse(item['lat']?.toString() ?? '');
        final lon = double.tryParse(item['lon']?.toString() ?? '');

        if (label.isNotEmpty && lat != null && lon != null) {
          results.add(AddressResult(
            label: label,
            latitude: lat,
            longitude: lon,
            rawData: item as Map<String, dynamic>?,
          ),);
        }
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
