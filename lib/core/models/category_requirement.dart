import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_approval_types.dart';

class CategoryRequirement {
  const CategoryRequirement({
    required this.categoryId,
    required this.categoryName,
    required this.riskLevel,
    required this.approvalRequired,
    this.evidenceTypes = const [],
    this.description,
    this.userMessage,
    this.adminNotes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String categoryId;
  final String categoryName;
  final CategoryRiskLevel riskLevel;
  final bool approvalRequired;
  final List<EvidenceType> evidenceTypes;
  final String? description;
  final String? userMessage;
  final String? adminNotes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isSensitive => riskLevel == CategoryRiskLevel.sensitive;

  bool get requiresApproval =>
      isActive && approvalRequired && riskLevel == CategoryRiskLevel.sensitive;

  factory CategoryRequirement.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return CategoryRequirement.fromMap(doc.data() ?? const {}, id: doc.id);
  }

  factory CategoryRequirement.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    final categoryId = _readString(map['categoryId']) ?? id ?? '';
    return CategoryRequirement(
      categoryId: categoryId,
      categoryName: _readString(map['categoryName']) ?? categoryId,
      riskLevel: categoryRiskLevelFromFirestore(map['riskLevel']),
      approvalRequired: map['approvalRequired'] == true,
      evidenceTypes: evidenceTypesFromFirestore(map['evidenceTypes']),
      description: _readString(map['description']),
      userMessage: _readString(map['userMessage']),
      adminNotes: _readString(map['adminNotes']),
      isActive: map['isActive'] != false,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'categoryId': categoryId,
      'categoryName': categoryName,
      'riskLevel': categoryRiskLevelToFirestore(riskLevel),
      'approvalRequired': approvalRequired,
      'evidenceTypes': evidenceTypesToFirestore(evidenceTypes),
      if (description != null) 'description': description,
      if (userMessage != null) 'userMessage': userMessage,
      if (adminNotes != null) 'adminNotes': adminNotes,
      'isActive': isActive,
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
