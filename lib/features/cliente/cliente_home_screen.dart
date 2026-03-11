// lib/features/cliente/cliente_home_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

import 'package:chegaja_v2/features/common/smart_search_bar.dart';
import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/repositories/servico_repo.dart';
import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/core/services/location_data_service.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/utils/currency_utils.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_chip.dart';
import 'package:chegaja_v2/core/widgets/app_list_tile.dart';
import 'package:chegaja_v2/core/widgets/app_shell_scaffold.dart';
import 'package:chegaja_v2/core/widgets/app_state_views.dart';
import 'package:chegaja_v2/core/widgets/app_tab_bar.dart';
import 'package:chegaja_v2/features/cliente/prestador_search_delegate.dart';
import 'package:chegaja_v2/features/common/widgets/region_selection_widget.dart';

import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/features/cliente/cliente_perfil_screen.dart';
import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';
import 'package:chegaja_v2/features/common/pedido_chat_preview.dart';
import 'package:chegaja_v2/features/common/mensagens/mensagens_tab.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';
import 'package:chegaja_v2/features/common/widgets/stories_carousel_widget.dart';
import 'package:chegaja_v2/core/widgets/theme_mode_selector_tile.dart';
import 'package:chegaja_v2/features/common/suporte_screen.dart';
import 'package:chegaja_v2/features/admin/admin_panel_screen.dart';

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
  final currency = CurrencyUtils.formatter(localeName: l10n.localeName);
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

Future<String?> _loadRegionLabel() async {
  final code = await AuthService.getUserRegion();
  if (code == null || code.trim().isEmpty) return null;

  final normalized = code.trim().toUpperCase();
  final countries = await LocationDataService.instance.getCountries();
  for (final c in countries) {
    if (c.isoCode.toUpperCase() == normalized) {
      final flag = c.flag.trim();
      return flag.isNotEmpty ? '${c.name} $flag' : c.name;
    }
  }
  return normalized;
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
  String? _activeClienteUid;
  StreamSubscription<User?>? _authSub;
  bool _isEnsuringClienteSession = false;

  // badge de mensagens não lidas
  StreamSubscription<List<Pedido>>? _pedidosSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _chatSubs = {};
  final Map<String, bool> _unreadPorPedido = {};
  bool _hasUnreadMessages = false;
  Stream<List<Pedido>>? _pedidosClienteStream;
  Stream<List<Servico>>? _servicosStream;

  @override
  void initState() {
    super.initState();
    unawaited(_ensureClienteSession());
    _servicosStream ??= ServicosRepo.streamServicosAtivos();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _syncClienteStreams();
    });
    _syncClienteStreams();
  }

  Future<void> _ensureClienteSession() async {
    if (_isEnsuringClienteSession) return;
    _isEnsuringClienteSession = true;

    try {
      await AuthService.ensureSignedInAnonymously().timeout(
        const Duration(seconds: 12),
      );
      await AuthService.setActiveRole('cliente');
    } catch (error) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[ClienteHome] auth bootstrap error: $error');
      }
    } finally {
      _isEnsuringClienteSession = false;
    }
  }

  void _syncClienteStreams() {
    final user = AuthService.currentUser;
    if (user == null) {
      _resetClienteStreams();
      unawaited(_ensureClienteSession());
      return;
    }

    final uid = user.uid;
    if (_activeClienteUid == uid && _pedidosClienteStream != null) {
      _servicosStream ??= ServicosRepo.streamServicosAtivos();
      return;
    }

    _resetClienteStreams();
    _activeClienteUid = uid;
    // Keep UI and internal badge tracking on independent streams.
    // This avoids a stalled UI stream when one listener receives an error first.
    _pedidosClienteStream = PedidosRepo.streamPedidosDoCliente(uid);
    _pedidosSub = PedidosRepo.streamPedidosDoCliente(uid).listen(
      _onPedidosUpdate,
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[ClienteHome] pedidosSub error: $error');
        }
      },
    );
    _servicosStream ??= ServicosRepo.streamServicosAtivos();
  }

  void _resetClienteStreams() {
    _pedidosSub?.cancel();
    _pedidosSub = null;
    for (final sub in _chatSubs.values) {
      sub.cancel();
    }
    _chatSubs.clear();
    _unreadPorPedido.clear();
    _hasUnreadMessages = false;
    _pedidosClienteStream = null;
    _activeClienteUid = null;
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
          onError: (Object error, StackTrace stackTrace) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('[ClienteHome] chatSub(${p.id}) error: $error');
            }
          },
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
    _authSub?.cancel();
    _resetClienteStreams();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _syncClienteStreams();
    _servicosStream ??= ServicosRepo.streamServicosAtivos();
    return AppShellScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: [
        AppShellDestination(
          label: l10n.navHome,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          child: _ClienteInicioTab(
            pedidosStream: _pedidosClienteStream,
            servicosStream: _servicosStream,
          ),
        ),
        AppShellDestination(
          label: l10n.navMyOrders,
          icon: Icons.list_alt_outlined,
          selectedIcon: Icons.list_alt,
          child: _ClientePedidosTab(pedidosStream: _pedidosClienteStream),
        ),
        AppShellDestination(
          label: l10n.navMessages,
          icon: Icons.chat_bubble_outline,
          selectedIcon: Icons.chat_bubble,
          showBadge: _hasUnreadMessages,
          child: const MensagensTab(viewerRole: 'cliente'),
        ),
        AppShellDestination(
          label: l10n.navProfile,
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          child: _ContaTab(roleLabel: l10n.roleLabelCustomer),
        ),
      ],
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final double tabHeight = constraints.maxHeight * 0.62;
        final double maxWidth = constraints.maxWidth > AppBreakpoints.tabletMax
            ? AppBreakpoints.contentMaxTwoColumn
            : AppBreakpoints.contentMaxSingleColumn;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x5,
            AppSpacing.x5,
            AppSpacing.x2,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.homeGreeting,
                        style: theme.textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: 'Pesquisar Prestadores',
                        onPressed: () {
                          showSearch(
                            context: context,
                            delegate: PrestadorSearchDelegate(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    l10n.homeSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  if (user != null)
                    StreamBuilder<List<Pedido>>(
                      stream: pedidosStream ??
                          PedidosRepo.streamPedidosDoCliente(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasError) {
                          return const SizedBox.shrink();
                        }

                        final pedidos = snapshot.data ?? [];
                        final pendentes = pedidos
                            .where(_temAcaoPendente)
                            .toList()
                          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                        final pedido =
                            pendentes.isNotEmpty ? pendentes.first : null;
                        if (pedido == null) return const SizedBox.shrink();

                        return AppCard(
                          variant: AppCardVariant.flat,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PedidoDetalheScreen(pedidoId: pedido.id),
                              ),
                            );
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.notifications_active_outlined,
                                size: 22,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.x3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.homePendingTitle,
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: AppSpacing.x1),
                                    Text(
                                      _textoAcaoPendente(pedido, l10n),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.x1),
                                    Text(
                                      l10n.homePendingCta,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.x2),
                  const StoriesCarouselWidget(),
                  const SizedBox(height: AppSpacing.x2),
                  if (user != null)
                    _ClienteMensagensBanner(clienteId: user.uid),
                  const SizedBox(height: AppSpacing.x4),
                  SizedBox(
                    height: tabHeight,
                    child: StreamBuilder<List<Servico>>(
                      stream:
                          servicosStream ?? ServicosRepo.streamServicosAtivos(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const AppLoadingView();
                        }

                        if (snapshot.hasError) {
                          return AppErrorView(
                            message: l10n.servicesLoadError(
                              snapshot.error.toString(),
                            ),
                          );
                        }

                        final servicos = snapshot.data ?? [];
                        if (servicos.isEmpty) {
                          return AppEmptyView(
                            title: l10n.availableServicesTitle,
                            message: l10n.servicesEmptyMessage,
                          );
                        }

                        final modos = <String>[
                          'ORCAMENTO',
                          'AGENDADO',
                          'IMEDIATO',
                        ];

                        return DefaultTabController(
                          length: modos.length,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.x2),
                              Text(
                                l10n.availableServicesTitle,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.x2),
                              AppTabBar(
                                isScrollable: true,
                                tabs: [
                                  Tab(text: l10n.serviceTabQuote),
                                  Tab(text: l10n.serviceTabScheduled),
                                  Tab(text: l10n.serviceTabImmediate),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.x2),
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
  State<_ClienteMensagensBanner> createState() =>
      _ClienteMensagensBannerState();
}

class _ClienteMensagensBannerState extends State<_ClienteMensagensBanner> {
  StreamSubscription<List<Pedido>>? _pedidosSub;

  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _chatSubs = {};
  final Map<String, bool> _unreadPorPedido = {};
  final Map<String, DateTime?> _lastUnreadAtPorPedido = {};
  final Map<String, Pedido> _pedidoPorId = {};

  bool _hasUnread = false;
  Pedido? _pedidoMaisRecente;

  @override
  void initState() {
    super.initState();
    _pedidosSub = PedidosRepo.streamPedidosDoCliente(widget.clienteId)
        .listen(_onPedidosUpdate);
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
          onError: (Object error, StackTrace stackTrace) {
            _unreadPorPedido[p.id] = false;
            _lastUnreadAtPorPedido[p.id] = null;
            _recalculateGlobal();
            if (kDebugMode) {
              // ignore: avoid_print
              print('[ClienteHomeBanner] chatSub(${p.id}) error: $error');
            }
          },
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
      _pedidoMaisRecente =
          bestPedidoId != null ? _pedidoPorId[bestPedidoId] : null;
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
    if (!_hasUnread || _pedidoMaisRecente == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final pedido = _pedidoMaisRecente!;

    return AppCard(
      variant: AppCardVariant.flat,
      onTap: () async {
        await ChatService.instance.ensureChatMetaForPedido(pedido.id);

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
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
            ),
          );
          return;
        }

        await Navigator.of(context).push(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.mark_chat_unread_outlined,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.unreadMessagesTitle,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  l10n.unreadMessagesCta,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
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
  // O SmartSearchBar gere a pesquisa agpra. A lista abaixo mostra tudo por defeito.

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final targetMode = _normalizeServicoMode(widget.modo);

    // Mostra apenas a lista completa filtrada pelo modo (Tab atual)
    final filtered = widget.servicos
        .where((s) => _normalizeServicoMode(s.mode) == targetMode)
        .toList();

    return Column(
      children: [
        SmartSearchBar<Servico>(
          hintText: l10n.serviceSearchHint,
          allItems: widget.servicos
              .where((s) => _normalizeServicoMode(s.mode) == targetMode)
              .toList(),
          idSelector: (s) => s.id,
          nameSelector: (s) => s.name,
          keywordsSelector: (s) => s.keywords,
          onItemSelected: (servico) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NovoPedidoScreen(
                  modo: widget.modo,
                  servicoInicial: servico,
                ),
              ),
            );
          },
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
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final icon = _mapIcon(servico.iconKey);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servico.nameForLang(locale.languageCode),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.x1),
                AppChip(
                  label: _descricaoModo(servico.mode, l10n),
                  variant: AppChipVariant.choice,
                  size: AppChipSize.sm,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
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
    final theme = Theme.of(context);
    final user = AuthService.currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
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
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.x3),
            AppTabBar(
              tabs: [
                Tab(text: l10n.ordersTabPending),
                Tab(text: l10n.ordersTabCompleted),
                Tab(text: l10n.ordersTabCancelled),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            Expanded(
              child: StreamBuilder<List<Pedido>>(
                initialData: const <Pedido>[],
                stream: (pedidosStream ??
                        PedidosRepo.streamPedidosDoCliente(user.uid))
                    .timeout(
                  const Duration(seconds: 12),
                  onTimeout: (sink) {
                    if (kDebugMode) {
                      // ignore: avoid_print
                      print('[ClientePedidosTab] stream timeout -> empty list');
                    }
                    sink.add(const <Pedido>[]);
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
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
                      .where(
                        (p) =>
                            p.estado != 'concluido' && p.estado != 'cancelado',
                      )
                      .toList();
                  final concluidos =
                      pedidos.where((p) => p.estado == 'concluido').toList();
                  final cancelados =
                      pedidos.where((p) => p.estado == 'cancelado').toList();

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
    final theme = Theme.of(context);
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
    final tipoPagamentoLabel =
        _labelTipoPagamentoCliente(pedido.tipoPagamento, l10n);

    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  pedido.titulo,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            pedido.categoria ?? l10n.categoryNotDefined,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            subtitulo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              AppChip(
                label: estadoLabel,
                variant: AppChipVariant.status,
                size: AppChipSize.sm,
              ),
              AppChip(
                label: tipoPrecoLabel,
                variant: AppChipVariant.choice,
                size: AppChipSize.sm,
              ),
              AppChip(
                label: tipoPagamentoLabel,
                variant: AppChipVariant.filter,
                size: AppChipSize.sm,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l10n.orderValueLabel(valorLabel),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (acaoPendente) ...[
            const SizedBox(height: AppSpacing.x2),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppPalette.warning,
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: Text(
                    textoAcao,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppPalette.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.x2),
          PedidoChatPreview(
            pedidoId: pedido.id,
            viewerRole: 'cliente',
          ),
        ],
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
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > AppBreakpoints.tabletMax
            ? AppBreakpoints.contentMaxSingleColumn
            : double.infinity;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x5,
            AppSpacing.x5,
            AppSpacing.x6,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountTitle(roleLabel),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  AppCard(
                    child: Column(
                      children: [
                        AppListTile(
                          title: Text(l10n.accountNameTitle),
                          subtitle: Text(l10n.accountProfileSubtitle),
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ClientePerfilScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        AppListTile(
                          title: const Text('País / Região'),
                          subtitle: FutureBuilder<String?>(
                            future: _loadRegionLabel(),
                            builder: (context, snapshot) {
                              final label = snapshot.data;
                              if (label != null && label.trim().isNotEmpty) {
                                return Text(label);
                              }
                              return const Text('Selecionar...');
                            },
                          ),
                          leading: const Icon(Icons.public),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await RegionSelectionWidget.show(context);
                          },
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        const ThemeModeSelectorTile(
                          title: 'Tema',
                          systemLabel: 'Sistema',
                          lightLabel: 'Claro',
                          darkLabel: 'Escuro',
                        ),
                        const Divider(height: AppSpacing.x5),
                        AppListTile(
                          title: Text(l10n.accountSettings),
                          leading: const Icon(Icons.settings_outlined),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        AppListTile(
                          title: Text(l10n.accountHelpSupport),
                          leading: const Icon(Icons.help_outline),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SuporteScreen(userType: 'cliente'),
                              ),
                            );
                          },
                        ),
                        FutureBuilder<IdTokenResult?>(
                          future: FirebaseAuth.instance.currentUser
                              ?.getIdTokenResult(),
                          builder: (context, snapshot) {
                            final claims = snapshot.data?.claims ??
                                const <String, dynamic>{};
                            final isAdmin = claims['admin'] == true ||
                                AppConfig.useFirebaseEmulators;
                            if (!isAdmin) return const SizedBox.shrink();
                            return Column(
                              children: [
                                const SizedBox(height: AppSpacing.x2),
                                AppListTile(
                                  title: const Text('Backoffice Admin'),
                                  subtitle: const Text(
                                      'Métricas, suporte e moderação'),
                                  leading: const Icon(
                                      Icons.admin_panel_settings_outlined),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminPanelScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
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
    );
  }
}
