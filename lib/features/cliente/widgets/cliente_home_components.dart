import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/core/widgets/service_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _clienteHomeHouseIllustration =
    'assets/illustrations/home_service_house.svg';

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
          final showIllustration = constraints.maxWidth >= 300;
          final illustrationWidth = constraints.maxWidth >= 560 ? 148.0 : 82.0;
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
          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: copy),
              if (showIllustration) ...[
                const SizedBox(width: AppSpacing.x4),
                SizedBox(
                  width: illustrationWidth,
                  child: const _ClienteHomeHeroIllustration(),
                ),
              ],
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
                header,
                const SizedBox(height: AppSpacing.x5),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: header),
              const SizedBox(width: AppSpacing.x6),
              SizedBox(width: 280, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class _ClienteHomeHeroIllustration extends StatelessWidget {
  const _ClienteHomeHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _clienteHomeHouseIllustration,
      fit: BoxFit.contain,
      semanticsLabel: 'Casa com marcador de localizacao',
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
          minItemWidth: 170,
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
    final visualSeed = '${servico.iconKey ?? ''} ${servico.name}';
    final accent = clienteServiceAccentFor(visualSeed);
    final asset = clienteServiceAssetFor(visualSeed);
    final key = Key(
      'cliente_home_service_tile_${clienteHomeSafeKey(servico.id)}',
    );

    return AppCard(
      key: key,
      onTap: onTap,
      variant: AppCardVariant.outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 220;
          final icon = SvgPicture.asset(
            asset,
            fit: BoxFit.contain,
            semanticsLabel: servico.nameForLang(localeCode),
          );
          final title = Text(
            servico.nameForLang(localeCode),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          );
          final pill = AppStatusPill(
            label: modeLabel,
            tone: clienteServiceToneFor(servico.mode),
            size: AppStatusPillSize.sm,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(width: 48, height: 48, child: icon),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: accent,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x3),
                title,
                const SizedBox(height: AppSpacing.x2),
                pill,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 48, height: 48, child: icon),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.x2),
                    pill,
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Icon(
                Icons.arrow_forward_rounded,
                color: accent,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServicePreviewTile extends StatelessWidget {
  const _ServicePreviewTile({
    required this.label,
    required this.asset,
  });

  final String label;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      variant: AppCardVariant.outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 220;
          final icon = SvgPicture.asset(
            asset,
            fit: BoxFit.contain,
            semanticsLabel: label,
          );
          final title = Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          );
          const pill = AppStatusPill(
            label: 'A carregar',
            tone: AppStatusTone.neutral,
            size: AppStatusPillSize.sm,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 48, height: 48, child: icon),
                const SizedBox(height: AppSpacing.x3),
                title,
                const SizedBox(height: AppSpacing.x2),
                pill,
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 48, height: 48, child: icon),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.x2),
                    pill,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ClienteServicesLoadingPreview extends StatelessWidget {
  const ClienteServicesLoadingPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ClienteServicesSection(
      title: 'Servicos disponiveis',
      subtitle: 'Estamos a carregar o catalogo. Estas categorias ficam aqui.',
      search: const _ServiceLoadingSearch(),
      children: const [
        _ServicePreviewTile(
          label: 'Canalizacao',
          asset: 'assets/icons/services/service_plumbing.svg',
        ),
        _ServicePreviewTile(
          label: 'Limpeza',
          asset: 'assets/icons/services/service_cleaning.svg',
        ),
        _ServicePreviewTile(
          label: 'Eletricista',
          asset: 'assets/icons/services/service_electric.svg',
        ),
        _ServicePreviewTile(
          label: 'Pintura',
          asset: 'assets/icons/services/service_painting.svg',
        ),
        _ServicePreviewTile(
          label: 'Mudancas',
          asset: 'assets/icons/services/service_moving.svg',
        ),
        _ServicePreviewTile(
          label: 'Montagem',
          asset: 'assets/icons/services/service_assembly.svg',
        ),
      ],
    );
  }
}

class _ServiceLoadingSearch extends StatelessWidget {
  const _ServiceLoadingSearch();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      size: AppCardSize.compact,
      variant: AppCardVariant.outlined,
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              'Procurar servico...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
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
  return serviceIconFor(iconKey);
}

Color clienteServiceAccentFor(String? iconKey) {
  return serviceAccentFor(iconKey);
}

String clienteServiceAssetFor(String? iconKey) {
  return serviceAssetFor(iconKey);
}
