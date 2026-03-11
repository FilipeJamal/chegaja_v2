import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/prestador.dart';
import '../../core/utils/geohash_utils.dart';

class PrestadorRepo {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _prestadoresRef => _db.collection('prestadores');

  /// Obtém os dados do prestador via ID (uid)
  Future<Prestador?> getPrestador(String uid) async {
    try {
      final doc = await _prestadoresRef.doc(uid).get();
      if (!doc.exists) return null;
      return Prestador.fromFirestore(doc);
    } catch (e) {
      // Log error properly in production
      debugPrint('Erro ao obter prestador: $e');
      return null;
    }
  }

  /// Atualiza a agenda de trabalho
  Future<void> updateAgenda(
    String uid, {
    required Map<String, List<String>> workingHours,
    List<DateTime>? blockedDates,
  }) async {
    final Map<String, dynamic> data = {
      'workingHours': workingHours,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (blockedDates != null) {
      data['blockedDates'] = blockedDates.map((e) => Timestamp.fromDate(e)).toList();
    }

    await _prestadoresRef.doc(uid).update(data);
  }

  /// Busca prestadores com filtros avançados (D3):
  /// - Geolocalização (Raio em Km)
  /// - Categoria
  /// - Estado Online/Offline
  /// - Disponibilidade de Horário
  Future<List<Prestador>> buscaPrestadores({
    double? latitude,
    double? longitude,
    double raioKm = 30.0,
    String? categoriaId, // ID ou Nome da categoria
    bool apenasOnline = true,
  }) async {
    Query query = _prestadoresRef;

    // 1. Filtro inicial por Categoria (se houver)
    if (categoriaId != null && categoriaId.isNotEmpty) {
      query = query.where('categories', arrayContains: categoriaId);
    }
    
    // 2. Filtro por Online (se solicitado)
    if (apenasOnline) {
      query = query.where('isOnline', isEqualTo: true);
    }

    // Se não tiver lat/lng, retorna query simples limitada
    if (latitude == null || longitude == null) {
      final snapshot = await query.limit(20).get();
      return snapshot.docs.map((d) => Prestador.fromFirestore(d)).toList();
    }

    // 3. GEOQUERY (Manual usando Geohash Neighbors)
    final Set<String> searchHashes = GeoHashUtils.getGeohashesForRadius(
      latitude, 
      longitude, 
      raioKm,
    ).toSet();

    final List<Prestador> candidatos = [];
    final List<Future<QuerySnapshot>> futures = [];

    for (String hash in searchHashes) {
      final range = GeoHashUtils.getGeohashRange(hash);
      
      // Index required: categories + geohash, isOnline + geohash
      futures.add(
        query
          .orderBy('geohash')
          .startAt([range['start']])
          .endAt([range['end']])
          .get(),
      );
    }

    final snapshots = await Future.wait(futures);
    final Set<String> seenIds = {};
    
    for (var snap in snapshots) {
      for (var doc in snap.docs) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          candidatos.add(Prestador.fromFirestore(doc));
        }
      }
    }

    // 4. Filtragem Fina em Memória (Raio Exato + Horário)
    final filtered = candidatos.where((p) {
      // A. Distância Exata (se location for null, ignora)
      if (p.location == null) return false;
      final double dist = _getDistanceFromLatLonInKm(
        latitude, longitude, 
        p.location!.latitude, p.location!.longitude,
      );
      if (dist > raioKm) return false;

      // B. Horário de Trabalho
      if (p.workingHours.isNotEmpty) {
        if (!_isWithinWorkingHours(p.workingHours)) return false;
      }
      
      // C. Bloqueio de datas
      if (_isDateBlocked(p.blockedDates)) return false;

      return true;
    }).toList();

    // 5. Ordenar por Score Híbrido (Distância vs Qualidade)
    filtered.sort((a, b) {
       // Assuming location is not null here as per filter
       final double distA = _getDistanceFromLatLonInKm(latitude, longitude, a.location!.latitude, a.location!.longitude);
       final double distB = _getDistanceFromLatLonInKm(latitude, longitude, b.location!.latitude, b.location!.longitude);
       
       final double scoreA = distA - (a.ratingAvg * 0.2);
       final double scoreB = distB - (b.ratingAvg * 0.2);

       return scoreA.compareTo(scoreB);
    });

    return filtered;
  }

  // --- Helpers ---

  bool _isWithinWorkingHours(Map<String, List<String>> schedule) {
    final now = DateTime.now();
    final weekDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final todayStr = weekDays[now.weekday - 1];

    if (!schedule.containsKey(todayStr)) return false; 
    
    final slots = schedule[todayStr] ?? [];
    if (slots.isEmpty) return false;

    for (final slot in slots) {
      final parts = slot.split('-');
      if (parts.length != 2) continue;
      
      final start = _timeToDouble(parts[0]);
      final end = _timeToDouble(parts[1]);
      final current = now.hour + (now.minute / 60.0);

      if (current >= start && current <= end) return true;
    }
    return false;
  }

  bool _isDateBlocked(List<DateTime> blockedDates) {
    if (blockedDates.isEmpty) return false;
    final now = DateTime.now();
    for (final date in blockedDates) {
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return true; 
      }
    }
    return false;
  }

  double _timeToDouble(String time) {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h + (m / 60.0);
  }

  double _getDistanceFromLatLonInKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; 
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = 
      sin(dLat/2) * sin(dLat/2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * 
      sin(dLon/2) * sin(dLon/2); 
    final c = 2 * asin(sqrt(a)); 
    return R * c;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }
}
