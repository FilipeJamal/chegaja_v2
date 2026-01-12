// scripts/seed_catalog.dart
// Script executável para popular o catálogo premium no Firestore
//
// USAGE:
//   dart scripts/seed_catalog.dart [options]
//
// OPTIONS:
//   --dry-run         Simula sem fazer alterações
//   --force-clear     Limpa catálogo existente antes de popular
//   --limit=N         Limita a N serviços (para testes)
//   --help            Mostra esta ajuda

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';
import '../lib/seed/seed_catalogo_premium.dart';

void main(List<String> arguments) async {
  // Parse argumentos
  var dryRun = false;
  var forceClear = false;
  int? limit;
  var showHelp = false;

  for (final arg in arguments) {
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--force-clear') {
      forceClear = true;
    } else if (arg.startsWith('--limit=')) {
      limit = int.tryParse(arg.substring(8));
    } else if (arg == '--help' || arg == '-h') {
      showHelp = true;
    }
  }

  if (showHelp) {
    _mostrarAjuda();
    exit(0);
  }

  print('''
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║       ChegaJá - Gerador de Catálogo Premium v2.0            ║
║       Catálogo Massivo com 2.000+ Serviços                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

''');

  if (dryRun) {
    print('🔍 MODO DRY RUN - Nenhuma alteração será feita\n');
  }

  if (forceClear) {
    print('⚠️  MODO FORCE CLEAR - Catálogo existente será limpo!\n');
  }

  if (limit != null) {
    print('🎯 LIMITE: Apenas $limit serviços serão gerados\n');
  }

  // Confirmar se não for dry-run
  if (!dryRun) {
    print('⚠️  Esta operação irá modificar o Firestore!');
    print('Deseja continuar? (s/N): ');
    final resposta = stdin.readLineSync()?.toLowerCase();

    if (resposta != 's' && resposta != 'sim') {
      print('❌ Operação cancelada pelo utilizador');
      exit(0);
    }
    print('');
  }

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Executar seed
    await seedCatalogoPremium(
      dryRun: dryRun,
      forceClear: forceClear,
      limit: limit,
    );

    print('\n✅ SUCESSO!');
    exit(0);
  } catch (e, stackTrace) {
    print('\n❌ ERRO: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

void _mostrarAjuda() {
  print('''
ChegaJá - Script de Seed do Catálogo Premium

USAGE:
  dart scripts/seed_catalog.dart [options]

OPTIONS:
  --dry-run         Simula a operação sem fazer alterações no Firestore
                    Útil para ver quantos serviços serão criados

  --force-clear     CUIDADO! Limpa todos os serviços existentes antes de popular
                    Use apenas se quiser começar do zero

  --limit=N         Limita a criação de N serviços (para testes)
                    Exemplo: --limit=100

  --help, -h        Mostra esta mensagem de ajuda

EXEMPLOS:
  # Ver quantos serviços serão criados (sem alterar Firestore)
  dart scripts/seed_catalog.dart --dry-run

  # Popular com limite de 500 serviços (para testar)
  dart scripts/seed_catalog.dart --limit=500

  # Limpar catálogo existente e popular com catálogo completo
  dart scripts/seed_catalog.dart --force-clear

  # Popular catálogo completo (merge com existentes)
  dart scripts/seed_catalog.dart

IMPORTANTE:
  - Sempre execute --dry-run primeiro para ver o que será feito!
  - Use --force-clear apenas se tiver certeza absoluta
  - Em produção, faça backup antes de usar --force-clear

ESTRUTURA DO CATÁLOGO:
  12 Macros → 60+ Categorias → 250+ Especialidades → 2.000+ Serviços

  Macros incluídos:
    1. Saúde e Bem-Estar
    2. Jurídico e Finanças
    3. Casa e Obras
    4. Educação
    5. Tecnologia
    6. Beleza e Estética
    7. Auto e Mobilidade
    8. Limpeza
    9. Entregas e Mudanças
    10. Criativo
    11. Eventos
    12. Pets e Animais
''');
}
