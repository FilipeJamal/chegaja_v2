import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_theme_extension.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';

class ServiceVisual {
  const ServiceVisual({
    required this.assetPath,
    required this.accent,
    required this.fallbackIcon,
  });

  final String assetPath;
  final Color accent;
  final IconData fallbackIcon;

  ServiceVisual forTheme(ChegaJaTheme? theme) {
    if (theme == null || !theme.usesU1) return this;

    final themedAccent = switch (accent) {
      AppPalette.primary => AppPalette.u1Primary,
      AppPalette.accentBlue => AppPalette.u1AccentBlue,
      AppPalette.success => AppPalette.u1AccentTeal,
      AppPalette.warning => AppPalette.u1AccentSun,
      _ => accent,
    };
    if (themedAccent == accent) return this;
    return ServiceVisual(
      assetPath: assetPath,
      accent: themedAccent,
      fallbackIcon: fallbackIcon,
    );
  }
}

const _assetsBasePath = 'assets/icons/services';

const _defaultServiceVisual = ServiceVisual(
  assetPath: '$_assetsBasePath/service_default.svg',
  accent: AppPalette.primary,
  fallbackIcon: Icons.home_repair_service_rounded,
);

const List<_ServiceVisualRule> _serviceVisualRules = [
  _ServiceVisualRule(
    tokens: ['retrat', 'lapis', 'grafite', 'portrait'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_portrait.svg',
      accent: Color(0xFF475569),
      fallbackIcon: Icons.draw_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['caric'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_caricature.svg',
      accent: Color(0xFFF97316),
      fallbackIcon: Icons.face_retouching_natural_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['ilustr', 'illustr'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_illustration.svg',
      accent: Color(0xFF7C3AED),
      fallbackIcon: Icons.brush_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['escult', 'escultura', '3d'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_sculpture_3d.svg',
      accent: Color(0xFF0B74FF),
      fallbackIcon: Icons.view_in_ar_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['canal', 'plumb', 'torneira', 'fuga'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_plumbing.svg',
      accent: AppPalette.accentBlue,
      fallbackIcon: Icons.plumbing_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['limp', 'clean', 'higien'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_cleaning.svg',
      accent: AppPalette.success,
      fallbackIcon: Icons.cleaning_services_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['eletric', 'electric', 'tomada', 'quadro'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_electric.svg',
      accent: AppPalette.warning,
      fallbackIcon: Icons.electrical_services_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['pedr', 'obra', 'reboco', 'construcao', 'acabamento'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_masonry.svg',
      accent: Color(0xFFF97316),
      fallbackIcon: Icons.construction_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['serralh', 'fechadura', 'chave', 'portao', 'grade', 'ferro'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_locksmith.svg',
      accent: Color(0xFF20B894),
      fallbackIcon: Icons.key_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['carp', 'madeira'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_carpentry.svg',
      accent: Color(0xFF92400E),
      fallbackIcon: Icons.carpenter_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['pint', 'tinta', 'parede'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_painting.svg',
      accent: Color(0xFF7C3AED),
      fallbackIcon: Icons.format_paint_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['mud', 'entrega', 'logistica', 'transporte'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_moving.svg',
      accent: Color(0xFFF97316),
      fallbackIcon: Icons.local_shipping_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['montagem', 'moveis', 'armario'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_assembly.svg',
      accent: Color(0xFFF97316),
      fallbackIcon: Icons.handyman_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['bolo', 'cake', 'confeit', 'doce', 'fondant'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_cake.svg',
      accent: Color(0xFFEC4899),
      fallbackIcon: Icons.cake_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['barbeiro', 'barba', 'degrade'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_barber.svg',
      accent: Color(0xFF0B74FF),
      fallbackIcon: Icons.content_cut_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['cabeleireiro', 'cabelo', 'unhas', 'beleza', 'estetica'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_hairdresser.svg',
      accent: Color(0xFFEC4899),
      fallbackIcon: Icons.spa_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['babysitter', 'ama', 'infantil', 'crianca'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_babysitter.svg',
      accent: Color(0xFFF59E0B),
      fallbackIcon: Icons.child_care_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['idoso', 'idosos', 'acompanhante', 'cuidador'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_elder_care.svg',
      accent: Color(0xFF20B894),
      fallbackIcon: Icons.elderly_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['dog', 'walker', 'passeio', 'caes'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_dog_walker.svg',
      accent: Color(0xFF7C3AED),
      fallbackIcon: Icons.pets_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['pet', 'animais'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_pet_sitter.svg',
      accent: Color(0xFFEC4899),
      fallbackIcon: Icons.pets_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['mecanico', 'mecanica', 'auto', 'mobilidade'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_mechanic.svg',
      accent: Color(0xFF0B74FF),
      fallbackIcon: Icons.car_repair_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['eletrodomestico', 'reparacao tecnica', 'tecnologia'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_appliance.svg',
      accent: Color(0xFF0B74FF),
      fallbackIcon: Icons.settings_input_component_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['web', 'app', 'apps', 'desenvolvimento', 'digital'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_web.svg',
      accent: Color(0xFF0B74FF),
      fallbackIcon: Icons.code_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['designer_grafico', 'grafico', 'design'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_graphic_design.svg',
      accent: Color(0xFF7C3AED),
      fallbackIcon: Icons.design_services_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['musica', 'instrumento'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_music.svg',
      accent: Color(0xFF7C3AED),
      fallbackIcon: Icons.music_note_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['linguas', 'lingua', 'conversacao', 'gramatica'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_language.svg',
      accent: Color(0xFF0B74FF),
      fallbackIcon: Icons.translate_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['explicador', 'explicacoes', 'aulas', 'formacao', 'educacao'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_tutor.svg',
      accent: Color(0xFF20B894),
      fallbackIcon: Icons.school_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['massag', 'bem-estar', 'bem estar', 'wellness'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_massage.svg',
      accent: Color(0xFFEC4899),
      fallbackIcon: Icons.self_improvement_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['saude', 'domicilio'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_health.svg',
      accent: Color(0xFF20B894),
      fallbackIcon: Icons.health_and_safety_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['catering', 'evento', 'eventos'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_catering.svg',
      accent: Color(0xFFF97316),
      fallbackIcon: Icons.room_service_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['personal_shopper', 'assistente', 'shopper', 'lifestyle'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_personal_shopper.svg',
      accent: Color(0xFF7C3AED),
      fallbackIcon: Icons.shopping_bag_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['artes_marciais', 'marciais', 'lutas', 'defesa'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_martial_arts.svg',
      accent: Color(0xFF0B74FF),
      fallbackIcon: Icons.sports_mma_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['fitness', 'danca', 'desporto'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_fitness.svg',
      accent: Color(0xFF20B894),
      fallbackIcon: Icons.fitness_center_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['jard', 'garden'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_garden.svg',
      accent: Color(0xFF20B894),
      fallbackIcon: Icons.yard_rounded,
    ),
  ),
  _ServiceVisualRule(
    tokens: ['handyman', 'faz tudo', 'manutencao', 'reparos', 'reparacao'],
    visual: ServiceVisual(
      assetPath: '$_assetsBasePath/service_handyman.svg',
      accent: Color(0xFFF97316),
      fallbackIcon: Icons.home_repair_service_rounded,
    ),
  ),
];

ServiceVisual serviceVisualFor(
  String? seed, {
  ChegaJaTheme? theme,
}) {
  final normalized = normalizeServiceVisualSeed(seed);
  if (normalized.isEmpty) return _defaultServiceVisual.forTheme(theme);

  for (final rule in _serviceVisualRules) {
    if (rule.matches(normalized)) return rule.visual.forTheme(theme);
  }

  return _defaultServiceVisual.forTheme(theme);
}

String serviceAssetFor(String? seed) => serviceVisualFor(seed).assetPath;

Color serviceAccentFor(
  String? seed, {
  ChegaJaTheme? theme,
}) =>
    serviceVisualFor(seed, theme: theme).accent;

IconData serviceIconFor(String? seed) => serviceVisualFor(seed).fallbackIcon;

String normalizeServiceVisualSeed(String? seed) {
  var value = (seed ?? '').toLowerCase().trim();
  if (value.isEmpty) return '';

  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  for (final entry in replacements.entries) {
    value = value.replaceAll(entry.key, entry.value);
  }

  return value.replaceAll(RegExp(r'\s+'), ' ');
}

class _ServiceVisualRule {
  const _ServiceVisualRule({
    required this.tokens,
    required this.visual,
  });

  final List<String> tokens;
  final ServiceVisual visual;

  bool matches(String normalizedSeed) {
    return tokens.any((token) => normalizedSeed.contains(token));
  }
}
