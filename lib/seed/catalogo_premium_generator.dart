// lib/seed/catalogo_premium_generator.dart
// Gerador de catálogo PREMIUM com 2.000+ serviços organizados hierarquicamente

import 'catalogo_premium_data.dart';

/// Gera catálogo completo com 2.000+ serviços
List<Map<String, dynamic>> gerarCatalogoPremium({int? limit}) {
  final servicos = <Map<String, dynamic>>[];
  final ids = <String>{};
  int contador = 1;

  for (final macro in macrosCatalogo) {
    for (final categoria in macro.categorias) {
      // 1. Adicionar serviço base da categoria (se aplicável)
      if (categoria.incluirBase) {
        final id = 'SRV-${contador.toString().padLeft(4, '0')}';
        servicos.add(_criarServico(
          id: id,
          nome: categoria.nomeBase,
          macro: macro.nome,
          categoria: categoria.nome,
          especialidade: null,
          mode: categoria.mode,
          nivel: categoria.nivelVerificacao,
          preco: categoria.precoMedio,
          duracao: categoria.duracaoMedia,
          keywords: categoria.keywords,
          descricao: categoria.descricao,
          iconKey: categoria.iconKey ?? macro.iconKey,
          cor: macro.cor,
        ));
        ids.add(id);
        contador++;
      }

      // 2. Gerar serviços por especialidade
      for (final espec in categoria.especialidades) {
        // Adicionar especialidade base
        final especId = 'SRV-${contador.toString().padLeft(4, '0')}';
        servicos.add(_criarServico(
          id: especId,
          nome: espec.nome,
          macro: macro.nome,
          categoria: categoria.nome,
          especialidade: espec.nome,
          mode: espec.mode ?? categoria.mode,
          nivel: espec.nivelVerificacao ?? categoria.nivelVerificacao,
          preco: espec.precoMedio ?? categoria.precoMedio,
          duracao: espec.duracaoMedia ?? categoria.duracaoMedia,
          keywords: [...categoria.keywords, ...espec.keywords],
          sinonimos: espec.sinonimos,
          descricao: espec.descricao,
          exemplos: espec.exemplosPedidos,
          credenciais: espec.credenciais,
          entidade: espec.entidadeReguladora,
          linkOrdem: espec.linkOrdem,
          requerSeguro: espec.requerSeguro,
          requerPortfolio: espec.requerPortfolio,
          iconKey: espec.iconKey ?? categoria.iconKey ?? macro.iconKey,
          cor: macro.cor,
        ));
        ids.add(especId);
        contador++;

        // 3. Gerar variações por ações e objetos
        if (espec.acoes.isNotEmpty && espec.objetos.isNotEmpty) {
          for (final acao in espec.acoes) {
            for (final objeto in espec.objetos) {
              final variacaoId = 'SRV-${contador.toString().padLeft(4, '0')}';
              final nomeVariacao = '${acao.label} ${objeto.nome}';

              servicos.add(_criarServico(
                id: variacaoId,
                nome: nomeVariacao,
                macro: macro.nome,
                categoria: categoria.nome,
                especialidade: espec.nome,
                mode: objeto.mode ?? espec.mode ?? categoria.mode,
                nivel: espec.nivelVerificacao ?? categoria.nivelVerificacao,
                preco: objeto.precoMedio ?? espec.precoMedio ?? categoria.precoMedio,
                duracao: objeto.duracaoMedia ?? espec.duracaoMedia ?? categoria.duracaoMedia,
                keywords: [
                  ...categoria.keywords,
                  ...espec.keywords,
                  ...acao.keywords,
                  ...objeto.keywords,
                ],
                descricao: '${acao.label} ${objeto.nome}. ${espec.descricao}',
                credenciais: espec.credenciais,
                entidade: espec.entidadeReguladora,
                linkOrdem: espec.linkOrdem,
                requerSeguro: espec.requerSeguro,
                requerPortfolio: espec.requerPortfolio,
                iconKey: espec.iconKey ?? categoria.iconKey ?? macro.iconKey,
                cor: macro.cor,
              ));
              ids.add(variacaoId);
              contador++;
            }
          }
        }
      }
    }
  }

  print('✅ Gerado ${servicos.length} serviços no catálogo premium!');

  if (limit != null && servicos.length > limit) {
    return servicos.sublist(0, limit);
  }

  return servicos;
}

/// Cria um serviço formatado para Firestore
Map<String, dynamic> _criarServico({
  required String id,
  required String nome,
  required String macro,
  required String categoria,
  String? especialidade,
  required String mode,
  required NivelVerificacaoEnum nivel,
  PrecoMedio? preco,
  int? duracao,
  required List<String> keywords,
  List<String> sinonimos = const [],
  String? descricao,
  List<String> exemplos = const [],
  List<String> credenciais = const [],
  String? entidade,
  String? linkOrdem,
  bool requerSeguro = false,
  bool requerPortfolio = false,
  String? iconKey,
  String? cor,
}) {
  // Normalizar keywords (remover acentos, lowercase)
  final keywordsNormalizadas = keywords.map(_normalizar).toSet().toList();

  // Criar texto pesquisável (para full-text search futuro)
  final searchableText = [
    nome,
    macro,
    categoria,
    if (especialidade != null) especialidade,
    ...keywords,
    ...sinonimos,
    if (descricao != null) descricao,
  ].join(' ').toLowerCase();

  // Tags automáticas
  final tags = <String>{
    _slugify(macro),
    _slugify(categoria),
    if (especialidade != null) _slugify(especialidade),
    if (nivel != NivelVerificacaoEnum.nenhum) 'verificado',
    if (requerSeguro) 'seguro',
    if (requerPortfolio) 'portfolio',
  }.toList();

  return {
    'id': id,
    'nome': nome,
    'slug': _slugify(nome),
    'macro': macro,
    'categoria': categoria,
    if (especialidade != null) 'especialidade': especialidade,
    'mode': mode,
    'tipoPrecificacao': preco != null ? 'fixo' : 'a_combinar',
    if (preco != null) 'precoMedioMin': preco.min,
    if (preco != null) 'precoMedioMax': preco.max,
    if (duracao != null) 'duracaoMediaMinutos': duracao,
    'nivelVerificacao': nivel.name,
    'credenciaisObrigatorias': credenciais,
    if (entidade != null) 'entidadeReguladora': entidade,
    if (linkOrdem != null) 'linkOrdem': linkOrdem,
    'requerSeguro': requerSeguro,
    'requerPortfolio': requerPortfolio,
    'keywords': keywords,
    'keywordsNormalizadas': keywordsNormalizadas,
    'sinonimos': sinonimos,
    'tags': tags,
    'searchableText': searchableText,
    if (descricao != null) 'descricao': descricao,
    'exemplosPedidos': exemplos,
    if (iconKey != null) 'iconKey': iconKey,
    if (cor != null) 'cor': cor,
    'totalPedidos': 0,
    'totalPrestadores': 0,
    'isPopular': false,
    'isTendencia': false,
    'isActive': true,
    // 'createdAt' e 'updatedAt' serão adicionados pelo seed script
  };
}

/// Normaliza texto (remove acentos, lowercase, trim)
String _normalizar(String text) {
  const comAcento = 'áàâãéèêíïóôõöúçÁÀÂÃÉÈÊÍÏÓÔÕÖÚÇ';
  const semAcento = 'aaaaeeeiiooooucAAAAAEEEIIOOOOUC';

  var normalized = text.toLowerCase().trim();

  for (var i = 0; i < comAcento.length; i++) {
    normalized = normalized.replaceAll(comAcento[i], semAcento[i]);
  }

  return normalized;
}

/// Cria slug URL-friendly
String _slugify(String text) {
  return _normalizar(text)
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^\w-]'), '')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
