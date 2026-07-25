import 'package:chegaja_v2/core/repositories/prestador_repo.dart';
import 'package:chegaja_v2/features/prestador/agenda/prestador_agenda_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('screen guard blocks private agenda reads before phone approval',
      (tester) async {
    final repository = _FakeAgendaRepository();
    var gateCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: PrestadorAgendaScreen(
          repository: repository,
          uidResolver: () async => 'provider-1',
          accessGate: (
            context, {
            required action,
          }) async {
            gateCalls += 1;
            expect(action, contains('agenda privada'));
            return false;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(gateCalls, 1);
    expect(repository.loadCount, 0);
    expect(
      find.byKey(const Key('prestador_agenda_access_denied')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('screen guard loads private agenda only after phone approval',
      (tester) async {
    final repository = _FakeAgendaRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PrestadorAgendaScreen(
          embedded: true,
          experienceV2Override: true,
          repository: repository,
          uidResolver: () async => 'provider-1',
          accessGate: (
            context, {
            required action,
          }) async =>
              true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.loadCount, 1);
    expect(
      find.byKey(const Key('prestador_agenda_embedded')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('embedded agenda handles an unavailable auth session safely',
      (tester) async {
    final repository = _FakeAgendaRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PrestadorAgendaContent(
          repository: repository,
          uidResolver: () async => null,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'Não conseguimos carregar a agenda. Verifica a ligação e tenta novamente.',
      ),
      findsOneWidget,
    );
    expect(repository.loadCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loads private schedule and saves edited working hours',
      (tester) async {
    final repository = _FakeAgendaRepository(
      agenda: ProviderAgendaData(
        workingHours: const {
          'monday': ['08:00', '17:00'],
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PrestadorAgendaContent(
          repository: repository,
          uidResolver: () async => 'provider-1',
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('prestador_agenda_embedded')),
      findsOneWidget,
    );
    expect(find.byType(Scaffold), findsNothing);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('prestador_agenda_toggle_monday')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('prestador_agenda_toggle_tuesday')),
          )
          .value,
      isFalse,
    );

    await tester.tap(
      find.byKey(const Key('prestador_agenda_toggle_tuesday')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('prestador_agenda_save')));
    await tester.pump();

    expect(repository.savedUid, 'provider-1');
    expect(repository.savedWorkingHours, {
      'monday': ['08:00', '17:00'],
      'tuesday': ['09:00', '18:00'],
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a recoverable load error and retries', (tester) async {
    final repository = _FakeAgendaRepository(
      agenda: ProviderAgendaData(
        workingHours: const {
          'friday': ['10:00', '16:00'],
        },
      ),
      failingLoads: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PrestadorAgendaContent(
          repository: repository,
          uidResolver: () async => 'provider-1',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(repository.loadCount, 2);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('prestador_agenda_toggle_friday')),
          )
          .value,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone route keeps its Scaffold and works in dark mode',
      (tester) async {
    final repository = _FakeAgendaRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: PrestadorAgendaScreen(
          experienceV2Override: true,
          accessPreauthorized: true,
          repository: repository,
          uidResolver: () async => 'provider-1',
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Minha Agenda'), findsOneWidget);
    expect(find.byKey(const Key('prestador_agenda_days')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flag off keeps the standalone legacy schedule experience',
      (tester) async {
    final repository = _FakeAgendaRepository(
      agenda: ProviderAgendaData(
        workingHours: const {
          'monday': ['08:00', '17:00'],
        },
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PrestadorAgendaScreen(
          experienceV2Override: false,
          accessPreauthorized: true,
          repository: repository,
          uidResolver: () async => 'provider-1',
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('prestador_agenda_standalone_legacy')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prestador_agenda_days_legacy')),
      findsOneWidget,
    );
    expect(find.byType(SwitchListTile), findsNothing);
    expect(
      tester
          .widget<Switch>(
            find.byKey(
              const Key('prestador_agenda_legacy_toggle_monday'),
            ),
          )
          .value,
      isTrue,
    );

    await tester.tap(
      find.byKey(
        const Key('prestador_agenda_legacy_toggle_tuesday'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('prestador_agenda_save')));
    await tester.pump();

    expect(repository.savedUid, 'provider-1');
    expect(repository.savedWorkingHours, {
      'monday': ['08:00', '17:00'],
      'tuesday': ['09:00', '18:00'],
    });
    expect(tester.takeException(), isNull);
  });
}

class _FakeAgendaRepository implements PrestadorAgendaRepository {
  _FakeAgendaRepository({
    ProviderAgendaData? agenda,
    this.failingLoads = 0,
  }) : agenda = agenda ?? ProviderAgendaData.empty;

  final ProviderAgendaData agenda;
  int failingLoads;
  int loadCount = 0;
  String? savedUid;
  Map<String, List<String>>? savedWorkingHours;

  @override
  Future<ProviderAgendaData> getAgenda(String uid) async {
    loadCount += 1;
    if (failingLoads > 0) {
      failingLoads -= 1;
      throw StateError('offline');
    }
    return agenda;
  }

  @override
  Future<void> updateAgenda(
    String uid, {
    required Map<String, List<String>> workingHours,
    List<DateTime>? blockedDates,
  }) async {
    savedUid = uid;
    savedWorkingHours = workingHours.map(
      (day, hours) => MapEntry(day, List<String>.from(hours)),
    );
  }
}
