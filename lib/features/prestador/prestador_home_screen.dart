// lib/features/prestador/prestador_home_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Needed for Position
import 'package:intl/intl.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/core/services/location_service.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/utils/cancelamento_motivos.dart';
import 'package:chegaja_v2/core/widgets/app_content_shell.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:chegaja_v2/core/widgets/app_shell_scaffold.dart';
import 'package:chegaja_v2/core/widgets/app_state_views.dart';

import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_empty_state.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:chegaja_v2/features/common/pedido_chat_preview.dart';
import 'package:chegaja_v2/features/common/mensagens/mensagens_tab.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';

import 'package:chegaja_v2/features/prestador/prestador_perfil_screen.dart';
import 'package:chegaja_v2/features/prestador/prestador_settings_screen.dart';
import 'package:chegaja_v2/features/prestador/prestador_pagamentos_screen.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_home_components.dart';

import 'widgets/prestador_pedido_acoes.dart';

final Map<String, Set<String>> _ignoradosPorPrestador = <String, Set<String>>{};

const double kCommissionPercent = 0.15;
const bool _disablePrestadorTrackingForEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

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

bool _isConcluido(Pedido p) => p.estado == 'concluido';
bool _isCancelado(Pedido p) => p.estado == 'cancelado';

bool _temAcaoPendentePrestador(Pedido p) {
  if (p.estado == 'aguarda_resposta_prestador') return true;
  if (p.estado == 'aceito') return true;
  if (p.estado == 'em_andamento') return true;
  if (p.statusConfirmacaoValor == 'pendente_prestador') return true;
  return false;
}

String _textoAcaoPendentePrestador(Pedido p) {
  if (p.estado == 'aguarda_resposta_prestador') {
    return 'Tens um convite direto de cliente.';
  }
  if (p.estado == 'aceito') {
    return 'Tens um trabalho aceite, pronto para iniciar.';
  }
  if (p.estado == 'em_andamento') {
    return 'Tens um serviço em andamento. Marca como concluído quando terminares.';
  }
  if (p.statusConfirmacaoValor == 'pendente_prestador') {
    return 'Define e envia o valor final do serviço.';
  }
  return '';
}

class PrestadorHomeScreen extends StatefulWidget {
  const PrestadorHomeScreen({super.key});

  @override
  State<PrestadorHomeScreen> createState() => _PrestadorHomeScreenState();
}

class _PrestadorHomeScreenState extends State<PrestadorHomeScreen> {
  int _currentIndex = 0;
  bool _online = false;
  bool _roleReady = false;
  StreamSubscription<User?>? _authSub;

  // ✅ Badge sem ChatMessage / sem streamMessagesForPedido
  StreamSubscription<List<Pedido>>? _pedidosSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _prestadorDocSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _chatSubs = {};
  final Map<String, bool> _unreadPorPedido = {};
  bool _hasUnreadMessages = false;

  // Tracking
  StreamSubscription<Position>? _trackingSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (!mounted) return;
      unawaited(_initPrestador());
    });
    unawaited(_initPrestador());
  }

  Future<void> _initPrestador() async {
    try {
      await AuthService.ensureSignedInAnonymously();
    } catch (_) {}

    try {
      await AuthService.setActiveRole('prestador');
    } catch (_) {}

    final user = AuthService.currentUser;
    if (!mounted) return;
    if (user == null) {
      if (_roleReady) {
        setState(() => _roleReady = false);
      }
      return;
    }

    // Mantem o estado online sincronizado com prestadores/{uid}.isOnline
    _prestadorDocSub ??= FirebaseFirestore.instance
        .collection('prestadores')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      final onlineFromDb = (data?['isOnline'] as bool?) ?? false;
      if (!mounted) return;

      // Se houver mudança de estado, atualiza UI e Tracking
      if (_online != onlineFromDb) {
        setState(() => _online = onlineFromDb);
      }

      // Garante que o tracking reflete o estado do DB (single source of truth)
      _manageTracking(onlineFromDb);
    });

    _pedidosSub ??=
        PedidosRepo.streamPedidosDoPrestador(user.uid).listen(_onPedidosUpdate);

    if (!_roleReady) {
      setState(() => _roleReady = true);
    }
  }

  Future<void> _ensureChatMetaForPrestador(Pedido pedido) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    await ChatService.instance.ensureChatMetaForPedido(pedido.id);

    final myName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : 'Prestador';

    final myPhoto = user.photoURL ?? '';

    final data = <String, dynamic>{
      'pedidoId': pedido.id,
      'pedidoTitulo': pedido.titulo,
      'prestadorId': user.uid,
      'prestadorNome': myName,
      'prestadorPhotoUrl': myPhoto,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final clienteId = pedido.clienteId.trim();
    if (clienteId.isNotEmpty) {
      data['clienteId'] = clienteId;
      // nome/foto do cliente podem vir depois via MensagensTab (fetch em 'clientes')
      data['clienteNome'] = 'Cliente';
    }

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(pedido.id)
          .set(data, SetOptions(merge: true));
    } catch (_) {}
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
      // ✅ garante que o chat tem prestadorId => MensagensTab do prestador passa a mostrar
      _ensureChatMetaForPrestador(p);

      if (!_chatSubs.containsKey(p.id)) {
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
            _recalculateHasUnread();
            if (kDebugMode) {
              // ignore: avoid_print
              print('[PrestadorHome] chatSub(${p.id}) error: $error');
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

      // prestador considera "não lido" mensagens do cliente não vistas pelo prestador
      if (senderRole != 'cliente') continue;
      if (data['seenByPrestador'] == true) continue;

      hasUnread = true;
      break;
    }

    _unreadPorPedido[pedidoId] = hasUnread;
    _recalculateHasUnread();
  }

  void _recalculateHasUnread() {
    final anyUnread = _unreadPorPedido.values.any((v) => v);
    if (!mounted) return;
    setState(() {
      _hasUnreadMessages = anyUnread;
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _trackingSub?.cancel();
    _prestadorDocSub?.cancel();
    _pedidosSub?.cancel();
    for (final sub in _chatSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _manageTracking(bool shouldBeOnline) async {
    final user = AuthService.currentUser;
    if (user == null) {
      await _trackingSub?.cancel();
      _trackingSub = null;
      return;
    }

    if (_disablePrestadorTrackingForEmulatorTests) {
      await _trackingSub?.cancel();
      _trackingSub = null;
      return;
    }

    if (shouldBeOnline) {
      // Se deve estar online mas nao tem tracking, inicia
      if (_trackingSub == null) {
        debugPrint('Iniciando tracking prestador: ${user.uid}');
        _trackingSub = await LocationService.instance.startPrestadorTracking(
          prestadorId: user.uid,
          isOnline: true,
        );
      }
    } else {
      // Se deve estar offline, cancela se existir
      if (_trackingSub != null) {
        debugPrint('Parando tracking prestador: ${user.uid}');
        await _trackingSub?.cancel();
        _trackingSub = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppShellScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: [
        AppShellDestination(
          label: l10n.navHome,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          child: _PrestadorInicioTab(
            online: _online,
            roleReady: _roleReady,
            onToggleOnline: (value) => setState(() => _online = value),
          ),
        ),
        AppShellDestination(
          label: l10n.navMyJobs,
          icon: Icons.work_outline,
          selectedIcon: Icons.work,
          child: const _PrestadorPedidosTab(),
        ),
        AppShellDestination(
          label: l10n.navMessages,
          icon: Icons.chat_bubble_outline,
          selectedIcon: Icons.chat_bubble,
          showBadge: _hasUnreadMessages,
          child: const MensagensTab(viewerRole: 'prestador'),
        ),
        AppShellDestination(
          label: l10n.navProfile,
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          child: _ContaTab(roleLabel: l10n.roleLabelProvider),
        ),
      ],
    );
  }
}

class _PrestadorInicioTab extends StatefulWidget {
  final bool online;
  final bool roleReady;
  final ValueChanged<bool> onToggleOnline;

  const _PrestadorInicioTab({
    required this.online,
    required this.roleReady,
    required this.onToggleOnline,
  });

  @override
  State<_PrestadorInicioTab> createState() => _PrestadorInicioTabState();
}

class _PrestadorInicioTabState extends State<_PrestadorInicioTab> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _settingsStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _pedidosSettingsStream;
  Set<String> _disponiveisIds = <String>{};
  bool _disponiveisCarregados = false;
  bool _processandoRemocoes = false;

  @override
  void initState() {
    super.initState();
    _maybeInitSettingsStream();
  }

  @override
  void didUpdateWidget(covariant _PrestadorInicioTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.roleReady && widget.roleReady) {
      _maybeInitSettingsStream();
    }
  }

  void _maybeInitSettingsStream() {
    if (_settingsStream != null) return;
    if (!widget.roleReady) return;
    final user = AuthService.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('prestadores').doc(
          user.uid,
        );
    _settingsStream = ref.snapshots();
    _pedidosSettingsStream = ref.snapshots();
  }

  Set<String> get _ignorados {
    final user = AuthService.currentUser;
    final key = user?.uid ?? '__anon__';
    return _ignoradosPorPrestador.putIfAbsent(key, () => <String>{});
  }

  void _resetDisponiveis() {
    _disponiveisIds = <String>{};
    _disponiveisCarregados = false;
  }

  void _atualizarDisponiveis(List<Pedido> atuais) {
    final idsAtuais = atuais.map((p) => p.id).toSet();

    if (!_disponiveisCarregados) {
      _disponiveisCarregados = true;
      _disponiveisIds = idsAtuais;
      return;
    }

    final removidos = _disponiveisIds.difference(idsAtuais);
    _disponiveisIds = idsAtuais;

    if (removidos.isEmpty) return;
    _notificarRemocoes(removidos);
  }

  Future<void> _notificarRemocoes(Set<String> removidos) async {
    if (_processandoRemocoes) return;
    _processandoRemocoes = true;

    final uid = AuthService.currentUser?.uid;

    for (final pedidoId in removidos) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('pedidos')
            .doc(pedidoId)
            .get();

        if (!mounted) return;

        final data = doc.data();
        if (data == null) {
          _mostrarSnack('Pedido removido.');
          continue;
        }

        final estado =
            (data['status'] ?? data['estado'] ?? 'criado').toString();
        final prestadorId = data['prestadorId']?.toString();
        final canceladoPor = data['canceladoPor']?.toString();

        if (uid != null && prestadorId == uid) {
          continue;
        }

        if (estado == 'cancelado') {
          if (canceladoPor == 'cliente') {
            _mostrarSnack('Cliente cancelou o pedido.');
          } else {
            _mostrarSnack('Pedido cancelado.');
          }
          continue;
        }

        if (prestadorId != null && prestadorId.isNotEmpty) {
          _mostrarSnack('Outro prestador aceitou o pedido.');
          continue;
        }

        if (estado != 'criado') {
          _mostrarSnack('Pedido atualizado.');
          continue;
        }
      } catch (_) {
        if (!mounted) return;
        _mostrarSnack('Pedido removido.');
      }
    }

    _processandoRemocoes = false;
  }

  void _mostrarSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _ensureChatMetaAfterAccept(Pedido pedido) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    await ChatService.instance.ensureChatMetaForPedido(pedido.id);

    final myName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : 'Prestador';

    final myPhoto = user.photoURL ?? '';

    final data = <String, dynamic>{
      'pedidoId': pedido.id,
      'pedidoTitulo': pedido.titulo,
      'prestadorId': user.uid,
      'prestadorNome': myName,
      'prestadorPhotoUrl': myPhoto,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final clienteId = pedido.clienteId.trim();
    if (clienteId.isNotEmpty) {
      data['clienteId'] = clienteId;
      data['clienteNome'] = 'Cliente';
    }

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(pedido.id)
          .set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _aceitarPedido(BuildContext context, Pedido pedido) async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilizador não autenticado.')),
      );
      return;
    }

    try {
      await PedidoService.instance.aceitarPedidoAberto(
        pedido: pedido,
        prestadorId: user.uid,
      );

      // ✅ garante que o chat fica associável ao prestador (prestadorId)
      await _ensureChatMetaAfterAccept(pedido);

      if (!context.mounted) return;

      final isOrcamento = pedido.tipoPreco == 'por_orcamento';

      if (isOrcamento) {
        final bool enviarAgora = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text('Pedido aceite ✅'),
                  content: const Text(
                    'Este pedido é por orçamento.\n\nQueres enviar o orçamento (faixa min/max) agora?',
                  ),
                  actions: [
                    TextButton(
                      key: const Key('prestador_orcamento_dialog_later_button'),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Mais tarde'),
                    ),
                    TextButton(
                      key: const Key('prestador_orcamento_dialog_now_button'),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Enviar agora'),
                    ),
                  ],
                );
              },
            ) ??
            false;

        if (!context.mounted) return;

        if (enviarAgora) {
          await _proporServico(context, pedido);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pedido aceite. Podes enviar o orçamento no detalhe do pedido.',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido aceite.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao aceitar pedido: $e')),
        );
      }
    }
  }

  Future<void> _proporServico(BuildContext context, Pedido pedido) async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilizador não autenticado.')),
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
                  'Define uma faixa de preço para este serviço.\nInclui deslocação e mão de obra.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text('Valor mínimo (€)'),
                TextField(
                  key: const Key('orcamento_min_field'),
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
                  key: const Key('orcamento_max_field'),
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
                  key: const Key('orcamento_msg_field'),
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
              key: const Key('orcamento_enviar_button'),
              onPressed: () async {
                final min = double.tryParse(
                  minController.text.replaceAll(',', '.').trim(),
                );
                final max = double.tryParse(
                  maxController.text.replaceAll(',', '.').trim(),
                );

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

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proposta enviada ao cliente.'),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao enviar proposta: $e')),
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
    setState(() => _ignorados.add(pedido.id));
  }

  Widget _buildPedidosDisponiveisSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required DateFormat df,
  }) {
    if (!widget.roleReady) {
      return const AppLoadingView(label: 'A preparar pedidos...');
    }

    return StreamBuilder<List<Pedido>>(
      stream: PedidosRepo.streamPedidosDisponiveis(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PrestadorAvailableOrdersSection(
            count: 0,
            child: AppLoadingView(label: 'A carregar pedidos compativeis...'),
          );
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            // ignore: avoid_print
            print(
              '[PrestadorHome] pedidos disponiveis error: ${snapshot.error}',
            );
          }
          return const PrestadorAvailableOrdersSection(
            count: 0,
            child: AppErrorView(
              message:
                  'Nao conseguimos carregar os pedidos agora. Tenta novamente daqui a pouco.',
            ),
          );
        }

        var pedidos = snapshot.data ?? [];
        pedidos = pedidos.where((p) => !_ignorados.contains(p.id)).toList();

        if (pedidos.isEmpty) {
          _atualizarDisponiveis(const <Pedido>[]);
          return PrestadorAvailableOrdersSection(
            count: 0,
            child: PedidoEmptyState(
              title: l10n.noOrdersAvailableMessage,
              message: l10n.providerHomeSubtitle,
              icon: Icons.search_off_rounded,
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _pedidosSettingsStream,
          builder: (context, settingsSnap) {
            final sdata = settingsSnap.data?.data();

            if (settingsSnap.connectionState == ConnectionState.waiting &&
                sdata == null) {
              return const PrestadorAvailableOrdersSection(
                count: 0,
                child: AppLoadingView(label: 'A carregar configuracao...'),
              );
            }

            if (sdata == null) {
              _resetDisponiveis();
              return PrestadorAvailableOrdersSection(
                count: 0,
                child: PedidoEmptyState(
                  title: 'Configura a tua area de atuacao',
                  message:
                      'Seleciona categorias para receber pedidos compativeis.',
                  icon: Icons.tune,
                  actionLabel: 'Configurar',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrestadorSettingsScreen(),
                      ),
                    );
                  },
                ),
              );
            }

            final servicos =
                (sdata['servicos'] as List?)?.whereType<String>().toSet() ??
                    <String>{};
            final servicosNomes = (sdata['servicosNomes'] as List?)
                    ?.whereType<String>()
                    .toSet() ??
                <String>{};
            final hasCategorias =
                servicos.isNotEmpty || servicosNomes.isNotEmpty;

            if (!hasCategorias) {
              _resetDisponiveis();
              return PrestadorAvailableOrdersSection(
                count: 0,
                child: PedidoEmptyState(
                  title: 'Seleciona categorias',
                  message:
                      'Escolhe os servicos que fazes para receber pedidos.',
                  icon: Icons.list_alt,
                  actionLabel: 'Selecionar categorias',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrestadorSettingsScreen(),
                      ),
                    );
                  },
                ),
              );
            }

            final radiusKm = (sdata['radiusKm'] as num?)?.toDouble() ?? 10.0;
            final lastLoc = sdata['lastLocation'] as Map<String, dynamic>?;
            final lat = (lastLoc?['lat'] as num?)?.toDouble();
            final lng = (lastLoc?['lng'] as num?)?.toDouble();
            final isOnline = (sdata['isOnline'] as bool?) ?? false;

            if (!isOnline) {
              _resetDisponiveis();
              return const PrestadorAvailableOrdersSection(
                count: 0,
                child: PedidoEmptyState(
                  title: 'Estas offline',
                  message:
                      'Ativa o modo online para receber pedidos compativeis.',
                  icon: Icons.wifi_off_rounded,
                ),
              );
            }

            bool matchesService(Pedido p) {
              if (servicos.contains(p.servicoId)) return true;
              final nome = p.servicoNome ?? p.categoria;
              return nome != null && servicosNomes.contains(nome);
            }

            bool matchesDistance(Pedido p) {
              if (lat == null || lng == null) return true;
              if (p.latitude == null || p.longitude == null) return true;

              final distKm = LocationService.instance.distanceKm(
                lat1: lat,
                lng1: lng,
                lat2: p.latitude!,
                lng2: p.longitude!,
              );

              return distKm <= radiusKm;
            }

            final filtered = pedidos
                .where((p) => matchesService(p) && matchesDistance(p))
                .toList();

            _atualizarDisponiveis(filtered);

            if (filtered.isEmpty) {
              return const PrestadorAvailableOrdersSection(
                count: 0,
                child: PedidoEmptyState(
                  title: 'Sem pedidos compativeis agora',
                  message: 'Ajusta servicos/raio ou atualiza a localizacao.',
                  icon: Icons.search_off_rounded,
                ),
              );
            }

            return PrestadorAvailableOrdersSection(
              count: filtered.length,
              child: AppResponsiveGrid(
                minItemWidth: 340,
                spacing: AppSpacing.x3,
                runSpacing: AppSpacing.x3,
                children: [
                  for (final pedido in filtered)
                    PrestadorAvailableOrderCard(
                      pedido: pedido,
                      descricao: pedido.descricao,
                      agendadoPara: pedido.agendadoPara,
                      modo: pedido.modo,
                      tipoPrecoLabel: _labelTipoPreco(pedido.tipoPreco),
                      tipoPagamentoLabel:
                          _labelTipoPagamento(pedido.tipoPagamento),
                      df: df,
                      onAceitar: () => _aceitarPedido(context, pedido),
                      onIgnorar: () => _ignorarPedido(pedido),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.roleReady) {
      unawaited(AuthService.ensureSignedInAnonymously());
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;

    if (user == null) {
      unawaited(AuthService.ensureSignedInAnonymously());
      return const Center(child: Text('A recuperar sessão...'));
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
            final statusConf = p.statusConfirmacaoValor;

            if (statusConf.isNotEmpty &&
                statusConf != 'nenhum' &&
                statusConf != 'confirmado_cliente') {
              continue;
            }

            final d = p.concluidoEm!;
            final mesmoMes = d.year == now.year && d.month == now.month;
            final mesmoDia = mesmoMes && d.day == now.day;

            if (mesmoMes) servicosMes++;

            if (mesmoDia) {
              final total = p.earningsTotal ?? p.precoFinal ?? p.preco ?? 0.0;
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

        final pendentesComAcao = pedidosDoPrestador
            .where(_temAcaoPendentePrestador)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final Pedido? trabalhoDestaque =
            pendentesComAcao.isNotEmpty ? pendentesComAcao.first : null;

        final categoriasPanel =
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _settingsStream,
          builder: (context, settingsSnap) {
            final data = settingsSnap.data?.data() ?? <String, dynamic>{};
            final servicosNomes = (data['servicosNomes'] as List?)
                    ?.whereType<String>()
                    .toList() ??
                <String>[];
            final loading =
                settingsSnap.connectionState == ConnectionState.waiting &&
                    data.isEmpty;

            return PrestadorCategoriesPanel(
              categories: servicosNomes,
              loading: loading,
              onEdit: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrestadorSettingsScreen(),
                  ),
                );
              },
            );
          },
        );

        final pedidosDisponiveis = _buildPedidosDisponiveisSection(
          context: context,
          l10n: l10n,
          df: df,
        );

        return AppPageScaffold(
          title: l10n.providerHomeGreeting,
          subtitle: l10n.providerHomeSubtitle,
          width: AppContentWidth.wide,
          child: _PrestadorInicioDashboard(
            online: widget.online,
            onToggleOnline: (value) async {
              widget.onToggleOnline(value);
              final user = AuthService.currentUser;
              if (user != null) {
                await LocationService.instance.updatePrestadorLastLocation(
                  prestadorId: user.uid,
                  isOnline: value,
                );
              }
            },
            liquidoHojeStr: liquidoHojeStr,
            brutoHojeStr: brutoHojeStr,
            taxaHojeStr: taxaHojeStr,
            servicosMesStr: servicosMesStr,
            trabalhoDestaque: trabalhoDestaque,
            trabalhoDestaqueTexto: trabalhoDestaque == null
                ? null
                : _textoAcaoPendentePrestador(trabalhoDestaque),
            onOpenTrabalhoDestaque: trabalhoDestaque == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PedidoDetalheScreen(
                          pedidoId: trabalhoDestaque.id,
                          isCliente: false,
                        ),
                      ),
                    );
                  },
            mensagens: _PrestadorMensagensBanner(prestadorId: user.uid),
            categorias: categoriasPanel,
            pedidosDisponiveis: pedidosDisponiveis,
          ),
        );
      },
    );
  }
}

class _PrestadorInicioDashboard extends StatelessWidget {
  const _PrestadorInicioDashboard({
    required this.online,
    required this.onToggleOnline,
    required this.liquidoHojeStr,
    required this.brutoHojeStr,
    required this.taxaHojeStr,
    required this.servicosMesStr,
    required this.trabalhoDestaque,
    required this.trabalhoDestaqueTexto,
    required this.onOpenTrabalhoDestaque,
    required this.mensagens,
    required this.categorias,
    required this.pedidosDisponiveis,
  });

  final bool online;
  final ValueChanged<bool> onToggleOnline;
  final String liquidoHojeStr;
  final String brutoHojeStr;
  final String taxaHojeStr;
  final String servicosMesStr;
  final Pedido? trabalhoDestaque;
  final String? trabalhoDestaqueTexto;
  final VoidCallback? onOpenTrabalhoDestaque;
  final Widget mensagens;
  final Widget categorias;
  final Widget pedidosDisponiveis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PrestadorAvailabilityPanel(
          online: online,
          onChanged: onToggleOnline,
        ),
        const SizedBox(height: AppSpacing.x4),
        PrestadorMetricStrip(
          liquidoHoje: liquidoHojeStr,
          brutoHoje: brutoHojeStr,
          taxaHoje: taxaHojeStr,
          servicosMes: servicosMesStr,
        ),
        const SizedBox(height: AppSpacing.x5),
        LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= AppBreakpoints.desktopMin;
            final nextWorkPanel = trabalhoDestaque != null &&
                    trabalhoDestaqueTexto != null &&
                    onOpenTrabalhoDestaque != null
                ? PrestadorNextWorkPanel(
                    pedido: trabalhoDestaque!,
                    actionText: trabalhoDestaqueTexto!,
                    onOpen: onOpenTrabalhoDestaque!,
                  )
                : null;

            final mainColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nextWorkPanel != null) ...[
                  nextWorkPanel,
                  const SizedBox(height: AppSpacing.x4),
                ],
                pedidosDisponiveis,
              ],
            );

            final sideColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                mensagens,
                const SizedBox(height: AppSpacing.x4),
                categorias,
              ],
            );

            if (!desktop) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (nextWorkPanel != null) ...[
                    nextWorkPanel,
                    const SizedBox(height: AppSpacing.x4),
                  ],
                  mensagens,
                  const SizedBox(height: AppSpacing.x4),
                  categorias,
                  const SizedBox(height: AppSpacing.x5),
                  pedidosDisponiveis,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: mainColumn),
                const SizedBox(width: AppSpacing.x5),
                Expanded(flex: 3, child: sideColumn),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PrestadorMensagensBanner extends StatefulWidget {
  final String prestadorId;

  const _PrestadorMensagensBanner({
    required this.prestadorId,
  });

  @override
  State<_PrestadorMensagensBanner> createState() =>
      _PrestadorMensagensBannerState();
}

class _PrestadorMensagensBannerState extends State<_PrestadorMensagensBanner> {
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
    _pedidosSub = PedidosRepo.streamPedidosDoPrestador(widget.prestadorId)
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

      ChatService.instance.ensureChatMetaForPedido(p.id);

      if (!_chatSubs.containsKey(p.id)) {
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
              print('[PrestadorHomeBanner] chatSub(${p.id}) error: $error');
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

      if (senderRole != 'cliente') continue;
      if (data['seenByPrestador'] == true) continue;

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
    if (!_hasUnread || _pedidoMaisRecente == null) {
      return const SizedBox.shrink();
    }

    final primary = Theme.of(context).colorScheme.primary;
    final pedido = _pedidoMaisRecente!;

    // ✅ agora abre o CHAT (Instagram/WhatsApp), não o detalhe
    return GestureDetector(
      onTap: () async {
        await ChatService.instance.ensureChatMetaForPedido(pedido.id);

        final snap = await FirebaseFirestore.instance
            .collection('chats')
            .doc(pedido.id)
            .get();

        final data = snap.data() ?? {};

        final clienteId = (data['clienteId'] ?? pedido.clienteId).toString();
        final clienteNome = (data['clienteNome'] ?? 'Cliente').toString();
        final clientePhoto = (data['clientePhotoUrl'] ?? '').toString();
        final pedidoTitulo = (data['pedidoTitulo'] ?? pedido.titulo).toString();

        if (!context.mounted) return;

        if (clienteId.trim().isEmpty) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PedidoDetalheScreen(
                pedidoId: pedido.id,
                isCliente: false,
              ),
            ),
          );
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              pedidoId: pedido.id,
              viewerRole: 'prestador',
              otherUserId: clienteId.trim(),
              otherUserName:
                  clienteNome.trim().isEmpty ? 'Cliente' : clienteNome.trim(),
              otherUserPhotoUrl: clientePhoto.trim(),
              pedidoTitulo: pedidoTitulo,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
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
                  const Text(
                    'Tens novas mensagens de clientes',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No trabalho: ${pedido.titulo}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Toca aqui para abrir o chat.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
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

class _PrestadorPedidosTab extends StatelessWidget {
  const _PrestadorPedidosTab();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      unawaited(AuthService.ensureSignedInAnonymously());
      return const AppLoadingView(label: 'A preparar sessão...');
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const TabBar(
              labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingView(
                      label: 'A carregar trabalhos...',
                    );
                  }

                  if (snapshot.hasError) {
                    if (kDebugMode) {
                      // ignore: avoid_print
                      print(
                        '[PrestadorPedidosTab] trabalhos stream error: ${snapshot.error}',
                      );
                    }
                    return const AppErrorView(
                      message:
                          'Nao conseguimos carregar os trabalhos agora. Tenta novamente daqui a pouco.',
                    );
                  }

                  final pedidos = snapshot.data ?? [];

                  final emAberto = pedidos
                      .where((p) => !_isConcluido(p) && !_isCancelado(p))
                      .toList();
                  final concluidos = pedidos.where(_isConcluido).toList();
                  final cancelados = pedidos.where(_isCancelado).toList();

                  emAberto.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  concluidos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  cancelados.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return TabBarView(
                    children: [
                      _PrestadorListaPedidos(
                        pedidos: emAberto,
                        emptyTitle: 'Sem trabalhos em aberto',
                        emptyMessage:
                            'Vai a Inicio para aceitar pedidos compativeis quando estiveres online.',
                        df: df,
                        podeCancelar: true,
                      ),
                      _PrestadorListaPedidos(
                        pedidos: concluidos,
                        emptyTitle: 'Sem trabalhos concluidos',
                        emptyMessage:
                            'Os trabalhos concluidos ficam aqui para consulta.',
                        df: df,
                        podeCancelar: false,
                      ),
                      _PrestadorListaPedidos(
                        pedidos: cancelados,
                        emptyTitle: 'Sem trabalhos cancelados',
                        emptyMessage:
                            'Trabalhos cancelados aparecem aqui quando existirem.',
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
  final String emptyTitle;
  final String emptyMessage;
  final DateFormat df;
  final bool podeCancelar;

  const _PrestadorListaPedidos({
    required this.pedidos,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.df,
    required this.podeCancelar,
  });

  @override
  Widget build(BuildContext context) {
    if (pedidos.isEmpty) {
      return PedidoEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: Icons.work_outline,
      );
    }

    return ListView.separated(
      itemCount: pedidos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        return _PrestadorPedidoCard(
          pedido: pedido,
          df: df,
          podeCancelar: podeCancelar,
        );
      },
    );
  }
}

class _PrestadorPedidoCard extends StatelessWidget {
  final Pedido pedido;
  final DateFormat df;
  final bool podeCancelar;

  const _PrestadorPedidoCard({
    required this.pedido,
    required this.df,
    required this.podeCancelar,
  });

  Future<void> _cancelarTrabalho(BuildContext context) async {
    final emServico = pedido.estado == 'em_andamento' ||
        pedido.estado == 'aguarda_confirmacao_valor';
    final motivos = CancelamentoMotivos.forPrestador(emServico: emServico);
    CancelamentoMotivoOption selectedMotivo = motivos.first;
    final detalheController = TextEditingController();
    String? detalheError;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final precisaDetalhe = selectedMotivo.requiresDetail;
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
                  DropdownButtonFormField<CancelamentoMotivoOption>(
                    initialValue: selectedMotivo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Motivo do cancelamento',
                    ),
                    items: [
                      for (final motivo in motivos)
                        DropdownMenuItem(
                          value: motivo,
                          child: Text(motivo.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedMotivo = value;
                        detalheError = null;
                      });
                    },
                  ),
                  if (precisaDetalhe) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: detalheController,
                      maxLines: 3,
                      onChanged: (_) {
                        if (detalheError == null) return;
                        setState(() => detalheError = null);
                      },
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Detalhe do motivo',
                        errorText: detalheError,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Não'),
                ),
                TextButton(
                  onPressed: () {
                    if (precisaDetalhe &&
                        detalheController.text.trim().isEmpty) {
                      setState(() {
                        detalheError = 'Informe um detalhe.';
                      });
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Sim, cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmar != true) return;

    final motivo = selectedMotivo.id;
    final motivoDetalhe = detalheController.text.trim();
    final motivoDetalheFinal = motivoDetalhe.isEmpty ? null : motivoDetalhe;

    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      await PedidoService.instance.cancelarPorPrestador(
        pedido: pedido,
        prestadorId: user.uid,
        motivo: motivo,
        motivoDetalhe: motivoDetalheFinal,
        motivoIsId: true,
        tipoReembolso: 'nenhum',
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trabalho cancelado.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar trabalho: $e')),
      );
    }
  }

  void _abrirDetalhe(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PedidoDetalheScreen(
          pedidoId: pedido.id,
          isCliente: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desc = pedido.descricao.trim();
    final temDescricao = desc.isNotEmpty;
    final tipoPrecoLabel = _labelTipoPreco(pedido.tipoPreco);
    final tipoPagamentoLabel = _labelTipoPagamento(pedido.tipoPagamento);
    final listData = PedidoListPresenter.dataFor(
      pedido,
      role: PedidoViewerRole.prestador,
    );

    final bool isConcluido = pedido.estado == 'concluido';

    double? totalPago;
    double? commission;
    double? liquido;

    if (isConcluido) {
      final t = pedido.earningsTotal ?? pedido.precoFinal ?? pedido.preco;
      if (t != null && t > 0) {
        final c = pedido.commissionPlatform ?? (t * kCommissionPercent);
        final l = pedido.earningsProvider ?? (t - c);
        totalPago = t;
        commission = c;
        liquido = l;
      }
    }

    String? valorClienteLabel;
    String? valorPrestadorLabel;

    if (totalPago != null && commission != null && liquido != null) {
      valorClienteLabel =
          'Valor pago pelo cliente: € ${totalPago.toStringAsFixed(2)}';
      valorPrestadorLabel =
          'Tu recebes: € ${liquido.toStringAsFixed(2)} | Taxa: € ${commission.toStringAsFixed(2)}';
    } else if (isConcluido && pedido.preco != null) {
      valorClienteLabel =
          'Valor do serviço: € ${pedido.preco!.toStringAsFixed(2)}';
    }

    final bool mostrarCancelar =
        podeCancelar && pedido.estado != 'aguarda_resposta_prestador';

    final valueFooter = <Widget>[
      if (valorClienteLabel != null)
        Text(
          valorClienteLabel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      if (valorPrestadorLabel != null)
        Text(
          valorPrestadorLabel,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
    ];

    return PedidoListCard(
      data: listData,
      metaLabels: [
        tipoPrecoLabel,
        tipoPagamentoLabel,
      ],
      onTap: () => _abrirDetalhe(context),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (temDescricao) ...[
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 8),
          ],
          ...valueFooter,
          if (valueFooter.isNotEmpty) const SizedBox(height: 8),
          const SizedBox(height: 8),
          PedidoChatPreview(
            pedidoId: pedido.id,
            viewerRole: 'prestador',
          ),
          const SizedBox(height: 8),
          PrestadorPedidoAcoes(pedido: pedido),
          if (mostrarCancelar) ...[
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

  const _ContaTab({required this.roleLabel});

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
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(l10n.providerAccountProfileTitle),
                          subtitle: Text(l10n.providerAccountProfileSubtitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PrestadorPerfilScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: const Text('Pagamentos (Stripe)'),
                          subtitle: const Text('Ativar recebimentos online'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PrestadorPagamentosScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          trailing: const Icon(Icons.chevron_right),
                          title: const Text('Definições'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PrestadorSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: Text(l10n.accountHelpSupport),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
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
