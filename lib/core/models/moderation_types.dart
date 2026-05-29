enum ReportTargetType {
  providerProfile,
  clientProfile,
  portfolioMedia,
  story,
  chatMessage,
  review,
  serviceCategory,
  serviceRequest,
  user,
  other,
}

enum ReportReasonCode {
  illegalService,
  sexualContent,
  drugs,
  fraud,
  harassment,
  hateSpeech,
  violence,
  childSafety,
  personalData,
  spam,
  scam,
  impersonation,
  unsafeService,
  copyrightOrStolenMedia,
  offPlatformCircumvention,
  other,
}

enum ReportSeverity {
  low,
  medium,
  high,
  critical,
}

enum ModerationStatus {
  clean,
  approved,
  pendingReview,
  flagged,
  hidden,
  rejected,
  reviewed,
  resolved,
  dismissed,
  escalated,
  suspended,
  banned,
  appealRequested,
  restored,
}

const Map<ReportTargetType, String> _reportTargetTypeValues = {
  ReportTargetType.providerProfile: 'provider_profile',
  ReportTargetType.clientProfile: 'client_profile',
  ReportTargetType.portfolioMedia: 'portfolio_media',
  ReportTargetType.story: 'story',
  ReportTargetType.chatMessage: 'chat_message',
  ReportTargetType.review: 'review',
  ReportTargetType.serviceCategory: 'service_category',
  ReportTargetType.serviceRequest: 'service_request',
  ReportTargetType.user: 'user',
  ReportTargetType.other: 'other',
};

const Map<ReportReasonCode, String> _reportReasonCodeValues = {
  ReportReasonCode.illegalService: 'illegal_service',
  ReportReasonCode.sexualContent: 'sexual_content',
  ReportReasonCode.drugs: 'drugs',
  ReportReasonCode.fraud: 'fraud',
  ReportReasonCode.harassment: 'harassment',
  ReportReasonCode.hateSpeech: 'hate_speech',
  ReportReasonCode.violence: 'violence',
  ReportReasonCode.childSafety: 'child_safety',
  ReportReasonCode.personalData: 'personal_data',
  ReportReasonCode.spam: 'spam',
  ReportReasonCode.scam: 'scam',
  ReportReasonCode.impersonation: 'impersonation',
  ReportReasonCode.unsafeService: 'unsafe_service',
  ReportReasonCode.copyrightOrStolenMedia: 'copyright_or_stolen_media',
  ReportReasonCode.offPlatformCircumvention: 'off_platform_circumvention',
  ReportReasonCode.other: 'other',
};

const Map<ReportSeverity, String> _reportSeverityValues = {
  ReportSeverity.low: 'low',
  ReportSeverity.medium: 'medium',
  ReportSeverity.high: 'high',
  ReportSeverity.critical: 'critical',
};

const Map<ModerationStatus, String> _moderationStatusValues = {
  ModerationStatus.clean: 'clean',
  ModerationStatus.approved: 'approved',
  ModerationStatus.pendingReview: 'pending_review',
  ModerationStatus.flagged: 'flagged',
  ModerationStatus.hidden: 'hidden',
  ModerationStatus.rejected: 'rejected',
  ModerationStatus.reviewed: 'reviewed',
  ModerationStatus.resolved: 'resolved',
  ModerationStatus.dismissed: 'dismissed',
  ModerationStatus.escalated: 'escalated',
  ModerationStatus.suspended: 'suspended',
  ModerationStatus.banned: 'banned',
  ModerationStatus.appealRequested: 'appeal_requested',
  ModerationStatus.restored: 'restored',
};

String reportTargetTypeToFirestore(ReportTargetType value) =>
    _reportTargetTypeValues[value]!;

ReportTargetType? reportTargetTypeFromFirestore(Object? value) =>
    _parseEnumValue(_reportTargetTypeValues, value);

String reportReasonCodeToFirestore(ReportReasonCode value) =>
    _reportReasonCodeValues[value]!;

ReportReasonCode? reportReasonCodeFromFirestore(Object? value) =>
    _parseEnumValue(_reportReasonCodeValues, value);

String reportSeverityToFirestore(ReportSeverity value) =>
    _reportSeverityValues[value]!;

ReportSeverity? reportSeverityFromFirestore(Object? value) =>
    _parseEnumValue(_reportSeverityValues, value);

String moderationStatusToFirestore(ModerationStatus value) =>
    _moderationStatusValues[value]!;

ModerationStatus? moderationStatusFromFirestore(Object? value) =>
    _parseEnumValue(_moderationStatusValues, value);

T? _parseEnumValue<T>(Map<T, String> values, Object? raw) {
  if (raw is! String) return null;
  for (final entry in values.entries) {
    if (entry.value == raw) return entry.key;
  }
  return null;
}
