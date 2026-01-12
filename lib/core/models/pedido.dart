// lib/core/models/pedido.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo principal de Pedido do ChegaJá v2.
///
/// Suporta:
/// - modos: IMEDIATO / AGENDADO / POR_PROPOSTA
/// - tipos de preço: a_combinar / fixo / por_orcamento
/// - proposta de valor (mínimo/máximo) antes do cliente escolher o prestador
/// - valor final e confirmação de valor (pós-serviço)
/// - métricas virtuais de comissão (C3): commissionPlatform, earningsProvider, earningsTotal
/// - informação de cancelamento: canceladoPor / motivoCancelamento / tipoReembolso
/// - compatibilidade com campos ANTIGOS: estado, categoria, agendadoPara, preco, concluidoEm
/// - localização: latitude / longitude / enderecoTexto
class Pedido {
  final String id;

  // IDs principais
  final String clienteId;
  final String? prestadorId;

  // Serviço / categoria
  final String servicoId;
  final String? servicoNome; // opcional, só para mostrar na UI

  // Dados básicos
  final String titulo;
  final String descricao;

  /// modo: "IMEDIATO" | "AGENDADO" | "POR_PROPOSTA"
  final String modo;

  /// status principal do pedido:
  /// "criado" | "aceito" | "em_andamento" |
  /// "aguarda_resposta_cliente" | "concluido" | "cancelado"
  final String status;

  /// tipoPreco: "a_combinar" | "fixo" | "por_orcamento"
  final String tipoPreco;

  /// tipoPagamento: "dinheiro" | "online_antes" | "online_depois"
  /// (por enquanto usamos "dinheiro" como padrão)
  final String tipoPagamento;

  // ------------- Proposta de faixa de preço (pré-serviço) -------------

  /// Valor mínimo que o prestador diz que pode cobrar (estimativa).
  /// Ex.: 20.0 → 20€
  final double? valorMinEstimadoPrestador;

  /// Valor máximo que o prestador diz que pode cobrar (estimativa).
  /// Ex.: 35.0 → 35€
  final double? valorMaxEstimadoPrestador;

  /// Mensagem opcional do prestador junto com a proposta (ex.: "Inclui deslocação").
  final String? mensagemPropostaPrestador;

  /// Estado da proposta de valor:
  /// "nenhuma"            → ainda não há proposta
  /// "pendente_cliente"   → proposta enviada, cliente ainda não respondeu
  /// "aceita_cliente"     → cliente aceitou este prestador/proposta
  /// "rejeitada_cliente"  → cliente rejeitou esta proposta
  final String statusProposta;

  // ------------- Valor final + confirmação (pós-serviço) -------------

  /// Valor final que o prestador lança ao terminar o serviço
  /// (pode ou não ser dentro da faixa estimada).
  final double? precoPropostoPrestador;

  /// Valor final aprovado pelo cliente.
  final double? precoFinal;

  /// Estado da confirmação do valor FINAL pelo cliente:
  /// "nenhum"             → ainda não existe valor final proposto
  /// "pendente_cliente"   → prestador já propôs valor final
  /// "confirmado_cliente" → cliente aceitou o valor final
  /// "rejeitado_cliente"  → cliente rejeitou o valor final
  final String statusConfirmacaoValor;

  // ------------- C3 – Métricas de comissão (virtuais) -------------

  /// Quanto a PLATAFORMA teria ganho neste pedido (ex.: 15% do valor final).
  final double? commissionPlatform;

  /// Quanto o PRESTADOR teria ficado, depois de descontar a comissão simulada.
  final double? earningsProvider;

  /// Total cobrado ao cliente (espelho de precoFinal, para relatórios).
  final double? earningsTotal;

  // ------------- Localização -------------

  /// Latitude aproximada do local do serviço.
  final double? latitude;

  /// Longitude aproximada do local do serviço.
  final double? longitude;

  /// Morada textual (rua, nº, cidade, etc.).
  final String? enderecoTexto;

  // ------------- Informação de cancelamento -------------

  /// Quem cancelou o pedido:
  /// - 'cliente'
  /// - 'prestador'
  /// - null (ainda não foi cancelado)
  final String? canceladoPor;

  /// Motivo textual do cancelamento, se existir.
  final String? motivoCancelamento;

  /// Tipo de reembolso aplicado: 'total' | 'parcial' | 'nenhum' | null.
  final String? tipoReembolso;

  // ------------- No-show -------------

  final String? noShowReportedBy;
  final String? noShowReason;
  final DateTime? noShowAt;

  // ---------------------- Datas ----------------------

  /// Data/hora marcada para pedidos AGENDADOS (pode ser null noutros modos).
  final DateTime? dataAgendada;

  /// Datas de criação/atualização
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Pedido({
    required this.id,
    required this.clienteId,
    required this.prestadorId,
    required this.servicoId,
    this.servicoNome,
    required this.titulo,
    required this.descricao,
    required this.modo,
    required this.status,
    required this.tipoPreco,
    required this.tipoPagamento,
    this.valorMinEstimadoPrestador,
    this.valorMaxEstimadoPrestador,
    this.mensagemPropostaPrestador,
    required this.statusProposta,
    this.precoPropostoPrestador,
    this.precoFinal,
    required this.statusConfirmacaoValor,
    this.commissionPlatform,
    this.earningsProvider,
    this.earningsTotal,
    this.latitude,
    this.longitude,
    this.enderecoTexto,
    this.canceladoPor,
    this.motivoCancelamento,
    this.tipoReembolso,
    this.noShowReportedBy,
    this.noShowReason,
    this.noShowAt,
    this.dataAgendada,
    required this.createdAt,
    this.updatedAt,
  });

  /// Construtor vazio de conveniência (se precisares em algum sítio).
  factory Pedido.vazio() {
    final now = DateTime.now();
    return Pedido(
      id: '',
      clienteId: '',
      prestadorId: null,
      servicoId: '',
      servicoNome: null,
      titulo: '',
      descricao: '',
      modo: 'IMEDIATO',
      status: 'criado',
      tipoPreco: 'a_combinar',
      tipoPagamento: 'dinheiro',
      valorMinEstimadoPrestador: null,
      valorMaxEstimadoPrestador: null,
      mensagemPropostaPrestador: null,
      statusProposta: 'nenhuma',
      precoPropostoPrestador: null,
      precoFinal: null,
      statusConfirmacaoValor: 'nenhum',
      commissionPlatform: null,
      earningsProvider: null,
      earningsTotal: null,
      latitude: null,
      longitude: null,
      enderecoTexto: null,
      canceladoPor: null,
      motivoCancelamento: null,
      tipoReembolso: null,
      noShowReportedBy: null,
      noShowReason: null,
      noShowAt: null,
      dataAgendada: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ---------- Helpers internos ----------

  static DateTime? _tsToDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _stringOrEmpty(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    return text == 'null' ? '' : text;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }

  // ---------- Lê do Firestore: DocumentSnapshot (SUPORTA CAMPOS ANTIGOS) ----------

  factory Pedido.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawClienteId = data['clienteId'] ?? data['clientId'];

    return Pedido(
      id: doc.id,
      clienteId: _stringOrEmpty(rawClienteId),
      prestadorId: data['prestadorId'] as String?,
      servicoId: data['servicoId'] as String? ?? '',
      // nome do serviço:
      // 1) servicoNome (novo)
      // 2) categoria (antigo)
      // 3) servicoId (fallback para não ficar "Categoria não definida")
      servicoNome:
          (data['servicoNome'] ?? data['categoria'] ?? data['servicoId'])
              as String?,
      titulo: data['titulo'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      modo: data['modo'] as String? ?? 'IMEDIATO',
      // estado/status: pode vir em 'status' (novo) ou 'estado' (antigo)
      status: (data['status'] ?? data['estado']) as String? ?? 'criado',
      tipoPreco: data['tipoPreco'] as String? ?? 'a_combinar',
      tipoPagamento: data['tipoPagamento'] as String? ?? 'dinheiro',

      // Proposta de faixa de preço
      valorMinEstimadoPrestador:
          _toDouble(data['valorMinEstimadoPrestador']),
      valorMaxEstimadoPrestador:
          _toDouble(data['valorMaxEstimadoPrestador']),
      mensagemPropostaPrestador:
          data['mensagemPropostaPrestador'] as String?,

      statusProposta: data['statusProposta'] as String? ?? 'nenhuma',

      // Valor final e confirmação (pode ter 'precoFinal' ou só 'preco')
      precoPropostoPrestador: _toDouble(data['precoPropostoPrestador']),
      precoFinal: _toDouble(data['precoFinal'] ?? data['preco']),
      statusConfirmacaoValor:
          data['statusConfirmacaoValor'] as String? ?? 'nenhum',

      // C3 – métricas virtuais
      commissionPlatform: _toDouble(data['commissionPlatform']),
      earningsProvider: _toDouble(data['earningsProvider']),
      earningsTotal: _toDouble(data['earningsTotal']),

      // Localização
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      enderecoTexto: data['enderecoTexto'] as String?,

      // Cancelamento
      canceladoPor: data['canceladoPor'] as String?,
      motivoCancelamento: data['motivoCancelamento'] as String?,
      tipoReembolso: data['tipoReembolso'] as String?,
      noShowReportedBy: data['noShowReportedBy'] as String?,
      noShowReason: data['noShowReason'] as String?,
      noShowAt: _tsToDate(data['noShowAt']),

      // Datas: novo/antigo
      dataAgendada: _tsToDate(data['dataAgendada'] ?? data['agendadoPara']),
      createdAt:
          _tsToDate(data['createdAt'] ?? data['criadoEm']) ?? DateTime.now(),
      updatedAt: _tsToDate(data['updatedAt'] ?? data['concluidoEm']),
    );
  }

  // ---------- fromMap para compatibilidade com pedido_repo ----------

  /// Versão sem DocumentSnapshot, usada por código antigo:
  /// Pedido.fromMap(doc.id, doc.data())
  factory Pedido.fromMap(String id, Map<String, dynamic> data) {
    final rawClienteId = data['clienteId'] ?? data['clientId'];
    return Pedido(
      id: id,
      clienteId: _stringOrEmpty(rawClienteId),
      prestadorId: data['prestadorId'] as String?,
      servicoId: data['servicoId'] as String? ?? '',
      servicoNome:
          (data['servicoNome'] ?? data['categoria'] ?? data['servicoId'])
              as String?,
      titulo: data['titulo'] as String? ?? '',
      descricao: data['descricao'] as String? ?? '',
      modo: data['modo'] as String? ?? 'IMEDIATO',
      status: (data['status'] ?? data['estado']) as String? ?? 'criado',
      tipoPreco: data['tipoPreco'] as String? ?? 'a_combinar',
      tipoPagamento: data['tipoPagamento'] as String? ?? 'dinheiro',

      // Proposta de faixa de preço
      valorMinEstimadoPrestador:
          _toDouble(data['valorMinEstimadoPrestador']),
      valorMaxEstimadoPrestador:
          _toDouble(data['valorMaxEstimadoPrestador']),
      mensagemPropostaPrestador:
          data['mensagemPropostaPrestador'] as String?,

      statusProposta: data['statusProposta'] as String? ?? 'nenhuma',

      // Valor final e confirmação
      precoPropostoPrestador: _toDouble(data['precoPropostoPrestador']),
      precoFinal: _toDouble(data['precoFinal'] ?? data['preco']),
      statusConfirmacaoValor:
          data['statusConfirmacaoValor'] as String? ?? 'nenhum',

      // C3 – métricas virtuais
      commissionPlatform: _toDouble(data['commissionPlatform']),
      earningsProvider: _toDouble(data['earningsProvider']),
      earningsTotal: _toDouble(data['earningsTotal']),

      // Localização
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),
      enderecoTexto: data['enderecoTexto'] as String?,

      // Cancelamento
      canceladoPor: data['canceladoPor'] as String?,
      motivoCancelamento: data['motivoCancelamento'] as String?,
      tipoReembolso: data['tipoReembolso'] as String?,
      noShowReportedBy: data['noShowReportedBy'] as String?,
      noShowReason: data['noShowReason'] as String?,
      noShowAt: _tsToDate(data['noShowAt']),

      dataAgendada: _tsToDate(data['dataAgendada'] ?? data['agendadoPara']),
      createdAt:
          _tsToDate(data['createdAt'] ?? data['criadoEm']) ?? DateTime.now(),
      updatedAt: _tsToDate(data['updatedAt'] ?? data['concluidoEm']),
    );
  }

  // ---------- Para gravar no Firestore (ESCREVE NOVO + CAMPOS ANTIGOS) ----------

  Map<String, dynamic> toMap() {
    final precoValor = preco;
    return {
      'clienteId': clienteId,
      'prestadorId': prestadorId,
      'servicoId': servicoId,
      'servicoNome': servicoNome,
      'categoria': servicoNome, // compatibilidade antiga
      'titulo': titulo,
      'descricao': descricao,
      'modo': modo,

      'status': status,
      'estado': status, // compatibilidade antiga

      'tipoPreco': tipoPreco,
      'tipoPagamento': tipoPagamento,

      // Proposta de faixa de preço
      'valorMinEstimadoPrestador': valorMinEstimadoPrestador,
      'valorMaxEstimadoPrestador': valorMaxEstimadoPrestador,
      'mensagemPropostaPrestador': mensagemPropostaPrestador,
      'statusProposta': statusProposta,

      // Valor final e confirmação
      'precoPropostoPrestador': precoPropostoPrestador,
      'precoFinal': precoFinal,
      'statusConfirmacaoValor': statusConfirmacaoValor,

      // C3 – métricas virtuais
      'commissionPlatform': commissionPlatform,
      'earningsProvider': earningsProvider,
      'earningsTotal': earningsTotal,

      // Localização
      'latitude': latitude,
      'longitude': longitude,
      'enderecoTexto': enderecoTexto,

      // Cancelamento
      'canceladoPor': canceladoPor,
      'motivoCancelamento': motivoCancelamento,
      'tipoReembolso': tipoReembolso,
      'noShowReportedBy': noShowReportedBy,
      'noShowReason': noShowReason,
      'noShowAt': noShowAt != null ? Timestamp.fromDate(noShowAt!) : null,

      // Campo de preco “geral” para UIs antigas
      'preco': precoValor,

      // Datas novas + antigas
      'dataAgendada':
          dataAgendada != null ? Timestamp.fromDate(dataAgendada!) : null,
      'agendadoPara':
          dataAgendada != null ? Timestamp.fromDate(dataAgendada!) : null,

      'createdAt': Timestamp.fromDate(createdAt),
      'criadoEm': Timestamp.fromDate(createdAt),

      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'concluidoEm':
          updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // ---------- copyWith ----------

  Pedido copyWith({
    String? id,
    String? clienteId,
    String? prestadorId,
    String? servicoId,
    String? servicoNome,
    String? titulo,
    String? descricao,
    String? modo,
    String? status,
    String? tipoPreco,
    String? tipoPagamento,
    double? valorMinEstimadoPrestador,
    double? valorMaxEstimadoPrestador,
    String? mensagemPropostaPrestador,
    String? statusProposta,
    double? precoPropostoPrestador,
    double? precoFinal,
    String? statusConfirmacaoValor,
    double? commissionPlatform,
    double? earningsProvider,
    double? earningsTotal,
    double? latitude,
    double? longitude,
    String? enderecoTexto,
    String? canceladoPor,
    String? motivoCancelamento,
    String? tipoReembolso,
    String? noShowReportedBy,
    String? noShowReason,
    DateTime? noShowAt,
    DateTime? dataAgendada,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pedido(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      prestadorId: prestadorId ?? this.prestadorId,
      servicoId: servicoId ?? this.servicoId,
      servicoNome: servicoNome ?? this.servicoNome,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      modo: modo ?? this.modo,
      status: status ?? this.status,
      tipoPreco: tipoPreco ?? this.tipoPreco,
      tipoPagamento: tipoPagamento ?? this.tipoPagamento,
      valorMinEstimadoPrestador:
          valorMinEstimadoPrestador ?? this.valorMinEstimadoPrestador,
      valorMaxEstimadoPrestador:
          valorMaxEstimadoPrestador ?? this.valorMaxEstimadoPrestador,
      mensagemPropostaPrestador:
          mensagemPropostaPrestador ?? this.mensagemPropostaPrestador,
      statusProposta: statusProposta ?? this.statusProposta,
      precoPropostoPrestador:
          precoPropostoPrestador ?? this.precoPropostoPrestador,
      precoFinal: precoFinal ?? this.precoFinal,
      statusConfirmacaoValor:
          statusConfirmacaoValor ?? this.statusConfirmacaoValor,
      commissionPlatform:
          commissionPlatform ?? this.commissionPlatform,
      earningsProvider: earningsProvider ?? this.earningsProvider,
      earningsTotal: earningsTotal ?? this.earningsTotal,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      enderecoTexto: enderecoTexto ?? this.enderecoTexto,
      canceladoPor: canceladoPor ?? this.canceladoPor,
      motivoCancelamento: motivoCancelamento ?? this.motivoCancelamento,
      tipoReembolso: tipoReembolso ?? this.tipoReembolso,
      noShowReportedBy: noShowReportedBy ?? this.noShowReportedBy,
      noShowReason: noShowReason ?? this.noShowReason,
      noShowAt: noShowAt ?? this.noShowAt,
      dataAgendada: dataAgendada ?? this.dataAgendada,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------- GETTERS DE COMPATIBILIDADE (para não rebentar o resto do app) ----------

  /// Antes chamava-se 'estado' no modelo antigo → agora aponta para 'status'.
  String get estado => status;

  /// Antes havia 'categoria' → usamos o nome do serviço.
  String? get categoria => servicoNome;

  /// Antes havia 'agendadoPara' → usamos dataAgendada.
  DateTime? get agendadoPara => dataAgendada;

  /// Antes havia 'preco' → aqui escolhemos um valor razoável para mostrar:
  /// 1) precoFinal, 2) precoPropostoPrestador, 3) valorMaxEstimado, 4) valorMinEstimado.
  double? get preco =>
      precoFinal ??
      precoPropostoPrestador ??
      valorMaxEstimadoPrestador ??
      valorMinEstimadoPrestador;

  /// Antes havia 'concluidoEm' → usamos updatedAt como aproximação.
  DateTime? get concluidoEm => updatedAt;

  // ---------- Camada de comissão “virtual” ----------

  /// Taxa padrão de comissão para cálculos automáticos (ex.: 15%).
  static const double kDefaultCommissionRate = 0.15;

  /// Valor base usado para cálculo de comissão (igual ao `preco` acima).
  double? get _valorBaseComissao => preco;

  /// Comissão da plataforma a considerar (se não houver no doc, calcula pela taxa padrão).
  double? get commissionPlatformEfetiva =>
      commissionPlatform ??
      (_valorBaseComissao != null
          ? _valorBaseComissao! * kDefaultCommissionRate
          : null);

  /// Ganho líquido do prestador (se não houver no doc, calcula pela taxa padrão).
  double? get earningsProviderEfetivo =>
      earningsProvider ??
      (_valorBaseComissao != null
          ? _valorBaseComissao! * (1 - kDefaultCommissionRate)
          : null);

  /// Total cobrado ao cliente (se não houver no doc, usa o preço base).
  double? get earningsTotalEfetivo =>
      earningsTotal ?? _valorBaseComissao;
}
