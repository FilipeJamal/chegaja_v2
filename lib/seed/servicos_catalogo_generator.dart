// lib/seed/servicos_catalogo_generator.dart
// Gera um catalogo amplo de servicos com IDs estaveis e keywords.

List<Map<String, dynamic>> buildCatalogoCompleto({int? limit}) {
  final out = <Map<String, dynamic>>[];
  final ids = <String>{};

  void addItem(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString().trim();
    final name = (item['name'] ?? '').toString().trim();
    if (id.isEmpty || name.isEmpty) return;
    if (ids.contains(id)) return;
    ids.add(id);
    out.add(item);
  }

  for (final item in _baseServicosFixos()) {
    addItem(item);
  }

  for (final group in _groups) {
    final baseKeywords = _buildKeywordsForGroup(group, includeModeIntent: true);
    if (group.includeBase) {
      addItem({
        'id': group.baseId ?? _stableId(group.macro, group.sub, group.base),
        'name': group.base,
        'mode': group.mode,
        'keywords': baseKeywords,
        'iconKey': group.iconKey,
        'isActive': true,
      });
    }

    for (final action in group.actions) {
      for (final object in group.objects) {
        final name = '${action.label} $object';
        final keywords = <String>{
          ...baseKeywords,
          ...action.keywords.map((k) => 'k:$k'),
          object,
          group.sub,
          group.macro,
        };
        addItem({
          'id': _stableId(group.macro, group.sub, name),
          'name': name,
          'mode': group.mode,
          'keywords': _normalizeKeywords(keywords),
          'iconKey': group.iconKey,
          'isActive': true,
        });
      }
    }
  }

  if (limit != null && out.length > limit) {
    return out.sublist(0, limit);
  }
  return out;
}

class _Action {
  const _Action(this.label, [this.keywords = const []]);
  final String label;
  final List<String> keywords;
}

class _Group {
  const _Group({
    required this.macro,
    required this.sub,
    required this.base,
    required this.mode,
    required this.iconKey,
    required this.actions,
    required this.objects,
    this.includeBase = true,
    this.baseId,
    this.synonyms = const [],
    this.materials = const [],
    this.problems = const [],
    this.outputs = const [],
    this.extraKeywords = const [],
  });

  final String macro;
  final String sub;
  final String base;
  final String mode;
  final String iconKey;
  final List<_Action> actions;
  final List<String> objects;
  final bool includeBase;
  final String? baseId;
  final List<String> synonyms;
  final List<String> materials;
  final List<String> problems;
  final List<String> outputs;
  final List<String> extraKeywords;
}

const _actionsReparacao = [
  _Action('Repara\u00e7\u00e3o de', ['reparar', 'arranjar', 'consertar']),
  _Action('Instala\u00e7\u00e3o de', ['instalar', 'montagem']),
  _Action('Substitui\u00e7\u00e3o de', ['substituir', 'trocar']),
  _Action('Manuten\u00e7\u00e3o de', ['manutencao', 'manter']),
  _Action('Diagn\u00f3stico de', ['diagnostico', 'avaliacao']),
  _Action('Limpeza de', ['limpeza', 'higienizacao']),
  _Action('Revis\u00e3o de', ['revisao', 'inspecao']),
  _Action('Configura\u00e7\u00e3o de', ['configurar', 'ajustar']),
];

const _actionsConstrucao = [
  _Action('Constru\u00e7\u00e3o de', ['construcao']),
  _Action('Repara\u00e7\u00e3o de', ['reparacao']),
  _Action('Assentamento de', ['assentamento']),
  _Action('Demoli\u00e7\u00e3o de', ['demolicao']),
  _Action('Reboco de', ['reboco']),
  _Action('Refor\u00e7o de', ['reforco']),
  _Action('Nivelamento de', ['nivelamento']),
];

const _actionsLimpeza = [
  _Action('Limpeza de', ['limpeza']),
  _Action('Higieniza\u00e7\u00e3o de', ['higienizacao']),
  _Action('Desinfe\u00e7\u00e3o de', ['desinfeccao']),
  _Action('Lavagem de', ['lavagem']),
  _Action('Tratamento de', ['tratamento']),
  _Action('Remo\u00e7\u00e3o de', ['remocao']),
];

const _actionsEntrega = [
  _Action('Entrega de', ['entrega', 'delivery']),
  _Action('Transporte de', ['transporte']),
  _Action('Recolha de', ['recolha']),
  _Action('Distribui\u00e7\u00e3o de', ['distribuicao']),
  _Action('Envio de', ['envio']),
];

const _actionsAuto = [
  _Action('Repara\u00e7\u00e3o de', ['reparar']),
  _Action('Substitui\u00e7\u00e3o de', ['substituir']),
  _Action('Diagn\u00f3stico de', ['diagnostico']),
  _Action('Manuten\u00e7\u00e3o de', ['manutencao']),
  _Action('Revis\u00e3o de', ['revisao']),
  _Action('Limpeza de', ['limpeza']),
];

const _actionsDigital = [
  _Action('Cria\u00e7\u00e3o de', ['criar', 'criacao']),
  _Action('Desenvolvimento de', ['desenvolver', 'programar']),
  _Action('Implementa\u00e7\u00e3o de', ['implementar']),
  _Action('Otimiza\u00e7\u00e3o de', ['otimizar']),
  _Action('Manuten\u00e7\u00e3o de', ['manutencao', 'suporte']),
  _Action('Configura\u00e7\u00e3o de', ['configurar', 'setup']),
  _Action('Integra\u00e7\u00e3o de', ['integrar']),
  _Action('Repara\u00e7\u00e3o de', ['correcao', 'bugfix']),
];

const _actionsCriativo = [
  _Action('Cria\u00e7\u00e3o de', ['criacao']),
  _Action('Produ\u00e7\u00e3o de', ['producao']),
  _Action('Edi\u00e7\u00e3o de', ['edicao']),
  _Action('Sess\u00e3o de', ['sessao']),
  _Action('Ilustra\u00e7\u00e3o de', ['ilustracao']),
  _Action('Retrato de', ['retrato']),
];

const _actionsBeleza = [
  _Action('Corte de', ['corte']),
  _Action('Penteado de', ['penteado']),
  _Action('Colora\u00e7\u00e3o de', ['coloracao']),
  _Action('Tratamento de', ['tratamento']),
  _Action('Manicure de', ['manicure']),
  _Action('Pedicure de', ['pedicure']),
];

const _actionsEducacao = [
  _Action('Aulas de', ['aulas']),
  _Action('Explica\u00e7\u00f5es de', ['explicacoes']),
  _Action('Prepara\u00e7\u00e3o para', ['preparacao']),
  _Action('Treino de', ['treino']),
];

const _actionsBemEstar = [
  _Action('Sess\u00e3o de', ['sessao']),
  _Action('Massagem de', ['massagem']),
  _Action('Terapia de', ['terapia']),
  _Action('Tratamento de', ['tratamento']),
];

const _actionsPets = [
  _Action('Passeio de', ['passeio', 'dog walker']),
  _Action('Banho de', ['banho', 'higiene']),
  _Action('Tosa de', ['tosa', 'grooming']),
  _Action('Treino de', ['treino', 'adestramento']),
  _Action('Cuidados de', ['cuidados', 'pet sitter']),
  _Action('Alimenta\u00e7\u00e3o de', ['alimentacao']),
];

const _actionsEventos = [
  _Action('Organiza\u00e7\u00e3o de', ['organizacao']),
  _Action('Decora\u00e7\u00e3o de', ['decoracao']),
  _Action('Produ\u00e7\u00e3o de', ['producao']),
  _Action('Planeamento de', ['planeamento']),
  _Action('Catering para', ['catering']),
  _Action('Bolos para', ['bolo']),
];

final _groups = <_Group>[
  _Group(
    macro: 'Casa e Obras',
    sub: 'Reparos Domesticos',
    base: 'Servicos de reparacao',
    mode: 'IMEDIATO',
    iconKey: 'handyman',
    includeBase: true,
    baseId: _stableId('Casa e Obras', 'Reparos Domesticos', 'Servicos de reparacao'),
    actions: _actionsReparacao,
    objects: _expandObjects([
      'torneiras',
      'sanitas',
      'chuveiros',
      'banheiras',
      'tubagens',
      'esgotos',
      'ralos',
      'tomadas',
      'interruptores',
      'quadro eletrico',
      'iluminacao',
      'disjuntores',
      'portas',
      'janelas',
      'portoes',
      'grades',
      'corrimoes',
      'portas de vidro',
      'estores',
      'persianas',
      'ar condicionado',
      'esquentadores',
      'caldeiras',
      'aquecedores',
      'telhados',
      'calhas',
      'azulejos',
      'pavimentos',
      'gesso',
      'drywall',
      'cozinhas',
      'armarios',
      'moveis',
      'iluminacao de jardim',
      'videoporteiros',
      'campainhas',
      'sensores de movimento',
    ], ['residencial', 'comercial']),
    synonyms: ['faz tudo', 'manutencao', 'servicos gerais'],
    materials: ['ferramentas', 'chave inglesa', 'parafusos'],
    problems: ['fuga de agua', 'curto circuito', 'porta encravada'],
    extraKeywords: ['assistencia', 'manutencao residencial'],
  ),
  _Group(
    macro: 'Casa e Obras',
    sub: 'Construcao e Acabamentos',
    base: 'Construcao e acabamentos',
    mode: 'POR_PROPOSTA',
    iconKey: 'pedreiro',
    actions: _actionsConstrucao,
    objects: _expandObjects([
      'paredes',
      'muros',
      'colunas',
      'fundacoes',
      'chao',
      'escadas',
      'pilares',
      'churrasqueiras',
      'anexos',
      'casas de banho',
      'rebocos',
      'fachadas',
      'isolamentos',
      'pavimentos exteriores',
      'tetos falsos',
      'sancas',
      'divisorias',
      'cozinhas',
      'varandas',
      'impermeabilizacao',
      'pintura final',
    ], ['interior', 'exterior']),
  ),
  _Group(
    macro: 'Limpeza',
    sub: 'Limpeza e Higienizacao',
    base: 'Limpeza profissional',
    mode: 'AGENDADO',
    iconKey: 'limpeza_domestica',
    actions: _actionsLimpeza,
    objects: _expandObjects([
      'casas',
      'apartamentos',
      'cozinhas',
      'casas de banho',
      'quartos',
      'salas',
      'garagens',
      'varandas',
      'escritorios',
      'lojas',
      'vidros',
      'fachadas',
      'tapetes',
      'carpetes',
      'estofos',
      'colchoes',
      'cortinas',
      'pos-obra',
      'pos-evento',
      'armazens',
      'restaurantes',
      'condominios',
      'escadas comuns',
      'piscinas',
    ], ['residencial', 'comercial']),
    materials: ['detergente', 'desinfetante', 'aspirador'],
  ),
  _Group(
    macro: 'Mudancas e Logistica',
    sub: 'Mudancas e Entregas',
    base: 'Mudancas e entregas',
    mode: 'AGENDADO',
    iconKey: 'mudancas',
    actions: _actionsEntrega,
    objects: _expandObjects([
      'mudanca de casa',
      'mudanca de apartamento',
      'mudanca de escritorio',
      'transporte de moveis',
      'transporte de eletrodomesticos',
      'entrega de encomendas',
      'entrega de documentos',
      'recolha de mercadorias',
      'distribuicao local',
      'transporte de caixas',
      'mudanca local',
      'mudanca intermunicipal',
      'montagem no destino',
    ], ['local', 'intermunicipal']),
  ),
  _Group(
    macro: 'Auto e Mobilidade',
    sub: 'Mecanica e Detalhe Auto',
    base: 'Mecanica auto',
    mode: 'IMEDIATO',
    iconKey: 'mecanico',
    actions: _actionsAuto,
    objects: _expandObjects([
      'motor',
      'travoes',
      'suspensao',
      'embreagem',
      'direcao',
      'radiador',
      'escape',
      'correia',
      'amortecedores',
      'bateria',
      'alternador',
      'arranque',
      'farois',
      'sensores',
      'centralina',
      'pneus',
      'jantes',
      'alinhamento',
      'balanceamento',
      'lavagem exterior',
      'lavagem interior',
      'estofos auto',
      'polimento',
    ], const []),
  ),
  _Group(
    macro: 'Reparacoes Tecnicas',
    sub: 'Eletrodomesticos e Tecnologia',
    base: 'Reparacao tecnica',
    mode: 'AGENDADO',
    iconKey: 'reparacao_eletrodomesticos',
    actions: _actionsReparacao,
    objects: _expandObjects([
      'maquina de lavar',
      'frigorifico',
      'forno',
      'micro-ondas',
      'placa',
      'esquentador',
      'aspirador',
      'secador de roupa',
      'lava-louca',
      'telemovel',
      'tablet',
      'smartwatch',
      'computador',
      'portatil',
      'impressora',
      'router',
      'wifi',
      'servidor',
    ], const []),
  ),
  _Group(
    macro: 'Servicos Digitais',
    sub: 'Web e Apps',
    base: 'Desenvolvimento digital',
    mode: 'POR_PROPOSTA',
    iconKey: 'web_designer',
    actions: _actionsDigital,
    objects: _expandObjects([
      'website',
      'loja online',
      'landing page',
      'blog',
      'sistema web',
      'portal',
      'catalogo online',
      'aplicacao mobile',
      'app ios',
      'app android',
      'painel admin',
      'integracao api',
      'automatizacao',
      'seo',
      'analytics',
      'redes sociais',
      'anuncios google',
      'anuncios meta',
      'email marketing',
    ], const []),
  ),
  _Group(
    macro: 'Criativo',
    sub: 'Design, Foto e Video',
    base: 'Servicos criativos',
    mode: 'POR_PROPOSTA',
    iconKey: 'designer_grafico',
    actions: _actionsCriativo,
    objects: _expandObjects([
      'logotipo',
      'cartao de visita',
      'flyer',
      'cartaz',
      'branding',
      'apresentacao',
      'embalagens',
      'fotografia de eventos',
      'fotografia de produto',
      'retratos',
      'video para redes sociais',
      'edicao de video',
      'filmagem de eventos',
      'ilustracao',
      'caricatura',
      'retrato artistico',
      'arte digital',
    ], const []),
    synonyms: ['designer grafico', 'fotografo', 'videomaker', 'ilustrador'],
    materials: ['lapis', 'grafite', 'carvao', 'tablet grafico'],
    outputs: ['retrato', 'ilustracao', 'fotografia', 'video'],
  ),
  _Group(
    macro: 'Beleza e Estetica',
    sub: 'Cabelo e Unhas',
    base: 'Beleza e estetica',
    mode: 'AGENDADO',
    iconKey: 'cabeleireiro',
    actions: _actionsBeleza,
    objects: _expandObjects([
      'cabelo feminino',
      'cabelo masculino',
      'barba',
      'bigode',
      'penteados',
      'coloracao',
      'mechas',
      'unhas',
      'gel',
      'acrilico',
      'verniz',
      'sobrancelhas',
      'maquilhagem',
    ], ['domicilio']),
    synonyms: ['barbeiro', 'cabeleireiro', 'manicure'],
  ),
  const _Group(
    macro: 'Educacao',
    sub: 'Aulas e Explicacoes',
    base: 'Explicacoes e formacao',
    mode: 'AGENDADO',
    iconKey: 'explicador',
    actions: _actionsEducacao,
    objects: [
      'matematica',
      'portugues',
      'ingles',
      'fisica',
      'quimica',
      'biologia',
      'historia',
      'geografia',
      'programacao',
      'economia',
      'musica',
      'guitarra',
      'piano',
      'canto',
    ],
  ),
  _Group(
    macro: 'Saude e Bem-estar',
    sub: 'Bem-estar',
    base: 'Bem-estar e saude',
    mode: 'AGENDADO',
    iconKey: 'massagista',
    actions: _actionsBemEstar,
    objects: _expandObjects([
      'relaxamento',
      'desportiva',
      'drenagem linfatica',
      'massagem terapeutica',
      'reflexologia',
      'yoga',
      'pilates',
      'alongamentos',
      'treino funcional',
    ], ['domicilio']),
  ),
  _Group(
    macro: 'Animais',
    sub: 'Cuidados de Animais',
    base: 'Cuidados para animais',
    mode: 'AGENDADO',
    iconKey: 'pet',
    actions: _actionsPets,
    objects: _expandObjects([
      'caes',
      'gatos',
      'aves',
      'roedores',
      'aquarios',
      'passeio diario',
      'pet sitting',
      'banho e tosa',
    ], ['domicilio']),
  ),
  _Group(
    macro: 'Eventos',
    sub: 'Eventos e Catering',
    base: 'Eventos',
    mode: 'POR_PROPOSTA',
    iconKey: 'catering',
    actions: _actionsEventos,
    objects: _expandObjects([
      'casamentos',
      'aniversarios',
      'batizados',
      'eventos corporativos',
      'festas privadas',
      'catering',
      'bolos personalizados',
      'decoracao de festas',
      'som e luz',
      'dj',
    ], ['pequeno', 'grande']),
  ),
];

List<Map<String, dynamic>> _baseServicosFixos() {
  return [
    _fixed('canalizador', 'Canalizador', 'IMEDIATO', ['agua', 'fuga', 'torneira']),
    _fixed('eletricista', 'Eletricista', 'IMEDIATO', ['luz', 'tomada', 'quadro']),
    _fixed('pintor', 'Pintor', 'POR_PROPOSTA', ['pintura', 'paredes', 'tinta']),
    _fixed('pedreiro', 'Pedreiro', 'POR_PROPOSTA', ['obra', 'paredes', 'reboco']),
    _fixed('serralheiro', 'Serralheiro', 'IMEDIATO', ['portao', 'grade', 'ferro']),
    _fixed('carpinteiro', 'Carpinteiro', 'POR_PROPOSTA', ['madeira', 'moveis']),
    _fixed('montagem_moveis', 'Montagem de moveis', 'AGENDADO', ['montagem', 'armario']),
    _fixed('barbeiro', 'Barbeiro', 'AGENDADO', ['barba', 'corte', 'degrade']),
    _fixed('cabeleireiro', 'Cabeleireiro', 'AGENDADO', ['corte', 'escova', 'coloracao']),
    _fixed('babysitter', 'Babysitter', 'AGENDADO', ['ama', 'cuidador infantil']),
    _fixed('cuidador_idosos', 'Cuidador de idosos', 'AGENDADO', ['acompanhante', 'apoio domiciliario']),
    _fixed('dogwalker', 'Dog walker', 'IMEDIATO', ['passeio', 'caes']),
    _fixed('pet_sitter', 'Pet sitter', 'AGENDADO', ['cuidador de animais']),
    _fixed('confeitaria', 'Confeitaria', 'POR_PROPOSTA', ['bolo', 'cake', 'doces']),
    _fixed('cake_designer', 'Cake designer', 'POR_PROPOSTA', ['bolo personalizado', 'fondant']),
    _fixed('bolos_personalizados', 'Bolos personalizados', 'POR_PROPOSTA', ['bolo', 'personalizado']),
    _fixed('retratista_lapis', 'Retratista a lapis', 'POR_PROPOSTA', ['retrato', 'lapis', 'grafite']),
    _fixed('caricaturista', 'Caricaturista', 'POR_PROPOSTA', ['caricatura', 'retrato']),
    _fixed('ilustrador', 'Ilustrador', 'POR_PROPOSTA', ['ilustracao', 'arte']),
    _fixed('escultor_3d', 'Escultor 3D', 'POR_PROPOSTA', ['escultura', '3d']),
  ];
}

Map<String, dynamic> _fixed(
  String id,
  String name,
  String mode,
  List<String> keywords,
) {
  return {
    'id': id,
    'name': name,
    'mode': mode,
    'keywords': keywords,
    'iconKey': null,
    'isActive': true,
  };
}

List<String> _buildKeywordsForGroup(
  _Group group, {
  bool includeModeIntent = false,
}) {
  final set = <String>{
    group.base,
    group.sub,
    group.macro,
    ...group.synonyms.map((s) => 's:$s'),
    ...group.materials.map((m) => 'm:$m'),
    ...group.problems.map((p) => 'p:$p'),
    ...group.outputs.map((o) => 'o:$o'),
    ...group.extraKeywords,
  };

  if (includeModeIntent) {
    if (group.mode == 'IMEDIATO') {
      set.addAll(['i:urgente', 'i:24h', 'i:agora']);
    } else if (group.mode == 'AGENDADO') {
      set.addAll(['i:agenda', 'i:agendar']);
    } else if (group.mode == 'POR_PROPOSTA') {
      set.addAll(['i:orcamento', 'i:proposta']);
    }
  }

  return _normalizeKeywords(set);
}

List<String> _normalizeKeywords(Set<String> raw) {
  final list = raw
      .map((k) => k.trim())
      .where((k) => k.isNotEmpty)
      .toSet()
      .toList();
  list.sort();
  if (list.length > 60) {
    return list.sublist(0, 60);
  }
  return list;
}

List<String> _expandObjects(List<String> base, List<String> qualifiers) {
  if (qualifiers.isEmpty) return base;
  final out = <String>[];
  for (final obj in base) {
    out.add(obj);
    for (final q in qualifiers) {
      out.add('$obj $q');
    }
  }
  return out;
}

String _stableId(String macro, String sub, String name) {
  final seed = '${_slug(macro)}|${_slug(sub)}|${_slug(name)}';
  final hash = _fnv1a32(seed);
  final slug = _slug(name);
  final short = hash.toRadixString(36);
  final trimmed = slug.length > 42 ? slug.substring(0, 42) : slug;
  return 'svc_${trimmed}_$short';
}

String _slug(String input) {
  final lower = input.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_foldDiacritics(ch));
  }
  final cleaned = buffer.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
  return cleaned.replaceAll(RegExp(r'\\s+'), '_').trim();
}

int _fnv1a32(String input) {
  const int fnvPrime = 0x01000193;
  int hash = 0x811c9dc5;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * fnvPrime) & 0xffffffff;
  }
  return hash;
}

String _foldDiacritics(String ch) {
  switch (ch) {
    case '\\u00e0':
    case '\\u00e1':
    case '\\u00e2':
    case '\\u00e3':
    case '\\u00e4':
    case '\\u00e5':
      return 'a';
    case '\\u00e7':
      return 'c';
    case '\\u00e8':
    case '\\u00e9':
    case '\\u00ea':
    case '\\u00eb':
      return 'e';
    case '\\u00ec':
    case '\\u00ed':
    case '\\u00ee':
    case '\\u00ef':
      return 'i';
    case '\\u00f1':
      return 'n';
    case '\\u00f2':
    case '\\u00f3':
    case '\\u00f4':
    case '\\u00f5':
    case '\\u00f6':
      return 'o';
    case '\\u00f9':
    case '\\u00fa':
    case '\\u00fb':
    case '\\u00fc':
      return 'u';
    case '\\u00fd':
    case '\\u00ff':
      return 'y';
    default:
      return ch;
  }
}
