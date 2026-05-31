import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_approval_types.dart';

class SensitiveCategoryRequest {
  const SensitiveCategoryRequest({
    this.id,
    required this.providerId,
    required this.categoryId,
    required this.categoryName,
    required this.status,
    this.evidenceTypes = const [],
    this.evidenceText,
    this.portfolioUrls = const [],
    this.documentRefs = const [],
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.decisionReason,
    this.expiresAt,
  });

  final String? id;
  final String providerId;
  final String categoryId;
  final String categoryName;
  final SensitiveCategoryRequestStatus status;
  final List<EvidenceType> evidenceTypes;
  final String? evidenceText;
  final List<String> portfolioUrls;
  final List<String> documentRefs;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? decisionReason;
  final DateTime? expiresAt;

  bool get canProviderEdit =>
      status == SensitiveCategoryRequestStatus.draft ||
      status == SensitiveCategoryRequestStatus.needsMoreInfo;

  bool get isFinal =>
      status == SensitiveCategoryRequestStatus.approved ||
      status == SensitiveCategoryRequestStatus.rejected ||
      status == SensitiveCategoryRequestStatus.expired ||
      status == SensitiveCategoryRequestStatus.revoked;

  factory SensitiveCategoryRequest.draft({
    required String providerId,
    required String categoryId,
    required String categoryName,
    List<EvidenceType> evidenceTypes = const [],
    String? evidenceText,
    List<String> portfolioUrls = const [],
    List<String> documentRefs = const [],
  }) {
    return SensitiveCategoryRequest(
      providerId: providerId,
      categoryId: categoryId,
      categoryName: categoryName,
      status: SensitiveCategoryRequestStatus.draft,
      evidenceTypes: evidenceTypes,
      evidenceText: evidenceText,
      portfolioUrls: portfolioUrls,
      documentRefs: documentRefs,
    );
  }

  factory SensitiveCategoryRequest.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return SensitiveCategoryRequest.fromMap(doc.data() ?? const {}, id: doc.id);
  }

  factory SensitiveCategoryRequest.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    final categoryId = _readString(map['categoryId']) ?? '';
    return SensitiveCategoryRequest(
      id: id,
      providerId: _readString(map['providerId']) ?? '',
      categoryId: categoryId,
      categoryName: _readString(map['categoryName']) ?? categoryId,
      status: sensitiveCategoryRequestStatusFromFirestore(map['status']),
      evidenceTypes: evidenceTypesFromFirestore(map['evidenceTypes']),
      evidenceText: _readString(map['evidenceText']),
      portfolioUrls: _stringList(map['portfolioUrls']),
      documentRefs: _stringList(map['documentRefs']),
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      submittedAt: _toDateTime(map['submittedAt']),
      reviewedBy: _readString(map['reviewedBy']),
      reviewedAt: _toDateTime(map['reviewedAt']),
      decisionReason: _readString(map['decisionReason']),
      expiresAt: _toDateTime(map['expiresAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'status': sensitiveCategoryRequestStatusToFirestore(status),
      'evidenceTypes': evidenceTypesToFirestore(evidenceTypes),
      if (evidenceText != null) 'evidenceText': evidenceText,
      'portfolioUrls': portfolioUrls,
      'documentRefs': documentRefs,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (decisionReason != null) 'decisionReason': decisionReason,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
    };
  }

  SensitiveCategoryRequest copyWith({
    String? id,
    SensitiveCategoryRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
  }) {
    return SensitiveCategoryRequest(
      id: id ?? this.id,
      providerId: providerId,
      categoryId: categoryId,
      categoryName: categoryName,
      status: status ?? this.status,
      evidenceTypes: evidenceTypes,
      evidenceText: evidenceText,
      portfolioUrls: portfolioUrls,
      documentRefs: documentRefs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      decisionReason: decisionReason,
      expiresAt: expiresAt,
    );
  }
}

String? _readString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime? _toDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
