import 'package:chegaja_v2/core/services/role_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('sem role resolvida fica sem modo ativo', () async {
    final service = RoleModeService.forTesting();

    await service.load();

    expect(service.isLoaded, isTrue);
    expect(service.currentRole, isNull);
  });

  test('role da URL tem prioridade sobre role persistida', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      RoleModeService.storageKey: 'prestador',
    });
    final service = RoleModeService.forTesting();

    await service.load(urlRole: 'cliente');

    expect(service.currentRole, 'cliente');
  });

  test('usa role persistida quando nao ha role na URL', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      RoleModeService.storageKey: 'prestador',
    });
    final service = RoleModeService.forTesting();

    await service.load();

    expect(service.currentRole, 'prestador');
  });

  test('usa DEFAULT_ROLE quando nao ha URL nem role persistida', () async {
    final service = RoleModeService.forTesting();

    await service.load(defaultRole: 'cliente');

    expect(service.currentRole, 'cliente');
  });

  test('setMode persiste e notifica modo valido', () async {
    final service = RoleModeService.forTesting();
    var notifications = 0;
    service.addListener(() => notifications += 1);

    await service.load();
    await service.setMode('prestador');

    final prefs = await SharedPreferences.getInstance();
    expect(service.currentRole, 'prestador');
    expect(prefs.getString(RoleModeService.storageKey), 'prestador');
    expect(notifications, greaterThanOrEqualTo(2));
  });

  test('setMode ignora modo invalido', () async {
    final service = RoleModeService.forTesting();

    await service.load(defaultRole: 'cliente');
    await service.setMode('admin');

    expect(service.currentRole, 'cliente');
  });
}
