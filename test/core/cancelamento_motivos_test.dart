import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/utils/cancelamento_motivos.dart';

void main() {
  test('cliente motivos include expected ids', () {
    final motivos = CancelamentoMotivos.forCliente(emServico: false);
    final ids = motivos.map((m) => m.id).toSet();

    expect(ids.contains('nao_informado'), isTrue);
    expect(ids.contains('preco_alto'), isTrue);
    expect(ids.contains('outro'), isTrue);
  });

  test('cliente motivos in service exclude preco_alto', () {
    final motivos = CancelamentoMotivos.forCliente(emServico: true);
    final ids = motivos.map((m) => m.id).toSet();

    expect(ids.contains('preco_alto'), isFalse);
    expect(ids.contains('prestador_nao_compareceu'), isTrue);
  });

  test('prestador motivos include expected ids', () {
    final motivos = CancelamentoMotivos.forPrestador(emServico: false);
    final ids = motivos.map((m) => m.id).toSet();

    expect(ids.contains('cliente_nao_responde'), isTrue);
    expect(ids.contains('fora_da_area'), isTrue);
    expect(ids.contains('outro'), isTrue);
  });

  test('prestador motivos in service include no-show', () {
    final motivos = CancelamentoMotivos.forPrestador(emServico: true);
    final ids = motivos.map((m) => m.id).toSet();

    expect(ids.contains('cliente_ausente'), isTrue);
    expect(ids.contains('indisponivel'), isFalse);
  });

  test('motivo outro requires detail', () {
    final all = [
      ...CancelamentoMotivos.forCliente(emServico: false),
      ...CancelamentoMotivos.forCliente(emServico: true),
      ...CancelamentoMotivos.forPrestador(emServico: false),
      ...CancelamentoMotivos.forPrestador(emServico: true),
    ];

    final outros = all.where((m) => m.id == 'outro');
    expect(outros.isNotEmpty, isTrue);
    for (final motivo in outros) {
      expect(motivo.requiresDetail, isTrue);
    }
  });

  test('motivo ids are unique per list', () {
    for (final list in [
      CancelamentoMotivos.forCliente(emServico: false),
      CancelamentoMotivos.forCliente(emServico: true),
      CancelamentoMotivos.forPrestador(emServico: false),
      CancelamentoMotivos.forPrestador(emServico: true),
    ]) {
      final ids = list.map((m) => m.id).toList();
      final unique = ids.toSet();
      expect(unique.length, ids.length);
    }
  });
}
