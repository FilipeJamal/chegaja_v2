import 'package:chegaja_v2/core/services/private_storage_media_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aceita apenas caminhos internos privados suportados', () {
    expect(
      PrivateStorageMediaService.isPrivatePath(
        'chats/pedido-1/images/photo.jpg',
      ),
      isTrue,
    );
    expect(
      PrivateStorageMediaService.isPrivatePath(
        'pedidos/pedido-1/anexos/file.pdf',
      ),
      isTrue,
    );
    expect(
      PrivateStorageMediaService.isPrivatePath('temp/user-1/anexos/file.pdf'),
      isTrue,
    );
    expect(
      PrivateStorageMediaService.isPrivatePath('portfolio/user-1/photo.jpg'),
      isFalse,
    );
    expect(
      PrivateStorageMediaService.isPrivatePath('chats/p1/../secret.txt'),
      isFalse,
    );
    expect(
      PrivateStorageMediaService.isPrivatePath(
        'https://storage.invalid/object?token=secret',
      ),
      isFalse,
    );
  });

  test('URL pública é devolvida sem inicializar Firebase', () async {
    const url = 'https://cdn.example.invalid/public.jpg';
    expect(
      await PrivateStorageMediaService.resolveReferenceLazily(url),
      url,
    );
  });
}
