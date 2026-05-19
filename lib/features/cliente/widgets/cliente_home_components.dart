import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:flutter/material.dart';

class ClienteHomeHero extends StatelessWidget {
  const ClienteHomeHero({
    super.key,
    required this.greeting,
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.onSearch,
  });

  final String greeting;
  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: const Key('cliente_home_hero'),
      variant: AppCardVariant.elevated,
      size: AppCardSize.large,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRow = constraints.maxWidth >= 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                key: const Key('cliente_home_primary_cta'),
                label: primaryActionLabel,
                onPressed: onPrimaryAction,
                leadingIcon: Icons.add_rounded,
                trailingIcon: Icons.arrow_forward_rounded,
                size: AppButtonSize.lg,
                expanded: true,
              ),
              const SizedBox(height: AppSpacing.x2),
              AppButton(
                label: 'Pesquisar prestadores',
                onPressed: onSearch,
                leadingIcon: Icons.search_rounded,
                variant: AppButtonVariant.secondary,
                expanded: true,
              ),
            ],
          );

          if (!useRow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: AppSpacing.x5),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: copy),
              const SizedBox(width: AppSpacing.x6),
              SizedBox(width: 280, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class ClienteServicesSection extends StatelessWidget {
  const ClienteServicesSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.search,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Widget search;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('cliente_home_services_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: title,
          subtitle: subtitle,
        ),
        search,
        const SizedBox(height: AppSpacing.x4),
        AppResponsiveGrid(
          minItemWidth: 250,
          spacing: AppSpacing.x3,
          runSpacing: AppSpacing.x3,
          children: children,
        ),
      ],
    );
  }
}

class ClienteServiceTile extends StatelessWidget {
  const ClienteServiceTile({
    super.key,
    required this.servico,
    required this.localeCode,
    required this.modeLabel,
    required this.onTap,
  });

  final Servico servico;
  final String localeCode;
  final String modeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = clienteServiceIconFor(servico.iconKey);
    final key = Key(
      'cliente_home_service_tile_${clienteHomeSafeKey(servico.id)}',
    );

    return AppCard(
      key: key,
      onTap: onTap,
      variant: AppCardVariant.outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  servico.nameForLang(localeCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                AppStatusPill(
                  label: modeLabel,
                  tone: clienteServiceToneFor(servico.mode),
                  size: AppStatusPillSize.sm,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Icon(
            Icons.arrow_forward_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class ClienteHomeOperationsPanel extends StatelessWidget {
  const ClienteHomeOperationsPanel({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      key: const Key('cliente_home_operations_panel'),
      title: title,
      message: message,
      icon: Icons.notifications_active_outlined,
      tone: AppStatusTone.warning,
      primaryAction: AppActionPanelAction(
        label: actionLabel,
        icon: Icons.arrow_forward_rounded,
        onPressed: onAction,
      ),
    );
  }
}

class ClienteHomeMessagesPanel extends StatelessWidget {
  const ClienteHomeMessagesPanel({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      key: const Key('cliente_home_messages_panel'),
      title: title,
      message: message,
      icon: Icons.chat_bubble_outline_rounded,
      tone: AppStatusTone.info,
      primaryAction: AppActionPanelAction(
        label: actionLabel,
        icon: Icons.open_in_new_rounded,
        onPressed: onAction,
        variant: AppButtonVariant.secondary,
      ),
    );
  }
}

class ClienteHomeEmptyServices extends StatelessWidget {
  const ClienteHomeEmptyServices({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppActionPanel(
      title: 'Ainda estamos a preparar servicos para ti.',
      message: 'Tenta novamente daqui a pouco ou ajusta a pesquisa.',
      icon: Icons.search_off_rounded,
      tone: AppStatusTone.neutral,
    );
  }
}

String clienteHomeSafeKey(String raw) {
  final normalized = raw.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  return normalized.isEmpty ? 'sem_id' : normalized;
}

AppStatusTone clienteServiceToneFor(String? mode) {
  final normalized = (mode ?? '').toUpperCase().trim();
  if (normalized == 'IMEDIATO') return AppStatusTone.success;
  if (normalized == 'AGENDADO') return AppStatusTone.info;
  return AppStatusTone.warning;
}

IconData clienteServiceIconFor(String? iconKey) {
  final normalized = (iconKey ?? '').toLowerCase().trim();
  if (normalized.contains('canal') || normalized.contains('plumb')) {
    return Icons.plumbing_rounded;
  }
  if (normalized.contains('eletric') || normalized.contains('electric')) {
    return Icons.electrical_services_rounded;
  }
  if (normalized.contains('limp') || normalized.contains('clean')) {
    return Icons.cleaning_services_rounded;
  }
  if (normalized.contains('pint')) return Icons.format_paint_rounded;
  if (normalized.contains('jard')) return Icons.yard_rounded;
  if (normalized.contains('mont')) return Icons.handyman_rounded;
  return Icons.home_repair_service_rounded;
}
