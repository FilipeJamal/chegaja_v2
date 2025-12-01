// lib/core/services/politica_reembolso.dart
import 'package:chegaja_v2/core/models/pedido.dart';

/// Tipo de reembolso possível num cancelamento
enum TipoReembolso {
  total,
  parcial,
  nenhum,
}

/// Resultado da política de reembolso:
/// - tipo: total / parcial / nenhum
/// - mensagens: para mostrar ao cliente
class ReembolsoInfo {
  final TipoReembolso tipo;
  final String mensagemCurta;
  final String mensagemDetalhada;

  const ReembolsoInfo({
    required this.tipo,
    required this.mensagemCurta,
    required this.mensagemDetalhada,
  });
}

/// Motor de regras de reembolso.
/// Aqui decides janelas de tempo diferentes por modo do pedido
/// e se já existe prestador atribuído ou não.
class PoliticaReembolso {
  // ---------- CONFIG GERAL DAS REGRAS (podes ajustar estes números) ----------

  // IMEDIATO (trabalhos “já”, urgentes)
  static const Duration _janelaTotalImediato = Duration(minutes: 10);
  static const Duration _janelaParcialImediato = Duration(minutes: 60);

  // AGENDADO (trabalhos marcados para uma data/hora)
  static const Duration _antecedenciaTotalAgendado = Duration(hours: 24);
  static const Duration _antecedenciaParcialAgendado = Duration(hours: 2);

  // POR_PROPOSTA / POR_ORCAMENTO (pedidos em que há orçamentos)
  static const Duration _janelaTotalProposta = Duration(hours: 1);
  static const Duration _janelaParcialProposta = Duration(hours: 3);

  /// Função principal:
  /// Decide tipo de reembolso e mensagens para um cancelamento feito pelo cliente.
  ///
  /// Atenção:
  /// - Esta função assume que quem está a cancelar é o CLIENTE.
  /// - Para cancelamentos feitos pelo prestador / sistema, a regra base deve ser
  ///   reembolso TOTAL do cliente (fora casos de abuso).
  static ReembolsoInfo calcularParaCancelamentoCliente(
    Pedido pedido,
    DateTime agora,
  ) {
    // 0) Estados finais: concluído / cancelado → sem reembolso automático.
    if (pedido.estado == 'concluido' || pedido.estado == 'cancelado') {
      return const ReembolsoInfo(
        tipo: TipoReembolso.nenhum,
        mensagemCurta: 'Sem reembolso',
        mensagemDetalhada:
            'Este serviço já foi concluído ou cancelado anteriormente; '
            'não há reembolso automático disponível. Se algo está errado, '
            'abre um pedido de suporte para analisarmos.',
      );
    }

    // 1) Ainda NÃO há prestador atribuído → reembolso TOTAL sempre.
    //
    // Isto cobre:
    // - Pedido novo ainda à procura de prestador,
    // - Pedido que tinha prestador mas voltou ao "pool"
    //   (ex.: prestador cancelou e ainda não há novo prestador).
    if (pedido.prestadorId == null) {
      return const ReembolsoInfo(
        tipo: TipoReembolso.total,
        mensagemCurta: 'Reembolso total',
        mensagemDetalhada:
            'Como ainda não há nenhum prestador atribuído ao teu pedido, '
            'o cancelamento agora garante reembolso total.',
      );
    }

    // 2) Já existe prestador atribuído.
    //    A partir daqui, a política depende do modo do pedido.
    switch (pedido.modo) {
      case 'AGENDADO':
        return _paraAgendado(pedido, agora);
      case 'IMEDIATO':
        return _paraImediato(pedido, agora);
      case 'POR_PROPOSTA':
        return _paraProposta(pedido, agora);
      default:
        // Se aparecer algum modo estranho, tratamos como IMEDIATO por defeito
        return _paraImediato(pedido, agora);
    }
  }

  // -------------------- REGRAS IMEDIATO --------------------
  //
  // Exemplo:
  // - até 10 minutos depois de criar → reembolso TOTAL
  // - entre 10 e 60 minutos → PARCIAL
  // - depois de 60 minutos → SEM reembolso
  static ReembolsoInfo _paraImediato(Pedido pedido, DateTime agora) {
    final diff = agora.difference(pedido.createdAt);

    if (diff <= _janelaTotalImediato) {
      return const ReembolsoInfo(
        tipo: TipoReembolso.total,
        mensagemCurta: 'Reembolso total',
        mensagemDetalhada:
            'Pedidos imediatos podem ser cancelados com reembolso total '
            'até 10 minutos após o pedido, enquanto o prestador ainda se '
            'está a organizar para o serviço.',
      );
    } else if (diff <= _janelaParcialImediato) {
      return const ReembolsoInfo(
        tipo: TipoReembolso.parcial,
        mensagemCurta: 'Reembolso parcial',
        mensagemDetalhada:
            'Pedidos imediatos cancelados entre 10 e 60 minutos após o pedido '
            'têm direito a reembolso parcial, para compensar parte do tempo '
            'e deslocação do prestador.',
      );
    } else {
      return const ReembolsoInfo(
        tipo: TipoReembolso.nenhum,
        mensagemCurta: 'Sem reembolso',
        mensagemDetalhada:
            'Pedidos imediatos cancelados mais de 60 minutos após o pedido '
            'não têm direito a reembolso automático. Se houve algum problema '
            'grave, fala com o suporte.',
      );
    }
  }

  // -------------------- REGRAS AGENDADO --------------------
  //
  // Exemplo:
  // - com 24h ou mais de antecedência → TOTAL
  // - entre 2h e 24h antes → PARCIAL
  // - menos de 2h antes → SEM reembolso
  static ReembolsoInfo _paraAgendado(Pedido pedido, DateTime agora) {
    final data = pedido.agendadoPara;
    if (data == null) {
      // Se por algum motivo não tiver data, tratamos como IMEDIATO.
      return _paraImediato(pedido, agora);
    }

    final diff = data.difference(agora); // quanto tempo falta até ao serviço

    if (diff >= _antecedenciaTotalAgendado) {
      return const ReembolsoInfo(
        tipo: TipoReembolso.total,
        mensagemCurta: 'Reembolso total',
        mensagemDetalhada:
            'Serviços agendados podem ser cancelados com reembolso total '
            'até 24 horas antes da hora marcada.',
      );
    } else if (diff >= _antecedenciaParcialAgendado) {
      return const ReembolsoInfo(
        tipo: TipoReembolso.parcial,
        mensagemCurta: 'Reembolso parcial',
        mensagemDetalhada:
            'Serviços agendados cancelados entre 2 e 24 horas antes da hora '
            'marcada têm direito a reembolso parcial, pois o prestador já '
            'tinha reservado esse horário na agenda.',
      );
    } else {
      return const ReembolsoInfo(
        tipo: TipoReembolso.nenhum,
        mensagemCurta: 'Sem reembolso',
        mensagemDetalhada:
            'Serviços agendados cancelados a menos de 2 horas da hora marcada '
            'não têm direito a reembolso automático. Se houve algum imprevisto '
            'sério, fala com o suporte.',
      );
    }
  }

  // -------------------- REGRAS POR PROPOSTA / ORÇAMENTO --------------------
  //
  // Exemplo:
  // - enquanto ainda não aceitaste nenhum prestador → TOTAL
  // - até 1h depois de aceitares → TOTAL
  // - entre 1h e 3h depois de aceitares → PARCIAL
  // - depois de 3h → SEM reembolso
  //
  // (Aqui usamos createdAt como aproximação de "aceitoEm";
  // se criares o campo aceitoEm no Pedido, é só trocar.)
  static ReembolsoInfo _paraProposta(Pedido pedido, DateTime agora) {
    // Ainda sem prestador associado ou proposta pendente → sempre reembolso total
    if (pedido.prestadorId == null ||
        pedido.statusProposta == null ||
        pedido.statusProposta == 'pendente_cliente') {
      return const ReembolsoInfo(
        tipo: TipoReembolso.total,
        mensagemCurta: 'Reembolso total',
        mensagemDetalhada:
            'Enquanto ainda estás a receber propostas, o cancelamento é sempre '
            'com reembolso total.',
      );
    }

    // Já há prestador aceite; usamos janelas próprias
    final diff = agora.difference(pedido.createdAt);

    if (diff <= _janelaTotalProposta) {
      return const ReembolsoInfo(
        tipo: TipoReembolso.total,
        mensagemCurta: 'Reembolso total',
        mensagemDetalhada:
            'Até 1 hora depois de aceitares uma proposta, o cancelamento '
            'mantém reembolso total.',
      );
    } else if (diff <= _janelaParcialProposta) {
      return const ReembolsoInfo(
        tipo: TipoReembolso.parcial,
        mensagemCurta: 'Reembolso parcial',
        mensagemDetalhada:
            'Cancelamentos até 3 horas depois de aceitares uma proposta têm '
            'direito a reembolso parcial.',
      );
    } else {
      return const ReembolsoInfo(
        tipo: TipoReembolso.nenhum,
        mensagemCurta: 'Sem reembolso',
        mensagemDetalhada:
            'Cancelamentos muito depois de aceitares uma proposta não têm '
            'direito a reembolso automático.',
      );
    }
  }

  /// Converte o enum para string usada no Firestore
  /// ('total' | 'parcial' | 'nenhum')
  static String tipoToString(TipoReembolso tipo) {
    switch (tipo) {
      case TipoReembolso.total:
        return 'total';
      case TipoReembolso.parcial:
        return 'parcial';
      case TipoReembolso.nenhum:
        return 'nenhum';
    }
  }
}
