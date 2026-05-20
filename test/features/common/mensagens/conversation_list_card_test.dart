import 'package:chegaja_v2/features/common/mensagens/widgets/conversation_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('ConversationListCard', () {
    testWidgets('renders name and last message', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConversationListCard(
            name: 'Joao Silva',
            message: 'Chego as 10h.',
            timeLabel: '09:32',
            serviceLabel: 'Canalizacao',
          ),
        ),
      );

      expect(find.text('Joao Silva'), findsOneWidget);
      expect(find.text('Chego as 10h.'), findsOneWidget);
      expect(find.text('Canalizacao'), findsOneWidget);
    });

    testWidgets('renders unread badge', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConversationListCard(
            name: 'Marta Santos',
            message: 'Pode enviar um orcamento?',
            timeLabel: 'Ontem',
            unreadCount: 3,
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('calls onTap and onLongPress', (tester) async {
      var tapped = false;
      var longPressed = false;

      await tester.pumpWidget(
        _wrap(
          ConversationListCard(
            name: 'Carlos Almeida',
            message: 'Obrigado.',
            timeLabel: 'Sab',
            onTap: () => tapped = true,
            onLongPress: () => longPressed = true,
          ),
        ),
      );

      await tester.tap(find.byType(ConversationListCard));
      await tester.pump();
      expect(tapped, isTrue);

      await tester.longPress(find.byType(ConversationListCard));
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets('shows favorite indicator when active', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConversationListCard(
            name: 'Sofia Ferreira',
            message: 'Tudo certo.',
            timeLabel: 'Hoje',
            isFavorite: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    });

    testWidgets('works without remote image', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConversationListCard(
            name: 'Ana Costa',
            message: 'Sem imagem remota.',
            timeLabel: 'Agora',
            isOnline: true,
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('Ana Costa'), findsOneWidget);
    });
  });
}
