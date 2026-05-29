import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/models/trust_safety_report.dart';
import 'package:chegaja_v2/core/models/user_block.dart';

void main() {
  group('moderation type codecs', () {
    test('serializes and parses report target types', () {
      expect(
        reportTargetTypeToFirestore(ReportTargetType.providerProfile),
        'provider_profile',
      );
      expect(
        reportTargetTypeFromFirestore('chat_message'),
        ReportTargetType.chatMessage,
      );
      expect(reportTargetTypeFromFirestore('bad_target'), isNull);
    });

    test('serializes and parses reason codes, severities and statuses', () {
      expect(
        reportReasonCodeToFirestore(ReportReasonCode.childSafety),
        'child_safety',
      );
      expect(reportReasonCodeFromFirestore('fraud'), ReportReasonCode.fraud);
      expect(reportReasonCodeFromFirestore('bad_reason'), isNull);

      expect(reportSeverityToFirestore(ReportSeverity.critical), 'critical');
      expect(reportSeverityFromFirestore('high'), ReportSeverity.high);
      expect(reportSeverityFromFirestore('urgent'), isNull);

      expect(
        moderationStatusToFirestore(ModerationStatus.pendingReview),
        'pending_review',
      );
      expect(moderationStatusFromFirestore('hidden'), ModerationStatus.hidden);
      expect(moderationStatusFromFirestore('bad_status'), isNull);
    });
  });

  group('TrustSafetyReport', () {
    test('builds a valid create payload with pending review status', () {
      final report = TrustSafetyReport.create(
        reporterId: 'client1',
        targetType: ReportTargetType.providerProfile,
        targetId: 'provider1',
        reasonCode: ReportReasonCode.fraud,
        severity: ReportSeverity.high,
        details: 'Perfil parece enganoso',
        targetOwnerId: 'provider1',
      );

      final map = report.toFirestore();

      expect(map['reporterId'], 'client1');
      expect(map['targetType'], 'provider_profile');
      expect(map['targetId'], 'provider1');
      expect(map['reasonCode'], 'fraud');
      expect(map['severity'], 'high');
      expect(map['status'], 'pending_review');
      expect(map['details'], 'Perfil parece enganoso');
      expect(map['targetOwnerId'], 'provider1');
    });

    test('parses valid data and rejects invalid enum values defensively', () {
      final report = TrustSafetyReport.fromFirestoreMap(
        id: 'report1',
        data: const {
          'reporterId': 'client1',
          'targetType': 'provider_profile',
          'targetId': 'provider1',
          'reasonCode': 'fraud',
          'severity': 'high',
          'status': 'pending_review',
        },
      );

      expect(report, isNotNull);
      expect(report!.targetType, ReportTargetType.providerProfile);
      expect(report.reasonCode, ReportReasonCode.fraud);
      expect(report.status, ModerationStatus.pendingReview);

      final invalid = TrustSafetyReport.fromFirestoreMap(
        id: 'report2',
        data: const {
          'reporterId': 'client1',
          'targetType': 'unknown',
          'targetId': 'provider1',
          'reasonCode': 'fraud',
          'severity': 'high',
          'status': 'pending_review',
        },
      );

      expect(invalid, isNull);
    });
  });

  group('UserBlock', () {
    test('builds and parses a blocked user payload', () {
      final block = UserBlock.create(
        ownerUid: 'client1',
        blockedUid: 'provider1',
        reason: 'Nao quero receber mensagens',
        source: 'chat',
      );

      final map = block.toFirestore();

      expect(map['blockedUid'], 'provider1');
      expect(map['reason'], 'Nao quero receber mensagens');
      expect(map['source'], 'chat');

      final parsed = UserBlock.fromFirestoreMap(
        ownerUid: 'client1',
        id: 'provider1',
        data: map,
      );

      expect(parsed, isNotNull);
      expect(parsed!.ownerUid, 'client1');
      expect(parsed.blockedUid, 'provider1');
    });

    test('rejects self-block and mismatched document id defensively', () {
      expect(
        () => UserBlock.create(ownerUid: 'client1', blockedUid: 'client1'),
        throwsArgumentError,
      );

      final parsed = UserBlock.fromFirestoreMap(
        ownerUid: 'client1',
        id: 'provider1',
        data: const {'blockedUid': 'provider2'},
      );

      expect(parsed, isNull);
    });
  });
}
