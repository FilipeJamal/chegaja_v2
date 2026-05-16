import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/services/storage_path_policy.dart';

void main() {
  group('StoragePathPolicy', () {
    test('uses authenticated user folder for temporary pedido attachments', () {
      expect(
        StoragePathPolicy.tempPedidoAttachmentFolder(userId: 'cliente_1'),
        'temp/cliente_1/anexos',
      );
    });

    test('rejects blank user id for temporary pedido attachments', () {
      expect(
        () => StoragePathPolicy.tempPedidoAttachmentFolder(userId: '  '),
        throwsArgumentError,
      );
    });

    test('sanitizes file names used in Storage paths', () {
      expect(
        StoragePathPolicy.safeFileName('../foto cliente 1.jpg'),
        'foto_cliente_1.jpg',
      );
      expect(StoragePathPolicy.safeFileName(''), 'file');
    });

    test('maps supported attachment content types from file names', () {
      expect(
        StoragePathPolicy.attachmentContentTypeForFileName('foto.jpeg'),
        'image/jpeg',
      );
      expect(
        StoragePathPolicy.attachmentContentTypeForFileName('orcamento.pdf'),
        'application/pdf',
      );
      expect(
        StoragePathPolicy.attachmentContentTypeForFileName('notas.txt'),
        'text/plain',
      );
      expect(
        StoragePathPolicy.attachmentContentTypeForFileName('programa.exe'),
        isNull,
      );
    });
  });
}
