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

  test('extracts public profile handle from web and custom scheme paths', () {
    final webUri = Uri.parse('https://app.chegaja.pt/p/maria_bolos');
    final atUri = Uri.parse('https://app.chegaja.pt/p/@Maria_Bolos');
    final schemeUri = Uri.parse('chegaja://p/maria_bolos');

    expect(
      DeepLinkService.extractPublicProfileHandleForTesting(webUri),
      'maria_bolos',
    );
    expect(
      DeepLinkService.extractPublicProfileHandleForTesting(atUri),
      'maria_bolos',
    );
    expect(
      DeepLinkService.extractPublicProfileHandleForTesting(schemeUri),
      'maria_bolos',
    );
  });

  test('public handle parsing does not break pedido or chat links', () {
    final pedidoUri = Uri.parse('https://app.chegaja.pt/pedido/pedido_456');
    final chatUri = Uri.parse('https://app.chegaja.pt/chat/pedido_789');

    expect(DeepLinkService.extractPublicProfileHandleForTesting(pedidoUri),
        isNull);
    expect(
        DeepLinkService.extractPublicProfileHandleForTesting(chatUri), isNull);
    expect(DeepLinkService.extractPedidoIdForTesting(pedidoUri), 'pedido_456');
    expect(DeepLinkService.extractPedidoIdForTesting(chatUri), 'pedido_789');
  });
}
