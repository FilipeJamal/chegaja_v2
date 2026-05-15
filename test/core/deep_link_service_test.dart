import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/services/deep_link_service.dart';

void main() {
  test('extracts pedido id from custom scheme pedido link', () {
    final uri = Uri.parse('chegaja://pedido/pedido_123');

    expect(DeepLinkService.extractPedidoIdForTesting(uri), 'pedido_123');
    expect(DeepLinkService.extractOpenChatForTesting(uri), isFalse);
  });

  test('extracts chat target from custom scheme chat link', () {
    final uri = Uri.parse('chegaja://chat/pedido_123');

    expect(DeepLinkService.extractPedidoIdForTesting(uri), 'pedido_123');
    expect(DeepLinkService.extractOpenChatForTesting(uri), isTrue);
  });

  test('extracts pedido id from https path and query formats', () {
    final pathUri = Uri.parse('https://app.chegaja.pt/pedido/pedido_456');
    final queryUri = Uri.parse('https://chegaja.pt/?pedidoId=pedido_789');

    expect(DeepLinkService.extractPedidoIdForTesting(pathUri), 'pedido_456');
    expect(DeepLinkService.extractPedidoIdForTesting(queryUri), 'pedido_789');
  });

  test('detects chat from query type', () {
    final uri = Uri.parse('https://app.chegaja.pt/?pedidoId=p1&type=chat');

    expect(DeepLinkService.extractPedidoIdForTesting(uri), 'p1');
    expect(DeepLinkService.extractOpenChatForTesting(uri), isTrue);
  });
}
