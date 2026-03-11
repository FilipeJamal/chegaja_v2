// scripts/seed_catalog.dart
// Executable script to seed premium catalog into Firestore.
//
// Usage:
//   dart scripts/seed_catalog.dart [options]
//
// Options:
//   --dry-run
//   --force-clear
//   --limit=N
//   --help

import 'dart:io';

import 'package:chegaja_v2/firebase_options.dart';
import 'package:chegaja_v2/seed/seed_catalogo_premium.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main(List<String> arguments) async {
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
    _showHelp();
    exit(0);
  }

  stdout.writeln('''
+--------------------------------------------------------------+
| ChegaJa - Premium Catalog Seeder v2.0                        |
| Massive catalog with 2,000+ services                         |
+--------------------------------------------------------------+
''');

  if (dryRun) {
    stdout.writeln('[DRY RUN] No changes will be made.\n');
  }

  if (forceClear) {
    stdout.writeln('[FORCE CLEAR] Existing catalog will be cleared.\n');
  }

  if (limit != null) {
    stdout.writeln('[LIMIT] Only $limit services will be generated.\n');
  }

  if (!dryRun) {
    stdout.writeln('[WARNING] This operation will modify Firestore.');
    stdout.writeln('Do you want to continue? (y/N): ');
    final answer = stdin.readLineSync()?.trim().toLowerCase();

    if (answer != 'y' && answer != 'yes' && answer != 's' && answer != 'sim') {
      stdout.writeln('Operation canceled by user.');
      exit(0);
    }
    stdout.writeln('');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await seedCatalogoPremium(
      dryRun: dryRun,
      forceClear: forceClear,
      limit: limit,
    );

    stdout.writeln('\nSUCCESS');
    exit(0);
  } catch (e, stackTrace) {
    stdout.writeln('\nERROR: $e');
    stdout.writeln('Stack trace: $stackTrace');
    exit(1);
  }
}

void _showHelp() {
  stdout.writeln('''
ChegaJa - Premium Catalog Seeder

Usage:
  dart scripts/seed_catalog.dart [options]

Options:
  --dry-run         Simulate without changing Firestore
  --force-clear     Clear existing catalog before seeding
  --limit=N         Limit generated services (for tests)
  --help, -h        Show this help message

Examples:
  dart scripts/seed_catalog.dart --dry-run
  dart scripts/seed_catalog.dart --limit=500
  dart scripts/seed_catalog.dart --force-clear
  dart scripts/seed_catalog.dart
''');
}
