import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/catalog/provider_custom_service.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_catalog.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_matcher.dart';

class PrestadorServiceTaxonomySelector extends StatefulWidget {
  const PrestadorServiceTaxonomySelector({
    super.key,
    required this.selectedSubcategoryIds,
    required this.onChanged,
    this.customServices = const [],
    this.onCustomServicesChanged,
  });

  final Set<String> selectedSubcategoryIds;
  final ValueChanged<Set<String>> onChanged;
  final List<ProviderCustomService> customServices;
  final ValueChanged<List<ProviderCustomService>>? onCustomServicesChanged;

  @override
  State<PrestadorServiceTaxonomySelector> createState() =>
      _PrestadorServiceTaxonomySelectorState();
}

class _PrestadorServiceTaxonomySelectorState
    extends State<PrestadorServiceTaxonomySelector> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customDescriptionController =
      TextEditingController();
  final FocusNode _customNameFocus = FocusNode();
  String _selectedCategoryId = ServiceTaxonomyCatalog.categories.first.id;
  String _lastCustomQuery = '';

  @override
  void dispose() {
    _queryController.dispose();
    _customNameController.dispose();
    _customDescriptionController.dispose();
    _customNameFocus.dispose();
    super.dispose();
  }

  void _toggle(ServiceTaxonomySubcategory subcategory) {
    final next = {...widget.selectedSubcategoryIds};
    if (!next.add(subcategory.id)) {
      next.remove(subcategory.id);
    }
    widget.onChanged(next);
  }

  bool _isCustomFallbackQuery(String query) {
    if (query.trim().isEmpty) return false;
    final match = ServiceTaxonomyMatcher.matchServiceQuery(query);
    return !match.hasMatch && match.suggestions.isEmpty;
  }

  void _syncCustomName(String query) {
    final normalized = query.trim();
    if (!_isCustomFallbackQuery(normalized)) return;
    final current = _customNameController.text.trim();
    if (current.isEmpty || current == _lastCustomQuery) {
      _customNameController.text = normalized;
      _customNameController.selection = TextSelection.collapsed(
        offset: _customNameController.text.length,
      );
    }
    _lastCustomQuery = normalized;
  }

  void _addCustomService() {
    final name = _customNameController.text.trim();
    if (name.length < 2) return;

    final service = ProviderCustomService.fromInput(
      name: name,
      description: _customDescriptionController.text,
    );
    final nextCustomServices = [
      ...widget.customServices.where((item) => item.id != service.id),
      service,
    ];
    widget.onCustomServicesChanged?.call(nextCustomServices);

    final nextSelected = {...widget.selectedSubcategoryIds, service.id};
    widget.onChanged(nextSelected);

    setState(() {
      _queryController.clear();
      _customNameController.clear();
      _customDescriptionController.clear();
      _lastCustomQuery = '';
    });
  }

  void _removeCustomService(ProviderCustomService service) {
    widget.onCustomServicesChanged?.call(
      widget.customServices.where((item) => item.id != service.id).toList(),
    );
    final nextSelected = {...widget.selectedSubcategoryIds}..remove(service.id);
    widget.onChanged(nextSelected);
  }

  void _focusCustomServiceName() {
    _syncCustomName(_queryController.text);
    _customNameFocus.requestFocus();
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
      if (match.suggestions.isEmpty) {
        return [ServiceTaxonomyCatalog.otherSubcategory];
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
    final query = _queryController.text.trim();
    final visibleSubcategories = _visibleSubcategories();
    final showCustomServiceForm = _isCustomFallbackQuery(query);

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
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar pesquisa',
                      onPressed: () {
                        setState(() {
                          _queryController.clear();
                          _lastCustomQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (value) {
              setState(() {
                _syncCustomName(value);
              });
            },
          ),
          const SizedBox(height: 12),
          if (query.isEmpty)
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
                onTap:
                    showCustomServiceForm && subcategory.id == 'other_service'
                        ? _focusCustomServiceName
                        : () => _toggle(subcategory),
              ),
          if (showCustomServiceForm) ...[
            const SizedBox(height: 8),
            _CustomServiceForm(
              nameController: _customNameController,
              descriptionController: _customDescriptionController,
              nameFocusNode: _customNameFocus,
              onSubmit: _addCustomService,
            ),
          ],
          if (widget.customServices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Servicos personalizados',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final service in widget.customServices)
              _CustomServiceTile(
                service: service,
                selected: widget.selectedSubcategoryIds.contains(service.id),
                onRemove: () => _removeCustomService(service),
              ),
          ],
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
    final category = ServiceTaxonomyCatalog.findCategoryById(
      subcategory.parentCategoryId,
    );
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
                    if (category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Categoria: ${category.label}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
                    if (subcategory.id == 'other_service') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Se nao aparecer como categoria principal, adiciona o nome real do servico abaixo para clientes conseguirem encontrar-te.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
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

class _CustomServiceForm extends StatelessWidget {
  const _CustomServiceForm({
    required this.nameController,
    required this.descriptionController,
    required this.nameFocusNode,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final FocusNode nameFocusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adicionar servico personalizado',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Guarda o nome real do servico para aparecer na pesquisa dos clientes. Usa detalhes curtos e profissionais.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('custom_service_name_field'),
            controller: nameController,
            focusNode: nameFocusNode,
            maxLength: ProviderCustomService.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome do servico',
              hintText: 'Ex.: Consultora de imagem',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('custom_service_description_field'),
            controller: descriptionController,
            maxLength: ProviderCustomService.maxDescriptionLength,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Detalhes do servico',
              hintText:
                  'Ex.: estilo pessoal, guarda-roupa, imagem profissional...',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const Key('add_custom_service_button'),
              onPressed: onSubmit,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar servico'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomServiceTile extends StatelessWidget {
  const _CustomServiceTile({
    required this.service,
    required this.selected,
    required this.onRemove,
  });

  final ProviderCustomService service;
  final bool selected;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.add_business_outlined,
              color: selected ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Servico adicionado pelo prestador.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: Key('remove_custom_service_${service.id}'),
              tooltip: 'Remover servico personalizado',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
