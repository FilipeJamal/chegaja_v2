// scripts/export_servicos_json.dart
// Exports the initial servicos seed list to JSON.
//
// Usage:
//   dart run scripts/export_servicos_json.dart
//   dart run scripts/export_servicos_json.dart --output=scripts/servicos_seed.json
//   dart run scripts/export_servicos_json.dart --limit=200

import 'dart:convert';
import 'dart:io';

import 'package:chegaja_v2/seed/initial_servicos_full.dart';

void main(List<String> args) {
  var outputPath = 'scripts/servicos_seed.json';
  int? limit;

  for (final arg in args) {
    if (arg.startsWith('--output=')) {
      outputPath = arg.substring('--output='.length);
    } else if (arg.startsWith('--limit=')) {
      limit = int.tryParse(arg.substring('--limit='.length));
    }
  }

  final data = limit == null || limit <= 0 || limit >= initialServicosFull.length
      ? initialServicosFull
      : initialServicosFull.sublist(0, limit);

  const encoder = JsonEncoder.withIndent('  ');
  final json = encoder.convert(data);
  File(outputPath).writeAsStringSync('$json\n');
  stdout.writeln('Wrote ${data.length} items to $outputPath');
}
