import 'moderation_types.dart';

class ModerationCase {
  const ModerationCase({
    this.id,
    required this.sourceReportId,
    required this.targetType,
    required this.targetId,
    required this.status,
    required this.severity,
    this.assignedTo,
    this.actionTaken,
    this.decisionReason,
  });

  final String? id;
  final String sourceReportId;
  final ReportTargetType targetType;
  final String targetId;
  final ModerationStatus status;
  final ReportSeverity severity;
  final String? assignedTo;
  final String? actionTaken;
  final String? decisionReason;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'sourceReportId': sourceReportId,
      'targetType': reportTargetTypeToFirestore(targetType),
      'targetId': targetId,
      'status': moderationStatusToFirestore(status),
      'severity': reportSeverityToFirestore(severity),
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (actionTaken != null) 'actionTaken': actionTaken,
      if (decisionReason != null) 'decisionReason': decisionReason,
    };
  }
}
