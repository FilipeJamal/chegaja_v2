// lib/features/cliente/cliente_home_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/repositories/servico_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/core/services/servico_search.dart';

import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/features/cliente/cliente_perfil_screen.dart';
import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';
import 'package:chegaja_v2/features/common/pedido_chat_preview.dart';
import 'package:chegaja_v2/features/common/mensagens/mensagens_tab.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';

/// ---------- HELPERS GERAIS PARA A ABA "PEDIDOS" ----------

String _labelEstadoCliente(Pedido p, AppLocalizations l10n) {
  if (p.estado == 'cancelado') {
    if (p.canceladoPor == 'cliente') return l10n.statusCancelledByYou;
    if (p.canceladoPor == 'prestador') return l10n.statusCancelledByProvider;
    return l10n.statusCancelled;
  }

  switch (p.estado) {
    case 'criado':
      return l10n.statusLookingForProvider;
    case 'aguarda_resposta_prestador':
      return 'Aguardando resposta do prestador';
    case 'aguarda_proposta_prestador':
      return l10n.statusProviderPreparingQuote;
    case 'aguarda_resposta_cliente':
      return l10n.statusQuoteToDecide;
    case 'aceito':
      return l10n.statusProviderFound;
    case 'em_andamento':
      return l10n.statusServiceInProgress;
    case 'aguarda_confirmacao_valor':
      return l10n.statusAwaitingValueConfirmation;
    case 'concluido':
      return l10n.statusServiceCompleted;
    default:
      return p.estado;
  }
}

String _buildValorLabelLista(Pedido pedido, AppLocalizations l10n) {
  final currency = NumberFormat.simpleCurrency(locale: l10n.localeName);
  String formatValue(double value) => currency.format(value);

  if (pedido.precoFinal != null &&
      pedido.statusConfirmacaoValor == 'confirmado_cliente') {
    return formatValue(pedido.precoFinal!);
  }

  if (pedido.precoPropostoPrestador != null &&
      pedido.statusConfirmacaoValor == 'pendente_cliente') {
    return l10n.valueToConfirm(formatValue(pedido.precoPropostoPrestador!));
  }

  if (pedido.precoFinal != null) {
    return formatValue(pedido.precoFinal!);
  }

  if (pedido.precoPropostoPrestador != null) {
    return l10n.valueProposed(formatValue(pedido.precoPropostoPrestador!));
  }

  final min = pedido.valorMinEstimadoPrestador;
  final max = pedido.valorMaxEstimadoPrestador;

  if (min != null && max != null) {
    return l10n.valueEstimatedRange(
      formatValue(min),
      formatValue(max),
    );
  }
  if (min != null) return l10n.valueEstimatedFrom(formatValue(min));
  if (max != null) return l10n.valueEstimatedUpTo(formatValue(max));

  return l10n.valueUnknown;
}

String _labelTipoPrecoCliente(String? tipo, AppLocalizations l10n) {
  switch (tipo) {
    case 'fixo':
      return l10n.priceFixed;
    case 'por_orcamento':
      return l10n.priceByQuote;
    case 'a_combinar':
    default:
      return l10n.priceToArrange;
  }
}

String _labelTipoPagamentoCliente(String? tipo, AppLocalizations l10n) {
  switch (tipo) {
    case 'online_antes':
      return l10n.paymentOnlineBefore;
    case 'online_depois':
      return l10n.paymentOnlineAfter;
    case 'dinheiro':
    default:
      return l10n.paymentCash;
  }
}

String _normalizeServicoMode(String? mode) {
  final raw = (mode ?? '').toUpperCase().trim();
  if (raw == 'POR_PROPOSTA' || raw == 'ORCAMENTO' || raw == 'POR_ORCAMENTO') {
    return 'ORCAMENTO';
  }
  if (raw == 'AGENDADO') return 'AGENDADO';
  if (raw == 'IMEDIATO') return 'IMEDIATO';
  return 'IMEDIATO';
}

bool _temAcaoPendente(Pedido p) {
  if (p.estado == 'cancelado' || p.estado == 'concluido') return false;

  if (p.statusProposta == 'pendente_cliente') return true;
  if (p.statusConfirmacaoValor == 'pendente_cliente') return true;

  if (p.estado == 'aceito' || p.estado == 'aguarda_proposta_prestador') {
    return true;
  }

  return false;
}

String _textoAcaoPendente(Pedido p, AppLocalizations l10n) {
  if (p.estado == 'cancelado' || p.estado == 'concluido') return '';

  if (p.statusProposta == 'pendente_cliente') {
    return l10n.pendingActionQuoteToReview;
  }
  if (p.statusConfirmacaoValor == 'pendente_cliente') {
    return l10n.pendingActionValueToConfirm;
  }
  if (p.estado == 'aguarda_proposta_prestador') {
    return l10n.pendingActionProviderPreparingQuote;
  }
  if (p.estado == 'aceito') {
    return l10n.pendingActionProviderChat;
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

  // badge de mensagens não lidas
  StreamSubscription<List<Pedido>>? _pedidosSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _chatSubs = {};
  final Map<String, bool> _unreadPorPedido = {};
  bool _hasUnreadMessages = false;
  Stream<List<Pedido>>? _pedidosClienteStream;
  Stream<List<Servico>>? _servicosStream;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    AuthService.setActiveRole('cliente');
    final user = AuthService.currentUser;
    _servicosStream ??= ServicosRepo.streamServicosAtivos();
    if (user != null) {
      _pedidosClienteStream ??= PedidosRepo.streamPedidosDoCliente(user.uid);
      _pedidosSub = _pedidosClienteStream!.listen(_onPedidosUpdate);
    }
  }

  void _ensureStreams(String userId) {
    _pedidosClienteStream ??= PedidosRepo.streamPedidosDoCliente(userId);
    _servicosStream ??= ServicosRepo.streamServicosAtivos();
  }

  void _onPedidosUpdate(List<Pedido> pedidos) {
    final ativos = pedidos
        .where((p) => p.estado != 'concluido' && p.estado != 'cancelado')
        .toList();
    final idsAtivos = ativos.map((p) => p.id).toSet();

    final idsParaRemover =
        _chatSubs.keys.where((id) => !idsAtivos.contains(id)).toList();
    for (final id in idsParaRemover) {
      _chatSubs[id]?.cancel();
      _chatSubs.remove(id);
      _unreadPorPedido.remove(id);
    }

    for (final p in ativos) {
      if (!_chatSubs.containsKey(p.id)) {
        // garante meta do chat (para a aba Mensagens)
        ChatService.instance.ensureChatMetaForPedido(p.id);

        final q = FirebaseFirestore.instance
            .collection('chats')
            .doc(p.id)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(50);

        _chatSubs[p.id] = q.snapshots().listen(
          (snap) => _onMessagesUpdate(p.id, snap.docs),
        );
      }
    }
  }

  void _onMessagesUpdate(
    String pedidoId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    bool hasUnread = false;

    for (final d in docs) {
      final data = d.data();
      final senderRole = (data['senderRole'] ?? '').toString();

      if (senderRole != 'prestador') continue;
      if (data['seenByCliente'] == true) continue;

      hasUnread = true;
      break;
    }

    _unreadPorPedido[pedidoId] = hasUnread;
    _recalculateHasUnread();
  }

  void _recalculateHasUnread() {
    final anyUnread = _unreadPorPedido.values.any((v) => v);
    if (!mounted) return;
    setState(() => _hasUnreadMessages = anyUnread);
  }

  @override
  void dispose() {
    _pedidosSub?.cancel();
    for (final sub in _chatSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;
    if (user != null) {
      _ensureStreams(user.uid);
    } else {
      _servicosStream ??= ServicosRepo.streamServicosAtivos();
    }
    final pages = <Widget>[
      _ClienteInicioTab(
        pedidosStream: _pedidosClienteStream,
        servicosStream: _servicosStream,
      ),
      _ClientePedidosTab(pedidosStream: _pedidosClienteStream),
      const MensagensTab(viewerRole: 'cliente'),
      _ContaTab(roleLabel: l10n.roleLabelCustomer),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt_outlined),
            activeIcon: const Icon(Icons.list_alt),
            label: l10n.navMyOrders,
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (_hasUnreadMessages)
                  const Positioned(
                    right: -2,
                    top: -2,
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            activeIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble),
                if (_hasUnreadMessages)
                  const Positioned(
                    right: -2,
                    top: -2,
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: l10n.navMessages,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

/// ---------- ABA "INÍCIO" ----------

class _ClienteInicioTab extends StatelessWidget {
  final Stream<List<Pedido>>? pedidosStream;
  final Stream<List<Servico>>? servicosStream;

  const _ClienteInicioTab({
    this.pedidosStream,
    this.servicosStream,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double tabHeight = constraints.maxHeight * 0.65;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeGreeting,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.homeSubtitle,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 16),

                if (user != null)
                  StreamBuilder<List<Pedido>>(
                    stream: pedidosStream ??
                        PedidosRepo.streamPedidosDoCliente(user.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final pedidos = snapshot.data!;
                      final pendentesComAcao =
                          pedidos.where(_temAcaoPendente).toList();

                      if (pendentesComAcao.isEmpty) return const SizedBox.shrink();

                      pendentesComAcao.sort(
                        (a, b) => a.createdAt.compareTo(b.createdAt),
                      );

                      final proximo = pendentesComAcao.first;
                      final textoAcao = _textoAcaoPendente(proximo, l10n);

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PedidoDetalheScreen(
                                    pedidoId: proximo.id,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primary.withAlpha((0.08 * 255).round()),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.notifications_active_outlined, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.homePendingTitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          textoAcao,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.homePendingCta,
                                          style: const TextStyle(
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
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),

                if (user != null) ...[
                  _ClienteMensagensBanner(clienteId: user.uid),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  height: tabHeight,
                  child: StreamBuilder<List<Servico>>(
                    stream: servicosStream ?? ServicosRepo.streamServicosAtivos(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            l10n.servicesLoadError(
                              snapshot.error.toString(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final servicos = snapshot.data ?? [];
                      if (servicos.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.servicesEmptyMessage,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final modos = <String>['ORCAMENTO', 'AGENDADO', 'IMEDIATO'];

                      return DefaultTabController(
                        length: modos.length,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              l10n.availableServicesTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TabBar(
                              isScrollable: true,
                              labelStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              tabs: [
                                Tab(text: l10n.serviceTabQuote),
                                Tab(text: l10n.serviceTabScheduled),
                                Tab(text: l10n.serviceTabImmediate),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _ListaServicosPorModo(
                                    modo: 'ORCAMENTO',
                                    servicos: servicos,
                                  ),
                                  _ListaServicosPorModo(
                                    modo: 'AGENDADO',
                                    servicos: servicos,
                                  ),
                                  _ListaServicosPorModo(
                                    modo: 'IMEDIATO',
                                    servicos: servicos,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ---------- BANNER NOVAS MENSAGENS (CLIENTE) ----------

class _ClienteMensagensBanner extends StatefulWidget {
  final String clienteId;

  const _ClienteMensagensBanner({required this.clienteId});

  @override
  State<_ClienteMensagensBanner> createState() => _ClienteMensagensBannerState();
}

class _ClienteMensagensBannerState extends State<_ClienteMensagensBanner> {
  StreamSubscription<List<Pedido>>? _pedidosSub;

  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _chatSubs = {};
  final Map<String, bool> _unreadPorPedido = {};
  final Map<String, DateTime?> _lastUnreadAtPorPedido = {};
  final Map<String, Pedido> _pedidoPorId = {};

  bool _hasUnread = false;
  Pedido? _pedidoMaisRecente;

  @override
  void initState() {
    super.initState();
    _pedidosSub =
        PedidosRepo.streamPedidosDoCliente(widget.clienteId).listen(_onPedidosUpdate);
  }

  void _onPedidosUpdate(List<Pedido> pedidos) {
    final ativos = pedidos
        .where((p) => p.estado != 'concluido' && p.estado != 'cancelado')
        .toList();

    final idsAtivos = ativos.map((p) => p.id).toSet();

    final idsParaRemover =
        _chatSubs.keys.where((id) => !idsAtivos.contains(id)).toList();
    for (final id in idsParaRemover) {
      _chatSubs[id]?.cancel();
      _chatSubs.remove(id);
      _unreadPorPedido.remove(id);
      _lastUnreadAtPorPedido.remove(id);
      _pedidoPorId.remove(id);
    }

    for (final p in ativos) {
      _pedidoPorId[p.id] = p;

      if (!_chatSubs.containsKey(p.id)) {
        ChatService.instance.ensureChatMetaForPedido(p.id);

        final q = FirebaseFirestore.instance
            .collection('chats')
            .doc(p.id)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(50);

        _chatSubs[p.id] = q.snapshots().listen(
          (snap) => _onMessagesUpdate(p.id, snap.docs),
        );
      }
    }
  }

  void _onMessagesUpdate(
    String pedidoId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    bool hasUnread = false;
    DateTime? lastUnreadAt;

    for (final d in docs) {
      final data = d.data();
      final senderRole = (data['senderRole'] ?? '').toString();

      if (senderRole != 'prestador') continue;
      if (data['seenByCliente'] == true) continue;

      hasUnread = true;

      final ts = data['createdAt'];
      if (ts is Timestamp) {
        final dt = ts.toDate();
        if (lastUnreadAt == null || dt.isAfter(lastUnreadAt)) {
          lastUnreadAt = dt;
        }
      }
    }

    _unreadPorPedido[pedidoId] = hasUnread;
    _lastUnreadAtPorPedido[pedidoId] = lastUnreadAt;
    _recalculateGlobal();
  }

  void _recalculateGlobal() {
    bool anyUnread = false;
    String? bestPedidoId;
    DateTime? bestTime;

    _unreadPorPedido.forEach((id, hasUnread) {
      if (!hasUnread) return;
      anyUnread = true;
      final t = _lastUnreadAtPorPedido[id];
      if (t == null) return;
      if (bestTime == null || t.isAfter(bestTime!)) {
        bestTime = t;
        bestPedidoId = id;
      }
    });

    if (!mounted) return;

    setState(() {
      _hasUnread = anyUnread;
      _pedidoMaisRecente = bestPedidoId != null ? _pedidoPorId[bestPedidoId] : null;
    });
  }

  @override
  void dispose() {
    _pedidosSub?.cancel();
    for (final sub in _chatSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_hasUnread || _pedidoMaisRecente == null) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;
    final pedido = _pedidoMaisRecente!;

    return GestureDetector(
      onTap: () async {
        ChatService.instance.ensureChatMetaForPedido(pedido.id);

        final chatSnap = await FirebaseFirestore.instance
            .collection('chats')
            .doc(pedido.id)
            .get();

        final data = chatSnap.data() ?? {};
        final prestadorId = (data['prestadorId'] ?? '').toString();
        final prestadorNome = (data['prestadorNome'] ?? 'Prestador').toString();
        final prestadorPhoto = (data['prestadorPhotoUrl'] ?? '').toString();
        final pedidoTitulo = (data['pedidoTitulo'] ?? pedido.titulo).toString();

        if (!context.mounted) return;

        if (prestadorId.trim().isEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
            ),
          );
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              pedidoId: pedido.id,
              viewerRole: 'cliente',
              otherUserId: prestadorId.trim(),
              otherUserName: prestadorNome,
              otherUserPhotoUrl: prestadorPhoto,
              pedidoTitulo: pedidoTitulo,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primary.withAlpha((0.08 * 255).round()),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mark_chat_unread_outlined, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.unreadMessagesTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.unreadMessagesCta,
                    style: const TextStyle(
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
    );
  }
}

/// ---------- LISTA SERVIÇOS ----------

class _ListaServicosPorModo extends StatefulWidget {
  final String modo;
  final List<Servico> servicos;

  const _ListaServicosPorModo({
    required this.modo,
    required this.servicos,
  });

  @override
  State<_ListaServicosPorModo> createState() => _ListaServicosPorModoState();
}

class _ListaServicosPorModoState extends State<_ListaServicosPorModo> {
  String _search = '';
  ServicoSearchIndex<Servico>? _searchIndex;
  String _searchKey = '';

  void _ensureSearchIndex() {
    final list = widget.servicos;
    final key = list.isEmpty
        ? 'empty'
        : '${list.length}:${list.first.id}:${list.last.id}';
    if (_searchIndex != null && _searchKey == key) return;
    _searchKey = key;
    _searchIndex = ServicoSearchIndex<Servico>(
      items: list,
      id: (s) => s.id,
      name: (s) => s.name,
      keywords: (s) => s.keywords,
      mode: (s) => s.mode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final targetMode = _normalizeServicoMode(widget.modo);
    final query = _search.trim();
    final filtered = query.isEmpty
        ? widget.servicos
            .where((s) => _normalizeServicoMode(s.mode) == targetMode)
            .toList()
        : (() {
            _ensureSearchIndex();
            final results =
                _searchIndex?.search(query, limit: 300) ?? const <Servico>[];
            return results
                .where((s) => _normalizeServicoMode(s.mode) == targetMode)
                .toList();
          })();

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.serviceSearchHint,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.serviceSearchEmpty,
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final servico = filtered[index];
                    return _ServicoCard(
                      servico: servico,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NovoPedidoScreen(
                              modo: widget.modo,
                              servicoInicial: servico,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ServicoCard extends StatelessWidget {
  final Servico servico;
  final VoidCallback onTap;

  const _ServicoCard({
    required this.servico,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final icon = _mapIcon(servico.iconKey);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade100,
              child: Icon(icon, color: Colors.grey.shade800),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    servico.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _descricaoModo(servico.mode, l10n),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

String _descricaoModo(String mode, AppLocalizations l10n) {
  switch (mode) {
    case 'IMEDIATO':
      return l10n.serviceModeImmediateDescription;
    case 'AGENDADO':
      return l10n.serviceModeScheduledDescription;
    case 'POR_PROPOSTA':
      return l10n.serviceModeQuoteDescription;
    default:
      return mode;
  }
}

IconData _mapIcon(String? iconKey) {
  switch (iconKey) {
    case 'cleaning':
      return Icons.cleaning_services_outlined;
    case 'plumber':
      return Icons.plumbing_outlined;
    case 'electric':
      return Icons.flash_on_outlined;
    case 'move':
      return Icons.local_shipping_outlined;
    case 'pet':
      return Icons.pets_outlined;
    default:
      return Icons.miscellaneous_services_outlined;
  }
}

/// ---------- ABA "PEDIDOS" ----------

class _ClientePedidosTab extends StatelessWidget {
  final Stream<List<Pedido>>? pedidosStream;

  const _ClientePedidosTab({this.pedidosStream});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;
    if (user == null) {
      return Center(child: Text(l10n.userNotAuthenticatedError));
    }

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.myOrdersTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TabBar(
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: l10n.ordersTabPending),
                Tab(text: l10n.ordersTabCompleted),
                Tab(text: l10n.ordersTabCancelled),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Pedido>>(
                stream: pedidosStream ??
                    PedidosRepo.streamPedidosDoCliente(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        l10n.ordersLoadError(
                          snapshot.error.toString(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final pedidos = snapshot.data ?? [];

                  final pendentes = pedidos
                      .where((p) => p.estado != 'concluido' && p.estado != 'cancelado')
                      .toList();
                  final concluidos = pedidos.where((p) => p.estado == 'concluido').toList();
                  final cancelados = pedidos.where((p) => p.estado == 'cancelado').toList();

                  pendentes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  concluidos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  cancelados.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return TabBarView(
                    children: [
                      _ListaPedidosCliente(
                        pedidos: pendentes,
                        mensagemVazio: l10n.ordersEmptyPending,
                      ),
                      _ListaPedidosCliente(
                        pedidos: concluidos,
                        mensagemVazio: l10n.ordersEmptyCompleted,
                      ),
                      _ListaPedidosCliente(
                        pedidos: cancelados,
                        mensagemVazio: l10n.ordersEmptyCancelled,
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

class _ListaPedidosCliente extends StatelessWidget {
  final List<Pedido> pedidos;
  final String mensagemVazio;

  const _ListaPedidosCliente({
    required this.pedidos,
    required this.mensagemVazio,
  });

  @override
  Widget build(BuildContext context) {
    if (pedidos.isEmpty) {
      return Center(child: Text(mensagemVazio, textAlign: TextAlign.center));
    }

    return ListView.separated(
      itemCount: pedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        return _PedidoClienteCard(pedido: pedido);
      },
    );
  }
}

class _PedidoClienteCard extends StatelessWidget {
  final Pedido pedido;

  const _PedidoClienteCard({required this.pedido});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String subtitulo;
    if (pedido.tipoPreco == 'por_orcamento') {
      subtitulo = pedido.modo == 'AGENDADO'
          ? l10n.orderQuoteScheduled
          : l10n.orderQuoteImmediate;
    } else if (pedido.modo == 'AGENDADO') {
      subtitulo = l10n.orderScheduled;
    } else {
      subtitulo = l10n.orderImmediate;
    }

    final estadoLabel = _labelEstadoCliente(pedido, l10n);
    final valorLabel = _buildValorLabelLista(pedido, l10n);

    final acaoPendente = _temAcaoPendente(pedido);
    final textoAcao = _textoAcaoPendente(pedido, l10n);

    final tipoPrecoLabel = _labelTipoPrecoCliente(pedido.tipoPreco, l10n);
    final tipoPagamentoLabel = _labelTipoPagamentoCliente(pedido.tipoPagamento, l10n);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
                const Icon(Icons.assignment_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pedido.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              pedido.categoria ?? l10n.categoryNotDefined,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.orderStateLabel(estadoLabel),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.orderPriceModelLabel(tipoPrecoLabel),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.orderPaymentLabel(tipoPagamentoLabel),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.orderValueLabel(valorLabel),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            if (acaoPendente) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      textoAcao,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            PedidoChatPreview(
              pedidoId: pedido.id,
              viewerRole: 'cliente',
            ),
          ],
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
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountTitle(roleLabel),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(l10n.accountNameTitle),
            subtitle: Text(l10n.accountProfileSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ClientePerfilScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.accountSettings),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.accountHelpSupport),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
