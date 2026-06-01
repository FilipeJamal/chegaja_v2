import 'package:chegaja_v2/core/catalog/service_intent.dart';
import 'package:chegaja_v2/core/models/category_approval_types.dart';

class ServiceTaxonomyCategory {
  const ServiceTaxonomyCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.iconKey,
    required this.sortOrder,
    required this.subcategories,
    this.isActive = true,
  });

  final String id;
  final String label;
  final String description;
  final String iconKey;
  final int sortOrder;
  final bool isActive;
  final List<ServiceTaxonomySubcategory> subcategories;
}

class ServiceTaxonomySubcategory {
  const ServiceTaxonomySubcategory({
    required this.id,
    required this.parentCategoryId,
    required this.label,
    required this.description,
    required this.aliases,
    required this.commonPhrases,
    required this.examples,
    required this.allowedIntents,
    required this.defaultIntent,
    required this.legacyServicoIds,
    required this.legacyNames,
    required this.sortOrder,
    this.sensitiveRequirementId,
    this.riskLevel = CategoryRiskLevel.normal,
    this.requiresApproval = false,
    this.isActive = true,
  });

  final String id;
  final String parentCategoryId;
  final String label;
  final String description;
  final List<String> aliases;
  final List<String> commonPhrases;
  final List<String> examples;
  final List<ServiceIntent> allowedIntents;
  final ServiceIntent defaultIntent;
  final List<String> legacyServicoIds;
  final List<String> legacyNames;
  final String? sensitiveRequirementId;
  final CategoryRiskLevel riskLevel;
  final bool requiresApproval;
  final bool isActive;
  final int sortOrder;

  Iterable<String> get searchTerms sync* {
    yield label;
    yield* aliases;
    yield* commonPhrases;
    yield* examples;
    yield* legacyNames;
  }
}
