// lib/features/prestador/prestador_home_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/core/services/location_service.dart';
import 'package:chegaja_v2/core/utils/cancelamento_motivos.dart';

import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';
import 'package:chegaja_v2/features/common/pedido_chat_preview.dart';
import 'package:chegaja_v2/features/common/mensagens/mensagens_tab.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';

import 'package:chegaja_v2/features/prestador/prestador_perfil_screen.dart';
import 'package:chegaja_v2/features/prestador/prestador_settings_screen.dart';
import 'package:chegaja_v2/features/prestador/prestador_pagamentos_screen.dart';

import 'widgets/prestador_pedido_acoes.dart';

final Map<String, Set<String>> _ignoradosPorPrestador = <String, Set<String>>{};

const double kCommissionPercent = 0.15;

String _labelEstado(String estado) {
  switch (estado) {
    case 'criado':
      return 'Ã€ espera de prestador';
    case 'aguarda_resposta_prestador':
      return 'Convite pendente';
    case 'aguarda_resposta_cliente':
      return 'Proposta a aguardar cliente';
    case 'aceito':
      return 'Aceito, por iniciar';
    case 'em_andamento':
      return 'Em andamento';
    case 'aguarda_confirmacao_valor':
      return 'A aguardar confirmaÃ§Ã£o do valor';
    case 'concluido':
      return 'ConcluÃ­do';
    case 'cancelado':
      return 'Cancelado';
    default:
      return estado;
  }
}

String _labelTipoPreco(String tipo) {
  switch (tipo) {
    case 'fixo':
      return 'PreÃ§o fixo';
    case 'por_orcamento':
      return 'Por orÃ§amento';
    case 'a_combinar':
    default:
      return 'PreÃ§o a combinar';
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
    return 'Tens um serviÃ§o em andamento. Marca como concluÃ­do quando terminares.';
  }
  if (p.statusConfirmacaoValor == 'pendente_prestador') {
    return 'Define e envia o valor final do serviÃ§o.';
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

  // âœ… Badge sem ChatMessage / sem streamMessagesForPedido
  StreamSubscription<List<Pedido>>? _pedidosSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _prestadorDocSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _chatSubs = {};
  final Map<String, bool> _unreadPorPedido = {};
  bool _hasUnreadMessages = false;

  @override
  void initState() {
    super.initState();
    _initPrestador();
  }

  Future<void> _initPrestador() async {
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
      if (_online != onlineFromDb) {
        setState(() => _online = onlineFromDb);
      }
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

    ChatService.instance.ensureChatMetaForPedido(pedido.id);

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
      // âœ… garante que o chat tem prestadorId => MensagensTab do prestador passa a mostrar
      _ensureChatMetaForPrestador(p);

      if (!_chatSubs.containsKey(p.id)) {
        final q = FirebaseFirestore.instance
            .collection('chats')
            .doc(p.id)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(50);

        _chatSubs[p.id] = q.snapshots().listen((snap) {
          _onMessagesUpdate(p.id, snap.docs);
        });
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

      // prestador considera "nÃ£o lido" mensagens do cliente nÃ£o vistas pelo prestador
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
    _prestadorDocSub?.cancel();
    _pedidosSub?.cancel();
    for (final sub in _chatSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _PrestadorInicioTab(
        online: _online,
        roleReady: _roleReady,
        onToggleOnline: (value) => setState(() => _online = value),
      ),
      const _PrestadorPedidosTab(),
      const MensagensTab(viewerRole: 'prestador'),
      const _ContaTab(roleLabel: 'Prestador'),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Meus Trabalhos',
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
            label: 'Mensagens',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
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
    _settingsStream = FirebaseFirestore.instance
        .collection('prestadores')
        .doc(user.uid)
        .snapshots();
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

    ChatService.instance.ensureChatMetaForPedido(pedido.id);

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
        const SnackBar(content: Text('Utilizador nÃ£o autenticado.')),
      );
      return;
    }

    try {
      await PedidosRepo.aceitarPedido(
        pedidoId: pedido.id,
        prestadorId: user.uid,
      );

      // âœ… garante que o chat fica associÃ¡vel ao prestador (prestadorId)
      await _ensureChatMetaAfterAccept(pedido);

      if (!context.mounted) return;

      final isOrcamento = pedido.tipoPreco == 'por_orcamento';

      if (isOrcamento) {
        final bool enviarAgora = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text('Pedido aceite âœ…'),
                  content: const Text(
                    'Este pedido Ã© por orÃ§amento.\n\nQueres enviar o orÃ§amento (faixa min/max) agora?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Mais tarde'),
                    ),
                    TextButton(
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
                'Pedido aceite. Podes enviar o orÃ§amento no detalhe do pedido.',
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
        const SnackBar(content: Text('Utilizador nÃ£o autenticado.')),
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
          title: const Text('Propor serviÃ§o'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Define uma faixa de preÃ§o para este serviÃ§o.\nInclui deslocaÃ§Ã£o e mÃ£o de obra.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text('Valor mÃ­nimo (â‚¬)'),
                TextField(
                  controller: minController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: 'â‚¬ ',
                    hintText: 'Ex.: 20',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Valor mÃ¡ximo (â‚¬)'),
                TextField(
                  controller: maxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    prefixText: 'â‚¬ ',
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
                        'Ex.: Inclui deslocaÃ§Ã£o. Materiais grandes Ã  parte.',
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
                      content: Text('Preenche valores mÃ­nimo e mÃ¡ximo vÃ¡lidos.'),
                    ),
                  );
                  return;
                }

                if (min > max) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('O mÃ­nimo nÃ£o pode ser maior que o mÃ¡ximo.'),
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
                    const SnackBar(content: Text('Proposta enviada ao cliente.')),
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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final user = AuthService.currentUser;

    if (user == null) {
      return const Center(child: Text('Erro: utilizador nÃ£o autenticado.'));
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

        final liquidoHojeStr = 'â‚¬ ${liquidoHoje.toStringAsFixed(2)}';
        final brutoHojeStr = 'â‚¬ ${brutoHoje.toStringAsFixed(2)}';
        final taxaHojeStr = 'â‚¬ ${taxaHoje.toStringAsFixed(2)}';
        final servicosMesStr = servicosMes.toString();

        final pendentesComAcao = pedidosDoPrestador
            .where(_temAcaoPendentePrestador)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final Pedido? trabalhoDestaque =
            pendentesComAcao.isNotEmpty ? pendentesComAcao.first : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OlÃ¡, prestador ðŸ‘‹',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fica online para receber novos pedidos.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
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
                      color: Colors.black.withValues(alpha: 0.03),
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
                        widget.online ? 'EstÃ¡s ONLINE' : 'EstÃ¡s OFFLINE',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: widget.online
                              ? Colors.green[700]
                              : Colors.black87,
                        ),
                      ),
                    ),
                    Switch(
                      value: widget.online,
                      thumbColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return primary;
                          }
                          return Colors.grey.shade400;
                        },
                      ),
                      onChanged: (value) async {
                        widget.onToggleOnline(value);
                        final user = AuthService.currentUser;
                        if (user != null) {
                          await LocationService.instance.updatePrestadorLastLocation(
                            prestadorId: user.uid,
                            isOnline: value,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _KpiCard(
                    label: 'Ganhos hoje (lÃ­quido)',
                    value: liquidoHojeStr,
                    icon: Icons.euro_outlined,
                    subtitle: 'Bruto: $brutoHojeStr â€¢ Taxa: $taxaHojeStr',
                  ),
                  const SizedBox(width: 12),
                  _KpiCard(
                    label: 'ServiÃ§os este mÃªs',
                    value: servicosMesStr,
                    icon: Icons.work_outline,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (trabalhoDestaque != null) ...[
                GestureDetector(
                  // âœ… corrigido: antes estava a usar "pedido" que nÃ£o existia
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PedidoDetalheScreen(
                          pedidoId: trabalhoDestaque.id,
                          isCliente: false,
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
                        const Icon(Icons.notifications_active_outlined, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tens um trabalho para gerir',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _textoAcaoPendentePrestador(trabalhoDestaque),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Toca aqui para abrir o prÃ³ximo trabalho.',
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
                const SizedBox(height: 12),
              ],

              _PrestadorMensagensBanner(prestadorId: user.uid),
              const SizedBox(height: 16),

              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _settingsStream,
                builder: (context, settingsSnap) {
                  final data = settingsSnap.data?.data() ?? <String, dynamic>{};
                  final servicosNomes =
                      (data['servicosNomes'] as List?)
                              ?.whereType<String>()
                              .toList() ??
                          <String>[];
                  final hasCategorias = servicosNomes.isNotEmpty;

                  if (settingsSnap.connectionState ==
                          ConnectionState.waiting &&
                      data.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
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
                            Icon(Icons.category_outlined, color: primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Categorias de atuacao',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Usamos as categorias para filtrar pedidos compativeis.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        if (!hasCategorias)
                          const Text(
                            'Nenhuma categoria selecionada.',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: servicosNomes
                                .map((s) => Chip(label: Text(s)))
                                .toList(),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PrestadorSettingsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: Text(
                              hasCategorias
                                  ? 'Adicionar ou editar categorias'
                                  : 'Selecionar categorias',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Text(
                'Pedidos perto de ti',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              if (!widget.roleReady)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                StreamBuilder<List<Pedido>>(
                stream: PedidosRepo.streamPedidosDisponiveis(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                  pedidos =
                      pedidos.where((p) => !_ignorados.contains(p.id)).toList();

                  if (pedidos.isEmpty) {
                    _atualizarDisponiveis(const <Pedido>[]);
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Text(
                        'NÃ£o hÃ¡ pedidos disponÃ­veis neste momento.\n'
                        'Assim que um cliente criar um pedido, ele aparece aqui. ðŸ˜‰',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _settingsStream,
                    builder: (context, settingsSnap) {
                      final sdata = settingsSnap.data?.data();

                      if (settingsSnap.connectionState ==
                              ConnectionState.waiting &&
                          sdata == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (sdata == null) {
                        _resetDisponiveis();
                        return Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Configura a tua Ã¡rea de atuaÃ§Ã£o para receber pedidos compatÃ­veis.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PrestadorSettingsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.tune),
                                label: const Text('Configurar'),
                              ),
                            ],
                          ),
                        );
                      }

                      final servicos = (sdata['servicos'] as List?)
                              ?.whereType<String>()
                              .toSet() ??
                          <String>{};

                      final servicosNomes = (sdata['servicosNomes'] as List?)
                              ?.whereType<String>()
                              .toSet() ??
                          <String>{};
                      final hasCategorias =
                          servicos.isNotEmpty || servicosNomes.isNotEmpty;

                      if (!hasCategorias) {
                        _resetDisponiveis();
                        return Padding(
                          padding:
                              const EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Seleciona as categorias que fazes para receber pedidos.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PrestadorSettingsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.list_alt),
                                label: const Text('Selecionar categorias'),
                              ),
                            ],
                          ),
                        );
                      }

                      final radiusKm =
                          (sdata['radiusKm'] as num?)?.toDouble() ?? 10.0;

                      final lastLoc =
                          sdata['lastLocation'] as Map<String, dynamic>?;
                      final lat = (lastLoc?['lat'] as num?)?.toDouble();
                      final lng = (lastLoc?['lng'] as num?)?.toDouble();

                      final isOnline = (sdata['isOnline'] as bool?) ?? false;
                      if (!isOnline) {
                        _resetDisponiveis();
                        return const Padding(
                          padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Text(
                            'EstÃ¡s offline. Ativa o modo online para receber pedidos.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      bool matchesService(Pedido p) {
                        if (servicos.contains(p.servicoId)) return true;
                        final nome = p.servicoNome ?? p.categoria;
                        if (nome != null && servicosNomes.contains(nome)) return true;
                        return false;
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
                        return const Padding(
                          padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Text(
                            'Sem pedidos compatÃ­veis agora.\n'
                            'Ajusta serviÃ§os/raio ou atualiza a localizaÃ§Ã£o.',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final pedido = filtered[index];

                          final tipoPrecoLabel = _labelTipoPreco(pedido.tipoPreco);
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
                            onPropor: () => _aceitarPedido(context, pedido),
                            onIgnorar: () => _ignorarPedido(pedido),
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
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

        _chatSubs[p.id] = q.snapshots().listen((snap) {
          _onMessagesUpdate(p.id, snap.docs);
        });
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

    // âœ… agora abre o CHAT (Instagram/WhatsApp), nÃ£o o detalhe
    return GestureDetector(
      onTap: () async {
        ChatService.instance.ensureChatMetaForPedido(pedido.id);

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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PedidoDetalheScreen(
                pedidoId: pedido.id,
                isCliente: false,
              ),
            ),
          );
          return;
        }

        Navigator.of(context).push(
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
              color: Colors.black.withValues(alpha: 0.03),
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
                color: primary.withValues(alpha: 0.1),
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
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
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
  });

  @override
  Widget build(BuildContext context) {
    final linhaCategoria = categoria ?? 'Categoria nÃ£o definida';

    String linhaAgendamento;
    if (modo == 'AGENDADO' && agendadoPara != null) {
      linhaAgendamento = 'Agendado: ${df.format(agendadoPara!)}';
    } else {
      linhaAgendamento = 'ServiÃ§o imediato';
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
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: onIgnorar,
                child: const Text('Ignorar'),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: onPropor,
                child: const Text('Aceitar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            linhaCategoria,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            linhaAgendamento,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            tipoPrecoLabel,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            tipoPagamentoLabel,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (temDescricao) ...[
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ],
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
      return const Center(child: Text('Erro: utilizador nÃ£o autenticado.'));
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
                Tab(text: 'ConcluÃ­dos'),
                Tab(text: 'Cancelados'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Pedido>>(
                stream: PedidosRepo.streamPedidosDoPrestador(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                  final concluidos = pedidos.where(_isConcluido).toList();
                  final cancelados = pedidos.where(_isCancelado).toList();

                  emAberto.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  concluidos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  cancelados.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return TabBarView(
                    children: [
                      _PrestadorListaPedidos(
                        pedidos: emAberto,
                        mensagemVazio:
                            'Ainda nÃ£o tens trabalhos em aberto.\nVai Ã  aba InÃ­cio e aceita um pedido.',
                        df: df,
                        podeCancelar: true,
                      ),
                      _PrestadorListaPedidos(
                        pedidos: concluidos,
                        mensagemVazio: 'Ainda nÃ£o tens trabalhos concluÃ­dos.',
                        df: df,
                        podeCancelar: false,
                      ),
                      _PrestadorListaPedidos(
                        pedidos: cancelados,
                        mensagemVazio: 'Ainda nÃ£o tens trabalhos cancelados.',
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
    final emServico =
        pedido.estado == 'em_andamento' ||
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
                    'O pedido pode voltar a ficar disponÃ­vel para outros prestadores.',
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
                  child: const Text('NÃ£o'),
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
    final motivoDetalheFinal =
        motivoDetalhe.isEmpty ? null : motivoDetalhe;

    try {
      await PedidoService.instance.cancelarPorPrestador(
        pedido: pedido,
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
    String subtitulo;
    if (pedido.modo == 'AGENDADO' && pedido.agendadoPara != null) {
      subtitulo = 'Agendado: ${df.format(pedido.agendadoPara!)}';
    } else {
      subtitulo = 'ServiÃ§o imediato';
    }

    final categoria = pedido.categoria ?? 'Categoria nÃ£o definida';
    final desc = pedido.descricao.trim();
    final temDescricao = desc.isNotEmpty;

    final estadoLabel = _labelEstado(pedido.estado);
    final tipoPrecoLabel = _labelTipoPreco(pedido.tipoPreco);
    final tipoPagamentoLabel = _labelTipoPagamento(pedido.tipoPagamento);

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
          'Valor pago pelo cliente: â‚¬ ${totalPago.toStringAsFixed(2)}';
      valorPrestadorLabel =
          'Tu recebes: â‚¬ ${liquido.toStringAsFixed(2)} â€¢ Taxa: â‚¬ ${commission.toStringAsFixed(2)}';
    } else if (isConcluido && pedido.preco != null) {
      valorClienteLabel =
          'Valor do serviÃ§o: â‚¬ ${pedido.preco!.toStringAsFixed(2)}';
    }

    final bool mostrarCancelar =
        podeCancelar && pedido.estado != 'aguarda_resposta_prestador';

    final card = Container(
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
              const Icon(Icons.task_alt_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pedido.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => _abrirDetalhe(context),
                icon: const Icon(Icons.open_in_new),
                tooltip: 'Ver detalhe',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            categoria,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            'Estado: $estadoLabel',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text(
            tipoPrecoLabel,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            tipoPagamentoLabel,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (temDescricao) ...[
            const SizedBox(height: 6),
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
          if (valorClienteLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              valorClienteLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          if (valorPrestadorLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              valorPrestadorLabel,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
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

    return InkWell(
      onTap: () => _abrirDetalhe(context),
      borderRadius: BorderRadius.circular(18),
      child: card,
    );
  }
}

class _ContaTab extends StatelessWidget {
  final String roleLabel;

  const _ContaTab({required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conta ($roleLabel)',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: const Text('Ver o meu perfil'),
            subtitle: const Text('Perfil de Prestador'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrestadorPerfilScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Pagamentos (Stripe)'),
            subtitle: const Text('Ativar recebimentos online'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrestadorPagamentosScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('DefiniÃ§Ãµes'),
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
            title: const Text('Ajuda e suporte'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}


