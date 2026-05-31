import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_approval_types.dart';

class ProviderCategoryApproval {
  const ProviderCategoryApproval({
    required this.providerId,
    required this.categoryId,
    required this.categoryName,
    required this.status,
    this.sourceRequestId,
    this.approvedBy,
    this.approvedAt,
    this.expiresAt,
    this.revokedAt,
    this.decisionReason,
    this.createdAt,
    this.updatedAt,
  });

  final String providerId;
  final String categoryId;
  final String categoryName;
  final ProviderCategoryApprovalStatus status;
  final String? sourceRequestId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? decisionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCurrentlyApproved => isCurrentlyApprovedAt(DateTime.now());

  bool isCurrentlyApprovedAt(DateTime now) {
    if (status != ProviderCategoryApprovalStatus.approved) return false;
    final expiresAt = this.expiresAt;
    if (expiresAt == null) return true;
    return expiresAt.isAfter(now);
  }

  factory ProviderCategoryApproval.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ProviderCategoryApproval.fromMap(doc.data() ?? const {}, id: doc.id);
  }

  factory ProviderCategoryApproval.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    final parts = id?.split('_') ?? const <String>[];
    final fallbackProviderId = parts.isNotEmpty ? parts.first : '';
    final fallbackCategoryId =
        parts.length > 1 ? parts.sublist(1).join('_') : '';
    final categoryId = _readString(map['categoryId']) ?? fallbackCategoryId;
    return ProviderCategoryApproval(
      providerId: _readString(map['providerId']) ?? fallbackProviderId,
      categoryId: categoryId,
      categoryName: _readString(map['categoryName']) ?? categoryId,
      status: providerCategoryApprovalStatusFromFirestore(map['status']),
      sourceRequestId: _readString(map['sourceRequestId']),
      approvedBy: _readString(map['approvedBy']),
      approvedAt: _toDateTime(map['approvedAt']),
      expiresAt: _toDateTime(map['expiresAt']),
      revokedAt: _toDateTime(map['revokedAt']),
      decisionReason: _readString(map['decisionReason']),
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'status': providerCategoryApprovalStatusToFirestore(status),
      if (sourceRequestId != null) 'sourceRequestId': sourceRequestId,
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (revokedAt != null) 'revokedAt': Timestamp.fromDate(revokedAt!),
      if (decisionReason != null) 'decisionReason': decisionReason,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

String? _readString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

DateTime? _toDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
