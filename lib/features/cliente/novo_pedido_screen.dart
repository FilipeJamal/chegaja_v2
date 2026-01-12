// lib/features/cliente/novo_pedido_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
import 'package:chegaja_v2/core/repositories/servico_repo.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/features/cliente/aguardando_prestador_screen.dart';

class NovoPedidoScreen extends StatefulWidget {
  /// Modo do pedido: 'IMEDIATO', 'AGENDADO' ou 'POR_PROPOSTA'
  final String modo;

  /// Se não for null, estamos a editar um pedido existente
  final Pedido? pedidoInicial;

  /// Serviço pré-selecionado (quando o cliente clicou numa categoria)
  final Servico? servicoInicial;

  const NovoPedidoScreen({
    super.key,
    required this.modo,
    this.pedidoInicial,
    this.servicoInicial,
  });

  @override
  State<NovoPedidoScreen> createState() => _NovoPedidoScreenState();
}

class _NovoPedidoScreenState extends State<NovoPedidoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  late String _modo; // IMEDIATO / AGENDADO / POR_PROPOSTA
  String? _categoriaNome;
  DateTime? _agendadoPara;
  bool _salvando = false;

  bool get isEditing => widget.pedidoInicial != null;

  @override
  void initState() {
    super.initState();

    if (widget.pedidoInicial != null) {
      // --- EDITAR PEDIDO EXISTENTE ---
      final p = widget.pedidoInicial!;
      _modo = p.modo;
      _tituloController.text = p.titulo;
      _descricaoController.text = p.descricao ?? '';
      _categoriaNome = p.categoria;
      _agendadoPara = p.agendadoPara;
    } else {
      // --- NOVO PEDIDO ---
      if (widget.servicoInicial != null) {
        // Veio de uma categoria específica
        _modo = widget.servicoInicial!.mode;
        _categoriaNome = widget.servicoInicial!.name;
      } else {
        // Veio só com modo (IMEDIATO, AGENDADO, POR_PROPOSTA)
        _modo = widget.modo;
      }

      if (_modo == 'IMEDIATO') {
        _tituloController.text = 'Serviço urgente';
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataHora() async {
    final agora = DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: _agendadoPara ?? agora,
      firstDate: agora,
      lastDate: agora.add(const Duration(days: 60)),
    );

    if (data == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: _agendadoPara != null
          ? TimeOfDay.fromDateTime(_agendadoPara!)
          : TimeOfDay.fromDateTime(agora.add(const Duration(hours: 1))),
    );

    if (hora == null) return;

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

  Future<void> _submeter() async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilizador não autenticado.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final isAgendado = _modo == 'AGENDADO';

    if (isAgendado && _agendadoPara == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolhe a data e hora do serviço.'),
        ),
      );
      return;
    }

    if (_categoriaNome == null || _categoriaNome!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolhe uma categoria.')),
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

      if (isEditing) {
        final pedido = widget.pedidoInicial!;
        await PedidosRepo.atualizarPedidoCliente(
          pedidoId: pedido.id,
          titulo: titulo,
          descricao: descricao,
          modo: _modo,
          agendadoPara: agendadoPara,
          categoria: _categoriaNome,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido atualizado com sucesso!')),
        );
        Navigator.of(context).pop(); // volta ao detalhe ou home
      } else {
        // Criação de novo pedido → ir para o ecrã "Aguardando prestador"
        // (D2) Sem localização por enquanto para não sujar a base com dados falsos.
        // Futuramente, implementar Geolocator.getCurrentPosition() real.
        final String pedidoId = await PedidosRepo.criarPedido(
          clienteId: user.uid,
          titulo: titulo,
          descricao: descricao,
          modo: _modo,
          agendadoPara: agendadoPara,
          categoria: _categoriaNome,
          latitude: null, // Evitar dados falsos em produção
          longitude: null,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido criado! A procurar um prestador...'),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AguardandoPrestadorScreen(
              pedidoId: pedidoId,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Erro ao atualizar pedido: $e'
                : 'Erro ao criar pedido: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// Gera exemplo para o TÍTULO, conforme categoria + modo
  String _exemploTitulo(String? categoriaNome, String modo) {
    final c = (categoriaNome ?? '').toLowerCase();

    if (c.contains('canalizador')) {
      return 'Ex.: Fuga de água na cozinha';
    }
    if (c.contains('eletricista')) {
      return 'Ex.: Tomada deixou de funcionar na sala';
    }
    if (c.contains('pedreiro')) {
      return 'Ex.: Construção de muro no quintal';
    }
    if (c.contains('pintor')) {
      return 'Ex.: Pintar paredes do quarto e sala';
    }
    if (c.contains('serralheiro')) {
      return 'Ex.: Porta de ferro a enroscar / não fecha bem';
    }
    if (c.contains('carpinteiro')) {
      return 'Ex.: Fazer armário embutido no quarto';
    }
    if (c.contains('montagem de móveis') || c.contains('montagem')) {
      return 'Ex.: Montar roupeiro e cómoda do IKEA';
    }
    if (c.contains('limpeza pós-obra') || c.contains('pos-obra')) {
      return 'Ex.: Limpeza pós-obra de apartamento T2';
    }
    if (c.contains('limpeza') && c.contains('doméstica')) {
      return 'Ex.: Limpeza semanal de apartamento T1';
    }
    if (c.contains('jardinagem')) {
      return 'Ex.: Manutenção de jardim de casa';
    }
    if (c.contains('paisagismo')) {
      return 'Ex.: Projeto de jardim para quintal pequeno';
    }
    if (c.contains('mecânico')) {
      return 'Ex.: Carro não pega / luz do motor acesa';
    }
    if (c.contains('reboque')) {
      return 'Ex.: Reboque de carro parado na autoestrada';
    }
    if (c.contains('cabeleireiro') || c.contains('barber')) {
      return 'Ex.: Corte de cabelo + barba';
    }
    if (c.contains('manicure') || c.contains('pedicure')) {
      return 'Ex.: Manicure com gel + pedicure simples';
    }
    if (c.contains('massagista')) {
      return 'Ex.: Massagem de relaxamento 1 hora';
    }
    if (c.contains('personal trainer')) {
      return 'Ex.: Treino personalizado 3x por semana';
    }
    if (c.contains('babysitter')) {
      return 'Ex.: Babysitter para sexta à noite (20h-23h)';
    }
    if (c.contains('cuidador de idosos')) {
      return 'Ex.: Acompanhamento diário para idoso à tarde';
    }
    if (c.contains('cão') || c.contains('dog') || c.contains('pet')) {
      return 'Ex.: Passear cão grande 2x por dia';
    }
    if (c.contains('explicador')) {
      return 'Ex.: Explicações de Matemática 10º ano';
    }
    if (c.contains('idiomas') || c.contains('idioma')) {
      return 'Ex.: Aulas de inglês conversação';
    }
    if (c.contains('música') || c.contains('musica')) {
      return 'Ex.: Aulas de guitarra iniciante';
    }
    if (c.contains('designer') || c.contains('design')) {
      return 'Ex.: Criar logotipo para marca de roupa';
    }
    if (c.contains('ilustrador')) {
      return 'Ex.: Retrato digital estilo cartoon';
    }
    if (c.contains('fotógrafo') || c.contains('fotografo')) {
      return 'Ex.: Sessão fotográfica para família';
    }
    if (c.contains('vídeo') || c.contains('video')) {
      return 'Ex.: Gravação de vídeo para evento';
    }
    if (c.contains('social media')) {
      return 'Ex.: Gestão de redes sociais para pequeno negócio';
    }
    if (c.contains('programador')) {
      return 'Ex.: Desenvolvimento de website simples';
    }
    if (c.contains('confeitaria') || c.contains('bolo')) {
      return 'Ex.: Bolo de aniversário para 20 pessoas';
    }
    if (c.contains('catering')) {
      return 'Ex.: Catering para festa de aniversário 30 pessoas';
    }
    if (c.contains('decorador') || c.contains('decoração')) {
      return 'Ex.: Decoração de festa infantil tema heróis';
    }
    if (c.contains('dj')) {
      return 'Ex.: DJ para festa de casamento';
    }
    if (c.contains('animador')) {
      return 'Ex.: Animação para festa de crianças (2h)';
    }

    // fallback por modo
    if (modo == 'IMEDIATO') {
      return 'Ex.: Preciso de ajuda agora com um problema em casa';
    }
    if (modo == 'AGENDADO') {
      return 'Ex.: Quero marcar um serviço para um dia específico';
    }
    // POR_PROPOSTA
    return 'Ex.: Preciso de um orçamento para um serviço específico';
  }

  /// Gera exemplo para a DESCRIÇÃO
  String _exemploDescricao(String? categoriaNome, String modo) {
    final c = (categoriaNome ?? '').toLowerCase();

    if (c.contains('canalizador')) {
      return 'Ex.: Fuga de água debaixo da pia da cozinha, já há alguma humidade no chão.';
    }
    if (c.contains('eletricista')) {
      return 'Ex.: Tomada da sala deixou de funcionar e o disjuntor desarma quando ligo o aquecedor.';
    }
    if (c.contains('pedreiro')) {
      return 'Ex.: Preciso levantar um muro de 10m no quintal com acabamento simples.';
    }
    if (c.contains('pintor')) {
      return 'Ex.: Quero pintar quarto e sala (paredes e teto), cores claras.';
    }
    if (c.contains('limpeza')) {
      return 'Ex.: Limpeza completa de apartamento T2 (cozinha, WC, janelas e chão).';
    }
    if (c.contains('jardinagem')) {
      return 'Ex.: Corte da relva, podar arbustos e retirar folhas secas.';
    }
    if (c.contains('mecânico')) {
      return 'Ex.: Carro faz barulho estranho ao travar, luz ABS acesa.';
    }
    if (c.contains('babysitter')) {
      return 'Ex.: Criança de 5 anos, precisa de supervisão, brincar e dar jantar.';
    }
    if (c.contains('confeitaria')) {
      return 'Ex.: Bolo de chocolate de 2 andares, com decoração de super-herói.';
    }
    if (c.contains('fotógrafo') || c.contains('fotografo')) {
      return 'Ex.: Sessão ao ar livre, 10-15 fotos editadas para redes sociais.';
    }
    if (c.contains('designer') || c.contains('design')) {
      return 'Ex.: Criação de logotipo + paleta de cores + ficheiros para impressão e web.';
    }

    if (modo == 'IMEDIATO') {
      return 'Explica rapidamente o que está a acontecer e o que precisas que o prestador faça.';
    }
    if (modo == 'AGENDADO') {
      return 'Indica para quando queres o serviço, detalhes do local e o que deve ser feito.';
    }
    // POR_PROPOSTA
    return 'Explica com o máximo de detalhe o que precisas, para os prestadores enviarem orçamentos certeiros.';
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final primary = Theme.of(context).colorScheme.primary;

    final isImediato = _modo == 'IMEDIATO';
    final isAgendado = _modo == 'AGENDADO';
    final isProposta = _modo == 'POR_PROPOSTA';

    String tituloTopo;
    String subtituloTopo;
    if (isImediato) {
      tituloTopo = 'Serviço imediato';
      subtituloTopo =
          'Um prestador disponível será chamado o mais rápido possível.';
    } else if (isAgendado) {
      tituloTopo = 'Serviço por agendamento';
      subtituloTopo = 'Escolhe o dia e hora para o prestador ir até ti.';
    } else {
      tituloTopo = 'Serviço por proposta';
      subtituloTopo =
          'Descreve o que precisas e vários prestadores vão enviar orçamentos.';
    }

    final hintTitulo = _exemploTitulo(_categoriaNome, _modo);
    final hintDescricao = _exemploDescricao(_categoriaNome, _modo);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar pedido' : 'Novo pedido'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Servico>>(
          stream: ServicosRepo.streamServicosAtivos(),
          builder: (context, snapshot) {
            final loading =
                snapshot.connectionState == ConnectionState.waiting;
            final todos = snapshot.data ?? [];

            // filtra pelo modo
            final servicosFiltrados = todos.where((s) {
              if (isImediato) return s.mode == 'IMEDIATO';
              if (isAgendado) return s.mode == 'AGENDADO';
              if (isProposta) return s.mode == 'POR_PROPOSTA';
              return true;
            }).toList();

            // garantir que a categoria actual aparece (especialmente em edição)
            final nomes = servicosFiltrados.map((s) => s.name).toList();
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
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
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

                    // Categoria
                    const Text(
                      'Categoria',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
                      DropdownButtonFormField<String>(
                        value: _categoriaNome != null &&
                                _categoriaNome!.isNotEmpty
                            ? _categoriaNome
                            : null,
                        items: servicosFiltrados
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s.name,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(16)),
                          ),
                          hintText: 'Escolhe a categoria',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _categoriaNome = value;
                          });
                        },
                      ),
                    const SizedBox(height: 16),

                    // Título
                    const Text(
                      'Título do pedido',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
                          return 'Escreve um título para o pedido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descrição
                    const Text(
                      'Descrição (opcional)',
                      style: TextStyle(fontWeight: FontWeight.w600),
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

                    // Agendamento
                    if (isAgendado) ...[
                      const Text(
                        'Data e hora',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
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
                              Icon(Icons.event, color: primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _agendadoPara == null
                                      ? 'Escolher dia e hora'
                                      : df.format(_agendadoPara!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 24),

                    // Botão
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _salvando ? null : _submeter,
                        child: _salvando
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                isEditing
                                    ? 'Guardar alterações'
                                    : 'Criar pedido',
                              ),
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
