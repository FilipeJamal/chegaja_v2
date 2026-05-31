import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/category_requirement.dart';
import 'package:chegaja_v2/core/models/sensitive_category_request.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';

class SensitiveCategoryRequestInput {
  const SensitiveCategoryRequestInput({
    required this.evidenceTypes,
    required this.evidenceText,
    required this.portfolioUrls,
  });

  final List<EvidenceType> evidenceTypes;
  final String evidenceText;
  final List<String> portfolioUrls;
}

class SensitiveCategoryRequestSheet extends StatefulWidget {
  const SensitiveCategoryRequestSheet({
    super.key,
    required this.requirement,
    required this.onSubmit,
    this.initialRequest,
    this.portfolioUrls = const [],
  });

  final CategoryRequirement requirement;
  final SensitiveCategoryRequest? initialRequest;
  final List<String> portfolioUrls;
  final Future<void> Function(SensitiveCategoryRequestInput input) onSubmit;

  @override
  State<SensitiveCategoryRequestSheet> createState() =>
      _SensitiveCategoryRequestSheetState();
}

class _SensitiveCategoryRequestSheetState
    extends State<SensitiveCategoryRequestSheet> {
  static const int _maxEvidenceTextLength = 2000;
  static const int _minEvidenceTextLength = 20;

  late final TextEditingController _evidenceCtrl;
  late final Set<EvidenceType> _selectedEvidenceTypes;
  late final Set<String> _selectedPortfolioUrls;

  String? _validationError;
  String? _submitError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRequest;
    _evidenceCtrl = TextEditingController(text: initial?.evidenceText ?? '');
    _selectedEvidenceTypes = {
      ...?initial?.evidenceTypes,
    };
    _selectedPortfolioUrls = {
      ...?initial?.portfolioUrls,
    };
  }

  @override
  void dispose() {
    _evidenceCtrl.dispose();
    super.dispose();
  }

  List<EvidenceType> get _availableEvidenceTypes {
    if (widget.requirement.evidenceTypes.isNotEmpty) {
      return widget.requirement.evidenceTypes;
    }
    return const [
      EvidenceType.workExperience,
      EvidenceType.portfolioReference,
      EvidenceType.externalProfile,
      EvidenceType.declaration,
      EvidenceType.other,
    ];
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _validationError = _validate();
      _submitError = null;
    });
    if (_validationError != null) return;

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        SensitiveCategoryRequestInput(
          evidenceTypes: _selectedEvidenceTypes.toList(growable: false),
          evidenceText: _evidenceCtrl.text.trim(),
          portfolioUrls: _selectedPortfolioUrls.toList(growable: false),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Nao conseguimos enviar este pedido agora.';
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String? _validate() {
    if (_selectedEvidenceTypes.isEmpty) {
      return 'Seleciona pelo menos um tipo de comprovativo.';
    }
    final text = _evidenceCtrl.text.trim();
    if (text.length < _minEvidenceTextLength) {
      return 'Descreve a tua experiencia com pelo menos 20 caracteres.';
    }
    if (text.length > _maxEvidenceTextLength) {
      return 'Mantem a descricao ate 2000 caracteres.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isResubmit = widget.initialRequest?.status ==
        SensitiveCategoryRequestStatus.needsMoreInfo;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.requirement.categoryName,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              widget.requirement.userMessage ??
                  widget.requirement.description ??
                  'Esta categoria precisa de analise antes de ficar aprovada.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Tipo de comprovativo',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in _availableEvidenceTypes)
                  FilterChip(
                    label: Text(evidenceTypeLabel(type)),
                    selected: _selectedEvidenceTypes.contains(type),
                    onSelected: _submitting
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected) {
                                _selectedEvidenceTypes.add(type);
                              } else {
                                _selectedEvidenceTypes.remove(type);
                              }
                              _validationError = null;
                            });
                          },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('sensitive_category_evidence_text'),
              controller: _evidenceCtrl,
              enabled: !_submitting,
              minLines: 4,
              maxLines: 7,
              maxLength: _maxEvidenceTextLength,
              decoration: const InputDecoration(
                labelText: 'Experiencia ou comprovativo textual',
                helperText:
                    'Resume experiencia, formacao, referencias ou contexto profissional.',
              ),
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            if (widget.portfolioUrls.isNotEmpty) ...[
              Text(
                'Referencias do portfolio',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              AppCard(
                variant: AppCardVariant.flat,
                size: AppCardSize.compact,
                child: Column(
                  children: [
                    for (final url in widget.portfolioUrls)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _selectedPortfolioUrls.contains(url),
                        onChanged: _submitting
                            ? null
                            : (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedPortfolioUrls.add(url);
                                  } else {
                                    _selectedPortfolioUrls.remove(url);
                                  }
                                });
                              },
                        title: Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: const Text('Portfolio publico'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _InfoBox(
              icon: Icons.lock_outline,
              text:
                  'Nao envies documentos pessoais neste campo. Se for necessario, o ChegaJa pedira de forma segura.',
            ),
            const SizedBox(height: 8),
            _InfoBox(
              icon: Icons.upload_file_outlined,
              text:
                  'O envio de ficheiros fica para uma fase posterior. Por agora, descreve a tua experiencia e usa portfolio publico como referencia.',
            ),
            if (_validationError != null || _submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                _validationError ?? _submitError!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.secondary,
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: _submitting
                        ? 'A enviar...'
                        : isResubmit
                            ? 'Reenviar pedido'
                            : 'Enviar pedido',
                    leadingIcon: Icons.send_outlined,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String evidenceTypeLabel(EvidenceType type) {
  return switch (type) {
    EvidenceType.certificate => 'Comprovativo profissional',
    EvidenceType.license => 'Licenca profissional',
    EvidenceType.workExperience => 'Experiencia de trabalho',
    EvidenceType.portfolioReference => 'Portfolio publico',
    EvidenceType.externalProfile => 'Perfil profissional externo',
    EvidenceType.declaration => 'Declaracao profissional',
    EvidenceType.other => 'Outro comprovativo',
  };
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
