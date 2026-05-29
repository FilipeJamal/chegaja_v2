import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/trust_safety_text_normalizer.dart';

class ProhibitedTerm {
  const ProhibitedTerm({
    required this.id,
    required this.phrases,
    required this.reasonCode,
    required this.severity,
    required this.decision,
  });

  final String id;
  final List<String> phrases;
  final ReportReasonCode reasonCode;
  final ReportSeverity severity;
  final TrustSafetyDecision decision;
}

class ProhibitedTermMatch {
  const ProhibitedTermMatch({
    required this.term,
    required this.phrase,
  });

  final ProhibitedTerm term;
  final String phrase;
}

class ProhibitedTerms {
  const ProhibitedTerms._();

  static List<ProhibitedTermMatch> match(String text) {
    final normalized = TrustSafetyTextNormalizer.normalize(text);
    if (normalized.isEmpty) return const <ProhibitedTermMatch>[];

    final matches = <ProhibitedTermMatch>[];
    for (final term in values) {
      for (final phrase in term.phrases) {
        if (_containsPhrase(normalized, phrase)) {
          matches.add(ProhibitedTermMatch(term: term, phrase: phrase));
          break;
        }
      }
    }
    return matches;
  }

  static bool _containsPhrase(String text, String phrase) {
    final haystack = ' $text ';
    final needle = ' ${TrustSafetyTextNormalizer.normalize(phrase)} ';
    return haystack.contains(needle);
  }

  static const List<ProhibitedTerm> values = [
    ProhibitedTerm(
      id: 'sexual_services',
      phrases: [
        'prostituicao',
        'servico sexual',
        'servicos sexuais',
        'sexo pago',
        'acompanhante sexual',
        'exploracao sexual',
      ],
      reasonCode: ReportReasonCode.sexualContent,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'pornography',
      phrases: [
        'pornografia',
        'conteudo sexual explicito',
        'nudez sexual',
      ],
      reasonCode: ReportReasonCode.sexualContent,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'human_trafficking',
      phrases: [
        'trafico humano',
        'trabalho forcado',
      ],
      reasonCode: ReportReasonCode.illegalService,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'illegal_drugs',
      phrases: [
        'droga ilegal',
        'drogas ilegais',
        'vender droga',
        'cocaina',
        'heroina',
        'crack',
      ],
      reasonCode: ReportReasonCode.drugs,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'illegal_weapons',
      phrases: [
        'arma ilegal',
        'armas ilegais',
        'venda de armas',
        'pistola ilegal',
      ],
      reasonCode: ReportReasonCode.violence,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'document_forgery',
      phrases: [
        'falsificacao de documentos',
        'documento falso',
        'documentos falsos',
        'passaporte falso',
      ],
      reasonCode: ReportReasonCode.fraud,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'fraud',
      phrases: [
        'fraude',
        'golpe',
        'burla',
        'phishing',
      ],
      reasonCode: ReportReasonCode.fraud,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'child_exploitation',
      phrases: [
        'exploracao de menores',
        'abuso infantil',
        'menores sexual',
      ],
      reasonCode: ReportReasonCode.childSafety,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'criminal_violence',
      phrases: [
        'matar alguem',
        'agressao encomendada',
        'servico criminoso',
        'extorsao',
      ],
      reasonCode: ReportReasonCode.violence,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'ambiguous_adult_context',
      phrases: [
        'companhia discreta',
        'servico adulto',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
      decision: TrustSafetyDecision.needsReview,
    ),
  ];
}
