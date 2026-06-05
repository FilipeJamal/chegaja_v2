import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/catalog/service_intent.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_catalog.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_matcher.dart';
import 'package:chegaja_v2/core/models/provider_custom_service.dart';
import 'package:chegaja_v2/core/trust_safety/custom_service_safety_validator.dart';

class ServiceTaxonomySelection {
  const ServiceTaxonomySelection({
    required this.category,
    required this.subcategory,
    required this.intent,
    this.query = '',
    this.customService,
  });

  final ServiceTaxonomyCategory category;
  final ServiceTaxonomySubcategory subcategory;
  final ServiceIntent intent;
  final String query;
  final ProviderCustomService? customService;

  bool get isCustomService => customService != null;
  String get servicoId => customService?.id ?? subcategory.id;
  String get servicoNome => customService?.title ?? subcategory.label;
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
    ProviderCustomService? customService,
  }) {
    return ServiceTaxonomySelection(
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      intent: intent ?? this.intent,
      query: query ?? this.query,
      customService: customService ?? this.customService,
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
  late final TextEditingController _customNameController;
  late final TextEditingController _customDescriptionController;
  late final TextEditingController _customAliasesController;
  late final FocusNode _customNameFocus;
  String? _selectedCategoryId;
  ServiceTaxonomySelection? _localSelection;
  String? _customServiceMessage;
  bool _customServiceMessageIsError = false;
  bool _customServiceFormOpen = false;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.value?.query ?? '');
    _customNameController = TextEditingController(
      text: widget.value?.customService?.title ?? '',
    );
    _customDescriptionController = TextEditingController(
      text: widget.value?.customService?.description ?? '',
    );
    _customAliasesController = TextEditingController(
      text: widget.value?.customService?.aliases.join(', ') ?? '',
    );
    _customNameFocus = FocusNode();
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
    _customNameController.dispose();
    _customDescriptionController.dispose();
    _customAliasesController.dispose();
    _customNameFocus.dispose();
    super.dispose();
  }

  ServiceTaxonomyMatch get _match {
    return ServiceTaxonomyMatcher.matchServiceQuery(_queryController.text);
  }

  bool _isCustomFallbackQuery(String query) {
    if (query.trim().isEmpty) return false;
    final safety = CustomServiceSafetyValidator.validate(title: query);
    if (!safety.shouldSave) return true;
    final match = ServiceTaxonomyMatcher.matchServiceQuery(query);
    return !match.hasMatch && match.suggestions.isEmpty;
  }

  void _syncCustomNameFromQuery(String query) {
    final normalized = query.trim();
    if (!_isCustomFallbackQuery(normalized)) return;
    if (_customNameController.text.trim().isNotEmpty) return;
    _customNameController.text = normalized;
    _customNameController.selection = TextSelection.collapsed(
      offset: _customNameController.text.length,
    );
  }

  ServiceTaxonomyCategory? _categoryForSubcategory(
    ServiceTaxonomySubcategory subcategory,
  ) {
    return ServiceTaxonomyCatalog.findCategoryById(
      subcategory.parentCategoryId,
    );
  }

  void _selectSubcategory(ServiceTaxonomySubcategory subcategory) {
    final category = _categoryForSubcategory(subcategory);
    if (category == null) return;
    if (subcategory.id == ServiceTaxonomyCatalog.otherSubcategory.id) {
      _openCustomServiceForm(category);
      return;
    }
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

  void _openCustomServiceForm(ServiceTaxonomyCategory category) {
    final query = _queryController.text.trim();
    if (_customNameController.text.trim().isEmpty && query.isNotEmpty) {
      _customNameController.text = query;
      _customNameController.selection = TextSelection.collapsed(
        offset: _customNameController.text.length,
      );
    }
    setState(() {
      _selectedCategoryId = category.id;
      _localSelection = null;
      _customServiceMessage = null;
      _customServiceMessageIsError = false;
      _customServiceFormOpen = true;
    });
    _customNameFocus.requestFocus();
  }

  void _addCustomService() {
    final category = ServiceTaxonomyCatalog.findCategoryById('other') ??
        _categoryForSubcategory(ServiceTaxonomyCatalog.otherSubcategory);
    if (category == null) return;

    final title = _customNameController.text.trim();
    final description = _customDescriptionController.text.trim();
    if (title.length < 3 || description.length < 3) {
      setState(() {
        _customServiceMessage =
            'Indica o nome e uma descrição curta do serviço.';
        _customServiceMessageIsError = true;
      });
      return;
    }

    final aliases = _customAliasesController.text.split(RegExp(r'[,;\n]'));
    final safety = CustomServiceSafetyValidator.validate(
      title: title,
      description: description,
      aliases: aliases,
      query: _queryController.text,
    );
    if (!safety.shouldSave) {
      setState(() {
        _queryController.clear();
        _customNameController.clear();
        _customAliasesController.clear();
        _customServiceFormOpen = true;
        _customServiceMessage = safety.messageForUser;
        _customServiceMessageIsError = true;
      });
      return;
    }

    final customService = ProviderCustomService.fromInput(
      title: title,
      description: description,
      aliasesText: _customAliasesController.text,
      parentCategoryId: category.id,
      taxonomySubcategoryId: ServiceTaxonomyCatalog.otherSubcategory.id,
    );
    final selection = ServiceTaxonomySelection(
      category: category,
      subcategory: ServiceTaxonomyCatalog.otherSubcategory,
      intent: ServiceTaxonomyCatalog.otherSubcategory.defaultIntent,
      query: _queryController.text.trim(),
      customService: customService,
    );
    setState(() {
      _selectedCategoryId = category.id;
      _localSelection = selection;
      _customServiceMessage =
          safety.messageForUser.isEmpty ? null : safety.messageForUser;
      _customServiceMessageIsError = false;
      _customServiceFormOpen = safety.messageForUser.isNotEmpty;
    });
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
    final queryText = _queryController.text.trim();
    final match = _match;
    var suggestions = match.hasMatch
        ? <ServiceTaxonomySubcategory>[
            match.bestMatch!,
            ...match.suggestions.where((s) => s.id != match.bestMatch!.id),
          ].take(4).toList(growable: false)
        : match.suggestions.take(4).toList(growable: false);
    if (queryText.isNotEmpty && !match.hasMatch && match.suggestions.isEmpty) {
      suggestions = [ServiceTaxonomyCatalog.otherSubcategory];
    }
    final showOtherFallback = queryText.isNotEmpty &&
        suggestions.any(
          (suggestion) =>
              suggestion.id == ServiceTaxonomyCatalog.otherSubcategory.id,
        );
    final showCustomServiceForm = showOtherFallback || _customServiceFormOpen;

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
                        setState(() {
                          _queryController.clear();
                          _customServiceFormOpen = false;
                        });
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            onChanged: (value) {
              setState(() {
                _syncCustomNameFromQuery(value);
                _customServiceFormOpen = _isCustomFallbackQuery(value);
              });
            },
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              showOtherFallback
                  ? 'Nao encontramos uma categoria certa'
                  : 'Sugestoes',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showOtherFallback) ...[
              const SizedBox(height: 4),
              Text(
                'Escolhe Outro servico e usa a descricao para descrever melhor o que precisas.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
          if (showCustomServiceForm) ...[
            _CustomServiceRequestForm(
              nameController: _customNameController,
              descriptionController: _customDescriptionController,
              aliasesController: _customAliasesController,
              nameFocusNode: _customNameFocus,
              message: _customServiceMessage,
              messageIsError: _customServiceMessageIsError,
              onSubmit: _addCustomService,
            ),
            const SizedBox(height: 18),
          ],
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

class _CustomServiceRequestForm extends StatelessWidget {
  const _CustomServiceRequestForm({
    required this.nameController,
    required this.descriptionController,
    required this.aliasesController,
    required this.nameFocusNode,
    required this.message,
    required this.messageIsError,
    required this.onSubmit,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController aliasesController;
  final FocusNode nameFocusNode;
  final String? message;
  final bool messageIsError;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
        color: colorScheme.primaryContainer.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descreve o serviço que precisas',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('client_custom_service_name_field'),
            controller: nameController,
            focusNode: nameFocusNode,
            maxLength: ProviderCustomService.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome do serviço',
              hintText:
                  'Ex.: ajuda com guarda-roupa, conserto de máquina, serviço diferente',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('client_custom_service_description_field'),
            controller: descriptionController,
            maxLength: ProviderCustomService.maxDescriptionLength,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descrição do que precisas',
              hintText: 'Explica o problema ou o trabalho que queres.',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('client_custom_service_aliases_field'),
            controller: aliasesController,
            maxLength: ProviderCustomService.maxAliasLength *
                ProviderCustomService.maxAliases,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Palavras relacionadas',
              hintText: 'Ex.: roupa, estilo, imagem, moda, guarda-roupa',
              counterText: '',
            ),
          ),
          if (message != null && message!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: messageIsError ? colorScheme.error : colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const Key('client_custom_service_add_button'),
              onPressed: onSubmit,
              icon: const Icon(Icons.check),
              label: const Text('Usar serviço personalizado'),
            ),
          ),
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
