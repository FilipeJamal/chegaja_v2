import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/category_requirement.dart';
import 'package:chegaja_v2/core/models/provider_category_approval.dart';
import 'package:chegaja_v2/core/models/sensitive_category_request.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/trust_safety/sensitive_categories.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/prestador/widgets/category_approval_status_chip.dart';
import 'package:chegaja_v2/features/prestador/widgets/sensitive_category_request_sheet.dart';

typedef SensitiveCategoryRequestCallback = void Function(
  CategoryRequirement requirement,
  SensitiveCategoryRequest? currentRequest,
);

class PrestadorSensitiveCategoriesSection extends StatelessWidget {
  const PrestadorSensitiveCategoriesSection({
    super.key,
    required this.requirements,
    required this.requests,
    required this.approvals,
    required this.onRequestApproval,
    this.loading = false,
    this.error,
    this.onRefresh,
  });

  final List<CategoryRequirement> requirements;
  final List<SensitiveCategoryRequest> requests;
  final List<ProviderCategoryApproval> approvals;
  final SensitiveCategoryRequestCallback onRequestApproval;
  final bool loading;
  final String? error;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeRequirements = requirements
        .where((requirement) => requirement.requiresApproval)
        .toList(growable: false)
      ..sort((a, b) => a.categoryName.compareTo(b.categoryName));

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categorias sensiveis e comprovativos',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alguns servicos precisam de analise antes de poderes apresenta-los como aprovados no ChegaJa.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  tooltip: 'Atualizar categorias',
                  onPressed: loading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            _StateBox(
              icon: Icons.error_outline,
              message: error!,
              tone: AppStatusTone.danger,
            )
          else if (activeRequirements.isEmpty)
            const _StateBox(
              icon: Icons.check_circle_outline,
              message: 'Sem categorias sensiveis selecionadas.',
              tone: AppStatusTone.neutral,
            )
          else
            Column(
              children: [
                for (var index = 0; index < activeRequirements.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == activeRequirements.length - 1 ? 0 : 12,
                    ),
                    child: _SensitiveCategoryCard(
                      requirement: activeRequirements[index],
                      request: _latestRequestFor(
                        activeRequirements[index].categoryId,
                      ),
                      approval: _approvalFor(
                        activeRequirements[index].categoryId,
                      ),
                      onRequestApproval: onRequestApproval,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  SensitiveCategoryRequest? _latestRequestFor(String categoryId) {
    final matches = requests
        .where((request) => request.categoryId == categoryId)
        .toList(growable: false);
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final aDate = a.updatedAt ?? a.submittedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.submittedAt ?? b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return matches.first;
  }

  ProviderCategoryApproval? _approvalFor(String categoryId) {
    for (final approval in approvals) {
      if (approval.categoryId == categoryId && approval.isCurrentlyApproved) {
        return approval;
      }
    }
    return null;
  }
}

class _SensitiveCategoryCard extends StatelessWidget {
  const _SensitiveCategoryCard({
    required this.requirement,
    required this.request,
    required this.approval,
    required this.onRequestApproval,
  });

  final CategoryRequirement requirement;
  final SensitiveCategoryRequest? request;
  final ProviderCategoryApproval? approval;
  final SensitiveCategoryRequestCallback onRequestApproval;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canUpdate =
        request?.status == SensitiveCategoryRequestStatus.needsMoreInfo;
    final canCreate = approval == null &&
        (request == null ||
            request?.status == SensitiveCategoryRequestStatus.rejected ||
            request?.status == SensitiveCategoryRequestStatus.expired ||
            request?.status == SensitiveCategoryRequestStatus.revoked ||
            canUpdate);
    final message = requirement.userMessage ??
        requirement.description ??
        'Esta categoria precisa de analise antes de ficar aprovada.';

    return AppCard(
      variant: AppCardVariant.flat,
      size: AppCardSize.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requirement.categoryName,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (approval != null)
                CategoryApprovalStatusChip.approval(status: approval!.status)
              else if (request != null)
                CategoryApprovalStatusChip.request(status: request!.status)
              else
                const CategoryApprovalStatusChip.label(label: 'Sem pedido'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppStatusPill(
                label: requirement.riskLevel == CategoryRiskLevel.sensitive
                    ? 'Categoria sensivel'
                    : 'Categoria',
                tone: AppStatusTone.warning,
                size: AppStatusPillSize.sm,
                icon: Icons.info_outline,
              ),
              if (requirement.evidenceTypes.isNotEmpty)
                for (final type in requirement.evidenceTypes.take(3))
                  AppStatusPill(
                    label: evidenceTypeLabel(type),
                    tone: AppStatusTone.neutral,
                    size: AppStatusPillSize.sm,
                  ),
            ],
          ),
          if (canCreate) ...[
            const SizedBox(height: 12),
            AppButton(
              label: canUpdate ? 'Atualizar informacao' : 'Pedir aprovacao',
              leadingIcon:
                  canUpdate ? Icons.edit_note : Icons.assignment_outlined,
              variant: canUpdate
                  ? AppButtonVariant.secondary
                  : AppButtonVariant.primary,
              onPressed: () => onRequestApproval(requirement, request),
            ),
          ] else if (approval == null && request != null) ...[
            const SizedBox(height: 10),
            Text(
              'Pedido recebido. Aguarda a analise da equipa.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({
    required this.icon,
    required this.message,
    required this.tone,
  });

  final IconData icon;
  final String message;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = switch (tone) {
      AppStatusTone.danger => scheme.error,
      AppStatusTone.warning => Colors.orange,
      AppStatusTone.success => Colors.green,
      AppStatusTone.info => scheme.primary,
      AppStatusTone.neutral => scheme.onSurfaceVariant,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<CategoryRequirement> sensitiveRequirementsFromSelectedServices({
  required List<Servico> services,
  required Set<String> selectedServiceIds,
}) {
  final byId = <String, CategoryRequirement>{};
  for (final service in services) {
    if (!selectedServiceIds.contains(service.id)) continue;
    final searchableText = [
      service.name,
      ...service.nameI18n.values,
      ...service.keywords,
    ].join(' ');
    for (final sensitive in SensitiveCategories.match(searchableText)) {
      byId.putIfAbsent(
        sensitive.id,
        () => CategoryRequirement(
          categoryId: sensitive.id,
          categoryName: _sensitiveCategoryName(sensitive.id),
          riskLevel: CategoryRiskLevel.sensitive,
          approvalRequired: true,
          evidenceTypes: _defaultEvidenceTypesFor(sensitive.id),
          userMessage:
              'Esta categoria precisa de analise antes de ficar aprovada no ChegaJa.',
          isActive: true,
        ),
      );
    }
  }

  final requirements = byId.values.toList(growable: false)
    ..sort((a, b) => a.categoryName.compareTo(b.categoryName));
  return requirements;
}

String _sensitiveCategoryName(String id) {
  return switch (id) {
    'health' => 'Saude e bem-estar sensivel',
    'child_care' => 'Cuidados infantis',
    'elder_care' => 'Cuidados a idosos',
    'electricity' => 'Eletricidade',
    'gas' => 'Gas',
    'private_security' => 'Seguranca privada',
    'professional_food' => 'Alimentacao profissional',
    'training_nutrition' => 'Treino e nutricao',
    'transport' => 'Transporte',
    'in_home_service' => 'Servico em casa do cliente',
    _ => id,
  };
}

List<EvidenceType> _defaultEvidenceTypesFor(String id) {
  return switch (id) {
    'electricity' || 'gas' => const [
        EvidenceType.license,
        EvidenceType.workExperience,
        EvidenceType.portfolioReference,
      ],
    'child_care' || 'elder_care' => const [
        EvidenceType.workExperience,
        EvidenceType.declaration,
        EvidenceType.portfolioReference,
      ],
    'health' || 'training_nutrition' => const [
        EvidenceType.workExperience,
        EvidenceType.externalProfile,
        EvidenceType.declaration,
      ],
    _ => const [
        EvidenceType.workExperience,
        EvidenceType.portfolioReference,
        EvidenceType.other,
      ],
  };
}
