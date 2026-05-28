import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/common/widgets/media_viewer_screen.dart';

void main() {
  testWidgets('MediaViewerScreen mostra controlos de zoom no desktop',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaViewerScreen(
          urls: ['https://example.invalid/photo.jpg'],
          title: 'Foto de perfil',
        ),
      ),
    );

    expect(find.text('Foto de perfil'), findsOneWidget);
    expect(find.byTooltip('Aproximar'), findsOneWidget);
    expect(find.byTooltip('Afastar'), findsOneWidget);
    expect(find.byTooltip('Repor zoom'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('MediaViewerScreen permite aproximar, afastar e repor zoom',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaViewerScreen(
          urls: ['https://example.invalid/photo.jpg'],
          title: 'Portfolio',
        ),
      ),
    );

    await tester.tap(find.byTooltip('Aproximar'));
    await tester.pumpAndSettle();
    expect(find.text('125%'), findsOneWidget);

    await tester.tap(find.byTooltip('Afastar'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byTooltip('Aproximar'));
    await tester.pumpAndSettle();
    expect(find.text('125%'), findsOneWidget);

    await tester.tap(find.byTooltip('Repor zoom'));
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
  });
}
