// lib/features/cliente/cliente_home_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

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
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_content_shell.dart';
import 'package:chegaja_v2/core/widgets/app_list_tile.dart';
import 'package:chegaja_v2/core/widgets/app_metric_tile.dart';
import 'package:chegaja_v2/core/widgets/app_product_header.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_segmented_tabs.dart';
import 'package:chegaja_v2/core/widgets/app_shell_scaffold.dart';
import 'package:chegaja_v2/core/widgets/app_state_views.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_screen.dart';
import 'package:chegaja_v2/features/cliente/discovery/widgets/provider_suggestions_section.dart';
import 'package:chegaja_v2/features/common/widgets/region_selection_widget.dart';
import 'package:chegaja_v2/features/common/widgets/account_profile_summary.dart';
import 'package:chegaja_v2/features/common/widgets/role_mode_switch_tile.dart';
import 'package:chegaja_v2/features/common/widgets/settings_list_tile.dart';

import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/features/cliente/cliente_perfil_screen.dart';
import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_empty_state.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_service_catalog_search.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:chegaja_v2/features/common/pedido_chat_preview.dart';
import 'package:chegaja_v2/features/common/mensagens/mensagens_tab.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';
import 'package:chegaja_v2/features/common/widgets/stories_carousel_widget.dart';
import 'package:chegaja_v2/core/widgets/theme_mode_selector_tile.dart';
import 'package:chegaja_v2/features/common/suporte_screen.dart';
import 'package:chegaja_v2/features/common/permission_settings_screen.dart';
import 'package:chegaja_v2/features/admin/admin_panel_screen.dart';

final GlobalKey _clienteServicesAnchorKey = GlobalKey(
  debugLabel: 'cliente_home_services_anchor',
);

const bool _disableClienteHomeMessageStreamsForEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

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
      if (!mounted) return;
      setState(_syncClienteStreams);
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
      if (AuthService.currentUser != null && mounted) {
        unawaited(AuthService.setActiveRole('cliente'));
        setState(_syncClienteStreams);
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
    if (_disableClienteHomeMessageStreamsForEmulatorTests) {
      for (final id in _chatSubs.keys.toList()) {
        _cancelChatSub(id);
      }
      _unreadPorPedido.clear();
      if (mounted && _hasUnreadMessages) {
        setState(() => _hasUnreadMessages = false);
      }
      return;
    }

    final ativos = pedidos
        .where((p) => p.estado != 'concluido' && p.estado != 'cancelado')
        .toList();
    final idsAtivos = ativos.map((p) => p.id).toSet();

    final idsParaRemover =
        _chatSubs.keys.where((id) => !idsAtivos.contains(id)).toList();
    for (final id in idsParaRemover) {
      _cancelChatSub(id);
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
            _cancelChatSub(p.id);
            if (kDebugMode) {
              // ignore: avoid_print
              print('[ClienteHome] chatSub(${p.id}) error: $error');
            }
          },
        );
      }
    }
  }

  void _cancelChatSub(String pedidoId) {
    final sub = _chatSubs.remove(pedidoId);
    if (sub != null) {
      unawaited(sub.cancel());
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
            onOpenOrders: () => setState(() => _currentIndex = 1),
            onOpenMessages: () => setState(() => _currentIndex = 2),
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
          child: _ContaPremiumTab(roleLabel: l10n.roleLabelCustomer),
        ),
      ],
    );
  }
}

/// ---------- ABA "INÍCIO" ----------

class _ClienteInicioTab extends StatelessWidget {
  final Stream<List<Pedido>>? pedidosStream;
  final Stream<List<Servico>>? servicosStream;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenMessages;

  const _ClienteInicioTab({
    this.pedidosStream,
    this.servicosStream,
    required this.onOpenOrders,
    required this.onOpenMessages,
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
        onOpenOrders: onOpenOrders,
        onOpenMessages: onOpenMessages,
        onSearch: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProviderSearchScreen(),
            ),
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
    required this.onOpenOrders,
    required this.onOpenMessages,
    required this.onSearch,
  });

  final Stream<List<Pedido>>? pedidosStream;
  final Stream<List<Servico>>? servicosStream;
  final User? user;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenMessages;
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
              subtitle: AppConfig.pilotMode
                  ? 'Piloto em Maputo e Matola: limpeza, beleza, alimentação, reparações, tecnologia e eventos em destaque; o catálogo continua aberto.'
                  : 'Escolhe um servico, acompanha propostas e fala com o prestador sem perder contexto.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () => _scrollToServices(context),
              onSearch: onSearch,
            ),
            ProviderSuggestionsSection(
              margin: const EdgeInsets.only(
                top: AppSpacing.x5,
                bottom: AppSpacing.x5,
              ),
              onOpenSearch: onSearch,
            ),
            const SizedBox(height: AppSpacing.x5),
            if (AppConfig.storiesEnabled) ...[
              const StoriesCarouselWidget(),
              const SizedBox(height: AppSpacing.x5),
            ],
            _ClienteServicesStreamSection(
              user: user,
              servicosStream: servicosStream,
            ),
          ],
        );

        final sideColumn = _ClienteHomeSideColumn(
          user: user,
          pedidosStream: pedidosStream,
          onOpenOrders: onOpenOrders,
          onOpenMessages: onOpenMessages,
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
          return const ClienteServicesLoadingPreview();
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
  static const int _initialVisibleServices = 24;
  static const int _visibleServicesStep = 24;
  static const Duration _searchDebounce = Duration(milliseconds: 180);

  final TextEditingController _serviceSearchController =
      TextEditingController();
  Timer? _serviceSearchDebounce;
  String _selectedMode = 'ORCAMENTO';
  String _serviceQuery = '';
  int _visibleLimit = _initialVisibleServices;

  @override
  void dispose() {
    _serviceSearchDebounce?.cancel();
    _serviceSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final modes = <String, String>{
      'ORCAMENTO': l10n.serviceTabQuote,
      'AGENDADO': l10n.serviceTabScheduled,
      'IMEDIATO': l10n.serviceTabImmediate,
    };

    final catalog = visibleClienteCatalogServices(
      services: widget.servicos,
      selectedMode: _selectedMode,
      query: _serviceQuery,
      limit: _visibleLimit,
    );
    final visibleServices = catalog.services;

    return ClienteServicesSection(
      title: widget.title,
      subtitle: widget.subtitle,
      search: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildServiceSearchField(context, l10n),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final entry in modes.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _selectedMode == entry.key,
                  onSelected: (_) => setState(() {
                    _selectedMode = entry.key;
                    _visibleLimit = _initialVisibleServices;
                    _serviceQuery = '';
                    _serviceSearchController.clear();
                  }),
                ),
            ],
          ),
          if (catalog.isSearching || catalog.isTruncated) ...[
            const SizedBox(height: AppSpacing.x2),
            _ClienteCatalogResultSummary(
              query: _serviceQuery,
              totalMatched: catalog.totalMatched,
              visibleCount: visibleServices.length,
              isSearching: catalog.isSearching,
            ),
          ],
        ],
      ),
      children: [
        if (visibleServices.isEmpty)
          _ClienteCatalogEmptyResult(
            message: catalog.isSearching
                ? l10n.serviceSearchEmpty
                : 'Nao ha servicos disponiveis neste modo.',
          )
        else
          for (final servico in visibleServices)
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
        if (catalog.isTruncated)
          _ClienteCatalogShowMoreCard(
            visibleCount: visibleServices.length,
            totalCount: catalog.totalMatched,
            onPressed: () => setState(
              () => _visibleLimit += _visibleServicesStep,
            ),
          ),
      ],
    );
  }

  Widget _buildServiceSearchField(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      key: const Key('cliente_home_service_search_field'),
      controller: _serviceSearchController,
      onChanged: _onServiceSearchChanged,
      onSubmitted: _applyServiceSearchNow,
      textInputAction: TextInputAction.search,
      cursorColor: colorScheme.primary,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: l10n.serviceSearchHint,
        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
        suffixIcon: _serviceSearchController.text.isEmpty
            ? null
            : IconButton(
                key: const Key('cliente_home_service_search_clear'),
                tooltip: 'Limpar pesquisa',
                onPressed: _clearServiceSearch,
                icon: Icon(
                  Icons.close_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x3,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
    );
  }

  void _onServiceSearchChanged(String value) {
    _serviceSearchDebounce?.cancel();
    _serviceSearchDebounce = Timer(
      _searchDebounce,
      () => _applyServiceSearchNow(value),
    );
  }

  void _applyServiceSearchNow(String value) {
    if (!mounted) return;
    final nextQuery = value.trim();
    if (nextQuery == _serviceQuery) return;

    setState(() {
      _serviceQuery = nextQuery;
      _visibleLimit = _initialVisibleServices;
    });
  }

  void _clearServiceSearch() {
    _serviceSearchDebounce?.cancel();
    _serviceSearchController.clear();
    setState(() {
      _serviceQuery = '';
      _visibleLimit = _initialVisibleServices;
    });
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

class _ClienteCatalogResultSummary extends StatelessWidget {
  const _ClienteCatalogResultSummary({
    required this.query,
    required this.totalMatched,
    required this.visibleCount,
    required this.isSearching,
  });

  final String query;
  final int totalMatched;
  final int visibleCount;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isSearching
        ? 'Resultados para "$query": $visibleCount de $totalMatched'
        : 'A mostrar $visibleCount de $totalMatched servicos. Usa a pesquisa para encontrar mais rapido.';

    return Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ClienteCatalogEmptyResult extends StatelessWidget {
  const _ClienteCatalogEmptyResult({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClienteCatalogShowMoreCard extends StatelessWidget {
  const _ClienteCatalogShowMoreCard({
    required this.visibleCount,
    required this.totalCount,
    required this.onPressed,
  });

  final int visibleCount;
  final int totalCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$visibleCount de $totalCount servicos',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Carrega mais categorias se quiseres navegar sem pesquisar.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.expand_more_rounded),
              label: const Text('Ver mais servicos'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClienteHomeSideColumn extends StatelessWidget {
  const _ClienteHomeSideColumn({
    required this.user,
    required this.pedidosStream,
    required this.onOpenOrders,
    required this.onOpenMessages,
  });

  final User? user;
  final Stream<List<Pedido>>? pedidosStream;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenMessages;

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
          onOpenOrders: onOpenOrders,
        ),
        const SizedBox(height: AppSpacing.x4),
        _ClienteHomeSummaryPanel(
          clienteId: user!.uid,
          pedidosStream: pedidosStream,
        ),
        const SizedBox(height: AppSpacing.x4),
        _ClienteHomeGuidancePanel(
          onChooseService: () => _scrollToServices(context),
        ),
        const SizedBox(height: AppSpacing.x4),
        _ClienteMensagensBanner(clienteId: user!.uid),
        const SizedBox(height: AppSpacing.x4),
        _ClienteHomeSupportPanel(onOpenMessages: onOpenMessages),
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
    required this.onOpenOrders,
  });

  final String clienteId;
  final Stream<List<Pedido>>? pedidosStream;
  final VoidCallback onOpenOrders;

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
          return AppActionPanel(
            key: const Key('cliente_home_active_orders_panel'),
            title: 'Sem pedidos ativos',
            message:
                'Quando criares um pedido, acompanhas aqui o proximo passo.',
            icon: Icons.receipt_long_outlined,
            tone: AppStatusTone.neutral,
            primaryAction: AppActionPanelAction(
              label: 'Ver pedidos',
              icon: Icons.list_alt_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: onOpenOrders,
            ),
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

class _ClienteHomeSummaryPanel extends StatelessWidget {
  const _ClienteHomeSummaryPanel({
    required this.clienteId,
    required this.pedidosStream,
  });

  final String clienteId;
  final Stream<List<Pedido>>? pedidosStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pedido>>(
      stream: pedidosStream ?? PedidosRepo.streamPedidosDoCliente(clienteId),
      builder: (context, snapshot) {
        final pedidos = snapshot.data ?? const <Pedido>[];
        final ativos = pedidos.where((p) => !_pedidoEstaFinalizado(p)).length;
        final concluidos = pedidos
            .where((p) => p.estado.toLowerCase().trim() == 'concluido')
            .length;
        final aDecidir = pedidos.where(_temAcaoPendente).length;

        return Column(
          key: const Key('cliente_home_summary_panel'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Resumo rapido',
              subtitle: 'O essencial para nao perderes contexto.',
              dense: true,
            ),
            AppMetricTile(
              label: 'Pedidos ativos',
              value: '$ativos',
              supportingText: ativos == 1
                  ? 'Um servico em acompanhamento'
                  : 'Servicos em acompanhamento',
              icon: Icons.bolt_rounded,
              tone: ativos > 0 ? AppStatusTone.info : AppStatusTone.neutral,
            ),
            const SizedBox(height: AppSpacing.x3),
            AppMetricTile(
              label: 'Acoes para decidir',
              value: '$aDecidir',
              supportingText: aDecidir > 0
                  ? 'Tens uma resposta pendente'
                  : 'Nada urgente agora',
              icon: Icons.pending_actions_rounded,
              tone:
                  aDecidir > 0 ? AppStatusTone.warning : AppStatusTone.success,
            ),
            const SizedBox(height: AppSpacing.x3),
            AppMetricTile(
              label: 'Concluidos',
              value: '$concluidos',
              supportingText: 'Historico guardado nos pedidos',
              icon: Icons.verified_rounded,
              tone: AppStatusTone.success,
            ),
          ],
        );
      },
    );
  }
}

class _ClienteHomeGuidancePanel extends StatelessWidget {
  const _ClienteHomeGuidancePanel({
    required this.onChooseService,
  });

  final VoidCallback onChooseService;

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      key: const Key('cliente_home_guidance_panel'),
      title: 'Como comecar bem',
      message:
          'Escolhe uma categoria, descreve o que precisas e acompanha proposta, chat e estado no mesmo lugar.',
      icon: Icons.route_outlined,
      tone: AppStatusTone.info,
      primaryAction: AppActionPanelAction(
        label: 'Escolher servico',
        icon: Icons.add_rounded,
        onPressed: onChooseService,
      ),
    );
  }
}

class _ClienteHomeSupportPanel extends StatelessWidget {
  const _ClienteHomeSupportPanel({
    required this.onOpenMessages,
  });

  final VoidCallback onOpenMessages;

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      key: const Key('cliente_home_support_panel'),
      title: 'Precisas de ajuda?',
      message:
          'Abre Mensagens para acompanhar conversas ou falar no contexto do servico.',
      icon: Icons.headset_mic_outlined,
      tone: AppStatusTone.info,
      primaryAction: AppActionPanelAction(
        label: 'Abrir mensagens',
        icon: Icons.chat_bubble_outline_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: onOpenMessages,
      ),
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
    if (_disableClienteHomeMessageStreamsForEmulatorTests) {
      for (final id in _chatSubs.keys.toList()) {
        _cancelChatSub(id);
      }
      _unreadPorPedido.clear();
      _lastUnreadAtPorPedido.clear();
      _pedidoPorId.clear();
      if (mounted && _hasUnread) {
        setState(() {
          _hasUnread = false;
          _pedidoMaisRecente = null;
        });
      }
      return;
    }

    final ativos = pedidos
        .where((p) => p.estado != 'concluido' && p.estado != 'cancelado')
        .toList();

    final idsAtivos = ativos.map((p) => p.id).toSet();

    final idsParaRemover =
        _chatSubs.keys.where((id) => !idsAtivos.contains(id)).toList();
    for (final id in idsParaRemover) {
      _cancelChatSub(id);
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
            _cancelChatSub(p.id);
            if (kDebugMode) {
              // ignore: avoid_print
              print('[ClienteHomeBanner] chatSub(${p.id}) error: $error');
            }
          },
        );
      }
    }
  }

  void _cancelChatSub(String pedidoId) {
    final sub = _chatSubs.remove(pedidoId);
    if (sub != null) {
      unawaited(sub.cancel());
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

class _ClientePedidosTab extends StatefulWidget {
  final Stream<List<Pedido>>? pedidosStream;

  const _ClientePedidosTab({this.pedidosStream});

  @override
  State<_ClientePedidosTab> createState() => _ClientePedidosTabState();
}

class _ClientePedidosTabState extends State<_ClientePedidosTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AppContentShell(
              width: AppContentWidth.dashboard,
              child: SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppProductHeader(
                      title: l10n.myOrdersTitle,
                      subtitle:
                          'Acompanha pedidos ativos, concluidos e cancelados.',
                      showBrand: false,
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    Expanded(
                      child: StreamBuilder<List<Pedido>>(
                        stream: widget.pedidosStream ??
                            PedidosRepo.streamPedidosDoCliente(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const AppLoadingView(
                              label: 'A carregar pedidos...',
                            );
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
                                    p.estado != 'concluido' &&
                                    p.estado != 'cancelado',
                              )
                              .toList();
                          final concluidos = pedidos
                              .where((p) => p.estado == 'concluido')
                              .toList();
                          final cancelados = pedidos
                              .where((p) => p.estado == 'cancelado')
                              .toList();

                          pendentes.sort(
                            (a, b) => b.createdAt.compareTo(a.createdAt),
                          );
                          concluidos.sort(
                            (a, b) => b.createdAt.compareTo(a.createdAt),
                          );
                          cancelados.sort(
                            (a, b) => b.createdAt.compareTo(a.createdAt),
                          );

                          final selectedPedidos = switch (_selectedIndex) {
                            1 => concluidos,
                            2 => cancelados,
                            _ => pendentes,
                          };
                          final selectedEmptyTitle = switch (_selectedIndex) {
                            1 => 'Sem pedidos concluidos',
                            2 => 'Sem pedidos cancelados',
                            _ => 'Sem pedidos ativos',
                          };
                          final selectedEmptyMessage = switch (_selectedIndex) {
                            1 =>
                              'Os pedidos concluidos ficam guardados aqui para consulta.',
                            2 =>
                              'Pedidos cancelados aparecem aqui quando existirem.',
                            _ =>
                              'Quando criares um pedido, ele aparece aqui ate ser concluido ou cancelado.',
                          };

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSegmentedTabs(
                                items: [
                                  AppSegmentedTab(
                                    label: l10n.ordersTabPending,
                                    count: pendentes.length,
                                    icon: Icons.bolt_rounded,
                                  ),
                                  AppSegmentedTab(
                                    label: l10n.ordersTabCompleted,
                                    count: concluidos.length,
                                    icon: Icons.check_circle_outline_rounded,
                                  ),
                                  AppSegmentedTab(
                                    label: l10n.ordersTabCancelled,
                                    count: cancelados.length,
                                    icon: Icons.cancel_outlined,
                                  ),
                                ],
                                selectedIndex: _selectedIndex,
                                onChanged: (index) {
                                  setState(() => _selectedIndex = index);
                                },
                              ),
                              const SizedBox(height: AppSpacing.x4),
                              Expanded(
                                child: _ListaPedidosCliente(
                                  pedidos: selectedPedidos,
                                  emptyTitle: selectedEmptyTitle,
                                  emptyMessage: selectedEmptyMessage,
                                ),
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
          },
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
      padding: const EdgeInsets.only(bottom: AppSpacing.x7),
      itemCount: pedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x3),
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
                                    'Métricas, suporte e moderação',
                                  ),
                                  leading: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                  ),
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

class _ContaPremiumTab extends StatelessWidget {
  const _ContaPremiumTab({required this.roleLabel});

  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final name = _accountDisplayNameFor(user, fallback: roleLabel);

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: AppContentShell(
          width: AppContentWidth.medium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppProductHeader(
                title: l10n.accountTitle(roleLabel),
                subtitle: 'Gere perfil, preferencias e suporte num so lugar.',
                showBrand: false,
              ),
              const SizedBox(height: AppSpacing.x5),
              AccountProfileSummary(
                name: name,
                roleLabel: roleLabel,
                photoUrl: user?.photoURL,
                statusLabel: 'Perfil cliente',
                statusIcon: Icons.verified_user_outlined,
                statusTone: AppStatusTone.info,
                onEditPressed: () => _openClientePerfil(context),
              ),
              const SizedBox(height: AppSpacing.x5),
              AppCard(
                child: Column(
                  children: [
                    SettingsListTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppPalette.accentBlue,
                      title: l10n.accountNameTitle,
                      subtitle: l10n.accountProfileSubtitle,
                      showDivider: true,
                      onTap: () => _openClientePerfil(context),
                    ),
                    const RoleModeSwitchTile(
                      currentRole: 'cliente',
                      showDivider: true,
                    ),
                    FutureBuilder<String?>(
                      future: _loadRegionLabel(),
                      builder: (context, snapshot) {
                        final label = snapshot.data;
                        return SettingsListTile(
                          icon: Icons.public_rounded,
                          iconColor: AppPalette.success,
                          title: 'Pais / Regiao',
                          subtitle: label != null && label.trim().isNotEmpty
                              ? label
                              : 'Selecionar regiao da conta',
                          showDivider: true,
                          onTap: () async {
                            await RegionSelectionWidget.show(context);
                          },
                        );
                      },
                    ),
                    const ThemeModeSelectorTile(
                      title: 'Tema',
                      systemLabel: 'Sistema',
                      lightLabel: 'Claro',
                      darkLabel: 'Escuro',
                    ),
                    SettingsListTile(
                      icon: Icons.settings_outlined,
                      title: l10n.accountSettings,
                      subtitle: 'Permissoes e preferencias da aplicacao',
                      showDivider: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PermissionSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    SettingsListTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: AppPalette.warning,
                      title: l10n.accountHelpSupport,
                      subtitle: 'Perguntas frequentes e suporte',
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
                      future:
                          FirebaseAuth.instance.currentUser?.getIdTokenResult(),
                      builder: (context, snapshot) {
                        final claims =
                            snapshot.data?.claims ?? const <String, dynamic>{};
                        final isAdmin = claims['admin'] == true ||
                            AppConfig.useFirebaseEmulators;
                        if (!isAdmin) return const SizedBox.shrink();
                        return SettingsListTile(
                          icon: Icons.admin_panel_settings_outlined,
                          iconColor: AppPalette.accentCoral,
                          title: 'Backoffice Admin',
                          subtitle: 'Metricas, suporte e moderacao',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminPanelScreen(),
                              ),
                            );
                          },
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
  }

  void _openClientePerfil(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ClientePerfilScreen()),
    );
  }
}

String _accountDisplayNameFor(User? user, {required String fallback}) {
  final displayName = user?.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;

  final email = user?.email?.trim();
  if (email != null && email.isNotEmpty) {
    final localPart = email.split('@').first.trim();
    if (localPart.isNotEmpty) return localPart;
  }

  return fallback;
}
