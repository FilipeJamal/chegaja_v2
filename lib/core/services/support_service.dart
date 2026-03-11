
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

class SupportService {
  SupportService._();
  static final SupportService instance = SupportService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createTicket(String subject, String message, String userType) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) throw Exception('Utilizador não autenticado');

    await _db.collection('support_tickets').add({
      'uid': uid,
      'userType': userType,
      'subject': subject,
      'message': message,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
