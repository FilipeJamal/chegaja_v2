import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/features/common/trust_safety/block_user_dialog.dart';
import 'package:chegaja_v2/features/common/trust_safety/report_content_sheet.dart';

class TrustSafetyActionsMenu extends StatelessWidget {
  const TrustSafetyActionsMenu({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.blockedUid,
    this.targetOwnerId,
    this.targetName,
    this.sourceContext,
    this.reportLabel = 'Denunciar perfil',
    this.blockLabel = 'Bloquear utilizador',
    this.onReportSubmit,
    this.onBlockUser,
  });

  final ReportTargetType targetType;
  final String targetId;
  final String blockedUid;
  final String? targetOwnerId;
  final String? targetName;
  final String? sourceContext;
  final String reportLabel;
  final String blockLabel;
  final ReportSubmitCallback? onReportSubmit;
  final BlockUserCallback? onBlockUser;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TrustSafetyAction>(
      key: key ?? const Key('trust_safety_actions_menu'),
      tooltip: 'Acoes de seguranca',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (value) {
        switch (value) {
          case _TrustSafetyAction.report:
            ReportContentSheet.show(
              context,
              targetType: targetType,
              targetId: targetId,
              targetOwnerId: targetOwnerId,
              sourceContext: sourceContext,
              onSubmit: onReportSubmit,
            );
            break;
          case _TrustSafetyAction.block:
            BlockUserDialog.show(
              context,
              blockedUid: blockedUid,
              userLabel: targetName,
              onConfirm: onBlockUser,
            );
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _TrustSafetyAction.report,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: Text(reportLabel),
          ),
        ),
        PopupMenuItem(
          value: _TrustSafetyAction.block,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.block_rounded),
            title: Text(blockLabel),
          ),
        ),
      ],
    );
  }
}

enum _TrustSafetyAction { report, block }
