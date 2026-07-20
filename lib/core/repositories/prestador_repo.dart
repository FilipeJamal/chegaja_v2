import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/models/prestador.dart';

/// Public provider discovery and owner-only operational settings.
///
/// Exact location and availability are intentionally excluded from public
/// reads. Server-side dispatch performs geo/availability matching.
class PrestadorRepo {
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
    Query query = _publicRef.where('isSearchable', isEqualTo: true);
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
}
