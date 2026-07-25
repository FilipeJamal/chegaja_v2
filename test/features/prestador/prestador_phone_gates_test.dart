import 'dart:async';

import 'package:chegaja_v2/features/prestador/prestador_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _actionHarness({
  required Future<void> Function(BuildContext context) onPressed,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          key: const Key('protected_action'),
          onPressed: () => unawaited(onPressed(context)),
          child: const Text('Continuar'),
        ),
      ),
    ),
  );
}

void main() {
  test('só a descoberta pública fica disponível antes de confirmar telefone',
      () {
    expect(
      prestadorDestinationRequiresVerifiedPhone(
        PrestadorHomeDestination.opportunities,
      ),
      isFalse,
    );
    for (final destination in const [
      PrestadorHomeDestination.schedule,
      PrestadorHomeDestination.jobs,
      PrestadorHomeDestination.messages,
      PrestadorHomeDestination.business,
    ]) {
      expect(
        prestadorDestinationRequiresVerifiedPhone(destination),
        isTrue,
        reason: destination.name,
      );
    }
  });

  testWidgets(
    'sessão anónima não inicia leitura da agenda privada',
    (tester) async {
      var privateAgendaLoads = 0;
      String? requestedAction;

      await tester.pumpWidget(
        _actionHarness(
          onPressed: (context) async {
            await requestPrestadorAgendaAccess(
              context,
              verifiedPhoneGate: (
                context, {
                required action,
              }) async {
                requestedAction = action;
                return false;
              },
              onAllowed: () {
                privateAgendaLoads += 1;
              },
            );
          },
        ),
      );

      await tester.tap(find.byKey(const Key('protected_action')));
      await tester.pump();

      expect(requestedAction, contains('agenda privada'));
      expect(privateAgendaLoads, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'telefone confirmado autoriza a leitura da agenda privada',
    (tester) async {
      var privateAgendaLoads = 0;

      await tester.pumpWidget(
        _actionHarness(
          onPressed: (context) async {
            await requestPrestadorAgendaAccess(
              context,
              verifiedPhoneGate: (
                context, {
                required action,
              }) async {
                return true;
              },
              onAllowed: () {
                privateAgendaLoads += 1;
              },
            );
          },
        ),
      );

      await tester.tap(find.byKey(const Key('protected_action')));
      await tester.pump();

      expect(privateAgendaLoads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sessão anónima não ativa estado online nem escreve localização',
    (tester) async {
      var locationWrites = 0;
      bool? requestedOnlineState;
      String? requestedAction;

      await tester.pumpWidget(
        _actionHarness(
          onPressed: (context) async {
            await requestPrestadorAvailabilityChange(
              context,
              verifiedPhoneGate: (
                context, {
                required action,
              }) async {
                requestedAction = action;
                return false;
              },
              isOnline: true,
              onAllowed: (isOnline) {
                requestedOnlineState = isOnline;
                locationWrites += 1;
              },
            );
          },
        ),
      );

      await tester.tap(find.byKey(const Key('protected_action')));
      await tester.pump();

      expect(requestedAction, contains('localização operacional'));
      expect(requestedOnlineState, isNull);
      expect(locationWrites, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'telefone confirmado permite ativar online e escrever localização',
    (tester) async {
      var locationWrites = 0;
      bool? writtenOnlineState;

      await tester.pumpWidget(
        _actionHarness(
          onPressed: (context) async {
            await requestPrestadorAvailabilityChange(
              context,
              verifiedPhoneGate: (
                context, {
                required action,
              }) async {
                return true;
              },
              isOnline: true,
              onAllowed: (isOnline) {
                writtenOnlineState = isOnline;
                locationWrites += 1;
              },
            );
          },
        ),
      );

      await tester.tap(find.byKey(const Key('protected_action')));
      await tester.pump();

      expect(writtenOnlineState, isTrue);
      expect(locationWrites, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ficar offline não exige telefone e interrompe a partilha operacional',
    (tester) async {
      var gateCalls = 0;
      var availabilityWrites = 0;
      bool? writtenOnlineState;

      await tester.pumpWidget(
        _actionHarness(
          onPressed: (context) async {
            await requestPrestadorAvailabilityChange(
              context,
              verifiedPhoneGate: (
                context, {
                required action,
              }) async {
                gateCalls += 1;
                return false;
              },
              isOnline: false,
              onAllowed: (isOnline) {
                writtenOnlineState = isOnline;
                availabilityWrites += 1;
              },
            );
          },
        ),
      );

      await tester.tap(find.byKey(const Key('protected_action')));
      await tester.pump();

      expect(gateCalls, 0);
      expect(writtenOnlineState, isFalse);
      expect(availabilityWrites, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
