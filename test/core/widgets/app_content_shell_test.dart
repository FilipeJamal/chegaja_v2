import 'package:chegaja_v2/core/widgets/app_content_shell.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppContentShell constrains compact content width',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppContentShell(
            width: AppContentWidth.compact,
            child: SizedBox(
              key: Key('content'),
              height: 80,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const Key('content')));
    expect(size.width, lessThanOrEqualTo(520));
  });

  testWidgets('AppPageScaffold renders header and scrollable body',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppPageScaffold(
          title: 'Inicio',
          subtitle: 'Organiza os teus servicos',
          child: Text('Conteudo principal'),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Organiza os teus servicos'), findsOneWidget);
    expect(find.text('Conteudo principal'), findsOneWidget);
  });

  testWidgets('AppResponsiveGrid uses multiple columns on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: AppResponsiveGrid(
              minItemWidth: 260,
              children: List.generate(
                4,
                (index) => SizedBox(
                  key: Key('tile-$index'),
                  height: 80,
                  child: Text('Tile $index'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final first = tester.getTopLeft(find.byKey(const Key('tile-0')));
    final second = tester.getTopLeft(find.byKey(const Key('tile-1')));
    expect(second.dx, greaterThan(first.dx));
    expect(second.dy, equals(first.dy));
  });
}
