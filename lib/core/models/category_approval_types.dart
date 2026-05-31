enum CategoryRiskLevel {
  normal,
  sensitive,
  prohibited,
}

enum SensitiveCategoryRequestStatus {
  draft,
  submitted,
  pendingReview,
  approved,
  rejected,
  needsMoreInfo,
  expired,
  revoked,
}

enum EvidenceType {
  certificate,
  license,
  workExperience,
  portfolioReference,
  externalProfile,
  declaration,
  other,
}

enum ProviderCategoryApprovalStatus {
  approved,
  rejected,
  suspended,
  expired,
  revoked,
}

const Map<CategoryRiskLevel, String> _riskLevelValues = {
  CategoryRiskLevel.normal: 'normal',
  CategoryRiskLevel.sensitive: 'sensitive',
  CategoryRiskLevel.prohibited: 'prohibited',
};

const Map<SensitiveCategoryRequestStatus, String> _requestStatusValues = {
  SensitiveCategoryRequestStatus.draft: 'draft',
  SensitiveCategoryRequestStatus.submitted: 'submitted',
  SensitiveCategoryRequestStatus.pendingReview: 'pending_review',
  SensitiveCategoryRequestStatus.approved: 'approved',
  SensitiveCategoryRequestStatus.rejected: 'rejected',
  SensitiveCategoryRequestStatus.needsMoreInfo: 'needs_more_info',
  SensitiveCategoryRequestStatus.expired: 'expired',
  SensitiveCategoryRequestStatus.revoked: 'revoked',
};

const Map<EvidenceType, String> _evidenceTypeValues = {
  EvidenceType.certificate: 'certificate',
  EvidenceType.license: 'license',
  EvidenceType.workExperience: 'work_experience',
  EvidenceType.portfolioReference: 'portfolio_reference',
  EvidenceType.externalProfile: 'external_profile',
  EvidenceType.declaration: 'declaration',
  EvidenceType.other: 'other',
};

const Map<ProviderCategoryApprovalStatus, String> _approvalStatusValues = {
  ProviderCategoryApprovalStatus.approved: 'approved',
  ProviderCategoryApprovalStatus.rejected: 'rejected',
  ProviderCategoryApprovalStatus.suspended: 'suspended',
  ProviderCategoryApprovalStatus.expired: 'expired',
  ProviderCategoryApprovalStatus.revoked: 'revoked',
};

String categoryRiskLevelToFirestore(CategoryRiskLevel value) {
  return _riskLevelValues[value]!;
}

CategoryRiskLevel categoryRiskLevelFromFirestore(Object? value) {
  return _parseEnum(
    value,
    _riskLevelValues,
    fallback: CategoryRiskLevel.normal,
  );
}

String sensitiveCategoryRequestStatusToFirestore(
  SensitiveCategoryRequestStatus value,
) {
  return _requestStatusValues[value]!;
}

SensitiveCategoryRequestStatus sensitiveCategoryRequestStatusFromFirestore(
  Object? value,
) {
  return _parseEnum(
    value,
    _requestStatusValues,
    fallback: SensitiveCategoryRequestStatus.draft,
  );
}

String evidenceTypeToFirestore(EvidenceType value) {
  return _evidenceTypeValues[value]!;
}

EvidenceType? evidenceTypeFromFirestore(Object? value) {
  if (value is! String) return null;
  for (final entry in _evidenceTypeValues.entries) {
    if (entry.value == value) return entry.key;
  }
  return null;
}

List<EvidenceType> evidenceTypesFromFirestore(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .map(evidenceTypeFromFirestore)
      .whereType<EvidenceType>()
      .toList(growable: false);
}

List<String> evidenceTypesToFirestore(List<EvidenceType> values) {
  return values.map(evidenceTypeToFirestore).toList(growable: false);
}

String providerCategoryApprovalStatusToFirestore(
  ProviderCategoryApprovalStatus value,
) {
  return _approvalStatusValues[value]!;
}

ProviderCategoryApprovalStatus providerCategoryApprovalStatusFromFirestore(
  Object? value,
) {
  return _parseEnum(
    value,
    _approvalStatusValues,
    fallback: ProviderCategoryApprovalStatus.rejected,
  );
}

T _parseEnum<T>(
  Object? value,
  Map<T, String> values, {
  required T fallback,
}) {
  if (value is! String) return fallback;
  for (final entry in values.entries) {
    if (entry.value == value) return entry.key;
  }
  return fallback;
}
