// lib/core/services/location_data_service.dart
//
// Serviço (offline) para lista de Países / Cidades com cache em memória.
// Usa o package `country_state_city` (dados locais, sem API).

import 'dart:collection';

import 'package:country_state_city/country_state_city.dart';

class LocationDataService {
  LocationDataService._();

  static final LocationDataService instance = LocationDataService._();

  List<Country>? _countries;
  List<State>? _states;
  final Map<String, List<City>> _citiesByCountryCode = HashMap();
  final Map<String, List<State>> _statesByCountryCode = HashMap();
  final Map<String, List<City>> _citiesByStateKey = HashMap();

  /// Normaliza texto para pesquisa (lowercase + remove acentos + remove símbolos).
  static String normalize(String input) {
    final s = input.toLowerCase().trim();
    if (s.isEmpty) return '';

    final b = StringBuffer();
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      b.write(_replaceDiacriticsChar(ch));
    }

    // mantém letras/números/espaço
    final cleaned = b.toString().replaceAll(RegExp(r"[^a-z0-9 ]"), ' ');
    return cleaned.replaceAll(RegExp(r"\s+"), ' ').trim();
  }

  static String _replaceDiacriticsChar(String ch) {
    switch (ch) {
      case 'á':
      case 'à':
      case 'â':
      case 'ã':
      case 'ä':
      case 'å':
      case 'ā':
      case 'ă':
      case 'ą':
        return 'a';
      case 'æ':
        return 'ae';
      case 'ç':
      case 'ć':
      case 'č':
        return 'c';
      case 'ď':
      case 'đ':
        return 'd';
      case 'é':
      case 'è':
      case 'ê':
      case 'ë':
      case 'ē':
      case 'ė':
      case 'ę':
        return 'e';
      case 'ğ':
      case 'ģ':
        return 'g';
      case 'í':
      case 'ì':
      case 'î':
      case 'ï':
      case 'ī':
      case 'į':
        return 'i';
      case 'ł':
        return 'l';
      case 'ñ':
      case 'ń':
        return 'n';
      case 'ó':
      case 'ò':
      case 'ô':
      case 'õ':
      case 'ö':
      case 'ø':
      case 'ō':
        return 'o';
      case 'œ':
        return 'oe';
      case 'ř':
      case 'ŕ':
        return 'r';
      case 'ś':
      case 'š':
      case 'ş':
        return 's';
      case 'ß':
        return 'ss';
      case 'ú':
      case 'ù':
      case 'û':
      case 'ü':
      case 'ū':
      case 'ů':
        return 'u';
      case 'ý':
      case 'ÿ':
        return 'y';
      case 'ž':
      case 'ź':
      case 'ż':
        return 'z';
      default:
        return ch;
    }
  }

  Future<List<Country>> getCountries() async {
    _countries ??= await getAllCountries();
    _countries!.sort((a, b) => a.name.compareTo(b.name));
    return _countries!;
  }

  Future<List<City>> getCitiesForCountryCode(String countryCode) async {
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return const <City>[];

    final cached = _citiesByCountryCode[code];
    if (cached != null) return cached;

    final cities = await getCountryCities(code);
    cities.sort((a, b) => a.name.compareTo(b.name));
    _citiesByCountryCode[code] = cities;
    return cities;
  }

  Future<List<State>> getStatesForCountryCode(String countryCode) async {
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return const <State>[];

    final cached = _statesByCountryCode[code];
    if (cached != null) return cached;

    _states ??= await getAllStates();
    final res = _states!
        .where((state) => state.countryCode.toUpperCase() == code)
        .toList();
    res.sort((a, b) => a.name.compareTo(b.name));
    _statesByCountryCode[code] = res;
    return res;
  }

  Future<List<City>> getCitiesForState(
    String countryCode,
    String stateCode,
  ) async {
    final c = countryCode.trim().toUpperCase();
    final s = stateCode.trim().toUpperCase();
    if (c.isEmpty || s.isEmpty) return const <City>[];

    final key = '$c:$s';
    final cached = _citiesByStateKey[key];
    if (cached != null) return cached;

    final cities = await getStateCities(c, s);
    _citiesByStateKey[key] = cities;
    return cities;
  }

  Future<Country?> findCountryByName(String name) async {
    final n = normalize(name);
    if (n.isEmpty) return null;
    final countries = await getCountries();
    for (final c in countries) {
      if (normalize(c.name) == n) return c;
    }
    // fallback: contém
    for (final c in countries) {
      if (normalize(c.name).contains(n)) return c;
    }
    return null;
  }

  Future<State?> findStateByName(String countryCode, String name) async {
    final n = normalize(name);
    if (n.isEmpty) return null;
    final states = await getStatesForCountryCode(countryCode);
    for (final s in states) {
      if (normalize(s.name) == n) return s;
    }
    for (final s in states) {
      if (normalize(s.name).contains(n)) return s;
    }
    return null;
  }

  Future<City?> findCityByNameForState(
    String countryCode,
    String stateCode,
    String name,
  ) async {
    final n = normalize(name);
    if (n.isEmpty) return null;
    final cities = await getCitiesForState(countryCode, stateCode);
    for (final c in cities) {
      if (normalize(c.name) == n) return c;
    }
    for (final c in cities) {
      if (normalize(c.name).contains(n)) return c;
    }
    return null;
  }
}
