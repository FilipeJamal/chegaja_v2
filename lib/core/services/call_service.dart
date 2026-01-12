import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallService {
  CallService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final CallService instance = CallService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _callsCol =>
      _db.collection('calls');

  Future<String> createCall({
    required String pedidoId,
    required String calleeId,
    required String callerRole,
    required String calleeRole,
    required bool videoEnabled,
  }) async {
    final callerId = _auth.currentUser?.uid ?? '';
    if (callerId.isEmpty) {
      throw StateError('createCall: user not signed in.');
    }
    if (calleeId.trim().isEmpty) {
      throw ArgumentError('createCall: calleeId vazio.');
    }

    final now = FieldValue.serverTimestamp();
    final ref = _callsCol.doc();
    await ref.set(
      {
        'pedidoId': pedidoId,
        'callerId': callerId,
        'calleeId': calleeId,
        'callerRole': callerRole,
        'calleeRole': calleeRole,
        'videoEnabled': videoEnabled,
        'status': 'ringing',
        'createdAt': now,
        'updatedAt': now,
      },
    );

    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamIncomingCalls({
    required String pedidoId,
    required String calleeId,
  }) {
    return _callsCol
        .where('pedidoId', isEqualTo: pedidoId)
        .where('calleeId', isEqualTo: calleeId)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamCall(String callId) {
    return _callsCol.doc(callId).snapshots();
  }

  Future<void> updateStatus(String callId, String status) {
    return _callsCol.doc(callId).set(
      {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == 'accepted') 'acceptedAt': FieldValue.serverTimestamp(),
        if (status == 'ended' || status == 'declined')
          'endedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> endCall(String callId) => updateStatus(callId, 'ended');
}
