import 'dart:async';

import 'package:chegaja_v2/core/services/role_mode_service.dart';
import 'package:chegaja_v2/features/auth/role_selector_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('seleciona papel local sem esperar pela autenticacao remota', () async {
    final service = RoleModeService.forTesting();
    await service.load();
    final authBlocker = Completer<void>();
    var remoteRole = '';

    await selectRoleForApp(
      role: 'cliente',
      roleModeService: service,
      ensureSignedIn: () => authBlocker.future,
      syncActiveRole: (role) async => remoteRole = role,
    ).timeout(const Duration(milliseconds: 200));

    expect(service.currentRole, 'cliente');
    expect(remoteRole, isEmpty);

    authBlocker.complete();
    await Future<void>.delayed(Duration.zero);
    expect(remoteRole, 'cliente');
  });
}
