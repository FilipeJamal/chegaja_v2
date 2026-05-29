class UserBlock {
  const UserBlock({
    required this.ownerUid,
    required this.blockedUid,
    this.reason,
    this.source,
  });

  factory UserBlock.create({
    required String ownerUid,
    required String blockedUid,
    String? reason,
    String? source,
  }) {
    final cleanOwnerUid = ownerUid.trim();
    final cleanBlockedUid = blockedUid.trim();
    if (cleanOwnerUid.isEmpty) {
      throw ArgumentError.value(ownerUid, 'ownerUid', 'Required');
    }
    if (cleanBlockedUid.isEmpty) {
      throw ArgumentError.value(blockedUid, 'blockedUid', 'Required');
    }
    if (cleanOwnerUid == cleanBlockedUid) {
      throw ArgumentError.value(blockedUid, 'blockedUid', 'Cannot block self');
    }

    return UserBlock(
      ownerUid: cleanOwnerUid,
      blockedUid: cleanBlockedUid,
      reason: _cleanOptional(reason, maxLength: 500),
      source: _cleanOptional(source, maxLength: 120),
    );
  }

  final String ownerUid;
  final String blockedUid;
  final String? reason;
  final String? source;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'blockedUid': blockedUid,
      if (reason != null) 'reason': reason,
      if (source != null) 'source': source,
    };
  }

  static UserBlock? fromFirestoreMap({
    required String ownerUid,
    required String id,
    required Map<String, dynamic> data,
  }) {
    final blockedUid = data['blockedUid'];
    if (blockedUid is! String || blockedUid.trim().isEmpty) return null;
    if (blockedUid != id) return null;
    if (blockedUid == ownerUid) return null;

    return UserBlock(
      ownerUid: ownerUid,
      blockedUid: blockedUid,
      reason: _readOptionalString(data['reason']),
      source: _readOptionalString(data['source']),
    );
  }
}

String? _cleanOptional(String? value, {required int maxLength}) {
  final clean = value?.trim();
  if (clean == null || clean.isEmpty) return null;
  if (clean.length > maxLength) {
    throw ArgumentError.value(value, 'value', 'Too long');
  }
  return clean;
}

String? _readOptionalString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value;
}
