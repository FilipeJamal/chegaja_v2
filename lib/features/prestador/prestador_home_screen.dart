// lib/features/prestador/prestador_home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';

import 'widgets/prestador_pedido_acoes.dart';

/// Helpers para mostrar textos bonitos no UI do prestador

String _labelEstado(String estado) {
  switch (estado) {
    case 'criado':
      return 'À espera de prestador';
    case 'aguarda_resposta_cliente':
      return 'Proposta a aguardar cliente';
    case 'aceito':
      return 'Aceito, por iniciar';
    case 'em_andamento':
      return 'Em andamento';
    case 'aguarda_confirmacao_valor':
      return 'A aguardar confirmação do valor';
    case 'concluido':
      return 'Concluído';
    case 'cancelado':
      return 'Cancelado';
    default:
      return estado;
  }
}

String _labelTipoPreco(String tipo) {
  switch (tipo) {
    case 'fixo':
      return 'Preço fixo';
    case 'por_orcamento':
      return 'Por orçamento';
    case 'a_combinar':
    default:
      return 'Preço a combinar';
  }
}

String _labelTipoPagamento(String tipo) {
  switch (tipo) {
    case 'online_antes':
      return 'Pagamento online (antes)';
    case 'online_depois':
      return 'Pagamento online (depois)';
    case 'dinheiro':
    default:
      return 'Pagamento em dinheiro';
  }
}

/// Percentagem de taxa da plataforma (15%).
const double kCommissionPercent = 0.15;

/// Helpers simples para saber se é histórico
bool _isConcluido(Pedido p) => p.estado == 'concluido';
bool _isCancelado(Pedido p) => p.estado == 'cancelado';

class PrestadorHomeScreen extends StatefulWidget {
  const PrestadorHomeScreen({super.key});

  @override
  State<PrestadorHomeScreen> createState() => _PrestadorHomeScreenState();
}

class _PrestadorHomeScreenState extends State<PrestadorHomeScreen> {
  int _currentIndex = 0;
  bool _online = true;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _PrestadorInicioTab(
        online: _online,
        onToggleOnline: (value) {
          setState(() {
            _online = value;
          });
        },
      ),
      const _PrestadorPedidosTab(),
      const _ContaTab(roleLabel: 'Prestador'),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Trabalhos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Conta',
          ),
        ],
      ),
    );
  }
}

class _PrestadorInicioTab extends StatefulWidget {
  final bool online;
  final ValueChanged<bool> onToggleOnline;

  const _PrestadorInicioTab({
    required this.online,
    required this.onToggleOnline,
    super.key,
  });

  @override
  State<_PrestadorInicioTab> createState() => _PrestadorInicioTabState();
}

class _PrestadorInicioTabState extends State<_PrestadorInicioTab> {
  /// ids que este prestador escolheu IGNORAR (só local na sessão)
  final Set<String> _ignorados = <String>{};

  /// Localização simulada do prestador para testes de distância (D2).
  /// Futuramente deve vir do GPS real (Geolocator) ou do perfil do user.
  double? _latPrestador;
  double? _lngPrestador;

  @override
  void initState() {
    super.initState();
    _fetchPrestadorLocation();
  }

  Future<void> _fetchPrestadorLocation() async {
    // (D2) Tenta buscar do perfil gravado no AuthService
    // Se não tiver, não filtra por distância (ou usa default se quiseres forçar).
    // Aqui vamos deixar null se não tiver, e o Repo decide o que fazer (ou a UI avisa).

    // Simulação: para já não forçamos Lisboa hardcoded aqui na UI,
    // mas se o user tiver gravado no perfil, usamos.
    final user = AuthService.currentUser;
    if (user != null) {
       // Buscaria do Firestore users/{uid} se quiséssemos persistência real.
       // Para este MVP/Protótipo, se não temos GPS real, deixamos null
       // ou definimos um "ponto de partida" se quisermos testar o filtro.

       // Exemplo: se quisermos testar o filtro, descomentar:
       // setState(() {
       //   _latPrestador = 38.7223;
       //   _lngPrestador = -9.1393;
       // });
    }
  }

  Future<void> _proporServico(
    BuildContext context,
    Pedido pedido,
  ) async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilizador não autenticado.'),
        ),
      );
      return;
    }

    final minController = TextEditingController();
    final maxController = TextEditingController();
    final msgController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Propor serviço'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Define uma faixa de preço para este serviço.\n'
                  'Inclui deslocação e mão de obra.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text('Valor mínimo (€)'),
                TextField(
                  controller: minController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: '€ ',
                    hintText: 'Ex.: 20',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Valor máximo (€)'),
                TextField(
                  controller: maxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: '€ ',
                    hintText: 'Ex.: 35',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Mensagem para o cliente (opcional)'),
                TextField(
                  controller: msgController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText:
                        'Ex.: Inclui deslocação. Materiais grandes à parte.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final min = double.tryParse(
                    minController.text.replaceAll(',', '.').trim());
                final max = double.tryParse(
                    maxController.text.replaceAll(',', '.').trim());

                if (min == null || max == null || min <= 0 || max <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Preenche valores mínimo e máximo válidos.'),
                    ),
                  );
                  return;
                }

                if (min > max) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content:
                          Text('O mínimo não pode ser maior que o máximo.'),
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();

                try {
                  await PedidoService.instance.enviarPropostaFaixa(
                    pedido: pedido,
                    prestadorId: user.uid,
                    valorMin: min,
                    valorMax: max,
                    mensagem: msgController.text.trim().isEmpty
                        ? null
                        : msgController.text.trim(),
                  );

                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proposta enviada ao cliente.'),
                    ),
                  );
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao enviar proposta: $e'),
                    ),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _ignorarPedido(Pedido pedido) {
    setState(() {
      _ignorados.add(pedido.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final user = AuthService.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Erro: utilizador não autenticado.'),
      );
    }

    final df = DateFormat('dd/MM HH:mm');

    return StreamBuilder<List<Pedido>>(
      stream: PedidosRepo.streamPedidosDoPrestador(user.uid),
      builder: (context, snapshot) {
        final pedidosDoPrestador = snapshot.data ?? [];

        final now = DateTime.now();
        double brutoHoje = 0;
        double taxaHoje = 0;
        double liquidoHoje = 0;
        int servicosMes = 0;

        for (final p in pedidosDoPrestador) {
          if (p.estado == 'concluido' && p.concluidoEm != null) {
            final d = p.concluidoEm!;
            final mesmoMes = d.year == now.year && d.month == now.month;
            final mesmoDia = mesmoMes && d.day == now.day;

            if (mesmoMes) {
              servicosMes++;
            }

            if (mesmoDia) {
              // total bruto cobrado ao cliente
              final total =
                  p.earningsTotal ?? p.precoFinal ?? p.preco ?? 0.0;

              if (total <= 0) continue;

              final commission =
                  p.commissionPlatform ?? (total * kCommissionPercent);
              final liquido = p.earningsProvider ?? (total - commission);

              brutoHoje += total;
              taxaHoje += commission;
              liquidoHoje += liquido;
            }
          }
        }

        final liquidoHojeStr = '€ ${liquidoHoje.toStringAsFixed(2)}';
        final brutoHojeStr = '€ ${brutoHoje.toStringAsFixed(2)}';
        final taxaHojeStr = '€ ${taxaHoje.toStringAsFixed(2)}';
        final servicosMesStr = servicosMes.toString();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Olá, prestador 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fica online para receber novos pedidos.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.online
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: widget.online ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.online ? 'Estás ONLINE' : 'Estás OFFLINE',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              widget.online ? Colors.green[700] : Colors.black87,
                        ),
                      ),
                    ),
                    Switch(
                      value: widget.online,
                      activeThumbColor: primary,
                      onChanged: widget.onToggleOnline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  _KpiCard(
                    label: 'Ganhos hoje (líquido)',
                    value: liquidoHojeStr,
                    icon: Icons.euro_outlined,
                    subtitle: 'Bruto: $brutoHojeStr • Taxa: $taxaHojeStr',
                  ),
                  const SizedBox(width: 12),
                  _KpiCard(
                    label: 'Serviços este mês',
                    value: servicosMesStr,
                    icon: Icons.work_outline,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Pedidos perto de ti',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<List<Pedido>>(
                  // (D2) Usar stream filtrada por distância se tivermos local.
                  // Caso contrário, usa stream normal (todos).
                  stream: (_latPrestador != null && _lngPrestador != null)
                      ? PedidosRepo.streamPedidosDisponiveisProximos(
                          latPrestador: _latPrestador!,
                          lngPrestador: _lngPrestador!,
                          raioKm: 50,
                        )
                      : PedidosRepo.streamPedidosDisponiveis(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro a carregar pedidos: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    var pedidos = snapshot.data ?? [];

                    // remove os que este prestador decidiu IGNORAR
                    pedidos = pedidos
                        .where((p) => !_ignorados.contains(p.id))
                        .toList();

                    if (pedidos.isEmpty) {
                      return const Center(
                        child: Text(
                          'Não há pedidos disponíveis neste momento.\n'
                          'Assim que um cliente criar um pedido, ele aparece aqui. 😉',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: pedidos.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final pedido = pedidos[index];

                        final tipoPrecoLabel =
                            _labelTipoPreco(pedido.tipoPreco);
                        final tipoPagamentoLabel =
                            _labelTipoPagamento(pedido.tipoPagamento);

                        return _PedidoDisponivelCard(
                          pedido: pedido,
                          titulo: pedido.titulo,
                          categoria: pedido.categoria,
                          descricao: pedido.descricao,
                          agendadoPara: pedido.agendadoPara,
                          modo: pedido.modo,
                          tipoPrecoLabel: tipoPrecoLabel,
                          tipoPagamentoLabel: tipoPagamentoLabel,
                          df: df,
                          onPropor: () => _proporServico(context, pedido),
                          onIgnorar: () => _ignorarPedido(pedido),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PedidoDisponivelCard extends StatelessWidget {
  final Pedido pedido;
  final String titulo;
  final String? categoria;
  final String? descricao;
  final DateTime? agendadoPara;
  final String modo;
  final String tipoPrecoLabel;
  final String tipoPagamentoLabel;
  final DateFormat df;
  final VoidCallback onPropor;
  final VoidCallback onIgnorar;

  const _PedidoDisponivelCard({
    required this.pedido,
    required this.titulo,
    required this.categoria,
    required this.descricao,
    required this.agendadoPara,
    required this.modo,
    required this.tipoPrecoLabel,
    required this.tipoPagamentoLabel,
    required this.df,
    required this.onPropor,
    required this.onIgnorar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final linhaCategoria = categoria ?? 'Categoria não definida';

    String linhaAgendamento;
    if (modo == 'AGENDADO' && agendadoPara != null) {
      linhaAgendamento = 'Agendado: ${df.format(agendadoPara!)}';
    } else {
      linhaAgendamento = 'Serviço imediato';
    }

    final desc = (descricao ?? '').trim();
    final temDescricao = desc.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: onIgnorar,
                child: const Text('Ignorar'),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: onPropor,
                child: const Text('Propor'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            linhaCategoria,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            linhaAgendamento,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tipoPrecoLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Text(
            tipoPagamentoLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          if (temDescricao) ...[
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ------------ ABA "MEUS TRABALHOS" COM ABAS ------------

class _PrestadorPedidosTab extends StatelessWidget {
  const _PrestadorPedidosTab();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Erro: utilizador não autenticado.'),
      );
    }

    final df = DateFormat('dd/MM HH:mm');

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meus trabalhos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const TabBar(
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: 'Em aberto'),
                Tab(text: 'Concluídos'),
                Tab(text: 'Cancelados'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Pedido>>(
                stream: PedidosRepo.streamPedidosDoPrestador(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro a carregar trabalhos: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final pedidos = snapshot.data ?? [];

                  final emAberto = pedidos
                      .where((p) => !_isConcluido(p) && !_isCancelado(p))
                      .toList();
                  final concluidos =
                      pedidos.where(_isConcluido).toList();
                  final cancelados =
                      pedidos.where(_isCancelado).toList();

                  emAberto.sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt),
                  );
                  concluidos.sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt),
                  );
                  cancelados.sort(
                    (a, b) => b.createdAt.compareTo(a.createdAt),
                  );

                  return TabBarView(
                    children: [
                      _PrestadorListaPedidos(
                        pedidos: emAberto,
                        mensagemVazio:
                            'Ainda não tens trabalhos em aberto.\nVai à aba Início e propõe um serviço.',
                        df: df,
                        podeCancelar: true,
                      ),
                      _PrestadorListaPedidos(
                        pedidos: concluidos,
                        mensagemVazio:
                            'Ainda não tens trabalhos concluídos.',
                        df: df,
                        podeCancelar: false,
                      ),
                      _PrestadorListaPedidos(
                        pedidos: cancelados,
                        mensagemVazio:
                            'Ainda não tens trabalhos cancelados.',
                        df: df,
                        podeCancelar: false,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrestadorListaPedidos extends StatelessWidget {
  final List<Pedido> pedidos;
  final String mensagemVazio;
  final DateFormat df;
  final bool podeCancelar;

  const _PrestadorListaPedidos({
    required this.pedidos,
    required this.mensagemVazio,
    required this.df,
    required this.podeCancelar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (pedidos.isEmpty) {
      return Center(
        child: Text(
          mensagemVazio,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: pedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = pedidos[index];
        return _PrestadorPedidoCard(
          pedido: p,
          df: df,
          podeCancelar: podeCancelar,
        );
      },
    );
  }
}

/// Card de um trabalho do prestador (usado em todas as abas)
class _PrestadorPedidoCard extends StatelessWidget {
  final Pedido pedido;
  final DateFormat df;
  final bool podeCancelar;

  const _PrestadorPedidoCard({
    required this.pedido,
    required this.df,
    required this.podeCancelar,
    super.key,
  });

  Future<void> _cancelarTrabalho(BuildContext context) async {
    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancelar trabalho'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tens a certeza que queres cancelar este trabalho?\n'
                'O pedido pode voltar a ficar disponível para outros prestadores.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'Motivo do cancelamento (opcional):',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motivoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Motivo',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final motivo = motivoController.text.trim();

    try {
      await PedidoService.instance.cancelarPorPrestador(
        pedido: pedido,
        motivo: motivo,
        // para já, quando o prestador cancela nós marcamos reembolso 'nenhum';
        // se quiseres podes mais tarde ligar a uma política de reembolso própria.
        tipoReembolso: 'nenhum',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trabalho cancelado.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cancelar trabalho: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String subtitulo;
    if (pedido.modo == 'AGENDADO' && pedido.agendadoPara != null) {
      subtitulo = 'Agendado: ${df.format(pedido.agendadoPara!)}';
    } else {
      subtitulo = 'Serviço imediato';
    }

    final categoria = pedido.categoria ?? 'Categoria não definida';
    final desc = pedido.descricao.trim();
    final temDescricao = desc.isNotEmpty;

    final estadoLabel = _labelEstado(pedido.estado);
    final tipoPrecoLabel = _labelTipoPreco(pedido.tipoPreco);
    final tipoPagamentoLabel = _labelTipoPagamento(pedido.tipoPagamento);

    final preco = pedido.preco;
    final precoTexto = (pedido.estado == 'concluido' && preco != null)
        ? 'Valor: € ${preco.toStringAsFixed(2)}'
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pedido.titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            categoria,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Estado: $estadoLabel',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tipoPrecoLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Text(
            tipoPagamentoLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          if (temDescricao) ...[
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
          if (precoTexto != null) ...[
            const SizedBox(height: 4),
            Text(
              precoTexto,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          PrestadorPedidoAcoes(
            pedido: pedido,
          ),
          if (podeCancelar) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _cancelarTrabalho(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
                child: const Text('Cancelar trabalho'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContaTab extends StatelessWidget {
  final String roleLabel;

  const _ContaTab({
    required this.roleLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Conta (Prestador)',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.person_outline),
            ),
            title: Text('O teu nome'),
            subtitle: Text('Perfil de Prestador'),
            trailing: Icon(Icons.edit_outlined),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Definições'),
          ),
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Ajuda e suporte'),
          ),
        ],
      ),
    );
  }
}
