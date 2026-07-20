import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/legal/legal_documents.dart';
import 'package:chegaja_v2/core/services/legal_consent_service.dart';

class LegalConsentGate {
  const LegalConsentGate._();

  static Future<bool> ensure(
    BuildContext context, {
    required String action,
  }) async {
    if (await LegalConsentService.instance.hasCurrentConsent()) return true;
    if (!context.mounted) return false;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LegalDocumentsScreen(
          requireAcceptance: true,
          action: action,
        ),
      ),
    );
    return result == true;
  }
}

class LegalDocumentsScreen extends StatefulWidget {
  const LegalDocumentsScreen({
    super.key,
    this.requireAcceptance = false,
    this.action = 'continuar',
  });

  final bool requireAcceptance;
  final String action;

  @override
  State<LegalDocumentsScreen> createState() => _LegalDocumentsScreenState();
}

class _LegalDocumentsScreenState extends State<LegalDocumentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _ageConfirmed = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    if (!_termsAccepted || !_privacyAccepted || !_ageConfirmed || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await LegalConsentService.instance.acceptCurrent();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e privacidade'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Termos'),
            Tab(text: 'Privacidade'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Versão ${LegalDocuments.version} • em vigor em ${LegalDocuments.effectiveDate}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _documentList(LegalDocuments.terms),
                _documentList(LegalDocuments.privacy),
              ],
            ),
          ),
          if (widget.requireAcceptance)
            SafeArea(
              top: false,
              child: Material(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Para ${widget.action}, confirma os documentos e a idade mínima.',
                      ),
                      CheckboxListTile(
                        value: _termsAccepted,
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                  () => _termsAccepted = value == true,
                                ),
                        title:
                            const Text('Li e aceito os Termos de Utilização'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: _privacyAccepted,
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                  () => _privacyAccepted = value == true,
                                ),
                        title: const Text('Li a Política de Privacidade'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        value: _ageConfirmed,
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                  () => _ageConfirmed = value == true,
                                ),
                        title: const Text(
                          'Confirmo que tenho pelo menos 18 anos',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_error != null)
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _termsAccepted &&
                                  _privacyAccepted &&
                                  _ageConfirmed &&
                                  !_saving
                              ? _accept
                              : null,
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Aceitar e continuar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _documentList(List<LegalSection> sections) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final section = sections[index];
        return Semantics(
          header: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(section.body),
            ],
          ),
        );
      },
    );
  }
}
