import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';

class CategoryApprovalStatusChip extends StatelessWidget {
  const CategoryApprovalStatusChip.request({
    super.key,
    required SensitiveCategoryRequestStatus status,
  })  : label = null,
        requestStatus = status,
        approvalStatus = null;

  const CategoryApprovalStatusChip.approval({
    super.key,
    required ProviderCategoryApprovalStatus status,
  })  : label = null,
        requestStatus = null,
        approvalStatus = status;

  const CategoryApprovalStatusChip.label({
    super.key,
    required this.label,
  })  : requestStatus = null,
        approvalStatus = null;

  final SensitiveCategoryRequestStatus? requestStatus;
  final ProviderCategoryApprovalStatus? approvalStatus;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve();
    return AppStatusPill(
      label: resolved.label,
      tone: resolved.tone,
      icon: resolved.icon,
      size: AppStatusPillSize.sm,
    );
  }

  _ResolvedStatus _resolve() {
    final request = requestStatus;
    if (request != null) {
      return switch (request) {
        SensitiveCategoryRequestStatus.draft => const _ResolvedStatus(
            label: 'Rascunho',
            tone: AppStatusTone.neutral,
            icon: Icons.edit_note,
          ),
        SensitiveCategoryRequestStatus.submitted ||
        SensitiveCategoryRequestStatus.pendingReview =>
          const _ResolvedStatus(
            label: 'Em analise',
            tone: AppStatusTone.info,
            icon: Icons.schedule,
          ),
        SensitiveCategoryRequestStatus.approved => const _ResolvedStatus(
            label: 'Aprovado',
            tone: AppStatusTone.success,
            icon: Icons.check_circle_outline,
          ),
        SensitiveCategoryRequestStatus.rejected => const _ResolvedStatus(
            label: 'Rejeitado',
            tone: AppStatusTone.danger,
            icon: Icons.cancel_outlined,
          ),
        SensitiveCategoryRequestStatus.needsMoreInfo => const _ResolvedStatus(
            label: 'Precisa de mais informacao',
            tone: AppStatusTone.warning,
            icon: Icons.info_outline,
          ),
        SensitiveCategoryRequestStatus.expired => const _ResolvedStatus(
            label: 'Expirado',
            tone: AppStatusTone.neutral,
            icon: Icons.event_busy,
          ),
        SensitiveCategoryRequestStatus.revoked => const _ResolvedStatus(
            label: 'Revogado',
            tone: AppStatusTone.danger,
            icon: Icons.block,
          ),
      };
    }

    final approval = approvalStatus;
    if (approval != null) {
      return switch (approval) {
        ProviderCategoryApprovalStatus.approved => const _ResolvedStatus(
            label: 'Aprovacao ativa',
            tone: AppStatusTone.success,
            icon: Icons.verified_user_outlined,
          ),
        ProviderCategoryApprovalStatus.rejected => const _ResolvedStatus(
            label: 'Rejeitado',
            tone: AppStatusTone.danger,
            icon: Icons.cancel_outlined,
          ),
        ProviderCategoryApprovalStatus.suspended => const _ResolvedStatus(
            label: 'Suspenso',
            tone: AppStatusTone.warning,
            icon: Icons.pause_circle_outline,
          ),
        ProviderCategoryApprovalStatus.expired => const _ResolvedStatus(
            label: 'Expirado',
            tone: AppStatusTone.neutral,
            icon: Icons.event_busy,
          ),
        ProviderCategoryApprovalStatus.revoked => const _ResolvedStatus(
            label: 'Revogado',
            tone: AppStatusTone.danger,
            icon: Icons.block,
          ),
      };
    }

    return _ResolvedStatus(
      label: label ?? 'Sem pedido',
      tone: AppStatusTone.neutral,
      icon: Icons.radio_button_unchecked,
    );
  }
}

class _ResolvedStatus {
  const _ResolvedStatus({
    required this.label,
    required this.tone,
    required this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final IconData icon;
}
