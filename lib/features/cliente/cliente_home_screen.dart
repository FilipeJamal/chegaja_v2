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
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_content_shell.dart';
import 'package:chegaja_v2/core/widgets/app_list_tile.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_shell_scaffold.dart';
import 'package:chegaja_v2/core/widgets/app_state_views.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/core/widgets/app_tab_bar.dart';
import 'package:chegaja_v2/features/cliente/prestador_search_delegate.dart';
import 'package:chegaja_v2/features/common/widgets/region_selection_widget.dart';

import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/features/cliente/cliente_perfil_screen.dart';
import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_empty_state.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:chegaja_v2/features/common/pedido_chat_preview.dart';
import 'package:chegaja_v2/features/common/mensagens/mensagens_tab.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';
import 'package:chegaja_v2/features/common/widgets/stories_carousel_widget.dart';
import 'package:chegaja_v2/core/widgets/theme_mode_selector_tile.dart';
import 'package:chegaja_v2/features/common/suporte_screen.dart';
import 'package:chegaja_v2/features/admin/admin_panel_screen.dart';

final GlobalKey _clienteServicesAnchorKey = GlobalKey(
  debugLabel: 'cliente_home_services_anchor',
);

/// ---------- HELPERS GERAIS PARA A ABA "PEDIDOS" ----------

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

Duration _clienteAuthBootstrapTimeout() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    return const Duration(seconds: 45);
  }
  return const Duration(seconds: 12);
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
        _clienteAuthBootstrapTimeout(),
      );
      await AuthService.setActiveRole('cliente');
      if (mounted) {
        setState(_syncClienteStreams);
      }
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
    _servicosStream = null;
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
    final user = AuthService.currentUser;
    return AppPageScaffold(
      width: AppContentWidth.dashboard,
      child: _ClienteHomeDashboard(
        pedidosStream: pedidosStream,
        servicosStream: servicosStream,
        user: user,
        onSearch: () {
          showSearch(
            context: context,
            delegate: PrestadorSearchDelegate(),
          );
        },
      ),
    );
  }
}

class _ClienteHomeDashboard extends StatelessWidget {
  const _ClienteHomeDashboard({
    required this.pedidosStream,
    required this.servicosStream,
    required this.user,
    required this.onSearch,
  });

  final Stream<List<Pedido>>? pedidosStream;
  final Stream<List<Servico>>? servicosStream;
  final User? user;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.desktopMin;
        final mainColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClienteHomeHero(
              greeting: l10n.homeGreeting,
              title: l10n.homeSubtitle,
              subtitle:
                  'Escolhe um servico, acompanha propostas e fala com o prestador sem perder contexto.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () => _scrollToServices(context),
              onSearch: onSearch,
            ),
            const SizedBox(height: AppSpacing.x5),
            const StoriesCarouselWidget(),
            const SizedBox(height: AppSpacing.x5),
            _ClienteServicesStreamSection(
              user: user,
              servicosStream: servicosStream,
            ),
          ],
        );

        final sideColumn = _ClienteHomeSideColumn(
          user: user,
          pedidosStream: pedidosStream,
        );

        if (!isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mainColumn,
              const SizedBox(height: AppSpacing.x5),
              sideColumn,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: mainColumn),
            const SizedBox(width: AppSpacing.x6),
            Expanded(flex: 4, child: sideColumn),
          ],
        );
      },
    );
  }
}

void _scrollToServices(BuildContext context) {
  final targetContext = _clienteServicesAnchorKey.currentContext;
  if (targetContext == null) return;
  Scrollable.ensureVisible(
    targetContext,
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
  );
}

class _ClienteServicesStreamSection extends StatelessWidget {
  const _ClienteServicesStreamSection({
    required this.user,
    required this.servicosStream,
  });

  final User? user;
  final Stream<List<Servico>>? servicosStream;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return const AppLoadingView(label: 'A preparar a tua area de cliente...');
    }

    return StreamBuilder<List<Servico>>(
      stream: servicosStream ?? ServicosRepo.streamServicosAtivos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingView(
            label: 'A carregar servicos disponiveis...',
          );
        }

        if (snapshot.hasError) {
          return const AppErrorView(
            message:
                'Nao conseguimos carregar os servicos agora. Verifica a ligacao e tenta novamente.',
          );
        }

        final servicos = snapshot.data ?? const <Servico>[];
        if (servicos.isEmpty) {
          return const ClienteHomeEmptyServices();
        }

        return _ClienteServicesCatalog(
          key: _clienteServicesAnchorKey,
          servicos: servicos,
          title: l10n.availableServicesTitle,
          subtitle:
              'Escolhe uma categoria para iniciar um pedido com mais contexto.',
        );
      },
    );
  }
}

class _ClienteServicesCatalog extends StatefulWidget {
  const _ClienteServicesCatalog({
    super.key,
    required this.servicos,
    required this.title,
    required this.subtitle,
  });

  final List<Servico> servicos;
  final String title;
  final String subtitle;

  @override
  State<_ClienteServicesCatalog> createState() =>
      _ClienteServicesCatalogState();
}

class _ClienteServicesCatalogState extends State<_ClienteServicesCatalog> {
  String _selectedMode = 'ORCAMENTO';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final modes = <String, String>{
      'ORCAMENTO': l10n.serviceTabQuote,
      'AGENDADO': l10n.serviceTabScheduled,
      'IMEDIATO': l10n.serviceTabImmediate,
    };

    final filtered = widget.servicos
        .where(
          (servico) => _normalizeServicoMode(servico.mode) == _selectedMode,
        )
        .toList();

    return ClienteServicesSection(
      title: widget.title,
      subtitle: widget.subtitle,
      search: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SmartSearchBar<Servico>(
            hintText: l10n.serviceSearchHint,
            allItems: filtered,
            idSelector: (s) => s.id,
            nameSelector: (s) => s.name,
            keywordsSelector: (s) => s.keywords,
            onItemSelected: (servico) => _openNovoPedido(
              context: context,
              modo: _selectedMode,
              servico: servico,
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final entry in modes.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _selectedMode == entry.key,
                  onSelected: (_) => setState(() => _selectedMode = entry.key),
                ),
            ],
          ),
        ],
      ),
      children: [
        if (filtered.isEmpty)
          const ClienteHomeEmptyServices()
        else
          for (final servico in filtered)
            ClienteServiceTile(
              servico: servico,
              localeCode: locale.languageCode,
              modeLabel: modes[_selectedMode] ?? _selectedMode,
              onTap: () => _openNovoPedido(
                context: context,
                modo: _selectedMode,
                servico: servico,
              ),
            ),
      ],
    );
  }

  void _openNovoPedido({
    required BuildContext context,
    required String modo,
    required Servico servico,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NovoPedidoScreen(
          modo: modo,
          servicoInicial: servico,
        ),
      ),
    );
  }
}

class _ClienteHomeSideColumn extends StatelessWidget {
  const _ClienteHomeSideColumn({
    required this.user,
    required this.pedidosStream,
  });

  final User? user;
  final Stream<List<Pedido>>? pedidosStream;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClientePendingActionPanel(
          clienteId: user!.uid,
          pedidosStream: pedidosStream,
        ),
        const SizedBox(height: AppSpacing.x4),
        _ClienteActiveOrdersPanel(
          clienteId: user!.uid,
          pedidosStream: pedidosStream,
        ),
        const SizedBox(height: AppSpacing.x4),
        _ClienteMensagensBanner(clienteId: user!.uid),
      ],
    );
  }
}

class _ClientePendingActionPanel extends StatelessWidget {
  const _ClientePendingActionPanel({
    required this.clienteId,
    required this.pedidosStream,
  });

  final String clienteId;
  final Stream<List<Pedido>>? pedidosStream;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Pedido>>(
      stream: pedidosStream ?? PedidosRepo.streamPedidosDoCliente(clienteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final pendentes = (snapshot.data ?? const <Pedido>[])
            .where(_temAcaoPendente)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (pendentes.isEmpty) return const SizedBox.shrink();
        final pedido = pendentes.first;

        return ClienteHomeOperationsPanel(
          title: l10n.homePendingTitle,
          message: _textoAcaoPendente(pedido, l10n),
          actionLabel: l10n.homePendingCta,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
            ),
          ),
        );
      },
    );
  }
}

class _ClienteActiveOrdersPanel extends StatelessWidget {
  const _ClienteActiveOrdersPanel({
    required this.clienteId,
    required this.pedidosStream,
  });

  final String clienteId;
  final Stream<List<Pedido>>? pedidosStream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<Pedido>>(
      stream: pedidosStream ?? PedidosRepo.streamPedidosDoCliente(clienteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final ativos = (snapshot.data ?? const <Pedido>[])
            .where((pedido) => !_pedidoEstaFinalizado(pedido))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (ativos.isEmpty) {
          return const AppActionPanel(
            key: Key('cliente_home_active_orders_panel'),
            title: 'Sem pedidos ativos',
            message:
                'Quando criares um pedido, acompanhas aqui o proximo passo.',
            icon: Icons.receipt_long_outlined,
            tone: AppStatusTone.neutral,
          );
        }

        final pedido = ativos.first;
        final cardData = PedidoListPresenter.dataFor(
          pedido,
          role: PedidoViewerRole.cliente,
        );

        return Column(
          key: const Key('cliente_home_active_orders_panel'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Pedido em curso',
              subtitle: 'Continua de onde paraste.',
              dense: true,
              trailing: ativos.length > 1
                  ? AppStatusPill(
                      label: '${ativos.length} ativos',
                      tone: AppStatusTone.info,
                      size: AppStatusPillSize.sm,
                    )
                  : null,
            ),
            PedidoListCard(
              data: cardData,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
                ),
              ),
            ),
            if (ativos.length > 1) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(
                'Ve mais pedidos na aba Pedidos.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

bool _pedidoEstaFinalizado(Pedido pedido) {
  final status = pedido.status.toLowerCase().trim();
  final estado = pedido.estado.toLowerCase().trim();
  return status == 'concluido' ||
      status == 'cancelado' ||
      estado == 'concluido' ||
      estado == 'cancelado';
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

    final pedido = _pedidoMaisRecente!;

    return ClienteHomeMessagesPanel(
      title: l10n.unreadMessagesTitle,
      message: l10n.unreadMessagesCta,
      actionLabel: l10n.unreadMessagesCta,
      onAction: () async {
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
    );
  }
}

/// ---------- LISTA SERVIÇOS ----------

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
                    return const AppLoadingView(label: 'A carregar pedidos...');
                  }
                  if (snapshot.hasError) {
                    if (kDebugMode) {
                      // ignore: avoid_print
                      print(
                        '[ClientePedidosTab] stream error: ${snapshot.error}',
                      );
                    }
                    return const AppErrorView(
                      message:
                          'Nao conseguimos carregar os pedidos agora. Tenta novamente daqui a pouco.',
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
                        emptyTitle: 'Sem pedidos ativos',
                        emptyMessage:
                            'Quando criares um pedido, ele aparece aqui ate ser concluido ou cancelado.',
                      ),
                      _ListaPedidosCliente(
                        pedidos: concluidos,
                        emptyTitle: 'Sem pedidos concluidos',
                        emptyMessage:
                            'Os pedidos concluidos ficam guardados aqui para consulta.',
                      ),
                      _ListaPedidosCliente(
                        pedidos: cancelados,
                        emptyTitle: 'Sem pedidos cancelados',
                        emptyMessage:
                            'Pedidos cancelados aparecem aqui quando existirem.',
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
  final String emptyTitle;
  final String emptyMessage;

  const _ListaPedidosCliente({
    required this.pedidos,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (pedidos.isEmpty) {
      return PedidoEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: Icons.assignment_outlined,
      );
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
    final tipoPrecoLabel = _labelTipoPrecoCliente(pedido.tipoPreco, l10n);
    final tipoPagamentoLabel =
        _labelTipoPagamentoCliente(pedido.tipoPagamento, l10n);
    final listData = PedidoListPresenter.dataFor(
      pedido,
      role: PedidoViewerRole.cliente,
      localeName: l10n.localeName,
    );

    return PedidoListCard(
      data: listData,
      metaLabels: [
        tipoPrecoLabel,
        tipoPagamentoLabel,
      ],
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
          ),
        );
      },
      footer: PedidoChatPreview(
        pedidoId: pedido.id,
        viewerRole: 'cliente',
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
