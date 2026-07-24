import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('targeted dispatch maps the target provider without private identity',
      () {
    final expiresAt = DateTime.utc(2026, 7, 21, 12);
    final pedido = Pedido.fromMap('pedido_target', {
      'pedidoId': 'pedido_target',
      'targetProviderId': 'provider1',
      'prestadorId': null,
      'servicoId': 'plumbing',
      'servicoNome': 'Canalizacao',
      'status': 'aguarda_resposta_cliente',
      'modo': 'POR_PROPOSTA',
      'tipoPreco': 'por_orcamento',
      'valorMinEstimadoPrestador': 500,
      'valorMaxEstimadoPrestador': 750,
      'statusProposta': 'pendente_cliente',
      'propostaExpiresAt': Timestamp.fromDate(expiresAt),
      'enderecoTexto': 'Zona Norte',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 7, 21, 10)),
    });

    expect(pedido.prestadorId, 'provider1');
    expect(pedido.clienteId, isEmpty);
    expect(pedido.status, 'aguarda_resposta_cliente');
    expect(pedido.valorMinEstimadoPrestador, 500);
    expect(pedido.valorMaxEstimadoPrestador, 750);
    expect(pedido.propostaExpiresAt?.isAtSameMomentAs(expiresAt), isTrue);
    expect(pedido.mensagemPropostaPrestador, isNull);
    expect(pedido.enderecoTexto, 'Zona Norte');
    expect(pedido.hasAcceptedProviderAccess, isFalse);
  });

  test('full pedido exposes the accepted provider grant explicitly', () {
    final grantedAt = DateTime.utc(2026, 7, 21, 13);
    final pedido = Pedido.fromMap('pedido_granted', {
      'clienteId': 'client1',
      'prestadorId': 'provider1',
      'providerAccessGranted': true,
      'providerAccessGrantedTo': 'provider1',
      'providerAccessGrantedAt': Timestamp.fromDate(grantedAt),
      'status': 'aceito',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 7, 21, 10)),
    });

    expect(pedido.hasAcceptedProviderAccess, isTrue);
    expect(pedido.providerAccessGranted, isTrue);
    expect(
      pedido.providerAccessGrantedAt?.isAtSameMomentAs(grantedAt),
      isTrue,
    );

    final revoked = pedido.copyWith(clearProviderAccess: true);
    expect(revoked.providerAccessGranted, isFalse);
    expect(revoked.providerAccessGrantedTo, isNull);
    expect(revoked.providerAccessGrantedAt, isNull);
    expect(revoked.hasAcceptedProviderAccess, isFalse);
  });

  test('epoch or malformed grant timestamps never activate private access', () {
    final pedido = Pedido.fromMap('pedido_epoch', {
      'clienteId': 'client1',
      'prestadorId': 'provider1',
      'providerAccessGranted': true,
      'providerAccessGrantedTo': 'provider1',
      'providerAccessGrantedAt': Timestamp.fromMillisecondsSinceEpoch(0),
      'status': 'aceito',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 7, 21, 10)),
    });

    expect(pedido.hasAcceptedProviderAccess, isFalse);
  });
}
