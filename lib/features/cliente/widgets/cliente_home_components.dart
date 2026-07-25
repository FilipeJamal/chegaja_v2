import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/theme/app_semantic_colors.dart';
import 'package:chegaja_v2/core/theme/app_theme_extension.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_brand_wordmark.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/core/widgets/app_text_field.dart';
import 'package:chegaja_v2/core/widgets/service_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _clienteHomeHeroIllustration =
    'assets/illustrations/coimbra_services_hero.png';
const _clienteLegacyHomeIllustration =
    'assets/illustrations/home_service_house.svg';

class ClienteHomeHero extends StatefulWidget {
  const ClienteHomeHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSearch,
    this.greeting,
    this.locationLabel = 'Coimbra',
    this.selectedMode = 'IMEDIATO',
    this.onModeChanged,
    this.onContinue,
    this.primaryActionLabel = 'Continuar',
    this.onPrimaryAction,
    this.requestHint = 'Descreva o que precisa',
    this.nowLabel = 'Agora',
    this.scheduleLabel = 'Agendar',
    this.quotesLabel = 'Orçamentos',
  });

  final String? greeting;
  final String title;
  final String subtitle;
  final String locationLabel;
  final String selectedMode;
  final ValueChanged<String>? onModeChanged;
  final ValueChanged<String>? onContinue;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback onSearch;
  final String requestHint;
  final String nowLabel;
  final String scheduleLabel;
  final String quotesLabel;

  @override
  State<ClienteHomeHero> createState() => _ClienteHomeHeroState();
}

class _ClienteHomeHeroState extends State<ClienteHomeHero> {
  final TextEditingController _requestController = TextEditingController();

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;
    final mobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tabletMin;

    return Container(
      key: const Key('cliente_home_hero'),
      padding: mobile ? EdgeInsets.zero : const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: mobile ? Colors.transparent : theme.colorScheme.surface,
        borderRadius:
            mobile ? null : BorderRadius.circular(visualTokens.radiusXl),
        border: mobile
            ? null
            : Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.72),
              ),
        boxShadow: mobile ? const [] : visualTokens.shadowLevel2,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AppBreakpoints.tabletMin;
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final stackHeader = !wide && textScale > 1.3;
          final illustrationSize = wide ? 210.0 : 136.0;
          final titleStyle = (wide
                  ? theme.textTheme.displayMedium
                  : theme.textTheme.headlineMedium)
              ?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1.08,
          );
          final locationChip = Semantics(
            label: 'Localização: ${widget.locationLabel}',
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTapTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3,
              ),
              decoration: BoxDecoration(
                color: mobile
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
                border: mobile
                    ? Border.all(
                        color: theme.colorScheme.outlineVariant,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color:
                        mobile ? AppPalette.brandPurple : AppPalette.brandCoral,
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Flexible(
                    child: Text(
                      widget.locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (mobile) ...[
                    const SizedBox(width: AppSpacing.x1),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stackHeader)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBrandWordmark(
                      size:
                          mobile ? AppBrandSize.regular : AppBrandSize.compact,
                      showIcon: !mobile,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    locationChip,
                  ],
                )
              else
                Row(
                  children: [
                    AppBrandWordmark(
                      size:
                          mobile ? AppBrandSize.regular : AppBrandSize.compact,
                      showIcon: !mobile,
                    ),
                    const Spacer(),
                    Flexible(child: locationChip),
                  ],
                ),
              const SizedBox(height: AppSpacing.x5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: titleStyle),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  SizedBox(
                    width: illustrationSize,
                    height: illustrationSize,
                    child: const _ClienteHomeHeroIllustration(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x4),
              ClienteServiceModeSelector(
                selectedMode: widget.selectedMode,
                onChanged: widget.onModeChanged,
                nowLabel: widget.nowLabel,
                scheduleLabel: widget.scheduleLabel,
                quotesLabel: widget.quotesLabel,
              ),
              const SizedBox(height: AppSpacing.x3),
              AppTextField(
                controller: _requestController,
                hintText: widget.requestHint,
                textInputAction: TextInputAction.next,
                prefix: Icon(
                  mobile ? Icons.search_rounded : Icons.edit_note_rounded,
                  color: mobile ? AppPalette.brandPurple : null,
                ),
                variant: mobile
                    ? AppTextFieldVariant.outlined
                    : AppTextFieldVariant.filled,
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: AppSpacing.x3),
              AppButton(
                key: const Key('cliente_home_primary_cta'),
                label: widget.primaryActionLabel,
                onPressed: _continue,
                trailingIcon: mobile ? null : Icons.arrow_forward_rounded,
                size: AppButtonSize.lg,
                variant: AppButtonVariant.brand,
                expanded: true,
              ),
              if (!mobile) ...[
                const SizedBox(height: AppSpacing.x1),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    key: const Key('cliente_home_provider_search_cta'),
                    onPressed: widget.onSearch,
                    icon: const Icon(Icons.manage_search_rounded, size: 18),
                    label: const Text('Pesquisar prestadores'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _continue() {
    final description = _requestController.text.trim();
    if (widget.onContinue != null) {
      widget.onContinue!(description);
      return;
    }
    widget.onPrimaryAction?.call();
  }
}

/// Rollback-safe Home surface used while the U1 experience flag is disabled.
class ClienteLegacyHomeHero extends StatelessWidget {
  const ClienteLegacyHomeHero({
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
      key: const Key('cliente_home_legacy_hero'),
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
                  child: SvgPicture.asset(
                    _clienteLegacyHomeIllustration,
                    fit: BoxFit.contain,
                    semanticsLabel: 'Casa com marcador de localização',
                  ),
                ),
              ],
            ],
          );

          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                key: const Key('cliente_home_legacy_primary_cta'),
                label: primaryActionLabel,
                onPressed: onPrimaryAction,
                leadingIcon: Icons.add_rounded,
                trailingIcon: Icons.arrow_forward_rounded,
                size: AppButtonSize.lg,
                expanded: true,
              ),
              const SizedBox(height: AppSpacing.x2),
              AppButton(
                key: const Key('cliente_home_legacy_provider_search_cta'),
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

class ClienteServiceModeSelector extends StatelessWidget {
  const ClienteServiceModeSelector({
    super.key,
    required this.selectedMode,
    required this.onChanged,
    this.nowLabel = 'Agora',
    this.scheduleLabel = 'Agendar',
    this.quotesLabel = 'Orçamentos',
  });

  final String selectedMode;
  final ValueChanged<String>? onChanged;
  final String nowLabel;
  final String scheduleLabel;
  final String quotesLabel;

  @override
  Widget build(BuildContext context) {
    final visualTokens = context.chegaJaTheme;
    final theme = Theme.of(context);
    final mobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tabletMin;
    final items = [
      (mode: 'IMEDIATO', label: nowLabel, icon: Icons.bolt_rounded),
      (mode: 'AGENDADO', label: scheduleLabel, icon: Icons.event_rounded),
      (
        mode: 'ORCAMENTO',
        label: quotesLabel,
        icon: Icons.request_quote_rounded,
      ),
    ];

    return Container(
      key: const Key('cliente_home_mode_selector'),
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: mobile
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          mobile ? visualTokens.radiusLg : visualTokens.radiusMd,
        ),
        border:
            mobile ? Border.all(color: theme.colorScheme.outlineVariant) : null,
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(
              flex: items[index].mode == 'ORCAMENTO' ? 12 : 10,
              child: _ClienteServiceModeItem(
                key: Key(
                  'cliente_home_mode_${items[index].mode.toLowerCase()}',
                ),
                label: items[index].label,
                icon: items[index].icon,
                selected: selectedMode == items[index].mode,
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(items[index].mode),
              ),
            ),
            if (mobile && index < items.length - 1)
              SizedBox(
                height: 36,
                child: VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ClienteServiceModeItem extends StatelessWidget {
  const _ClienteServiceModeItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;
    final mobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tabletMin;
    final stackContent =
        mobile && MediaQuery.textScalerOf(context).scale(14) / 14 > 1.2;
    final foreground = selected
        ? (mobile ? AppPalette.brandCoral : theme.colorScheme.primary)
        : theme.colorScheme.onSurfaceVariant;
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (mobile ? theme.textTheme.labelLarge : theme.textTheme.labelMedium)
          ?.copyWith(
        color: foreground,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(visualTokens.radiusSm),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            constraints: BoxConstraints(
              minHeight: mobile ? 68 : AppSizes.minTapTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x1,
              vertical: AppSpacing.x2,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? (mobile
                      ? AppPalette.brandCoral.withValues(alpha: 0.08)
                      : theme.colorScheme.surface)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(visualTokens.radiusSm),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.28)
                    : Colors.transparent,
              ),
              boxShadow: selected ? visualTokens.shadowLevel1 : const [],
            ),
            child: ExcludeSemantics(
              child: Flex(
                direction: stackContent ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: mobile ? 23 : 17,
                    color: foreground,
                  ),
                  SizedBox(
                    width: stackContent ? 0 : AppSpacing.x1,
                    height: stackContent ? AppSpacing.x1 : 0,
                  ),
                  if (stackContent)
                    labelWidget
                  else
                    Flexible(child: labelWidget),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClienteHomeHeroIllustration extends StatelessWidget {
  const _ClienteHomeHeroIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final visualTokens = context.chegaJaTheme;
    return Semantics(
      image: true,
      label: 'Serviços locais em Coimbra',
      child: ExcludeSemantics(
        child: Container(
          key: const Key('cliente_home_hero_illustration'),
          decoration: BoxDecoration(
            color: isDark ? AppPalette.u1LightSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(visualTokens.radiusLg),
            border: isDark
                ? Border.all(
                    color: AppPalette.brandPurple.withValues(alpha: 0.45),
                  )
                : null,
            boxShadow: isDark ? visualTokens.shadowLevel2 : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            _clienteHomeHeroIllustration,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
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
          minItemWidth: 170,
          spacing: AppSpacing.x3,
          runSpacing: AppSpacing.x3,
          children: children,
        ),
      ],
    );
  }
}

class ClienteQuickServicesStrip extends StatelessWidget {
  const ClienteQuickServicesStrip({
    super.key,
    required this.title,
    required this.services,
    required this.localeCode,
    required this.onSelect,
    this.onSeeAll,
    this.seeAllLabel = 'Ver todos',
  });

  final String title;
  final List<Servico> services;
  final String localeCode;
  final ValueChanged<Servico> onSelect;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = services.take(4).toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const Key('cliente_home_quick_services'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: title,
          dense: true,
          trailing: onSeeAll == null
              ? null
              : TextButton(
                  key: const Key('cliente_home_provider_search_cta'),
                  onPressed: onSeeAll,
                  child: Text(
                    seeAllLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.x2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < visible.length; index += 1) ...[
              Expanded(
                child: _ClienteQuickServiceItem(
                  service: visible[index],
                  localeCode: localeCode,
                  onTap: () => onSelect(visible[index]),
                ),
              ),
              if (index < visible.length - 1)
                const SizedBox(width: AppSpacing.x2),
            ],
          ],
        ),
      ],
    );
  }
}

class _ClienteQuickServiceItem extends StatelessWidget {
  const _ClienteQuickServiceItem({
    required this.service,
    required this.localeCode,
    required this.onTap,
  });

  final Servico service;
  final String localeCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;
    final name = service.nameForLang(localeCode);
    final seed = '${service.iconKey ?? ''} ${service.name}';
    final accent = clienteServiceAccentFor(
      seed,
      theme: context.chegaJaTheme,
    );
    final asset = clienteServiceAssetFor(seed);

    return Semantics(
      button: true,
      label: name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(visualTokens.radiusMd),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.x2,
                horizontal: AppSpacing.x1,
              ),
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(AppSpacing.x2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.18),
                        ),
                      ),
                      child: SvgPicture.asset(asset, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClientePrivacyNotice extends StatelessWidget {
  const ClientePrivacyNotice({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppSemanticColors.status(theme, AppStatusTone.success);
    final visualTokens = context.chegaJaTheme;
    return Semantics(
      label: message,
      child: Container(
        key: const Key('cliente_home_privacy_notice'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(visualTokens.radiusMd),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              size: 21,
              color: colors.foreground,
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClienteRecentRequestCard extends StatelessWidget {
  const ClienteRecentRequestCard({
    super.key,
    required this.title,
    required this.status,
    required this.onOpen,
  });

  final String title;
  final String status;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;
    return AppCard(
      key: const Key('cliente_home_recent_request'),
      onTap: onOpen,
      semanticLabel: 'Pedido recente: $title. $status',
      variant: AppCardVariant.outlined,
      size: AppCardSize.compact,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.brandCoral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(visualTokens.radiusMd),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppPalette.brandCoral,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
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
    final accent = clienteServiceAccentFor(
      visualSeed,
      theme: context.chegaJaTheme,
    );
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
    return const ClienteServicesSection(
      title: 'Servicos disponiveis',
      subtitle: 'Estamos a carregar o catalogo. Estas categorias ficam aqui.',
      search: _ServiceLoadingSearch(),
      children: [
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

Color clienteServiceAccentFor(
  String? iconKey, {
  ChegaJaTheme? theme,
}) {
  return serviceAccentFor(iconKey, theme: theme);
}

String clienteServiceAssetFor(String? iconKey) {
  return serviceAssetFor(iconKey);
}
