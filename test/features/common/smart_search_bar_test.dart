import 'package:chegaja_v2/features/common/smart_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SearchItem {
  const _SearchItem(this.id, this.name, this.keywords);

  final String id;
  final String name;
  final List<String> keywords;
}

void main() {
  const items = [
    _SearchItem('portrait', 'Retrato a lapis', ['desenho', 'arte']),
    _SearchItem('cleaning', 'Limpeza residencial', ['casa']),
    _SearchItem('plumbing', 'Canalizacao', ['agua']),
  ];

  Widget buildSubject({ValueChanged<_SearchItem>? onSelected}) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SmartSearchBar<_SearchItem>(
          hintText: 'Procurar servico...',
          allItems: items,
          idSelector: (item) => item.id,
          nameSelector: (item) => item.name,
          keywordsSelector: (item) => item.keywords,
          onItemSelected: onSelected ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('debounces service suggestions while typing', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'retrato');
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Retrato a lapis'), findsNothing);

    await tester.pump(const Duration(milliseconds: 180));

    expect(find.text('Retrato a lapis'), findsOneWidget);
  });

  testWidgets('renders readable suggestions in dark theme', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'limpeza');
    await tester.pump(const Duration(milliseconds: 300));

    final title = tester.widget<Text>(find.text('Limpeza residencial'));
    final context = tester.element(find.byType(SmartSearchBar<_SearchItem>));

    expect(title.style?.color, Theme.of(context).colorScheme.onSurface);
    expect(title.overflow, TextOverflow.ellipsis);
  });

  testWidgets('calls selection callback from suggestion', (tester) async {
    _SearchItem? selected;
    await tester
        .pumpWidget(buildSubject(onSelected: (item) => selected = item));

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'canal');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byType(ListTile));
    await tester.pump();

    expect(selected?.id, 'plumbing');
  });
}
