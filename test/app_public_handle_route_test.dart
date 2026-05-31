import 'package:chegaja_v2/app.dart';
import 'package:chegaja_v2/features/common/public_profile_by_handle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('route factory cria wrapper para /p/{handle}', () {
    final route = buildChegaJaRoute(
      const RouteSettings(name: '/p/maria_bolos'),
    );

    expect(route, isA<MaterialPageRoute<void>>());
  });

  testWidgets('MaterialApp abre PublicProfileByHandleScreen para /p/{handle}',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/p/maria_bolos',
        onGenerateRoute: buildChegaJaRoute,
      ),
    );
    await tester.pump();

    expect(find.byType(PublicProfileByHandleScreen), findsOneWidget);
  });

  test('route factory ignora rotas fora de /p/{handle}', () {
    expect(
      buildChegaJaRoute(const RouteSettings(name: '/pedido/pedido_1')),
      isNull,
    );
    expect(
      buildChegaJaRoute(const RouteSettings(name: '/chat/pedido_1')),
      isNull,
    );
  });
}
