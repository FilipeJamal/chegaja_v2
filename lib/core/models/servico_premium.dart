// lib/core/models/servico_premium.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo PREMIUM de Serviço com hierarquia completa
///
/// Estrutura:
/// MACRO (12) → CATEGORIA (48) → ESPECIALIDADE (200+) → SERVIÇO (2000+)
class ServicoPremium {
  /// ID único do serviço (ex: SRV-0001)
  final String id;

  /// Nome do serviço (ex: "Consulta de Psicologia Clínica")
  final String nome;

  /// Slug URL-friendly (ex: "consulta-psicologia-clinica")
  final String slug;

  // ============ HIERARQUIA ============

  /// Macro-categoria (ex: "Saúde e Bem-Estar")
  final String macro;

  /// Categoria (ex: "Saúde Mental")
  final String categoria;

  /// Especialidade (ex: "Psicologia Clínica") - pode ser null
  final String? especialidade;

  // ============ OPERACIONAL ============

  /// Modo: "IMEDIATO", "AGENDADO", "POR_PROPOSTA"
  final String mode;

  /// Tipo de precificação
  final String tipoPrecificacao; // 'fixo', 'por_hora', 'a_combinar', 'por_orcamento'

  /// Preço médio mínimo (€)
  final double? precoMedioMin;

  /// Preço médio máximo (€)
  final double? precoMedioMax;

  /// Duração média em minutos
  final int? duracaoMediaMinutos;

  // ============ VERIFICAÇÁO PROFISSIONAL ============

  /// Nível de verificação requerido
  final NivelVerificacao nivelVerificacao;

  /// Credenciais obrigatórias
  final List<String> credenciaisObrigatorias;

  /// Entidade reguladora (ex: "Ordem dos Advogados")
  final String? entidadeReguladora;

  /// Link da ordem profissional
  final String? linkOrdem;

  /// Requer seguro de responsabilidade civil
  final bool requerSeguro;

  /// Requer portfólio obrigatório
  final bool requerPortfolio;

  // ============ PESQUISA E SEO ============

  /// Keywords para busca (com acentos)
  final List<String> keywords;

  /// Keywords normalizadas (sem acentos, lowercase)
  final List<String> keywordsNormalizadas;

  /// Sinônimos do serviço
  final List<String> sinonimos;

  /// Tags adicionais
  final List<String> tags;

  /// Texto pesquisável (concatenação de todos os campos de texto)
  final String? searchableText;

  // ============ METADADOS ============

  /// Descrição do serviço
  final String? descricao;

  /// Exemplos de pedidos
  final List<String> exemplosPedidos;

  /// Chave do ícone
  final String? iconKey;

  /// Cor em hex (ex: "#FF6B9D")
  final String? cor;

  /// URL da imagem
  final String? imagemUrl;

  // ============ POPULARIDADE ============

  /// Total de pedidos realizados
  final int totalPedidos;

  /// Total de prestadores que oferecem este serviço
  final int totalPrestadores;

  /// Avaliação média (0-5)
  final double? avaliacaoMedia;

  /// É um serviço popular?
  final bool isPopular;

  /// É um serviço em tendência?
  final bool isTendencia;

  // ============ STATUS ============

  /// Serviço está ativo?
  final bool isActive;

  /// Data de criação
  final DateTime? createdAt;

  /// Data de última atualização
  final DateTime? updatedAt;

  const ServicoPremium({
    required this.id,
    required this.nome,
    required this.slug,
    required this.macro,
    required this.categoria,
    this.especialidade,
    required this.mode,
    this.tipoPrecificacao = 'a_combinar',
    this.precoMedioMin,
    this.precoMedioMax,
    this.duracaoMediaMinutos,
    this.nivelVerificacao = NivelVerificacao.nenhum,
    this.credenciaisObrigatorias = const [],
    this.entidadeReguladora,
    this.linkOrdem,
    this.requerSeguro = false,
    this.requerPortfolio = false,
    required this.keywords,
    required this.keywordsNormalizadas,
    this.sinonimos = const [],
    this.tags = const [],
    this.searchableText,
    this.descricao,
    this.exemplosPedidos = const [],
    this.iconKey,
    this.cor,
    this.imagemUrl,
    this.totalPedidos = 0,
    this.totalPrestadores = 0,
    this.avaliacaoMedia,
    this.isPopular = false,
    this.isTendencia = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Construtor a partir de DocumentSnapshot
  factory ServicoPremium.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ServicoPremium.fromMap(data, doc.id);
  }

  /// Construtor a partir de Map
  factory ServicoPremium.fromMap(Map<String, dynamic> map, String id) {
    return ServicoPremium(
      id: id,
      nome: map['nome']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      macro: map['macro']?.toString() ?? '',
      categoria: map['categoria']?.toString() ?? '',
      especialidade: map['especialidade']?.toString(),
      mode: map['mode']?.toString() ?? 'IMEDIATO',
      tipoPrecificacao: map['tipoPrecificacao']?.toString() ?? 'a_combinar',
      precoMedioMin: _toDouble(map['precoMedioMin']),
      precoMedioMax: _toDouble(map['precoMedioMax']),
      duracaoMediaMinutos: _toInt(map['duracaoMediaMinutos']),
      nivelVerificacao: NivelVerificacao.fromString(
        map['nivelVerificacao']?.toString() ?? 'nenhum',
      ),
      credenciaisObrigatorias: _toListString(map['credenciaisObrigatorias']),
      entidadeReguladora: map['entidadeReguladora']?.toString(),
      linkOrdem: map['linkOrdem']?.toString(),
      requerSeguro: map['requerSeguro'] == true,
      requerPortfolio: map['requerPortfolio'] == true,
      keywords: _toListString(map['keywords']),
      keywordsNormalizadas: _toListString(map['keywordsNormalizadas']),
      sinonimos: _toListString(map['sinonimos']),
      tags: _toListString(map['tags']),
      searchableText: map['searchableText']?.toString(),
      descricao: map['descricao']?.toString(),
      exemplosPedidos: _toListString(map['exemplosPedidos']),
      iconKey: map['iconKey']?.toString(),
      cor: map['cor']?.toString(),
      imagemUrl: map['imagemUrl']?.toString(),
      totalPedidos: _toInt(map['totalPedidos']) ?? 0,
      totalPrestadores: _toInt(map['totalPrestadores']) ?? 0,
      avaliacaoMedia: _toDouble(map['avaliacaoMedia']),
      isPopular: map['isPopular'] == true,
      isTendencia: map['isTendencia'] == true,
      isActive: map['isActive'] ?? true,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  /// Converte para Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'slug': slug,
      'macro': macro,
      'categoria': categoria,
      if (especialidade != null) 'especialidade': especialidade,
      'mode': mode,
      'tipoPrecificacao': tipoPrecificacao,
      if (precoMedioMin != null) 'precoMedioMin': precoMedioMin,
      if (precoMedioMax != null) 'precoMedioMax': precoMedioMax,
      if (duracaoMediaMinutos != null) 'duracaoMediaMinutos': duracaoMediaMinutos,
      'nivelVerificacao': nivelVerificacao.name,
      'credenciaisObrigatorias': credenciaisObrigatorias,
      if (entidadeReguladora != null) 'entidadeReguladora': entidadeReguladora,
      if (linkOrdem != null) 'linkOrdem': linkOrdem,
      'requerSeguro': requerSeguro,
      'requerPortfolio': requerPortfolio,
      'keywords': keywords,
      'keywordsNormalizadas': keywordsNormalizadas,
      'sinonimos': sinonimos,
      'tags': tags,
      if (searchableText != null) 'searchableText': searchableText,
      if (descricao != null) 'descricao': descricao,
      'exemplosPedidos': exemplosPedidos,
      if (iconKey != null) 'iconKey': iconKey,
      if (cor != null) 'cor': cor,
      if (imagemUrl != null) 'imagemUrl': imagemUrl,
      'totalPedidos': totalPedidos,
      'totalPrestadores': totalPrestadores,
      if (avaliacaoMedia != null) 'avaliacaoMedia': avaliacaoMedia,
      'isPopular': isPopular,
      'isTendencia': isTendencia,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  // ============ HELPERS ============

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed;
  }

  static List<String> _toListString(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

/// Níveis de verificação profissional
enum NivelVerificacao {
  /// Nenhuma verificação necessária (ex: limpeza, entregas)
  nenhum,

  /// Verificação básica (identidade + telefone)
  basico,

  /// Verificação profissional (certificados técnicos)
  profissional,

  /// Verificação avançada (cédula profissional + seguro RC)
  avancado;

  static NivelVerificacao fromString(String value) {
    switch (value.toLowerCase()) {
      case 'basico':
      case 'básico':
        return NivelVerificacao.basico;
      case 'profissional':
        return NivelVerificacao.profissional;
      case 'avancado':
      case 'avançado':
        return NivelVerificacao.avancado;
      default:
        return NivelVerificacao.nenhum;
    }
  }

  String get displayName {
    switch (this) {
      case NivelVerificacao.nenhum:
        return 'Sem verificação';
      case NivelVerificacao.basico:
        return 'Verificação básica';
      case NivelVerificacao.profissional:
        return 'Profissional certificado';
      case NivelVerificacao.avancado:
        return 'Profissional regulamentado';
    }
  }

  String get emoji {
    switch (this) {
      case NivelVerificacao.nenhum:
        return '';
      case NivelVerificacao.basico:
        return '✓';
      case NivelVerificacao.profissional:
        return '⭐';
      case NivelVerificacao.avancado:
        return '🏆';
    }
  }
}
