import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/catalog/service_taxonomy.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_catalog.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_matcher.dart';

class PrestadorServiceTaxonomySelector extends StatefulWidget {
  const PrestadorServiceTaxonomySelector({
    super.key,
    required this.selectedSubcategoryIds,
    required this.onChanged,
  });

  final Set<String> selectedSubcategoryIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<PrestadorServiceTaxonomySelector> createState() =>
      _PrestadorServiceTaxonomySelectorState();
}

class _PrestadorServiceTaxonomySelectorState
    extends State<PrestadorServiceTaxonomySelector> {
  final TextEditingController _queryController = TextEditingController();
  String _selectedCategoryId = ServiceTaxonomyCatalog.categories.first.id;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _toggle(ServiceTaxonomySubcategory subcategory) {
    final next = {...widget.selectedSubcategoryIds};
    if (!next.add(subcategory.id)) {
      next.remove(subcategory.id);
    }
    widget.onChanged(next);
  }

  List<ServiceTaxonomySubcategory> _visibleSubcategories() {
    final query = _queryController.text.trim();
    if (query.isNotEmpty) {
      final match = ServiceTaxonomyMatcher.matchServiceQuery(
        query,
        suggestionLimit: 12,
      );
      if (match.hasMatch) {
        return [
          match.bestMatch!,
          ...match.suggestions.where((item) => item.id != match.bestMatch!.id),
        ].toList(growable: false);
      }
      return match.suggestions;
    }

    final category =
        ServiceTaxonomyCatalog.findCategoryById(_selectedCategoryId);
    return category?.subcategories.where((item) => item.isActive).toList() ??
        const [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories = ServiceTaxonomyCatalog.categories
        .where((category) => category.isActive)
        .toList(growable: false);
    final visibleSubcategories = _visibleSubcategories();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categorias profissionais',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Escolhe subcategorias profissionais. Os exemplos ajudam clientes a encontrar-te sem virar microtarefa.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('prestador_service_taxonomy_query_field'),
            controller: _queryController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Pesquisar servico, exemplo ou alias',
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
          const SizedBox(height: 12),
          if (_queryController.text.trim().isEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  ChoiceChip(
                    label: Text(category.label),
                    selected: _selectedCategoryId == category.id,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() => _selectedCategoryId = category.id);
                    },
                  ),
              ],
            ),
          const SizedBox(height: 12),
          if (visibleSubcategories.isEmpty)
            Text(
              'Nenhuma subcategoria encontrada.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final subcategory in visibleSubcategories)
              _ProviderSubcategoryTile(
                subcategory: subcategory,
                selected: widget.selectedSubcategoryIds.contains(
                  subcategory.id,
                ),
                onTap: () => _toggle(subcategory),
              ),
        ],
      ),
    );
  }
}

class _ProviderSubcategoryTile extends StatelessWidget {
  const _ProviderSubcategoryTile({
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
    final aliases = subcategory.aliases.take(5).join(', ');
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
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: selected, onChanged: (_) => onTap()),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subcategory.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subcategory.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (aliases.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Exemplos: $aliases',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (examples.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        examples,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (subcategory.requiresApproval) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Exige prestador com aprovacao na categoria.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
