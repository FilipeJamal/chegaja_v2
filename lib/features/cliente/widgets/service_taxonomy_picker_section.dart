import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/catalog/service_intent.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_catalog.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_matcher.dart';

class ServiceTaxonomySelection {
  const ServiceTaxonomySelection({
    required this.category,
    required this.subcategory,
    required this.intent,
    this.query = '',
  });

  final ServiceTaxonomyCategory category;
  final ServiceTaxonomySubcategory subcategory;
  final ServiceIntent intent;
  final String query;

  String get servicoId => subcategory.id;
  String get servicoNome => subcategory.label;
  String get legacyMode => intent.legacyMode;
  bool get requiresApproval => subcategory.requiresApproval;
  String? get sensitiveRequirementId {
    if (!requiresApproval) return null;
    return subcategory.sensitiveRequirementId ?? subcategory.id;
  }

  ServiceTaxonomySelection copyWith({
    ServiceTaxonomyCategory? category,
    ServiceTaxonomySubcategory? subcategory,
    ServiceIntent? intent,
    String? query,
  }) {
    return ServiceTaxonomySelection(
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      intent: intent ?? this.intent,
      query: query ?? this.query,
    );
  }
}

class ServiceTaxonomyPickerSection extends StatefulWidget {
  const ServiceTaxonomyPickerSection({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final ServiceTaxonomySelection? value;
  final ValueChanged<ServiceTaxonomySelection> onChanged;
  final String? errorText;

  @override
  State<ServiceTaxonomyPickerSection> createState() =>
      _ServiceTaxonomyPickerSectionState();
}

class _ServiceTaxonomyPickerSectionState
    extends State<ServiceTaxonomyPickerSection> {
  late final TextEditingController _queryController;
  String? _selectedCategoryId;
  ServiceTaxonomySelection? _localSelection;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.value?.query ?? '');
    _selectedCategoryId = widget.value?.category.id;
  }

  @override
  void didUpdateWidget(ServiceTaxonomyPickerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value?.category.id != oldWidget.value?.category.id) {
      _selectedCategoryId = widget.value?.category.id;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  ServiceTaxonomyMatch get _match {
    return ServiceTaxonomyMatcher.matchServiceQuery(_queryController.text);
  }

  ServiceTaxonomyCategory? _categoryForSubcategory(
    ServiceTaxonomySubcategory subcategory,
  ) {
    return ServiceTaxonomyCatalog.findCategoryById(
        subcategory.parentCategoryId);
  }

  void _selectSubcategory(ServiceTaxonomySubcategory subcategory) {
    final category = _categoryForSubcategory(subcategory);
    if (category == null) return;
    final current = widget.value ?? _localSelection;
    final intent = current?.subcategory.id == subcategory.id
        ? current!.intent
        : subcategory.defaultIntent;
    final selection = ServiceTaxonomySelection(
      category: category,
      subcategory: subcategory,
      intent: intent,
      query: _queryController.text.trim(),
    );
    setState(() => _selectedCategoryId = category.id);
    _localSelection = selection;
    widget.onChanged(selection);
  }

  void _selectIntent(ServiceIntent intent) {
    final current = widget.value ?? _localSelection;
    if (current == null) return;
    final selection = current.copyWith(intent: intent);
    setState(() => _localSelection = selection);
    widget.onChanged(selection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ServiceTaxonomyCatalog.categories
        .where((category) => category.isActive)
        .toList(growable: false);
    final selectedCategory =
        _selectedCategoryId == null || _selectedCategoryId!.isEmpty
            ? null
            : ServiceTaxonomyCatalog.findCategoryById(_selectedCategoryId!);
    final currentSelection = widget.value ?? _localSelection;
    final selectedSubcategory = currentSelection?.subcategory;
    final match = _match;
    final suggestions = match.hasMatch
        ? <ServiceTaxonomySubcategory>[
            match.bestMatch!,
            ...match.suggestions.where((s) => s.id != match.bestMatch!.id),
          ].take(4).toList(growable: false)
        : match.suggestions.take(4).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.errorText == null
              ? colorScheme.outlineVariant
              : colorScheme.error,
        ),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Que servico precisas?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('service_taxonomy_query_field'),
            controller: _queryController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText:
                  'Ex.: cano rebentou, bolo de aniversario, arranjar luz...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _queryController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar pesquisa',
                      onPressed: () {
                        setState(_queryController.clear);
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Sugestoes',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in suggestions)
                  ActionChip(
                    label: Text(suggestion.label),
                    avatar: const Icon(Icons.auto_awesome, size: 18),
                    onPressed: () => _selectSubcategory(suggestion),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Escolhe uma categoria',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                ChoiceChip(
                  label: Text(category.label),
                  selected: selectedCategory?.id == category.id,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => _selectedCategoryId = category.id);
                  },
                ),
            ],
          ),
          if (selectedCategory != null) ...[
            const SizedBox(height: 18),
            Text(
              'Escolhe o tipo de servico',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final subcategory
                in selectedCategory.subcategories.where((sub) => sub.isActive))
              _SubcategoryTile(
                subcategory: subcategory,
                selected: selectedSubcategory?.id == subcategory.id,
                onTap: () => _selectSubcategory(subcategory),
              ),
          ],
          if (selectedSubcategory != null) ...[
            const SizedBox(height: 18),
            Text(
              'Quando precisas?',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final intent in selectedSubcategory.allowedIntents)
                  ChoiceChip(
                    label: Text(intent.label),
                    selected: currentSelection?.intent == intent,
                    onSelected: (selected) {
                      if (selected) _selectIntent(intent);
                    },
                  ),
              ],
            ),
            if (selectedSubcategory.requiresApproval) ...[
              const SizedBox(height: 12),
              _ApprovalNotice(categoryName: selectedSubcategory.label),
            ],
          ],
          if (widget.errorText != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubcategoryTile extends StatelessWidget {
  const _SubcategoryTile({
    required this.subcategory,
    required this.selected,
    required this.onTap,
  });

  final ServiceTaxonomySubcategory subcategory;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final examples = subcategory.examples.take(2).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? colorScheme.primary : colorScheme.outlineVariant,
            ),
            color: selected
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subcategory.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (subcategory.requiresApproval)
                    Tooltip(
                      message: 'Exige aprovacao da categoria',
                      child: Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subcategory.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (examples.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  examples,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalNotice extends StatelessWidget {
  const _ApprovalNotice({required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Este servico exige prestador com aprovacao na categoria.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
