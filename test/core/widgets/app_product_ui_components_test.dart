import 'package:chegaja_v2/core/widgets/app_avatar.dart';
import 'package:chegaja_v2/core/widgets/app_filter_button.dart';
import 'package:chegaja_v2/core/widgets/app_premium_search_bar.dart';
import 'package:chegaja_v2/core/widgets/app_product_header.dart';
import 'package:chegaja_v2/core/widgets/app_segmented_tabs.dart';
import 'package:chegaja_v2/core/widgets/app_unread_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('product UI components', () {
    testWidgets('AppAvatar renders fallback initial', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppAvatar(label: 'Joao Silva')),
      );

      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('AppAvatar renders online indicator', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppAvatar(label: 'Marta Santos', isOnline: true)),
      );

      expect(
        find.byKey(const Key('app_avatar_online_indicator')),
        findsOneWidget,
      );
    });

    testWidgets('AppUnreadBadge renders counter', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppUnreadBadge(count: 7)),
      );

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('AppUnreadBadge caps large counters', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppUnreadBadge(count: 120)),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('AppPremiumSearchBar calls onChanged', (tester) async {
      var value = '';

      await tester.pumpWidget(
        _wrap(
          AppPremiumSearchBar(
            hintText: 'Pesquisar conversa',
            onChanged: (next) => value = next,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'canalizador');
      expect(value, 'canalizador');
    });

    testWidgets('AppFilterButton calls onPressed', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        _wrap(
          AppFilterButton(
            tooltip: 'Filtrar',
            onPressed: () => pressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(AppFilterButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('AppSegmentedTabs changes selection', (tester) async {
      var selected = 0;

      await tester.pumpWidget(
        _wrap(
          AppSegmentedTabs(
            items: const [
              AppSegmentedTab(label: 'Ativos', count: 2),
              AppSegmentedTab(label: 'Concluidos', count: 4),
            ],
            selectedIndex: selected,
            onChanged: (index) => selected = index,
          ),
        ),
      );

      await tester.tap(find.text('Concluidos'));
      await tester.pump();

      expect(selected, 1);
    });

    testWidgets('AppSegmentedTabs keeps horizontal overflow internal',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: AppSegmentedTabs(
              items: const [
                AppSegmentedTab(label: 'Pendentes', count: 0),
                AppSegmentedTab(label: 'Concluidos', count: 0),
                AppSegmentedTab(label: 'Cancelados', count: 0),
                AppSegmentedTab(label: 'Em analise', count: 0),
              ],
              selectedIndex: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(AppSegmentedTabs));

      expect(box.size.width, 320);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppProductHeader renders title, subtitle and actions',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppProductHeader(
            title: 'Mensagens',
            subtitle: 'Converse com prestadores.',
            onNotificationPressed: () {},
            avatar: const AppAvatar(label: 'Ana Silva'),
          ),
        ),
      );

      expect(find.text('Mensagens'), findsOneWidget);
      expect(find.text('Converse com prestadores.'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });
  });
}
