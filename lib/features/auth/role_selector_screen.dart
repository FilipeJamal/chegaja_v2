import 'package:flutter/material.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';

import '../cliente/cliente_home_screen.dart';
import '../prestador/prestador_home_screen.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x5,
                  vertical: AppSpacing.x4,
                ),
                child: SingleChildScrollView(
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
                      _RoleCard(
                        title: l10n.roleCustomerTitle,
                        description: l10n.roleCustomerDescription,
                        icon: Icons.search_rounded,
                        buttonLabel: l10n.roleCustomerTitle,
                        onTap: () async {
                          await AuthService.ensureSignedInAnonymously();
                          await AuthService.setActiveRole('cliente');
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ClienteHomeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      _RoleCard(
                        title: l10n.roleProviderTitle,
                        description: l10n.roleProviderDescription,
                        icon: Icons.work_outline_rounded,
                        buttonLabel: l10n.roleProviderTitle,
                        onTap: () async {
                          await AuthService.ensureSignedInAnonymously();
                          await AuthService.setActiveRole('prestador');
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrestadorHomeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.x3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final String buttonLabel;
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
            child: Icon(icon, color: AppPalette.primary),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x4),
          AppButton(
            label: buttonLabel,
            expanded: true,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
