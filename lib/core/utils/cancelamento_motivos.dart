// lib/core/utils/cancelamento_motivos.dart

class CancelamentoMotivoOption {
  final String id;
  final String label;
  final bool requiresDetail;

  const CancelamentoMotivoOption({
    required this.id,
    required this.label,
    this.requiresDetail = false,
  });
}

class CancelamentoMotivos {
  CancelamentoMotivos._();

  static List<CancelamentoMotivoOption> forCliente({
    required bool emServico,
  }) {
    if (!emServico) {
      return const [
        CancelamentoMotivoOption(
          id: 'nao_informado',
          label: 'Nao quero informar',
        ),
        CancelamentoMotivoOption(
          id: 'mudou_de_ideia',
          label: 'Mudei de ideia',
        ),
        CancelamentoMotivoOption(
          id: 'errei_categoria',
          label: 'Escolhi a categoria errada',
        ),
        CancelamentoMotivoOption(
          id: 'demora_resposta',
          label: 'Demora na resposta do prestador',
        ),
        CancelamentoMotivoOption(
          id: 'preco_alto',
          label: 'Preco acima do esperado',
        ),
        CancelamentoMotivoOption(
          id: 'outro',
          label: 'Outro motivo',
          requiresDetail: true,
        ),
      ];
    }

    return const [
      CancelamentoMotivoOption(
        id: 'problema_local',
        label: 'Problema no local do servico',
      ),
      CancelamentoMotivoOption(
        id: 'prestador_nao_compareceu',
        label: 'Prestador nao compareceu',
      ),
      CancelamentoMotivoOption(
        id: 'mudou_de_ideia',
        label: 'Mudei de ideia',
      ),
      CancelamentoMotivoOption(
        id: 'outro',
        label: 'Outro motivo',
        requiresDetail: true,
      ),
    ];
  }

  static List<CancelamentoMotivoOption> forPrestador({
    required bool emServico,
  }) {
    if (!emServico) {
      return const [
        CancelamentoMotivoOption(
          id: 'cliente_nao_responde',
          label: 'Cliente nao responde',
        ),
        CancelamentoMotivoOption(
          id: 'fora_da_area',
          label: 'Local fora da minha area',
        ),
        CancelamentoMotivoOption(
          id: 'indisponivel',
          label: 'Sem disponibilidade agora',
        ),
        CancelamentoMotivoOption(
          id: 'outro',
          label: 'Outro motivo',
          requiresDetail: true,
        ),
      ];
    }

    return const [
      CancelamentoMotivoOption(
        id: 'problema_tecnico',
        label: 'Problema tecnico no local',
      ),
      CancelamentoMotivoOption(
        id: 'cliente_ausente',
        label: 'Cliente ausente/no-show',
      ),
      CancelamentoMotivoOption(
        id: 'condicoes_risco',
        label: 'Condicoes de risco',
      ),
      CancelamentoMotivoOption(
        id: 'outro',
        label: 'Outro motivo',
        requiresDetail: true,
      ),
    ];
  }
}
