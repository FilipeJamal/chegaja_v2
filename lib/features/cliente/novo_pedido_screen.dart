// lib/features/cliente/novo_pedido_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/repositories/servico_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/features/cliente/aguardando_prestador_screen.dart';
import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';
import 'package:chegaja_v2/features/cliente/selecionar_prestador_screen.dart';

class NovoPedidoScreen extends StatefulWidget {
  /// Entrada do pedido: 'IMEDIATO', 'AGENDADO' ou 'ORCAMENTO' (atalho para preço por orçamento).
  final String modo;

  /// Se não for null, estamos a editar um pedido existente
  final Pedido? pedidoInicial;

  /// Serviço pré-selecionado (quando o cliente clicou numa categoria)
  final Servico? servicoInicial;
  final Future<List<Servico>> Function()? servicosLoader;

  const NovoPedidoScreen({
    super.key,
    required this.modo,
    this.pedidoInicial,
    this.servicoInicial,
    this.servicosLoader,
  });

  @override
  State<NovoPedidoScreen> createState() => _NovoPedidoScreenState();
}

enum _LocalizacaoModo { automatico, manual }
enum _BuscaPrestadorModo { automatico, manual }

class _NovoPedidoScreenState extends State<NovoPedidoScreen> {
  final _formKey = GlobalKey<FormState>();

  // ✅ PATCH: controlador para scroll e autovalidação
  final ScrollController _scrollController = ScrollController();
  bool _tentouSubmeter = false;

  // ✅ PATCH: key para conseguir “focar/scroll” no campo de agendamento
  final GlobalKey _agendadoFieldKey = GlobalKey();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _enderecoTextoController = TextEditingController();

  late String _modo; // IMEDIATO / AGENDADO (modo real gravado no Firestore)
  String _tipoPrecoSelecionado = 'a_combinar'; // a_combinar | fixo | por_orcamento
  String _tipoPagamentoSelecionado = 'dinheiro'; // dinheiro | online_antes | online_depois

  String? _categoriaNome;
  String? _servicoIdSelecionado;

  DateTime? _agendadoPara;
  bool _salvando = false;

  bool _entradaOrcamento = false; // atalho vindo do tab ORCAMENTO
  bool _didSetDefaultTitle = false;

  // Localização
  double? _latitude;
  double? _longitude;
  bool _obtendoLocal = false;
  _LocalizacaoModo _modoLocalizacao = _LocalizacaoModo.automatico;
  bool _procurandoEndereco = false;
  String? _enderecoManualSelecionado;
  _BuscaPrestadorModo _buscaPrestadorModo = _BuscaPrestadorModo.automatico;
  PrestadorSelecionado? _prestadorSelecionado;

  bool get isEditing => widget.pedidoInicial != null;
  bool get _modoManual => _modoLocalizacao == _LocalizacaoModo.manual;

  @override
  void initState() {
    super.initState();

    if (widget.pedidoInicial != null) {
      // --- EDITAR PEDIDO EXISTENTE ---
      final p = widget.pedidoInicial!;
      _modo = p.modo;
      _tituloController.text = p.titulo;
      _descricaoController.text = p.descricao;
      _categoriaNome = p.categoria;
      _servicoIdSelecionado = p.servicoId.isNotEmpty ? p.servicoId : null;
      _agendadoPara = p.agendadoPara;
      _tipoPrecoSelecionado = p.tipoPreco;
      _tipoPagamentoSelecionado = p.tipoPagamento;

      _latitude = p.latitude;
      _longitude = p.longitude;
      _enderecoTextoController.text = p.enderecoTexto ?? '';
      if (_enderecoTextoController.text.trim().isNotEmpty &&
          (_latitude == null || _longitude == null)) {
        _modoLocalizacao = _LocalizacaoModo.manual;
      }
    } else {
      // --- NOVO PEDIDO ---
      _entradaOrcamento = widget.modo == 'ORCAMENTO';

      // Categoria (se veio do catálogo)
      if (widget.servicoInicial != null) {
        _categoriaNome = widget.servicoInicial!.name;
        _servicoIdSelecionado = widget.servicoInicial!.id;
      }

      // Modo real (gravado no Firestore)
      if (_entradaOrcamento) {
        // Por padrão: orçamento imediato (o utilizador pode mudar para agendado)
        _modo = 'IMEDIATO';
        _tipoPrecoSelecionado = 'por_orcamento';
      } else {
        // ✅ Correção importante: respeitar o tab de entrada (AGENDADO)
        if (widget.modo == 'AGENDADO') {
          _modo = 'AGENDADO';
        } else if (widget.modo == 'IMEDIATO') {
          _modo = 'IMEDIATO';
        } else {
          _modo = widget.servicoInicial?.mode ?? widget.modo;
        }
      }

    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didSetDefaultTitle) return;
    if (!isEditing && _modo == 'IMEDIATO' && _tituloController.text.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      _tituloController.text = l10n.orderDefaultImmediateTitle;
    }
    _didSetDefaultTitle = true;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _enderecoTextoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataHora() async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: _agendadoPara ?? agora.add(const Duration(days: 1)),
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 60)),
    );

    if (data == null || !mounted) return;

    final hora = await _selecionarHoraAgendada();
    if (hora == null || !mounted) return;

    setState(() {
      _agendadoPara = DateTime(
        data.year,
        data.month,
        data.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<TimeOfDay?> _selecionarHoraAgendada() {
    return showTimePicker(
      context: context,
      initialTime: _agendadoPara != null
          ? TimeOfDay.fromDateTime(_agendadoPara!)
          : const TimeOfDay(hour: 10, minute: 0),
    );
  }

  Future<void> _obterLocalizacaoAtual() async {
    if (_obtendoLocal) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _obtendoLocal = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationServiceDisabled)),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionDenied)),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationPermissionDeniedForever)),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _enderecoManualSelecionado = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationFetchError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _obtendoLocal = false;
        });
      }
    }
  }

  Future<void> _escolherNoMapa() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => SelecionarLocalNoMapaScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _enderecoManualSelecionado = null;
      });
    }
  }

  Future<void> _procurarEnderecoManual() async {
    if (_procurandoEndereco) return;

    final query = _enderecoTextoController.text.trim();
    if (query.length < 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreve pelo menos 3 caracteres.')),
      );
      return;
    }

    setState(() => _procurandoEndereco = true);
    try {
      final resultados = await _buscarEnderecos(query);
      if (!mounted) return;

      if (resultados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum resultado encontrado.')),
        );
        return;
      }

      final escolhido = await _mostrarResultadosEndereco(resultados);
      if (!mounted) return;
      if (escolhido == null) return;

      setState(() {
        _latitude = escolhido.latitude;
        _longitude = escolhido.longitude;
        _enderecoTextoController.text = escolhido.label;
        _enderecoManualSelecionado = escolhido.label;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao pesquisar endereco: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _procurandoEndereco = false);
      }
    }
  }

  Future<List<_EnderecoSugestao>> _buscarEnderecos(String query) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '6',
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'ChegaJaApp/1.0',
        'Accept-Language': 'pt',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return <_EnderecoSugestao>[];

    final resultados = <_EnderecoSugestao>[];
    for (final item in data) {
      Map<String, dynamic>? map;
      if (item is Map<String, dynamic>) {
        map = item;
      } else if (item is Map) {
        map = Map<String, dynamic>.from(item);
      }
      if (map == null) continue;

      final label = (map['display_name'] ?? '').toString().trim();
      final lat = _parseDouble(map['lat']);
      final lon = _parseDouble(map['lon']);
      if (label.isEmpty || lat == null || lon == null) continue;

      resultados.add(
        _EnderecoSugestao(
          label: label,
          latitude: lat,
          longitude: lon,
        ),
      );
    }

    return resultados;
  }

  Future<_EnderecoSugestao?> _mostrarResultadosEndereco(
    List<_EnderecoSugestao> resultados,
  ) {
    return showModalBottomSheet<_EnderecoSugestao>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: resultados.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, index) {
              final item = resultados[index];
              return ListTile(
                title: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(ctx).pop(item),
              );
            },
          ),
        );
      },
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  Future<void> _escolherPrestadorManual() async {
    final servicoId = _servicoIdSelecionado;
    final servicoNome = _categoriaNome;

    if ((servicoId == null || servicoId.trim().isEmpty) &&
        (servicoNome == null || servicoNome.trim().isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolhe uma categoria primeiro.')),
      );
      return;
    }

    final selecionado = await Navigator.of(context).push<PrestadorSelecionado>(
      MaterialPageRoute(
        builder: (_) => SelecionarPrestadorScreen(
          servicoId: servicoId,
          servicoNome: servicoNome,
          latitude: _latitude,
          longitude: _longitude,
        ),
      ),
    );

    if (!mounted) return;
    if (selecionado == null) return;

    setState(() {
      _prestadorSelecionado = selecionado;
    });
  }

  String _distanciaPrestadorLabel(double? km) {
    if (km == null) return 'Distancia indisponivel';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  // ---------------- SUBMETER ----------------

  Future<void> _submeter() async {
    if (_salvando) return;

    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;

    // ✅ PATCH: autovalidação depois do 1º submit
    if (!_tentouSubmeter) {
      setState(() => _tentouSubmeter = true);
    }

    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userNotAuthenticatedError)),
      );
      return;
    }

    final formState = _formKey.currentState;
    if (formState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.formNotReadyError)),
      );
      return;
    }

    final valid = formState.validate();
    if (!valid) {
      // ✅ PATCH: antes era “silencioso”
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.missingRequiredFieldsError)),
      );
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    final isAgendado = _modo == 'AGENDADO';

    if (isAgendado) {
      if (_agendadoPara == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scheduleDateTimeRequiredError)),
        );

        final ctx = _agendadoFieldKey.currentContext;
        if (ctx != null) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
        return;
      }

      if (!_agendadoPara!.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scheduleDateTimeFutureError)),
        );

        final ctx = _agendadoFieldKey.currentContext;
        if (ctx != null) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
        return;
      }
    }

    if (_categoriaNome == null || _categoriaNome!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.categoryRequiredError)),
      );
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    if (!isEditing &&
        _buscaPrestadorModo == _BuscaPrestadorModo.manual &&
        _prestadorSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleciona um prestador para continuar.')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final titulo = _tituloController.text.trim();
      final descricao = _descricaoController.text.trim().isEmpty
          ? null
          : _descricaoController.text.trim();
      final agendadoPara = isAgendado ? _agendadoPara : null;
      final enderecoTexto = _enderecoTextoController.text.trim().isEmpty
          ? null
          : _enderecoTextoController.text.trim();

      // Modelo de preço / pagamento
      String tipoPreco = _tipoPrecoSelecionado;
      if (_entradaOrcamento) {
        tipoPreco = 'por_orcamento';
      }
      final String tipoPagamento = _tipoPagamentoSelecionado;

      if (isEditing) {
        final pedido = widget.pedidoInicial!;
        await PedidosRepo.atualizarPedidoCliente(
          pedidoId: pedido.id,
          titulo: titulo,
          servicoId: _servicoIdSelecionado,
          servicoNome: _categoriaNome,
          descricao: descricao,
          modo: _modo,
          agendadoPara: agendadoPara,
          categoria: _categoriaNome,
          latitude: _latitude,
          longitude: _longitude,
          enderecoTexto: enderecoTexto,
          tipoPreco: tipoPreco,
          tipoPagamento: tipoPagamento,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.orderUpdatedSuccess)),
        );
        Navigator.of(context).pop();
      } else {
        final bool manual =
            _buscaPrestadorModo == _BuscaPrestadorModo.manual &&
                _prestadorSelecionado != null;
        final String? prestadorId =
            manual ? _prestadorSelecionado!.id : null;

        final String pedidoId = await PedidosRepo.criarPedido(
          clienteId: user.uid,
          prestadorId: prestadorId,
          status: manual ? 'aguarda_resposta_prestador' : null,
          servicoId: _servicoIdSelecionado,
          servicoNome: _categoriaNome,
          titulo: titulo,
          descricao: descricao,
          modo: _modo,
          agendadoPara: agendadoPara,
          categoria: _categoriaNome,
          latitude: _latitude,
          longitude: _longitude,
          enderecoTexto: enderecoTexto,
          tipoPreco: tipoPreco,
          tipoPagamento: tipoPagamento,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.orderCreatedSuccess)),
        );

        if (manual) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PedidoDetalheScreen(
                pedidoId: pedidoId,
                isCliente: true,
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => AguardandoPrestadorScreen(
                pedidoId: pedidoId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? l10n.orderUpdateError(e.toString())
                : l10n.orderCreateError(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  String _exemploTitulo(
    AppLocalizations l10n,
    String? categoriaNome,
    String modo,
  ) {
    final c = (categoriaNome ?? '').toLowerCase();

    if (c.contains('canalizador') || c.contains('canalização')) {
      return l10n.orderTitleExamplePlumbing;
    }
    if (c.contains('eletricista') || c.contains('elétrica')) {
      return l10n.orderTitleExampleElectric;
    }
    if (c.contains('limpeza')) {
      return l10n.orderTitleExampleCleaning;
    }

    if (modo == 'IMEDIATO') {
      return l10n.orderTitleHintImmediate;
    }
    if (modo == 'AGENDADO') {
      return l10n.orderTitleHintScheduled;
    }
    if (_entradaOrcamento) {
      return l10n.orderTitleHintQuote;
    }

    return l10n.orderTitleHintDefault;
  }

  String _exemploDescricao(
    AppLocalizations l10n,
    String? categoriaNome,
    String modo,
  ) {
    final c = (categoriaNome ?? '').toLowerCase();

    if (c.contains('limpeza')) {
      return l10n.orderDescriptionExampleCleaning;
    }
    if (modo == 'IMEDIATO') {
      return l10n.orderDescriptionHintImmediate;
    }
    if (modo == 'AGENDADO') {
      return l10n.orderDescriptionHintScheduled;
    }
    if (_entradaOrcamento) {
      return l10n.orderDescriptionHintQuote;
    }

    return l10n.orderDescriptionHintDefault;
  }

  Widget _buildModeloPrecoSection(AppLocalizations l10n) {
    final isPorProposta = _entradaOrcamento;

    if (isPorProposta) {
      _tipoPrecoSelecionado = 'por_orcamento';
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.priceModelTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.priceModelQuoteInfo,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.priceModelTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _CompatDropdownButtonFormField<String>(
              value: _tipoPrecoSelecionado,
              decoration: InputDecoration(
                labelText: l10n.priceTypeLabel,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'a_combinar',
                  child: Text(l10n.priceToArrange),
                ),
                DropdownMenuItem(
                  value: 'fixo',
                  child: Text(l10n.priceFixed),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoPrecoSelecionado = value ?? 'a_combinar';
                });
              },
            ),
            const SizedBox(height: 12),
            _CompatDropdownButtonFormField<String>(
              value: _tipoPagamentoSelecionado,
              decoration: InputDecoration(
                labelText: l10n.paymentTypeLabel,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'dinheiro',
                  child: Text(l10n.paymentCash),
                ),
                DropdownMenuItem(
                  value: 'online_antes',
                  child: Text(l10n.paymentOnlineBefore),
                ),
                DropdownMenuItem(
                  value: 'online_depois',
                  child: Text(l10n.paymentOnlineAfter),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoPagamentoSelecionado = value ?? 'dinheiro';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final primary = Theme.of(context).colorScheme.primary;

    final isImediato = _modo == 'IMEDIATO';
    final isAgendado = _modo == 'AGENDADO';
    final isProposta = _entradaOrcamento;
    final isManual = _modoManual;

    String tituloTopo;
    String subtituloTopo;
    if (isProposta) {
      tituloTopo = l10n.orderHeaderQuoteTitle;
      subtituloTopo = l10n.orderHeaderQuoteSubtitle;
    } else if (isImediato) {
      tituloTopo = l10n.orderHeaderImmediateTitle;
      subtituloTopo = l10n.orderHeaderImmediateSubtitle;
    } else if (isAgendado) {
      tituloTopo = l10n.orderHeaderScheduledTitle;
      subtituloTopo = l10n.orderHeaderScheduledSubtitle;
    } else {
      tituloTopo = l10n.orderHeaderDefaultTitle;
      subtituloTopo = l10n.orderHeaderDefaultSubtitle;
    }

    final hintTitulo = _exemploTitulo(l10n, _categoriaNome, _modo);
    final hintDescricao = _exemploDescricao(l10n, _categoriaNome, _modo);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.orderEditTitle : l10n.orderNewTitle,
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Servico>>(
            future:
                (widget.servicosLoader ??
                    ServicosRepo.buscarServicosAtivosTodos)(),
            builder: (context, snapshot) {
              final servicos = snapshot.data ?? [];
              final bool loading = snapshot.connectionState ==
                      ConnectionState.waiting &&
                  servicos.isEmpty;

              final nomes = servicos.map((s) => s.name).toList();
              final servicosFiltrados = [...servicos];

              if (_categoriaNome != null &&
                  _categoriaNome!.isNotEmpty &&
                  !nomes.contains(_categoriaNome)) {
                servicosFiltrados.insert(
                  0,
                  Servico(
                    id: '_custom_${_categoriaNome!}',
                    name: _categoriaNome!,
                    mode: _modo,
                    keywords: const [],
                    iconKey: null,
                    isActive: true,
                  ),
                );
              }

              return SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _tentouSubmeter
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho
                      Text(
                        tituloTopo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtituloTopo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_entradaOrcamento) ...[
                        Text(
                          l10n.whenServiceNeededLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.serviceTabImmediate),
                              selected: _modo == 'IMEDIATO',
                              onSelected: (v) {
                                if (!v) return;
                                setState(() {
                                  _modo = 'IMEDIATO';
                                  _agendadoPara = null;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Text(l10n.serviceTabScheduled),
                              selected: _modo == 'AGENDADO',
                              onSelected: (v) {
                                if (!v) return;
                                setState(() {
                                  _modo = 'AGENDADO';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ], 

                      // Categoria
                      Text(
                        l10n.categoryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        _CompatDropdownButtonFormField<String>(
                          value: _servicoIdSelecionado,
                          items: servicosFiltrados
                              .map(
                                (s) => DropdownMenuItem<String>(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                            ),
                            hintText: l10n.categoryHint,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _servicoIdSelecionado = value;
                              _prestadorSelecionado = null;
                              if (value == null) {
                                _categoriaNome = null;
                                return;
                              }
                              final s = servicosFiltrados.firstWhere(
                                (x) => x.id == value,
                                orElse: () => servicosFiltrados.first,
                              );
                              _categoriaNome = s.name;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.categoryRequiredError;
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),

                      if (!isEditing) ...[
                        const Text(
                          'Encontrar prestador',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<_BuscaPrestadorModo>(
                                  segments: const [
                                    ButtonSegment(
                                      value: _BuscaPrestadorModo.automatico,
                                      label: Text('Automatico'),
                                      icon: Icon(Icons.auto_awesome),
                                    ),
                                    ButtonSegment(
                                      value: _BuscaPrestadorModo.manual,
                                      label: Text('Manual'),
                                      icon: Icon(Icons.search),
                                    ),
                                  ],
                                  selected: {_buscaPrestadorModo},
                                  onSelectionChanged: (selection) {
                                    setState(() {
                                      _buscaPrestadorModo = selection.first;
                                      if (_buscaPrestadorModo ==
                                          _BuscaPrestadorModo.automatico) {
                                        _prestadorSelecionado = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_buscaPrestadorModo ==
                                  _BuscaPrestadorModo.manual) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: _prestadorSelecionado == null
                                      ? const Text(
                                          'Nenhum prestador selecionado.',
                                          style: TextStyle(fontSize: 12),
                                        )
                                      : Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundImage:
                                                  _prestadorSelecionado!
                                                              .photoUrl !=
                                                          null
                                                      ? NetworkImage(
                                                          _prestadorSelecionado!
                                                              .photoUrl!,
                                                        )
                                                      : null,
                                              child: _prestadorSelecionado!
                                                          .photoUrl ==
                                                      null
                                                  ? Text(
                                                      _prestadorSelecionado!
                                                              .nome
                                                              .isNotEmpty
                                                          ? _prestadorSelecionado!
                                                              .nome[0]
                                                              .toUpperCase()
                                                          : '?',
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _prestadorSelecionado!.nome,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _prestadorSelecionado!
                                                                .ratingAvg ==
                                                            null
                                                        ? 'Sem avaliacoes'
                                                        : '${_prestadorSelecionado!.ratingAvg!.toStringAsFixed(1)} (${_prestadorSelecionado!.ratingCount})',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _distanciaPrestadorLabel(
                                                      _prestadorSelecionado!
                                                          .distanciaKm,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _escolherPrestadorManual,
                                    icon: const Icon(Icons.search, size: 18),
                                    label: Text(
                                      _prestadorSelecionado == null
                                          ? 'Pesquisar prestadores'
                                          : 'Trocar prestador',
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Vamos procurar um prestador automaticamente.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Título
                      Text(
                        l10n.orderTitleLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tituloController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16)),
                          ),
                          hintText: hintTitulo,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.orderTitleRequiredError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descrição
                      Text(
                        l10n.orderDescriptionOptionalLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16)),
                          ),
                          hintText: hintDescricao,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildModeloPrecoSection(l10n),

                      const SizedBox(height: 16),

                      // Localização
                      Text(
                        l10n.locationApproxLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _latitude != null && _longitude != null
                                  ? l10n.locationSelectedLabel
                                  : l10n.locationSelectPrompt,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<_LocalizacaoModo>(
                                segments: const [
                                  ButtonSegment(
                                    value: _LocalizacaoModo.automatico,
                                    label: Text('Automatico'),
                                    icon: Icon(Icons.my_location),
                                  ),
                                  ButtonSegment(
                                    value: _LocalizacaoModo.manual,
                                    label: Text('Manual'),
                                    icon: Icon(Icons.search),
                                  ),
                                ],
                                selected: {_modoLocalizacao},
                                onSelectionChanged: (selection) {
                                  setState(() {
                                    _modoLocalizacao = selection.first;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _enderecoTextoController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                ),
                                hintText: l10n.locationAddressHint,
                                suffixIcon: isManual
                                    ? IconButton(
                                        tooltip: 'Procurar endereco',
                                        onPressed: _procurandoEndereco
                                            ? null
                                            : _procurarEnderecoManual,
                                        icon: _procurandoEndereco
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.search),
                                      )
                                    : null,
                              ),
                              maxLines: 2,
                              onChanged: (value) {
                                if (!isManual) return;
                                final trimmed = value.trim();
                                if (_enderecoManualSelecionado == null) return;
                                if (trimmed == _enderecoManualSelecionado) return;
                                setState(() {
                                  _enderecoManualSelecionado = null;
                                  _latitude = null;
                                  _longitude = null;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isManual
                                        ? (_procurandoEndereco
                                            ? null
                                            : _procurarEnderecoManual)
                                        : (_obtendoLocal
                                            ? null
                                            : _obterLocalizacaoAtual),
                                    icon: Icon(
                                      isManual
                                          ? Icons.search
                                          : Icons.my_location,
                                      size: 18,
                                    ),
                                    label: Text(
                                      isManual
                                          ? (_procurandoEndereco
                                              ? 'A procurar...'
                                              : 'Procurar endereco')
                                          : (_obtendoLocal
                                              ? l10n.locationGetting
                                              : l10n.locationUseCurrent),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _escolherNoMapa,
                                    icon: const Icon(
                                      Icons.map_outlined,
                                      size: 18,
                                    ),
                                    label: Text(l10n.locationChooseOnMap),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (isAgendado) ...[
                        Text(
                          l10n.serviceDateTimeLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          key: _agendadoFieldKey,
                          borderRadius: BorderRadius.circular(16),
                          onTap: _selecionarDataHora,
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_note_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _agendadoPara != null
                                        ? df.format(_agendadoPara!)
                                        : l10n.serviceDateTimePick,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ] else
                        const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _salvando ? null : _submeter,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            backgroundColor: primary,
                          ),
                          child: Text(
                            isEditing
                                ? l10n.saveChangesButton
                                : l10n.submitOrderButton,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_salvando)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompatDropdownButtonFormField<T> extends StatelessWidget {
  const _CompatDropdownButtonFormField({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.decoration,
    this.validator,
  });

  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final T? value;
  final InputDecoration? decoration;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: decoration,
      validator: validator,
    );
  }
}

// ----------------- ECRÃ DE SELEÇÃO NO MAPA -----------------

class _EnderecoSugestao {
  final String label;
  final double latitude;
  final double longitude;

  const _EnderecoSugestao({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

class SelecionarLocalNoMapaScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const SelecionarLocalNoMapaScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<SelecionarLocalNoMapaScreen> createState() =>
      _SelecionarLocalNoMapaScreenState();
}

class _SelecionarLocalNoMapaScreenState
    extends State<SelecionarLocalNoMapaScreen> {
  late MapController _mapController;
  LatLng _center = const LatLng(38.7223, -9.1393); // Lisboa default

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  void _onPositionChanged(MapPosition position, bool hasGesture) {
    if (hasGesture && position.center != null) {
      setState(() {
        _center = position.center!;
      });
    }
  }

  void _confirmar() {
    Navigator.of(context).pop(_center);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapSelectTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15,
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                  ],
                ),
                const IgnorePointer(
                  ignoring: true,
                  child: Center(
                    child: Icon(
                      Icons.location_on,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.mapSelectInstruction,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _confirmar,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.mapSelectConfirm),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
