import 'moderation_types.dart';

class TrustSafetyReport {
  const TrustSafetyReport({
    this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reasonCode,
    required this.severity,
    required this.status,
    this.details,
    this.targetOwnerId,
    this.sourceContext,
    this.pedidoId,
    this.chatId,
    this.messageId,
    this.mediaUrl,
    this.mediaPath,
  });

  factory TrustSafetyReport.create({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required ReportReasonCode reasonCode,
    required ReportSeverity severity,
    String? details,
    String? targetOwnerId,
    String? sourceContext,
    String? pedidoId,
    String? chatId,
    String? messageId,
    String? mediaUrl,
    String? mediaPath,
  }) {
    final cleanReporterId = reporterId.trim();
    final cleanTargetId = targetId.trim();
    if (cleanReporterId.isEmpty) {
      throw ArgumentError.value(reporterId, 'reporterId', 'Required');
    }
    if (cleanTargetId.isEmpty) {
      throw ArgumentError.value(targetId, 'targetId', 'Required');
    }

    return TrustSafetyReport(
      reporterId: cleanReporterId,
      targetType: targetType,
      targetId: cleanTargetId,
      reasonCode: reasonCode,
      severity: severity,
      status: ModerationStatus.pendingReview,
      details: _cleanOptional(details, maxLength: 1000),
      targetOwnerId: _cleanOptional(targetOwnerId),
      sourceContext: _cleanOptional(sourceContext),
      pedidoId: _cleanOptional(pedidoId),
      chatId: _cleanOptional(chatId),
      messageId: _cleanOptional(messageId),
      mediaUrl: _cleanOptional(mediaUrl),
      mediaPath: _cleanOptional(mediaPath),
    );
  }

  final String? id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final ReportReasonCode reasonCode;
  final ReportSeverity severity;
  final ModerationStatus status;
  final String? details;
  final String? targetOwnerId;
  final String? sourceContext;
  final String? pedidoId;
  final String? chatId;
  final String? messageId;
  final String? mediaUrl;
  final String? mediaPath;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'reporterId': reporterId,
      'targetType': reportTargetTypeToFirestore(targetType),
      'targetId': targetId,
      'reasonCode': reportReasonCodeToFirestore(reasonCode),
      'severity': reportSeverityToFirestore(severity),
      'status': moderationStatusToFirestore(status),
      if (details != null) 'details': details,
      if (targetOwnerId != null) 'targetOwnerId': targetOwnerId,
      if (sourceContext != null) 'sourceContext': sourceContext,
      if (pedidoId != null) 'pedidoId': pedidoId,
      if (chatId != null) 'chatId': chatId,
      if (messageId != null) 'messageId': messageId,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaPath != null) 'mediaPath': mediaPath,
    };
  }

  static TrustSafetyReport? fromFirestoreMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final reporterId = data['reporterId'];
    final targetId = data['targetId'];
    final targetType = reportTargetTypeFromFirestore(data['targetType']);
    final reasonCode = reportReasonCodeFromFirestore(data['reasonCode']);
    final severity = reportSeverityFromFirestore(data['severity']);
    final status = moderationStatusFromFirestore(data['status']);

    if (reporterId is! String ||
        reporterId.trim().isEmpty ||
        targetId is! String ||
        targetId.trim().isEmpty ||
        targetType == null ||
        reasonCode == null ||
        severity == null ||
        status == null) {
      return null;
    }

    return TrustSafetyReport(
      id: id,
      reporterId: reporterId,
      targetType: targetType,
      targetId: targetId,
      reasonCode: reasonCode,
      severity: severity,
      status: status,
      details: _readOptionalString(data['details']),
      targetOwnerId: _readOptionalString(data['targetOwnerId']),
      sourceContext: _readOptionalString(data['sourceContext']),
      pedidoId: _readOptionalString(data['pedidoId']),
      chatId: _readOptionalString(data['chatId']),
      messageId: _readOptionalString(data['messageId']),
      mediaUrl: _readOptionalString(data['mediaUrl']),
      mediaPath: _readOptionalString(data['mediaPath']),
    );
  }
}

String? _cleanOptional(String? value, {int maxLength = 500}) {
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
