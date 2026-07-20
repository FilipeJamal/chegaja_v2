import 'package:chegaja_v2/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serviço genérico aceita apenas destinos públicos explícitos', () {
    expect(
      StorageService.isPublicDestinationPath(
        'profile_public/u1/profile.jpg',
      ),
      isTrue,
    );
    expect(
      StorageService.isPublicDestinationPath('portfolio/u1/work.jpg'),
      isTrue,
    );
    expect(
      StorageService.isPublicDestinationPath('chats/p1/files/private.pdf'),
      isFalse,
    );
    expect(
      StorageService.isPublicDestinationPath('users/u1/profile.jpg'),
      isFalse,
    );
    expect(
      StorageService.isPublicDestinationPath('portfolio/u1/../document.pdf'),
      isFalse,
    );
  });
}
