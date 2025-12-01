import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/repositories/servico_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';

/// ---------- HELPERS GERAIS PARA A ABA "PEDIDOS" ----------

/// Texto amigável para o estado do pedido
String _labelEstadoCliente(String estado) {
  switch (estado) {
    case 'criado':
      return 'À espera de prestador';
    case 'aguarda_resposta_cliente':
      return 'Proposta de prestador';
    case 'aceito':
      return 'Prestador escolhido';
    case 'em_andamento':
      return 'Em andamento';
    case 'aguarda_confirmacao_valor':
      return 'A confirmar valor';
    case 'concluido':
      return 'Concluído';
    case 'cancelado':
      return 'Cancelado';
    default:
      return estado;
  }
}

/// Lógica do texto que aparece como "Valor" na lista
String _buildValorLabelLista(Pedido pedido) {
  // 1) Valor final confirmado pelo cliente
  if (pedido.precoFinal != null &&
      pedido.statusConfirmacaoValor == 'confirmado_cliente') {
    return '€ ${pedido.precoFinal!.toStringAsFixed(2)}';
  }

  // 2) Prestador lançou valor final e está à espera do cliente
  if (pedido.precoPropostoPrestador != null &&
      pedido.statusConfirmacaoValor == 'pendente_cliente') {
    return '€ ${pedido.precoPropostoPrestador!.toStringAsFixed(2)} (a confirmar)';
  }

  // 3) Há valor final mas sem estado claro
  if (pedido.precoFinal != null) {
    return '€ ${pedido.precoFinal!.toStringAsFixed(2)}';
  }

  // 4) Só valor lançado pelo prestador
  if (pedido.precoPropostoPrestador != null) {
    return '€ ${pedido.precoPropostoPrestador!.toStringAsFixed(2)} (proposto)';
  }

  // 5) Só faixa estimada
  final min = pedido.valorMinEstimadoPrestador;
  final max = pedido.valorMaxEstimadoPrestador;

  if (min != null && max != null) {
    return '€ ${min.toStringAsFixed(2)} a € ${max.toStringAsFixed(2)} (estimado)';
  }
  if (min != null) {
    return 'Desde € ${min.toStringAsFixed(2)} (estimado)';
  }
  if (max != null) {
    return 'Até € ${max.toStringAsFixed(2)} (estimado)';
  }

  // 6) Nada
  return '—';
}

/// Se o cliente tem alguma ação pendente neste pedido
bool _temAcaoPendente(Pedido p) {
  // Tem proposta para decidir
  if (p.statusProposta == 'pendente_cliente') return true;

  // Tem valor final para confirmar
  if (p.statusConfirmacaoValor == 'pendente_cliente') return true;

  return false;
}

/// Mensagem curta de ação pendente
String _textoAcaoPendente(Pedido p) {
  if (p.statusProposta == 'pendente_cliente') {
    return 'Tens uma proposta para analisar.';
  }
  if (p.statusConfirmacaoValor == 'pendente_cliente') {
    return 'Confirma o valor final do serviço.';
  }
  return '';
}

/// ---------- ECRÃ PRINCIPAL ----------

class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _ClienteInicioTab(),
      const _ClientePedidosTab(),
      const _ContaTab(roleLabel: 'Cliente'),
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
            icon: Icon(Icons.list_alt_outlined),
            label: 'Pedidos',
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

/// Home do cliente (pesquisa + categorias dinâmicas)
class _ClienteInicioTab extends StatefulWidget {
  const _ClienteInicioTab({super.key});

  @override
  State<_ClienteInicioTab> createState() => _ClienteInicioTabState();
}

class _ClienteInicioTabState extends State<_ClienteInicioTab> {
  String _search = '';

  Future<void> _abrirNovoPedido(
    BuildContext context, {
    required String modo,
    Servico? servico,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NovoPedidoScreen(
          modo: modo,
          servicoInicial: servico,
        ),
      ),
    );
  }

  IconData _iconForServico(Servico s, Color primary) {
    switch (s.iconKey) {
      case 'canalizador':
        return Icons.plumbing_outlined;
      case 'eletricista':
        return Icons.electrical_services_outlined;
      case 'pedreiro':
        return Icons.construction_outlined;
      case 'mecanico':
        return Icons.build_outlined;
      case 'confeitaria':
        return Icons.cake_outlined;
      case 'babysitter':
        return Icons.child_friendly_outlined;
      case 'cuidador_cao':
        return Icons.pets_outlined;
      case 'fotografo':
        return Icons.photo_camera_outlined;
      case 'videomaker':
        return Icons.videocam_outlined;
      case 'designer_grafico':
        return Icons.brush_outlined;
      case 'social_media':
        return Icons.campaign_outlined;
      case 'personal_trainer':
        return Icons.fitness_center;
      default:
        return Icons.work_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final user = AuthService.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Olá 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'De que serviço precisas hoje?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),

          // 🔔 Banner de ações pendentes do cliente (propostas / confirmação de valor)
          if (user != null)
            StreamBuilder<List<Pedido>>(
              stream: PedidosRepo.streamPedidosDoCliente(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (!snapshot.hasData || (snapshot.data ?? []).isEmpty) {
                  return const SizedBox.shrink();
                }

                final pedidos = snapshot.data ?? [];
                final pendentes = pedidos.where(_temAcaoPendente).toList();

                if (pendentes.isEmpty) {
                  return const SizedBox.shrink();
                }

                final count = pendentes.length;
                final primeiro = pendentes.first;

                final titulo = count == 1
                    ? 'Tens 1 pedido à espera da tua decisão.'
                    : 'Tens $count pedidos à espera da tua decisão.';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PedidoDetalheScreen(
                            pedidoId: primeiro.id,
                            isCliente: true,
                          ),
                        ),
                      );
                    },
                    child: Ink(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            color: primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Tens pedidos à espera da tua decisão.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Toca aqui para abrir o próximo pedido e decidir.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Barra de pesquisa
          TextField(
            onChanged: (value) {
              setState(() {
                _search = value.toLowerCase().trim();
              });
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Procurar serviço (ex: canalizador, bolo, cão...)',
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Ações rápidas (modos directos)
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.flash_on_outlined,
                  label: 'Serviço agora',
                  description: 'Preciso de alguém já',
                  onTap: () => _abrirNovoPedido(
                    context,
                    modo: 'IMEDIATO',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.event_available_outlined,
                  label: 'Agendar',
                  description: 'Marcar para outro dia',
                  onTap: () => _abrirNovoPedido(
                    context,
                    modo: 'AGENDADO',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.assignment_outlined,
                  label: 'Por proposta',
                  description: 'Receber orçamentos',
                  onTap: () => _abrirNovoPedido(
                    context,
                    modo: 'POR_PROPOSTA',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Categorias populares',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Categorias dinâmicas
          Expanded(
            child: StreamBuilder<List<Servico>>(
              stream: ServicosRepo.streamServicosAtivos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro a carregar serviços: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final servicos = snapshot.data ?? [];

                // filtrar pela pesquisa
                final filtrados = servicos.where((s) {
                  if (_search.isEmpty) return true;
                  final texto =
                      (s.name + ' ' + s.keywords.join(' ')).toLowerCase();
                  return texto.contains(_search);
                }).toList();

                if (filtrados.isEmpty) {
                  return const Center(
                    child: Text(
                      'Não encontrámos serviços para essa pesquisa.\n'
                      'Tenta outra palavra 😉',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: filtrados.map((s) {
                    final icon = _iconForServico(s, primary);

                    String subtitle;
                    if (s.mode == 'IMEDIATO') {
                      subtitle = 'Serviço imediato';
                    } else if (s.mode == 'AGENDADO') {
                      subtitle = 'Por agendamento';
                    } else {
                      subtitle = 'Por proposta';
                    }

                    return _CategoriaCard(
                      icon: icon,
                      title: s.name,
                      subtitle: subtitle,
                      color: primary,
                      onTap: () => _abrirNovoPedido(
                        context,
                        modo: s.mode,
                        servico: s,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.description,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _CategoriaCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- ABA "PEDIDOS" COM ABAS (PENDENTES / CONCLUÍDOS / CANCELADOS) ----------

class _ClientePedidosTab extends StatelessWidget {
  const _ClientePedidosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Erro: utilizador não autenticado.'),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meus pedidos',
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
                Tab(text: 'Pendentes'),
                Tab(text: 'Concluídos'),
                Tab(text: 'Cancelados'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Pedido>>(
                stream: PedidosRepo.streamPedidosDoCliente(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child:
                          Text('Erro a carregar pedidos: ${snapshot.error}'),
                    );
                  }

                  final pedidos = snapshot.data ?? [];

                  final pendentes = pedidos
                      .where((p) =>
                          p.estado != 'concluido' && p.estado != 'cancelado')
                      .toList();
                  final concluidos = pedidos
                      .where((p) => p.estado == 'concluido')
                      .toList();
                  final cancelados = pedidos
                      .where((p) => p.estado == 'cancelado')
                      .toList();

                  pendentes
                      .sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  concluidos
                      .sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  cancelados
                      .sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return TabBarView(
                    children: [
                      _ClienteListaPedidos(
                        pedidos: pendentes,
                        mensagemVazio: 'Não tens pedidos pendentes.',
                      ),
                      _ClienteListaPedidos(
                        pedidos: concluidos,
                        mensagemVazio:
                            'Ainda não tens pedidos concluídos.',
                      ),
                      _ClienteListaPedidos(
                        pedidos: cancelados,
                        mensagemVazio:
                            'Ainda não tens pedidos cancelados.',
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

/// Lista de pedidos para um tipo específico (pendente, concluído, cancelado)
class _ClienteListaPedidos extends StatelessWidget {
  final List<Pedido> pedidos;
  final String mensagemVazio;

  const _ClienteListaPedidos({
    required this.pedidos,
    required this.mensagemVazio,
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
        return _ClientePedidoCard(pedido: p);
      },
    );
  }
}

/// Card de um pedido na lista do cliente
class _ClientePedidoCard extends StatelessWidget {
  final Pedido pedido;

  const _ClientePedidoCard({
    required this.pedido,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final categoria = pedido.categoria ?? 'Categoria não definida';
    final desc = pedido.descricao.trim();
    final temDescricao = desc.isNotEmpty;

    String subtitulo;
    if (pedido.modo == 'AGENDADO' && pedido.agendadoPara != null) {
      subtitulo = 'Agendado';
    } else if (pedido.modo == 'AGENDADO') {
      subtitulo = 'Serviço agendado';
    } else if (pedido.modo == 'POR_PROPOSTA') {
      subtitulo = 'Serviço por proposta';
    } else {
      subtitulo = 'Serviço imediato';
    }

    final estadoLabel = _labelEstadoCliente(pedido.estado);
    final valorLabel = _buildValorLabelLista(pedido);

    final acaoPendente = _temAcaoPendente(pedido);
    final textoAcao = _textoAcaoPendente(pedido);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PedidoDetalheScreen(
              pedidoId: pedido.id,
              isCliente: true,
            ),
          ),
        );
      },
      child: Ink(
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
            border: acaoPendente
                ? Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.5),
                    width: 1.2,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pedido.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (acaoPendente)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tua ação',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
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
                'Valor: $valorLabel',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              if (acaoPendente && textoAcao.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  textoAcao,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (temDescricao) ...[
                const SizedBox(height: 6),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- ABA "CONTA" ----------

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
        children: [
          Text(
            'Conta ($roleLabel)',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person_outline),
            ),
            title: const Text('O teu nome'),
            subtitle: Text('Perfil de $roleLabel'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () {
              // futuro: ecrã de edição de perfil
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Definições'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ajuda e suporte'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
