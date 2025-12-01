// lib/features/prestador/widgets/prestador_pedido_acoes.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';

class PrestadorPedidoAcoes extends StatelessWidget {
  final Pedido pedido;

  const PrestadorPedidoAcoes({
    required this.pedido,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    switch (pedido.estado) {
      case 'aceito':
        return _AcaoIniciarServico(pedido: pedido);
      case 'em_andamento':
        return _AcaoLancarValorFinal(pedido: pedido);
      case 'aguarda_confirmacao_valor':
        return _AcaoAguardandoConfirmacao(pedido: pedido);
      case 'concluido':
        return _AcaoConcluido(pedido: pedido);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// ---------------- 1) SERVIÇO AINDA NÃO INICIADO ----------------
class _AcaoIniciarServico extends StatelessWidget {
  final Pedido pedido;

  const _AcaoIniciarServico({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final bool isAgendado = pedido.modo == 'AGENDADO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAgendado
              ? 'Este serviço está agendado. Só deves iniciar perto da hora '
                'combinada com o cliente.'
              : 'Quando chegares ao local do serviço, clica em "Iniciar serviço".',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Iniciar serviço'),
            onPressed: () async {
              // Regra especial para AGENDADO:
              // não permitir iniciar muito antes da hora agendada.
              if (isAgendado && pedido.agendadoPara != null) {
                final agora = DateTime.now();
                final agendado = pedido.agendadoPara!;

                // Margem de tolerância antes da hora marcada
                const margemAntes = Duration(minutes: 30);

                final earliestStart = agendado.subtract(margemAntes);

                if (agora.isBefore(earliestStart)) {
                  final diff = agendado.difference(agora);
                  final horas = diff.inHours;
                  final minutos = diff.inMinutes % 60;
                  final textoTempo = horas > 0
                      ? '${horas}h ${minutos}min'
                      : '${minutos}min';

                  final dataFormatada =
                      DateFormat('dd/MM \'às\' HH:mm').format(agendado);

                  await showDialog<void>(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('Ainda é cedo para iniciar'),
                        content: Text(
                          'Este serviço está agendado para $dataFormatada.\n\n'
                          'Ainda faltam aproximadamente $textoTempo.\n\n'
                          'Só deves iniciar perto da hora combinada ou depois '
                          'de combinarem uma alteração com o cliente (por chat).',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                  return;
                }
              }

              try {
                await PedidoService.instance.iniciarPedido(pedido: pedido);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Serviço iniciado.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao iniciar serviço: $e')),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

/// ---------------- 2) EM ANDAMENTO → LANÇAR VALOR FINAL ----------------
class _AcaoLancarValorFinal extends StatelessWidget {
  final Pedido pedido;

  const _AcaoLancarValorFinal({required this.pedido});

  Future<void> _abrirDialogValorFinal(BuildContext context) async {
    final controller = TextEditingController();

    final valorDigitado = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Lançar valor final'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pedido.valorMinEstimadoPrestador != null ||
                  pedido.valorMaxEstimadoPrestador != null) ...[
                Text(
                  _descricaoFaixa(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text('Valor final a cobrar (€)'),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  prefixText: '€ ',
                  hintText: 'Ex.: 35',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final txt = controller.text.replaceAll(',', '.').trim();
                final valor = double.tryParse(txt);

                if (valor == null || valor <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Introduz um valor final válido.'),
                    ),
                  );
                  return;
                }

                // verifica se está fora da faixa
                final foraFaixa = PedidoService.valorForaDaFaixa(
                  valor: valor,
                  min: pedido.valorMinEstimadoPrestador,
                  max: pedido.valorMaxEstimadoPrestador,
                );

                if (foraFaixa) {
                  final faixaMsg = _descricaoFaixa();
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (ctx2) {
                      return AlertDialog(
                        title: const Text('Valor fora da faixa'),
                        content: Text(
                          'O valor que estás a lançar está fora da faixa que '
                          'tinhas indicado ao cliente.\n\n'
                          '$faixaMsg\n\n'
                          'Tens a certeza que € ${valor.toStringAsFixed(2)} '
                          'é o valor correto?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx2).pop(false),
                            child: const Text('Voltar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx2).pop(true),
                            child: const Text('Sim, confirmar valor'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm != true) {
                    return;
                  }
                }

                Navigator.of(ctx).pop(valor);
              },
              child: const Text('Enviar ao cliente'),
            ),
          ],
        );
      },
    );

    if (valorDigitado == null) return;

    try {
      await PedidoService.instance.proporValorFinal(
        pedido: pedido,
        valorFinal: valorDigitado,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Valor final enviado ao cliente para confirmação.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar valor final: $e')),
        );
      }
    }
  }

  String _descricaoFaixa() {
    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;

    if (min != null && max != null) {
      return 'Faixa combinada: € ${min.toStringAsFixed(2)} a '
          '€ ${max.toStringAsFixed(2)}.';
    }
    if (min != null) {
      return 'Faixa combinada: desde € ${min.toStringAsFixed(2)}.';
    }
    if (max != null) {
      return 'Faixa combinada: até € ${max.toStringAsFixed(2)}.';
    }
    return 'Sem faixa combinada.';
  }

  @override
  Widget build(BuildContext context) {
    final faixa = _descricaoFaixa();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          faixa,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Terminar serviço e lançar valor final'),
            onPressed: () => _abrirDialogValorFinal(context),
          ),
        ),
      ],
    );
  }
}

/// ---------------- 3) À ESPERA DO CLIENTE ----------------
class _AcaoAguardandoConfirmacao extends StatelessWidget {
  final Pedido pedido;

  const _AcaoAguardandoConfirmacao({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final valor = pedido.precoPropostoPrestador;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'À espera da confirmação do cliente para o valor final.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        if (valor != null) ...[
          Text(
            'Valor proposto: € ${valor.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          _ResumoComissaoCard(
            pedido: pedido,
            totalOverride: valor,
            showTitle: true,
          ),
        ],
      ],
    );
  }
}

/// ---------------- 4) CONCLUÍDO ----------------
class _AcaoConcluido extends StatelessWidget {
  final Pedido pedido;

  const _AcaoConcluido({required this.pedido});

  @override
  Widget build(BuildContext context) {
    return _ResumoComissaoCard(
      pedido: pedido,
      showTitle: true,
    );
  }
}

/// ---------------- CARD RESUMO (BRUTO / TAXA / LÍQUIDO) ----------------
class _ResumoComissaoCard extends StatelessWidget {
  final Pedido pedido;
  final double? totalOverride;
  final bool showTitle;

  const _ResumoComissaoCard({
    required this.pedido,
    this.totalOverride,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Valor bruto
    final double bruto = totalOverride ??
        pedido.earningsTotal ??
        pedido.precoFinal ??
        pedido.precoPropostoPrestador ??
        pedido.preco ??
        0.0;

    if (bruto <= 0) {
      return const SizedBox.shrink();
    }

    // 2) Usa campos gravados OU simula (sempre 15%)
    double? commission = pedido.commissionPlatform;
    double? liquido = pedido.earningsProvider;

    if (commission == null || liquido == null) {
      final sim = PedidoService.simularComissao(bruto);
      commission ??= sim['commissionPlatform'];
      liquido ??= sim['earningsProvider'];
    }

    // garantimos não-nulo daqui para baixo
    final double safeCommission = commission ?? 0.0;
    final double safeLiquido = liquido ?? 0.0;

    // 3) Percentagem dinâmica
    final double percent =
        bruto > 0 ? (safeCommission / bruto * 100.0) : 0.0;

    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            const Text(
              'Resumo do valor',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
          ],
          _linhaResumo(
            'Valor bruto',
            '€ ${bruto.toStringAsFixed(2)}',
          ),
          _linhaResumo(
            'Taxa da plataforma (${percent.toStringAsFixed(0)}%)',
            '€ ${safeCommission.toStringAsFixed(2)}',
          ),
          _linhaResumo(
            'Valor líquido (para ti)',
            '€ ${safeLiquido.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _linhaResumo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
