import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/models/prestador.dart';

@immutable
class ProviderAgendaData {
  ProviderAgendaData({
    Map<String, List<String>> workingHours = const {},
    List<DateTime> blockedDates = const [],
  })  : workingHours = Map.unmodifiable(
          workingHours.map(
            (day, hours) => MapEntry(
              day,
              List<String>.unmodifiable(hours),
            ),
          ),
        ),
        blockedDates = List<DateTime>.unmodifiable(blockedDates);

  final Map<String, List<String>> workingHours;
  final List<DateTime> blockedDates;

  static final ProviderAgendaData empty = ProviderAgendaData();
}

abstract interface class PrestadorAgendaRepository {
  Future<ProviderAgendaData> getAgenda(String uid);

  Future<void> updateAgenda(
    String uid, {
    required Map<String, List<String>> workingHours,
    List<DateTime>? blockedDates,
  });
}

/// Public provider discovery and owner-only operational settings.
///
/// Exact location and availability are intentionally excluded from public
/// reads. Server-side dispatch performs geo/availability matching.
class PrestadorRepo implements PrestadorAgendaRepository {
  PrestadorRepo({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference get _publicRef => _db.collection('provider_public');
  CollectionReference get _dispatchRef =>
      _db.collection('provider_dispatch_private');

  Future<Prestador?> getPrestador(String uid) async {
    try {
      final doc = await _publicRef.doc(uid).get();
      if (!doc.exists) return null;
      return Prestador.fromFirestore(doc);
    } catch (error) {
      debugPrint('Erro ao obter prestador publico: $error');
      return null;
    }
  }

  @override
  Future<void> updateAgenda(
    String uid, {
    required Map<String, List<String>> workingHours,
    List<DateTime>? blockedDates,
  }) async {
    final data = <String, dynamic>{
      'providerId': uid,
      'workingHours': workingHours,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (blockedDates != null) {
      data['blockedDates'] =
          blockedDates.map(Timestamp.fromDate).toList(growable: false);
    }
    await _dispatchRef.doc(uid).set(data, SetOptions(merge: true));
  }

  /// Loads owner-only availability data.
  ///
  /// Schedule data must never be sourced from `provider_public`: it affects
  /// dispatch and can expose a provider's operational routine.
  @override
  Future<ProviderAgendaData> getAgenda(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'Must not be empty.');
    }

    final doc = await _dispatchRef.doc(normalizedUid).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (!doc.exists || data == null) return ProviderAgendaData.empty;

    return ProviderAgendaData(
      workingHours: _parseWorkingHours(data['workingHours']),
      blockedDates: _parseBlockedDates(data['blockedDates']),
    );
  }

  /// Returns only explicitly searchable public profiles.
  ///
  /// `latitude`, `longitude`, online state and working hours are accepted for
  /// API compatibility but are not evaluated on public documents. Operational
  /// matching must use the server-side dispatch endpoint.
  Future<List<Prestador>> buscaPrestadores({
    double? latitude,
    double? longitude,
    double raioKm = 30.0,
    String? categoriaId,
    bool apenasOnline = true,
  }) async {
    Query query = _publicRef
        .where('marketId', isEqualTo: AppConfig.pilotMarket.id)
        .where('isSearchable', isEqualTo: true);
    if (categoriaId != null && categoriaId.trim().isNotEmpty) {
      query = query.where('categories', arrayContains: categoriaId.trim());
    }
    final snapshot = await query.limit(20).get();
    final providers = snapshot.docs
        .map(Prestador.fromFirestore)
        .toList(growable: false)
      ..sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
    return providers;
  }

  static Map<String, List<String>> _parseWorkingHours(Object? raw) {
    if (raw is! Map) return const {};

    final parsed = <String, List<String>>{};
    raw.forEach((key, value) {
      final day = key.toString().trim();
      if (day.isEmpty || value is! Iterable) return;

      final values = value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (values.length >= 2 &&
          _isValidTime(values[0]) &&
          _isValidTime(values[1])) {
        parsed[day] = [values[0], values[1]];
        return;
      }

      if (values.length == 1) {
        final legacyRange = values.single.split('-');
        if (legacyRange.length == 2) {
          final start = legacyRange[0].trim();
          final end = legacyRange[1].trim();
          if (_isValidTime(start) && _isValidTime(end)) {
            parsed[day] = [start, end];
          }
        }
      }
    });
    return parsed;
  }

  static List<DateTime> _parseBlockedDates(Object? raw) {
    if (raw is! Iterable) return const [];
    return raw
        .whereType<Timestamp>()
        .map((timestamp) => timestamp.toDate())
        .toList(growable: false);
  }

  static bool _isValidTime(String value) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    return match != null;
  }
}
