import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

import 'package:chegaja_v2/core/feature_flags/feature_flag.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_service.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/role_mode_service.dart';
import 'package:chegaja_v2/core/theme/app_theme_extension.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_brand_wordmark.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({
    super.key,
    this.u1ExperienceOverride,
  });

  /// Test/debug override. Production rollout remains controlled remotely.
  final bool? u1ExperienceOverride;

  @override
  Widget build(BuildContext context) {
    final experienceV2 = u1ExperienceOverride ??
        FeatureFlagService.instance.isEnabled(
          FeatureFlag.u1NavigationV2,
        );
    if (!experienceV2) return _buildLegacy(context);

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final chegaJaTheme = context.chegaJaTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: chegaJaTheme.softBrandGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= AppBreakpoints.tabletMin;
              final horizontalPadding = switch (constraints.maxWidth) {
                < AppBreakpoints.tabletMin => AppLayout.mobileHorizontalPadding,
                < AppBreakpoints.desktopMin =>
                  AppLayout.tabletHorizontalPadding,
                _ => AppLayout.desktopHorizontalPadding,
              };
              final verticalPadding =
                  constraints.maxHeight < 700 ? AppSpacing.x4 : AppSpacing.x7;

              return SingleChildScrollView(
                key: const Key('role-selector-scroll'),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - (verticalPadding * 2))
                        .clamp(0, double.infinity)
                        .toDouble(),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      key: const Key('role-selector-content'),
                      constraints: const BoxConstraints(
                        maxWidth: AppBreakpoints.contentMaxTwoColumn,
                      ),
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AppBrandWordmark(
                                  size: AppBrandSize.large,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x7),
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.roleSelectorWelcome,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayMedium,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x2),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Text(
                                l10n.roleSelectorPrompt,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x7),
                            _RoleChoices(
                              isWide: isWide,
                              customerCard: _RoleCard(
                                key: const Key('role-card-cliente'),
                                title: l10n.roleCustomerTitle,
                                description: l10n.roleCustomerDescription,
                                icon: Icons.search_rounded,
                                iconColor: AppPalette.brandCoral,
                                buttonLabel: l10n.roleCustomerTitle,
                                buttonKey: const Key('role-button-cliente'),
                                onTap: () async {
                                  await _selectRole('cliente');
                                },
                              ),
                              providerCard: _RoleCard(
                                key: const Key('role-card-prestador'),
                                title: l10n.roleProviderTitle,
                                description: l10n.roleProviderDescription,
                                icon: Icons.work_outline_rounded,
                                iconColor: AppPalette.brandPurple,
                                buttonLabel: l10n.roleProviderTitle,
                                buttonKey: const Key('role-button-prestador'),
                                onTap: () async {
                                  await _selectRole('prestador');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _selectRole(String role) async {
    await selectRoleForApp(role: role);
  }

  Widget _buildLegacy(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: const Key('role-selector-legacy'),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppPalette.primary.withValues(alpha: isDark ? 0.20 : 0.12),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.contentMaxSingleColumn,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x5,
                  vertical: AppSpacing.x4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      l10n.roleSelectorWelcome,
                      style: theme.textTheme.displayMedium,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      l10n.roleSelectorPrompt,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.x6),
                    _LegacyRoleCard(
                      key: const Key('legacy-role-card-cliente'),
                      title: l10n.roleCustomerTitle,
                      description: l10n.roleCustomerDescription,
                      icon: Icons.search_rounded,
                      buttonKey: const Key('role-button-cliente'),
                      onTap: () => _selectRole('cliente'),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    _LegacyRoleCard(
                      key: const Key('legacy-role-card-prestador'),
                      title: l10n.roleProviderTitle,
                      description: l10n.roleProviderDescription,
                      icon: Icons.work_outline_rounded,
                      buttonKey: const Key('role-button-prestador'),
                      onTap: () => _selectRole('prestador'),
                    ),
                    const SizedBox(height: AppSpacing.x3),
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

@visibleForTesting
Future<void> selectRoleForApp({
  required String role,
  RoleModeService? roleModeService,
  Future<void> Function()? ensureSignedIn,
  Future<void> Function(String role)? syncActiveRole,
  Duration remoteTimeout = const Duration(seconds: 20),
}) async {
  final modeService = roleModeService ?? RoleModeService.instance;

  // A navegacao e uma decisao local e deve acontecer imediatamente. Firebase
  // e sincronizado depois, sem bloquear Cliente/Prestador quando a rede ou um
  // emulador local estiver indisponivel.
  await modeService.setMode(role);

  final ensureAuth = ensureSignedIn ??
      () async {
        await AuthService.ensureSignedInAnonymously();
      };
  final syncRole = syncActiveRole ?? AuthService.setActiveRole;

  unawaited(
    _syncRemoteRole(
      role: role,
      ensureSignedIn: ensureAuth,
      syncActiveRole: syncRole,
      timeout: remoteTimeout,
    ),
  );
}

Future<void> _syncRemoteRole({
  required String role,
  required Future<void> Function() ensureSignedIn,
  required Future<void> Function(String role) syncActiveRole,
  required Duration timeout,
}) async {
  try {
    await ensureSignedIn().timeout(timeout);
    await syncActiveRole(role).timeout(timeout);
  } catch (error, stackTrace) {
    debugPrint('[RoleSelector] sincronizacao remota adiada: $error');
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

class _RoleChoices extends StatelessWidget {
  const _RoleChoices({
    required this.isWide,
    required this.customerCard,
    required this.providerCard,
  });

  final bool isWide;
  final Widget customerCard;
  final Widget providerCard;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.contentMaxSingleColumn,
        ),
        child: Column(
          children: [
            customerCard,
            const SizedBox(height: AppSpacing.x4),
            providerCard,
          ],
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: customerCard),
          const SizedBox(width: AppSpacing.x5),
          Expanded(child: providerCard),
        ],
      ),
    );
  }
}

class _LegacyRoleCard extends StatelessWidget {
  const _LegacyRoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonKey,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Key buttonKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      variant: AppCardVariant.elevated,
      size: AppCardSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: AppPalette.primary.withValues(alpha: 0.14),
            ),
            child: Icon(
              icon,
              color: AppPalette.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.x2),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.x4),
          AppButton(
            key: buttonKey,
            label: title,
            expanded: true,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.buttonLabel,
    required this.buttonKey,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String buttonLabel;
  final Key buttonKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;

    return AppCard(
      variant: AppCardVariant.elevated,
      size: AppCardSize.large,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(visualTokens.radiusMd),
                    color: iconColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
              Text(
                title,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          AppButton(
            key: buttonKey,
            label: buttonLabel,
            variant: AppButtonVariant.brand,
            size: AppButtonSize.lg,
            trailingIcon: Icons.arrow_forward_rounded,
            expanded: true,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
