import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';

enum AppBrandSize { compact, regular, large }

class AppBrandWordmark extends StatelessWidget {
  const AppBrandWordmark({
    super.key,
    this.size = AppBrandSize.regular,
    this.showIcon = true,
  });

  final AppBrandSize size;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final dimensions = switch (size) {
      AppBrandSize.compact => (icon: 26.0, text: 20.0),
      AppBrandSize.regular => (icon: 32.0, text: 25.0),
      AppBrandSize.large => (icon: 42.0, text: 32.0),
    };
    final gradient = context.chegaJaTheme.brandGradient;

    return Semantics(
      image: true,
      label: 'ChegaJá',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(dimensions.icon * 0.28),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: dimensions.icon,
                  height: dimensions.icon,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
            ],
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: gradient.createShader,
              child: Text(
                'ChegaJá',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppTypography.fontFamily,
                  fontSize: dimensions.text,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
