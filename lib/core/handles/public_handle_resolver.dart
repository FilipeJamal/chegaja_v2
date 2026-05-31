import 'package:cloud_firestore/cloud_firestore.dart';

import 'handle_validator.dart';

enum PublicHandleResolveStatus {
  resolved,
  invalidHandle,
  notFound,
  inactive,
  invalidRole,
  invalidData,
  error,
}

class PublicHandleResolveResult {
  const PublicHandleResolveResult._({
    required this.status,
    this.uid,
    this.handle,
    this.handleDisplay,
  });

  const PublicHandleResolveResult.resolved({
    required String uid,
    required String handle,
    String? handleDisplay,
  }) : this._(
          status: PublicHandleResolveStatus.resolved,
          uid: uid,
          handle: handle,
          handleDisplay: handleDisplay,
        );

  const PublicHandleResolveResult.invalidHandle()
      : this._(status: PublicHandleResolveStatus.invalidHandle);

  const PublicHandleResolveResult.notFound()
      : this._(status: PublicHandleResolveStatus.notFound);

  const PublicHandleResolveResult.inactive()
      : this._(status: PublicHandleResolveStatus.inactive);

  const PublicHandleResolveResult.invalidRole()
      : this._(status: PublicHandleResolveStatus.invalidRole);

  const PublicHandleResolveResult.invalidData()
      : this._(status: PublicHandleResolveStatus.invalidData);

  const PublicHandleResolveResult.error()
      : this._(status: PublicHandleResolveStatus.error);

  final PublicHandleResolveStatus status;
  final String? uid;
  final String? handle;
  final String? handleDisplay;

  bool get isResolved => status == PublicHandleResolveStatus.resolved;
}

class PublicHandleResolver {
  PublicHandleResolver({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<PublicHandleResolveResult> resolve(String rawHandle) async {
    final validation = HandleValidator.validate(rawHandle);
    if (!validation.isValid) {
      return const PublicHandleResolveResult.invalidHandle();
    }

    final handle = validation.normalizedHandle;

    try {
      final snap = await _firestore.collection('handles').doc(handle).get();
      final data = snap.data();
      if (!snap.exists || data == null) {
        return const PublicHandleResolveResult.notFound();
      }

      final status = _readString(data['status'])?.toLowerCase();
      if (status != 'active') {
        return const PublicHandleResolveResult.inactive();
      }

      final role = _readString(data['role'])?.toLowerCase();
      if (role != 'prestador') {
        return const PublicHandleResolveResult.invalidRole();
      }

      final uid = _readString(data['uid']);
      if (uid == null) {
        return const PublicHandleResolveResult.invalidData();
      }

      final storedHandle = _readString(data['handle']) ?? handle;
      final handleDisplay =
          _readString(data['handleDisplay']) ?? '@$storedHandle';

      return PublicHandleResolveResult.resolved(
        uid: uid,
        handle: storedHandle,
        handleDisplay: handleDisplay,
      );
    } catch (_) {
      return const PublicHandleResolveResult.error();
    }
  }
}

String? _readString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}
