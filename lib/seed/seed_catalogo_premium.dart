// lib/seed/seed_catalogo_premium.dart
// Script para popular o Firestore com o catálogo premium completo

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'catalogo_premium_generator.dart';

/// Popula Firestore com o catálogo premium
///
/// IMPORTANTE: Execute este script com cuidado!
/// - Verifica se há serviços existentes antes de popular
/// - Pode ser executado em modo MERGE (atualiza) ou REPLACE (limpa antes)
/// - Cria índices automaticamente
Future<void> seedCatalogoPremium({
  bool forceClear = false,
  bool dryRun = false,
  int? limit,
}) async {
  print('🚀 ChegaJá - Seed do Catálogo Premium');
  print('========================================\n');

  // Inicializar Firebase (se ainda não estiver)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('✅ Firebase já inicializado');
  }

  final firestore = FirebaseFirestore.instance;
  final servicosRef = firestore.collection('servicos');

  // 1. Verificar estado atual
  print('📊 Verificando estado atual do catálogo...');
  final existingCount = await servicosRef.count().get();
  final currentCount = existingCount.count;

  if (currentCount > 0) {
    print('⚠️  ATENÇÃO: Já existem $currentCount serviços no Firestore!');

    if (!forceClear) {
      print('');
      print('Opções:');
      print('  1. Use forceClear: true para limpar e repovoar');
      print('  2. Use dryRun: true para apenas ver o que seria criado');
      print('  3. Os novos serviços serão MERGEADOS com os existentes');
      print('');

      if (dryRun) {
        print('🔍 Modo DRY RUN - Nenhuma alteração será feita\n');
      } else {
        print('▶️  Continuando em modo MERGE...\n');
      }
    } else {
      if (dryRun) {
        print('🔍 Modo DRY RUN - Simulando limpeza de $currentCount serviços\n');
      } else {
        print('🗑️  Limpando $currentCount serviços existentes...');
        await _limparServicos(servicosRef);
        print('✅ Limpeza concluída!\n');
      }
    }
  } else {
    print('✅ Catálogo vazio - pronto para popular\n');
  }

  // 2. Gerar serviços
  print('🏗️  Gerando catálogo premium...');
  final servicos = gerarCatalogoPremium(limit: limit);
  print('✅ ${servicos.length} serviços gerados!\n');

  if (dryRun) {
    print('📋 DRY RUN - Serviços que seriam criados:\n');
    _mostrarEstatisticas(servicos);
    print('\n✅ DRY RUN completo - Nenhuma alteração foi feita');
    return;
  }

  // 3. Popular Firestore em batches
  print('📤 Populando Firestore...');
  await _popularFirestore(servicosRef, servicos);
  print('✅ Serviços salvos no Firestore!\n');

  // 4. Criar índices
  print('📇 Criando índices (verifique Firebase Console)...');
  _mostrarIndicesNecessarios();

  // 5. Estatísticas finais
  print('\n📊 RESUMO FINAL');
  print('=' * 50);
  _mostrarEstatisticas(servicos);

  print('\n✅ Seed do catálogo premium concluído com sucesso!');
  print('🎯 Total de serviços no Firestore: ${servicos.length}');
}

/// Limpa todos os serviços existentes
Future<void> _limparServicos(CollectionReference servicosRef) async {
  final snapshot = await servicosRef.get();

  final batches = <WriteBatch>[];
  var currentBatch = FirebaseFirestore.instance.batch();
  var operationCount = 0;

  for (final doc in snapshot.docs) {
    currentBatch.delete(doc.reference);
    operationCount++;

    // Firestore permite max 500 operações por batch
    if (operationCount >= 500) {
      batches.add(currentBatch);
      currentBatch = FirebaseFirestore.instance.batch();
      operationCount = 0;
    }
  }

  if (operationCount > 0) {
    batches.add(currentBatch);
  }

  // Executar todos os batches
  for (var i = 0; i < batches.length; i++) {
    await batches[i].commit();
    print('  Batch ${i + 1}/${batches.length} executado (${(i + 1) * 500} docs)');
  }
}

/// Popula Firestore com os serviços gerados
Future<void> _popularFirestore(
  CollectionReference servicosRef,
  List<Map<String, dynamic>> servicos,
) async {
  final batches = <WriteBatch>[];
  var currentBatch = FirebaseFirestore.instance.batch();
  var operationCount = 0;

  for (final servico in servicos) {
    final docRef = servicosRef.doc(servico['id']);

    // Adicionar timestamps
    final data = {
      ...servico,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    currentBatch.set(docRef, data, SetOptions(merge: true));
    operationCount++;

    if (operationCount >= 500) {
      batches.add(currentBatch);
      currentBatch = FirebaseFirestore.instance.batch();
      operationCount = 0;
    }
  }

  if (operationCount > 0) {
    batches.add(currentBatch);
  }

  // Executar batches com progresso
  for (var i = 0; i < batches.length; i++) {
    await batches[i].commit();
    final progress = ((i + 1) / batches.length * 100).toStringAsFixed(1);
    print('  Progresso: $progress% (${(i + 1) * 500}/${servicos.length} serviços)');
  }
}

/// Mostra estatísticas do catálogo
void _mostrarEstatisticas(List<Map<String, dynamic>> servicos) {
  // Agrupar por macro
  final porMacro = <String, int>{};
  final porCategoria = <String, int>{};
  final porNivelVerificacao = <String, int>{};
  final porMode = <String, int>{};

  for (final servico in servicos) {
    final macro = servico['macro']?.toString() ?? 'Sem macro';
    final categoria = servico['categoria']?.toString() ?? 'Sem categoria';
    final nivel = servico['nivelVerificacao']?.toString() ?? 'nenhum';
    final mode = servico['mode']?.toString() ?? 'IMEDIATO';

    porMacro[macro] = (porMacro[macro] ?? 0) + 1;
    porCategoria[categoria] = (porCategoria[categoria] ?? 0) + 1;
    porNivelVerificacao[nivel] = (porNivelVerificacao[nivel] ?? 0) + 1;
    porMode[mode] = (porMode[mode] ?? 0) + 1;
  }

  print('Por Macro:');
  porMacro.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))
    ..forEach((e) => print('  ${e.key}: ${e.value}'));

  print('\nPor Nível de Verificação:');
  porNivelVerificacao.entries.forEach((e) => print('  ${e.key}: ${e.value}'));

  print('\nPor Modo:');
  porMode.entries.forEach((e) => print('  ${e.key}: ${e.value}'));

  print('\nTop 10 Categorias:');
  porCategoria.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))
    ..take(10)
    ..forEach((e) => print('  ${e.key}: ${e.value}'));
}

/// Mostra índices necessários no Firestore
void _mostrarIndicesNecessarios() {
  print('''

📇 Índices recomendados (criar no Firebase Console):

1. Índice composto para pesquisa geográfica:
   Coleção: servicos
   Campos: isActive (Ascending), macro (Ascending), keywordsNormalizadas (Arrays)

2. Índice para filtro por verificação:
   Coleção: servicos
   Campos: isActive (Ascending), nivelVerificacao (Ascending), avaliacaoMedia (Descending)

3. Índice para pesquisa por categoria:
   Coleção: servicos
   Campos: isActive (Ascending), categoria (Ascending), totalPedidos (Descending)

4. Índice para popularidade:
   Coleção: servicos
   Campos: isActive (Ascending), isPopular (Descending), avaliacaoMedia (Descending)

Estes índices serão criados automaticamente quando as queries falharem.
Aguarde os links no console do Firebase.
''');
}

// ============================================================================
// FUNÇÕES AUXILIARES PARA TESTES
// ============================================================================

/// Conta serviços por macro
Future<Map<String, int>> contarServicosPorMacro() async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('servicos').get();

  final contagem = <String, int>{};

  for (final doc in snapshot.docs) {
    final macro = doc.data()['macro']?.toString() ?? 'Sem macro';
    contagem[macro] = (contagem[macro] ?? 0) + 1;
  }

  return contagem;
}

/// Busca serviços por keyword
Future<List<Map<String, dynamic>>> buscarPorKeyword(String keyword) async {
  final firestore = FirebaseFirestore.instance;
  final normalizada = keyword.toLowerCase();

  final snapshot = await firestore
      .collection('servicos')
      .where('keywordsNormalizadas', arrayContains: normalizada)
      .limit(20)
      .get();

  return snapshot.docs.map((doc) {
    return {'id': doc.id, ...doc.data()};
  }).toList();
}

/// Exporta catálogo para JSON (backup)
Future<void> exportarCatalogoParaJSON(String outputPath) async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('servicos').get();

  final servicos = snapshot.docs.map((doc) {
    return {'id': doc.id, ...doc.data()};
  }).toList();

  // Aqui você pode salvar em arquivo
  // import 'dart:convert';
  // import 'dart:io';
  // final json = jsonEncode(servicos);
  // await File(outputPath).writeAsString(json);

  print('✅ ${servicos.length} serviços exportados para $outputPath');
}
