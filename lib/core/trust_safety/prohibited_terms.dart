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

  static const List<String> sexualServicesTerms = [
    'servico sexual',
    'servicos sexuais',
    'sexo pago',
    'programa sexual',
    'acompanhante sexual',
    'acompanhantes sexuais',
    'exploracao sexual',
  ];

  static const List<String> prostitutionTerms = [
    'prostituicao',
    'prostituta',
    'prostitutas',
    'prostituto',
    'prostitutos',
    'garota de programa',
    'garoto de programa',
    'casa de prostituicao',
    'escort',
    'prostitu',
  ];

  static const List<String> obsceneServiceTerms = [
    'puta',
    'putas',
    'vadia',
    'vadias',
  ];

  static const List<String> pornographyTerms = [
    'pornografia',
    'conteudo adulto',
    'conteudo sexual explicito',
    'nudez sexual',
  ];

  static const List<String> illegalDrugTerms = [
    'droga',
    'drogas',
    'droga ilegal',
    'drogas ilegais',
    'comprar droga',
    'vender droga',
    'trafico',
    'trafico de drogas',
    'trafico de droga',
    'cocaina',
    'heroina',
    'crack',
    'metanfetamina',
    'ecstasy',
    'fabricar droga',
  ];

  static const List<String> weaponsTerms = [
    'arma ilegal',
    'armas ilegais',
    'venda de armas',
    'pistola ilegal',
    'arma de fogo ilegal',
    'municoes',
    'municao',
    'explosivos',
    'bomba caseira',
    'fabricar bomba',
  ];

  static const List<String> fraudTerms = [
    'fraude',
    'golpe',
    'burla',
    'esquema fraudulento',
    'cartao clonado',
    'clonar cartao',
    'phishing',
    'roubar senha',
    'hackear conta',
    'invadir conta',
    'roubo de identidade',
  ];

  static const List<String> documentForgeryTerms = [
    'falsificacao de documentos',
    'documento falso',
    'documentos falsos',
    'passaporte falso',
    'bilhete falso',
    'bi falso',
    'carta de conducao falsa',
    'diploma falso',
    'certificado falso',
  ];

  static const List<String> violenceCriminalTerms = [
    'assassino',
    'assassino de aluguel',
    'assassino a soldo',
    'matador',
    'matador de aluguel',
    'sicario',
    'pistoleiro',
    'matar alguem',
    'servico para matar',
    'encomenda de morte',
    'agressao encomendada',
    'espancamento pago',
    'violencia encomendada',
    'servico criminoso',
    'atividade criminosa',
    'atividades criminosas',
    'extorsao',
  ];

  static const List<String> childSafetyTerms = [
    'exploracao de menores',
    'exploracao de menor',
    'exploracao sexual infantil',
    'abuso infantil',
    'menores sexual',
    'pedofilia',
    'pedofilo',
    'venda de criancas',
    'comprar crianca',
    'aliciar menor',
    'material de abuso infantil',
  ];

  static const List<String> humanTraffickingTerms = [
    'trafico humano',
    'venda de pessoas',
    'contrabando humano',
    'exploracao de pessoas',
    'trabalho forcado',
  ];

  static const List<String> terrorismTerms = [
    'ato terrorista',
    'atentado',
    'bomba terrorista',
    'recrutamento terrorista',
    'organizacao terrorista',
    'incitar violencia',
  ];

  static const List<String> illegalMedicalTerms = [
    'cirurgia clandestina',
    'procedimento medico ilegal',
    'receita falsa',
    'vender medicamento controlado',
    'medicamento sem receita',
    'tratamento clandestino',
  ];

  static const List<String> otherIllegalServiceTerms = [
    'jogo ilegal',
    'lavagem de dinheiro',
    'contrabando',
    'mercadoria roubada',
    'roubo sob encomenda',
    'furto sob encomenda',
    'extorsao',
    'chantagem',
    'sequestro',
    'suborno',
    'corrupcao',
  ];

  static const List<String> platformAbuseTerms = [
    'contornar plataforma',
    'fugir da plataforma',
    'venda de contas',
  ];

  static List<ProhibitedTermMatch> match(String text) {
    final normalized = TrustSafetyTextNormalizer.normalize(text);
    if (normalized.isEmpty) return const <ProhibitedTermMatch>[];

    final contexts = <_TextMatchContext>[
      _TextMatchContext(normalized),
    ];
    final leetNormalized = _normalizeLeet(normalized);
    if (leetNormalized != normalized) {
      contexts.add(_TextMatchContext(leetNormalized));
    }

    final matches = <ProhibitedTermMatch>[];
    for (final term in values) {
      for (final phrase in term.phrases) {
        if (contexts.any((context) => _containsPhrase(context, phrase))) {
          matches.add(ProhibitedTermMatch(term: term, phrase: phrase));
          break;
        }
      }
    }
    return matches;
  }

  static bool _containsPhrase(_TextMatchContext context, String phrase) {
    final normalizedPhrase = TrustSafetyTextNormalizer.normalize(phrase);
    if (normalizedPhrase.isEmpty) return false;

    final phraseTokens = normalizedPhrase.split(' ');
    if (phraseTokens.length == 1) {
      final token = phraseTokens.single;
      if (_safePrefixTerms.contains(token)) {
        return context.tokens.any((value) => value.startsWith(token));
      }
      if (context.tokenSet.contains(token)) return true;
      if (_obfuscatableTokens.contains(token)) {
        return _containsObfuscatedToken(context.tokens, token);
      }
      return false;
    }

    return _containsTokenSequence(context.tokens, phraseTokens);
  }

  static bool _containsTokenSequence(
    List<String> tokens,
    List<String> phraseTokens,
  ) {
    if (phraseTokens.isEmpty || tokens.length < phraseTokens.length) {
      return false;
    }

    final maxStart = tokens.length - phraseTokens.length;
    for (var start = 0; start <= maxStart; start += 1) {
      var matched = true;
      var tokenIndex = start;
      for (var offset = 0; offset < phraseTokens.length; offset += 1) {
        final consumed = _matchPhraseTokenAt(
          tokens,
          tokenIndex,
          phraseTokens[offset],
        );
        if (consumed == 0) {
          matched = false;
          break;
        }
        tokenIndex += consumed;
      }
      if (matched) return true;
    }
    return false;
  }

  static int _matchPhraseTokenAt(
    List<String> tokens,
    int start,
    String phraseToken,
  ) {
    if (start >= tokens.length) return 0;
    if (tokens[start] == phraseToken) return 1;
    if (!_obfuscatableTokens.contains(phraseToken)) return 0;

    final maxWindow = phraseToken.length.clamp(2, 16);
    final compact = StringBuffer();
    var hasShortToken = false;

    for (var index = start;
        index < tokens.length && index < start + maxWindow;
        index += 1) {
      final token = tokens[index];
      if (token.length > phraseToken.length) return 0;
      if (token.length <= 2) hasShortToken = true;
      compact.write(token);

      final candidate = compact.toString();
      if (candidate.length > phraseToken.length) return 0;
      if (hasShortToken && candidate == phraseToken) {
        return index - start + 1;
      }
    }
    return 0;
  }

  static bool _containsObfuscatedToken(List<String> tokens, String target) {
    if (tokens.length < 2) return false;
    final maxWindow = target.length.clamp(2, 16);

    for (var start = 0; start < tokens.length; start += 1) {
      final compact = StringBuffer();
      var hasShortToken = false;

      for (var end = start;
          end < tokens.length && end < start + maxWindow;
          end += 1) {
        final token = tokens[end];
        if (token.length > target.length) break;
        if (token.length <= 2) hasShortToken = true;
        compact.write(token);

        final candidate = compact.toString();
        if (candidate.length > target.length) break;
        if (hasShortToken && candidate == target) return true;
      }
    }
    return false;
  }

  static String _normalizeLeet(String value) {
    return value
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't');
  }

  static const Set<String> _safePrefixTerms = {
    'prostitu',
    'pedofil',
    'assass',
    'sicari',
    'terror',
    'falsific',
    'trafic',
    'explosiv',
  };

  static const Set<String> _obfuscatableTokens = {
    'arma',
    'armas',
    'assassino',
    'assassinos',
    'droga',
    'drogas',
    'documento',
    'falso',
    'falsos',
    'puta',
    'putas',
    'sicario',
    'sicarios',
    'vadia',
    'vadias',
    'escort',
    'prostituta',
    'prostitutas',
    'prostituto',
    'prostitutos',
    'prostituicao',
  };

  static const List<ProhibitedTerm> values = [
    ProhibitedTerm(
      id: 'prostitution',
      phrases: prostitutionTerms,
      reasonCode: ReportReasonCode.sexualContent,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'sexual_services',
      phrases: sexualServicesTerms,
      reasonCode: ReportReasonCode.sexualContent,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'obscene_services',
      phrases: obsceneServiceTerms,
      reasonCode: ReportReasonCode.sexualContent,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'pornography',
      phrases: pornographyTerms,
      reasonCode: ReportReasonCode.sexualContent,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'illegal_drugs',
      phrases: illegalDrugTerms,
      reasonCode: ReportReasonCode.drugs,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'human_trafficking',
      phrases: humanTraffickingTerms,
      reasonCode: ReportReasonCode.illegalService,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'illegal_weapons',
      phrases: weaponsTerms,
      reasonCode: ReportReasonCode.violence,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'document_forgery',
      phrases: documentForgeryTerms,
      reasonCode: ReportReasonCode.fraud,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'fraud',
      phrases: fraudTerms,
      reasonCode: ReportReasonCode.fraud,
      severity: ReportSeverity.high,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'child_exploitation',
      phrases: childSafetyTerms,
      reasonCode: ReportReasonCode.childSafety,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'criminal_violence',
      phrases: violenceCriminalTerms,
      reasonCode: ReportReasonCode.violence,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'terrorism_extremism',
      phrases: terrorismTerms,
      reasonCode: ReportReasonCode.violence,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'illegal_medical',
      phrases: illegalMedicalTerms,
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'other_illegal_services',
      phrases: otherIllegalServiceTerms,
      reasonCode: ReportReasonCode.illegalService,
      severity: ReportSeverity.critical,
      decision: TrustSafetyDecision.block,
    ),
    ProhibitedTerm(
      id: 'platform_abuse',
      phrases: platformAbuseTerms,
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
      decision: TrustSafetyDecision.warn,
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

class _TextMatchContext {
  _TextMatchContext(String text)
      : tokens = text.split(' ').where((token) => token.isNotEmpty).toList(),
        tokenSet = text.split(' ').where((token) => token.isNotEmpty).toSet();

  final List<String> tokens;
  final Set<String> tokenSet;
}
