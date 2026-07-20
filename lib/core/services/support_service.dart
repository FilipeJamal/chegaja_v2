import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

class SupportService {
  SupportService._();

  static final SupportService instance = SupportService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  Future<String> createTicket({
    required String category,
    required String message,
    required String userType,
    String? pedidoId,
  }) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) throw Exception('Utilizador não autenticado');

    final result = await _functions.httpsCallable('support_createTicket').call({
      'category': category,
      'message': message,
      'userType': userType,
      if (pedidoId != null && pedidoId.trim().isNotEmpty)
        'pedidoId': pedidoId.trim(),
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['ticketId']?.toString() ?? '';
  }

  Stream<List<Map<String, dynamic>>> watchMyTickets() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('support_tickets')
        .where('uid', isEqualTo: uid)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      final rows = snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
          .toList();
      rows.sort(
        (a, b) => _millis(b['createdAt']).compareTo(_millis(a['createdAt'])),
      );
      return rows;
    });
  }

  static int _millis(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }
}
