import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_section_header.dart';

enum AppContentWidth { compact, medium, dashboard, wide, full }

class AppContentShell extends StatelessWidget {
  const AppContentShell({
    super.key,
    required this.child,
    this.width = AppContentWidth.dashboard,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final AppContentWidth width;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = padding ?? _paddingFor(constraints.maxWidth);
        final maxWidth = _maxWidthFor(width);

        Widget content = Padding(
          padding: resolvedPadding,
          child: child,
        );

        if (maxWidth != null) {
          content = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: content,
          );
        }

        return Align(
          alignment: alignment,
          child: content,
        );
      },
    );
  }

  EdgeInsetsGeometry _paddingFor(double availableWidth) {
    final horizontal = switch (availableWidth) {
      >= AppBreakpoints.desktopMin => AppLayout.desktopHorizontalPadding,
      >= AppBreakpoints.tabletMin => AppLayout.tabletHorizontalPadding,
      _ => AppLayout.mobileHorizontalPadding,
    };

    return EdgeInsets.fromLTRB(
      horizontal,
      AppSpacing.x5,
      horizontal,
      AppSpacing.x6,
    );
  }

  double? _maxWidthFor(AppContentWidth width) {
    switch (width) {
      case AppContentWidth.compact:
        return AppBreakpoints.contentMaxSingleColumn;
      case AppContentWidth.medium:
        return AppBreakpoints.contentMaxTwoColumn;
      case AppContentWidth.dashboard:
        return AppBreakpoints.contentMaxDashboard;
      case AppContentWidth.wide:
        return AppBreakpoints.contentMaxWide;
      case AppContentWidth.full:
        return null;
    }
  }
}

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    this.width = AppContentWidth.dashboard,
    this.scrollable = true,
    this.padding,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final AppContentWidth width;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final page = AppContentShell(
      width: width,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.trim().isNotEmpty)
            AppSectionHeader(
              title: title!,
              subtitle: subtitle,
              trailing: actions == null || actions!.isEmpty
                  ? null
                  : Wrap(
                      spacing: AppSpacing.x2,
                      runSpacing: AppSpacing.x2,
                      children: actions!,
                    ),
            ),
          child,
        ],
      ),
    );

    final background = Theme.of(context).scaffoldBackgroundColor;

    return ColoredBox(
      color: background,
      child: SafeArea(
        child: scrollable
            ? SingleChildScrollView(child: page)
            : SizedBox.expand(child: page),
      ),
    );
  }
}
