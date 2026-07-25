import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.label,
  });

  final String? label;

  @override
  Widget build(BuildContext context) {
    if (!context.chegaJaTheme.usesU1) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.x3),
              Text(label!),
            ],
          ],
        ),
      );
    }

    return Semantics(
      liveRegion: true,
      label: label ?? 'A carregar',
      child: ExcludeSemantics(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
              if (label != null) ...[
                const SizedBox(height: AppSpacing.x3),
                Text(label!, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (!context.chegaJaTheme.usesU1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.x3),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.x4),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _AppStateLayout(
      semanticLabel: '$title. $message',
      icon: icon,
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      title: title,
      message: message,
      primaryActionLabel: actionLabel,
      onPrimaryAction: onAction,
    );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.message,
    this.title = 'Não foi possível concluir',
    this.onRetry,
    this.retryLabel,
    this.onSupport,
    this.supportLabel = 'Contactar suporte',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final VoidCallback? onSupport;
  final String supportLabel;

  @override
  Widget build(BuildContext context) {
    if (!context.chegaJaTheme.usesU1) {
      final legacyRetryLabel = retryLabel ?? 'Try again';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 36,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.x3),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.x4),
                AppButton(
                  label: legacyRetryLabel,
                  onPressed: onRetry,
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _AppStateLayout(
      semanticLabel: '$title. $message',
      icon: Icons.error_outline_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      title: title,
      message: message,
      primaryActionLabel:
          onRetry == null ? null : (retryLabel ?? 'Tentar novamente'),
      onPrimaryAction: onRetry,
      secondaryActionLabel: onSupport == null ? null : supportLabel,
      onSecondaryAction: onSupport,
    );
  }
}

class AppOfflineView extends StatelessWidget {
  const AppOfflineView({
    super.key,
    this.title = 'Sem ligação à internet',
    this.message =
        'Podes continuar a consultar os dados guardados. Liga-te à internet para atualizar.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _AppStateLayout(
      semanticLabel: '$title. $message',
      icon: Icons.cloud_off_rounded,
      iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
      title: title,
      message: message,
      primaryActionLabel: onRetry == null ? null : 'Tentar novamente',
      onPrimaryAction: onRetry,
    );
  }
}

class AppRecoveryView extends StatelessWidget {
  const AppRecoveryView({
    super.key,
    required this.title,
    required this.message,
    required this.recoveryLabel,
    required this.onRecover,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final String recoveryLabel;
  final VoidCallback onRecover;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return _AppStateLayout(
      semanticLabel: '$title. $message',
      icon: Icons.restore_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      title: title,
      message: message,
      primaryActionLabel: recoveryLabel,
      onPrimaryAction: onRecover,
      secondaryActionLabel: secondaryLabel,
      onSecondaryAction: onSecondary,
    );
  }
}

class AppStaleDataBanner extends StatelessWidget {
  const AppStaleDataBanner({
    super.key,
    required this.message,
    this.onRefresh,
  });

  final String message;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;
    final warningColor =
        visualTokens.usesU1 ? AppPalette.u1Warning : AppPalette.warning;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      label: message,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        decoration: BoxDecoration(
          color: visualTokens.warningSurface,
          borderRadius: BorderRadius.circular(visualTokens.radiusMd),
          border: Border.all(
            color: warningColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.schedule_rounded,
                size: 20,
                color: warningColor,
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (onRefresh != null)
              TextButton(
                onPressed: onRefresh,
                child: const Text('Atualizar'),
              ),
          ],
        ),
      ),
    );
  }
}

class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  final double width;
  final double height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.chegaJaTheme;
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.skeletonBase,
              colors.skeletonHighlight,
              colors.skeletonBase,
            ],
          ),
          borderRadius: BorderRadius.circular(radius ?? colors.radiusSm),
        ),
      ),
    );
  }
}

class AppSkeletonLine extends StatelessWidget {
  const AppSkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonBox(
      width: width,
      height: height,
      radius: height / 2,
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 4,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final visualTokens = context.chegaJaTheme;
    return Semantics(
      liveRegion: true,
      label: 'A carregar conteúdo',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x3),
        itemBuilder: (_, __) => Row(
          children: [
            AppSkeletonBox(
              width: 48,
              height: 48,
              radius: visualTokens.radiusMd,
            ),
            const SizedBox(width: AppSpacing.x3),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonLine(width: 180),
                  SizedBox(height: AppSpacing.x2),
                  AppSkeletonLine(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppStateLayout extends StatelessWidget {
  const _AppStateLayout({
    required this.semanticLabel,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String semanticLabel;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      label: semanticLabel,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(visualTokens.radiusLg),
                        ),
                        child: Icon(icon, size: 32, color: iconColor),
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Text(
                        title,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (primaryActionLabel != null && onPrimaryAction != null) ...[
                  const SizedBox(height: AppSpacing.x4),
                  AppButton(
                    label: primaryActionLabel!,
                    onPressed: onPrimaryAction,
                  ),
                ],
                if (secondaryActionLabel != null &&
                    onSecondaryAction != null) ...[
                  const SizedBox(height: AppSpacing.x2),
                  AppButton(
                    label: secondaryActionLabel!,
                    onPressed: onSecondaryAction,
                    variant: AppButtonVariant.ghost,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
