enum PublicHandleStatus {
  active,
  released,
  reserved,
  blocked,
}

const Map<PublicHandleStatus, String> _publicHandleStatusValues = {
  PublicHandleStatus.active: 'active',
  PublicHandleStatus.released: 'released',
  PublicHandleStatus.reserved: 'reserved',
  PublicHandleStatus.blocked: 'blocked',
};

String publicHandleStatusToFirestore(PublicHandleStatus value) {
  return _publicHandleStatusValues[value]!;
}

PublicHandleStatus? publicHandleStatusFromFirestore(Object? value) {
  if (value is! String) return null;
  for (final entry in _publicHandleStatusValues.entries) {
    if (entry.value == value) return entry.key;
  }
  return null;
}

class PublicHandle {
  const PublicHandle({
    required this.handle,
    required this.uid,
    required this.role,
    required this.status,
    this.handleDisplay,
    this.createdAt,
    this.updatedAt,
    this.reservedUntil,
    this.releasedAt,
    this.previousOwnerUid,
    this.source,
  });

  final String handle;
  final String uid;
  final String role;
  final PublicHandleStatus status;
  final String? handleDisplay;
  final Object? createdAt;
  final Object? updatedAt;
  final Object? reservedUntil;
  final Object? releasedAt;
  final String? previousOwnerUid;
  final String? source;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'handle': handle,
      'uid': uid,
      'role': role,
      'status': publicHandleStatusToFirestore(status),
      if (handleDisplay != null) 'handleDisplay': handleDisplay,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (reservedUntil != null) 'reservedUntil': reservedUntil,
      if (releasedAt != null) 'releasedAt': releasedAt,
      if (previousOwnerUid != null) 'previousOwnerUid': previousOwnerUid,
      if (source != null) 'source': source,
    };
  }

  static PublicHandle? fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final handle = _readString(data['handle']) ?? id.trim();
    final uid = _readString(data['uid']);
    final role = _readString(data['role']);
    final status = publicHandleStatusFromFirestore(data['status']);

    if (handle.isEmpty || uid == null || role == null || status == null) {
      return null;
    }

    return PublicHandle(
      handle: handle,
      uid: uid,
      role: role,
      status: status,
      handleDisplay: _readString(data['handleDisplay']),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
      reservedUntil: data['reservedUntil'],
      releasedAt: data['releasedAt'],
      previousOwnerUid: _readString(data['previousOwnerUid']),
      source: _readString(data['source']),
    );
  }
}

String? _readString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}
