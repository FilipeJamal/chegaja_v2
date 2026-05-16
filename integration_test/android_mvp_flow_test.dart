import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';
import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/features/cliente/pedido_detalhe_screen.dart';
import 'package:chegaja_v2/features/prestador/prestador_home_screen.dart';
import 'package:chegaja_v2/firebase_options.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

const bool _runEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

bool get _shouldRun =>
    _runEmulatorTests &&
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android;

late FirebaseApp _clientApp;
late FirebaseApp _providerApp;
late FirebaseAuth _defaultAuth;
late FirebaseAuth _clientAuth;
late FirebaseAuth _providerAuth;
late FirebaseFirestore _defaultDb;
late FirebaseFirestore _clientDb;
late FirebaseFirestore _providerDb;

Future<void> _initFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  _clientApp = await _getOrCreateApp('m2_android_cliente');
  _providerApp = await _getOrCreateApp('m2_android_prestador');

  _defaultAuth = FirebaseAuth.instance;
  _clientAuth = FirebaseAuth.instanceFor(app: _clientApp);
  _providerAuth = FirebaseAuth.instanceFor(app: _providerApp);

  _defaultDb = FirebaseFirestore.instance;
  _clientDb = FirebaseFirestore.instanceFor(app: _clientApp);
  _providerDb = FirebaseFirestore.instanceFor(app: _providerApp);

  final host = defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';
  try {
    await _defaultAuth.useAuthEmulator(host, 9099);
    await _clientAuth.useAuthEmulator(host, 9099);
    await _providerAuth.useAuthEmulator(host, 9099);
    _defaultDb.useFirestoreEmulator(host, 8080);
    _clientDb.useFirestoreEmulator(host, 8080);
    _providerDb.useFirestoreEmulator(host, 8080);
  } catch (_) {
    // A segunda execucao no mesmo processo pode ja ter os emuladores ligados.
  }

  try {
    _defaultDb.settings = const Settings(persistenceEnabled: false);
    _clientDb.settings = const Settings(persistenceEnabled: false);
    _providerDb.settings = const Settings(persistenceEnabled: false);
  } catch (_) {}
}

Future<FirebaseApp> _getOrCreateApp(String name) async {
  try {
    return Firebase.app(name);
  } catch (_) {
    return Firebase.initializeApp(
      name: name,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> _signOutAll() async {
  if (_defaultAuth.currentUser != null) await _defaultAuth.signOut();
  if (_clientAuth.currentUser != null) await _clientAuth.signOut();
  if (_providerAuth.currentUser != null) await _providerAuth.signOut();
}

Future<User> _signInDefaultAs(String role) async {
  final user = await AuthService.ensureSignedInAnonymously().timeout(
    const Duration(seconds: 60),
  );
  await AuthService.setActiveRole(role);
  return user;
}

Future<User> _signIn(FirebaseAuth auth) async {
  final credential = await auth.signInAnonymously().timeout(
        const Duration(seconds: 60),
      );
  return credential.user!;
}

Future<void> _seedUser({
  required FirebaseFirestore db,
  required String uid,
  required String role,
}) {
  return db.collection('users').doc(uid).set(
    {
      'uid': uid,
      'isAnonymous': true,
      'activeRole': role,
      'roles.$role': true,
      'region': 'PT',
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}

Future<void> _seedProvider({
  required FirebaseFirestore db,
  required String uid,
  required Servico service,
}) {
  return db.collection('prestadores').doc(uid).set(
    {
      'nome': 'Prestador M2 Android',
      'isOnline': true,
      'servicos': [service.id],
      'servicosNomes': [service.name],
      'radiusKm': 50,
      'lastLocation': {'lat': 38.7223, 'lng': -9.1393},
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}

Future<String> _createPedidoAsClient({
  required FirebaseFirestore db,
  required String clienteId,
  required Servico service,
  required String title,
  required String tipoPreco,
}) async {
  final ref = await db.collection('pedidos').add({
    'clienteId': clienteId,
    'prestadorId': null,
    'servicoId': service.id,
    'servicoNome': service.name,
    'categoria': service.name,
    'titulo': title,
    'descricao': 'Pedido criado pelo teste M2 Android',
    'modo': 'IMEDIATO',
    'tipoPreco': tipoPreco,
    'tipoPagamento': 'dinheiro',
    'estado': 'criado',
    'status': 'criado',
    'statusProposta': 'nenhuma',
    'statusConfirmacaoValor': 'nenhum',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'latitude': null,
    'longitude': null,
    'enderecoTexto': 'Rua de teste M2 Android',
  });
  return ref.id;
}

Future<Pedido> _pedido(FirebaseFirestore db, String pedidoId) async {
  final snap = await db.collection('pedidos').doc(pedidoId).get();
  final data = snap.data();
  if (data == null) throw StateError('Pedido $pedidoId nao encontrado');
  return Pedido.fromMap(snap.id, data);
}

Future<Pedido> _waitPedido(
  FirebaseFirestore db,
  String pedidoId,
  bool Function(Pedido pedido) predicate,
  String label,
) async {
  return _eventually(
    () async {
      final pedido = await _pedido(db, pedidoId);
      return predicate(pedido) ? pedido : null;
    },
    label,
  );
}

Future<T> _eventually<T>(
  FutureOr<T?> Function() body,
  String label, {
  Duration timeout = const Duration(seconds: 75),
}) async {
  final deadline = DateTime.now().add(timeout);
  Object? lastError;
  while (DateTime.now().isBefore(deadline)) {
    try {
      final value = await body();
      if (value != null) return value;
    } catch (error) {
      lastError = error;
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  throw TimeoutException('Timeout aguardando $label. Ultimo erro: $lastError');
}

Future<void> _pumpHarness(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void _registerWidgetCleanup(WidgetTester tester) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder,
  String label, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Widget nao encontrado: $label');
}

Future<void> _tapByKey(
  WidgetTester tester,
  String key,
  String label,
) async {
  final finder = find.byKey(Key(key));
  await _pumpUntilFound(tester, finder, label);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tapByKeyWithScroll(
  WidgetTester tester,
  String key,
  String label, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final finder = find.byKey(Key(key));
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pump(const Duration(milliseconds: 100));
      final hitTestableFinder = finder.hitTestable();
      if (hitTestableFinder.evaluate().isNotEmpty) {
        await tester.tap(hitTestableFinder);
        await tester.pump(const Duration(milliseconds: 300));
        return;
      }
    }

    final scrollables = find.byType(SingleChildScrollView);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.drag(scrollables.first, const Offset(0, -520));
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
  final visibleTexts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where((text) => text.trim().isNotEmpty)
      .take(30)
      .join(' | ');
  throw TestFailure(
    'Widget nao encontrado: $label. Textos visiveis: $visibleTexts',
  );
}

String _visibleTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where((text) => text.trim().isNotEmpty)
      .take(40)
      .join(' | ');
}

Future<String> _createPedidoWithClienteUi(
  WidgetTester tester, {
  required Servico service,
  required String title,
  required String modo,
  required String clienteId,
}) async {
  await _pumpHarness(
    tester,
    NovoPedidoScreen(
      modo: modo,
      servicoInicial: service,
      servicosLoader: () async => [service],
    ),
  );

  await _pumpUntilFound(
    tester,
    find.byKey(const Key('novo_pedido_titulo_field')),
    'campo titulo do novo pedido',
  );
  await tester.enterText(
    find.byKey(const Key('novo_pedido_titulo_field')),
    title,
  );
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump(const Duration(milliseconds: 500));
  await _tapByKeyWithScroll(
    tester,
    'novo_pedido_submit_button',
    'submeter pedido',
  );

  final deadline = DateTime.now().add(const Duration(seconds: 75));
  Object? lastError;
  final seenTitles = <String>{};
  while (DateTime.now().isBefore(deadline)) {
    try {
      final qs = await _defaultDb
          .collection('pedidos')
          .where('clienteId', isEqualTo: clienteId)
          .get();
      for (final doc in qs.docs) {
        final data = doc.data();
        final docTitle = data['titulo']?.toString();
        if (docTitle != null) seenTitles.add(docTitle);
        if (docTitle == title) return doc.id;
      }
    } catch (error) {
      lastError = error;
    }
    await tester.pump(const Duration(milliseconds: 300));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  throw TimeoutException(
    'Timeout aguardando pedido criado por UI cliente. '
    'Titulos vistos para cliente: ${seenTitles.join(' || ')}. '
    'Textos visiveis: ${_visibleTexts(tester)}. '
    'Ultimo erro: $lastError',
  );
}

Servico _testService(String suffix) {
  final safeSuffix = suffix.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  return Servico(
    id: 'svc_m2_android_$safeSuffix',
    name: 'Canalizador M2 Android $safeSuffix',
    mode: 'IMEDIATO',
    keywords: const ['agua', 'teste'],
    iconKey: null,
    isActive: true,
  );
}

Future<void> _providerAcceptsFromHomeUi(
  WidgetTester tester,
  String pedidoId, {
  bool dismissQuoteDialog = false,
}) async {
  await _eventually(
    () async {
      final openPedidos = await _defaultDb
          .collection('pedidos')
          .where('status', isEqualTo: 'criado')
          .where('prestadorId', isNull: true)
          .orderBy('createdAt', descending: true)
          .get();
      return openPedidos.docs.any((d) => d.id == pedidoId) ? true : null;
    },
    'pedido aberto visivel para prestador',
  );
  await _pumpHarness(tester, const PrestadorHomeScreen());
  await _tapByKeyWithScroll(
    tester,
    'prestador_aceitar_pedido_$pedidoId',
    'prestador aceitar pedido aberto',
  );
  if (dismissQuoteDialog) {
    final finder = find.byKey(
      const Key('prestador_orcamento_dialog_later_button'),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isEmpty) continue;
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 300));
      break;
    }
  }
}

Future<void> _providerStartsAndSendsFinalUi(
  WidgetTester tester,
  String pedidoId, {
  required double value,
}) async {
  await _pumpHarness(
    tester,
    PedidoDetalheScreen(pedidoId: pedidoId, isCliente: false),
  );
  await _tapByKey(tester, 'prestador_iniciar_servico_button', 'iniciar');
  await _waitPedido(
    _defaultDb,
    pedidoId,
    (p) => p.estado == 'em_andamento',
    'pedido em andamento',
  );

  await _pumpHarness(
    tester,
    PedidoDetalheScreen(pedidoId: pedidoId, isCliente: false),
  );
  await _tapByKey(
    tester,
    'prestador_lancar_valor_final_button',
    'abrir valor final',
  );
  await _pumpUntilFound(
    tester,
    find.byKey(const Key('valor_final_field')),
    'campo valor final',
  );
  await tester.enterText(
    find.byKey(const Key('valor_final_field')),
    value.toStringAsFixed(0),
  );
  await _tapByKey(
      tester, 'prestador_enviar_valor_final_button', 'enviar valor');
  await _waitPedido(
    _defaultDb,
    pedidoId,
    (p) =>
        p.estado == 'aguarda_confirmacao_valor' &&
        p.statusConfirmacaoValor == 'pendente_cliente',
    'valor final pendente',
  );
}

Future<void> _providerSendsQuoteUi(
  WidgetTester tester,
  String pedidoId,
) async {
  await _pumpHarness(
    tester,
    PedidoDetalheScreen(pedidoId: pedidoId, isCliente: false),
  );
  await _tapByKey(
    tester,
    'prestador_enviar_orcamento_button',
    'abrir envio de orcamento',
  );
  await _pumpUntilFound(
    tester,
    find.byKey(const Key('orcamento_min_field')),
    'campo minimo orcamento',
  );
  await tester.enterText(find.byKey(const Key('orcamento_min_field')), '20');
  await tester.enterText(find.byKey(const Key('orcamento_max_field')), '35');
  await _tapByKey(tester, 'orcamento_enviar_button', 'enviar orcamento');
  await _waitPedido(
    _defaultDb,
    pedidoId,
    (p) =>
        p.estado == 'aguarda_resposta_cliente' &&
        p.statusProposta == 'pendente_cliente',
    'orcamento pendente cliente',
  );
}

Future<void> _clientAcceptsQuoteUi(
  WidgetTester tester,
  String pedidoId,
) async {
  await _pumpHarness(
    tester,
    PedidoDetalheScreen(pedidoId: pedidoId, isCliente: true),
  );
  await _tapByKey(
    tester,
    'cliente_aceitar_proposta_button',
    'cliente aceitar proposta',
  );
  await _waitPedido(
    _defaultDb,
    pedidoId,
    (p) => p.estado == 'aceito' && p.statusProposta == 'aceita_cliente',
    'proposta aceita',
  );
}

Future<void> _clientConfirmsValueUi(
  WidgetTester tester,
  String pedidoId,
) async {
  await _pumpHarness(
    tester,
    PedidoDetalheScreen(pedidoId: pedidoId, isCliente: true),
  );
  await _tapByKey(tester, 'confirmar_valor_button', 'confirmar valor');
  await _waitPedido(
    _defaultDb,
    pedidoId,
    (p) => p.estado == 'concluido',
    'pedido concluido',
  );
}

void _expectMoney(Pedido pedido, double finalValue) {
  expect(pedido.precoFinal, finalValue);
  expect(pedido.earningsTotal, finalValue);
  expect(pedido.commissionPlatform, closeTo(finalValue * 0.15, 0.001));
  expect(pedido.earningsProvider, closeTo(finalValue * 0.85, 0.001));
}

void _expectHistory(Pedido pedido, Iterable<String> eventos) {
  final history = pedido.historico.map((item) => item.evento).toSet();
  for (final evento in eventos) {
    expect(history, contains(evento));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!_shouldRun) return;
    await _initFirebase();
  });

  setUp(() async {
    if (!_shouldRun) return;
    await _signOutAll();
  });

  tearDown(() async {
    if (!_shouldRun) return;
    await _signOutAll();
  });

  testWidgets(
    'Cliente Android UI conclui pedido normal com prestador simulado',
    (tester) async {
      if (!_shouldRun) return;
      _registerWidgetCleanup(tester);

      final client = await _signInDefaultAs('cliente');
      final provider = await _signIn(_providerAuth);
      final service = _testService(
          'cliente_normal_${DateTime.now().microsecondsSinceEpoch}');
      await _seedUser(db: _providerDb, uid: provider.uid, role: 'prestador');
      await _seedProvider(db: _providerDb, uid: provider.uid, service: service);

      final title =
          'M2 Android Cliente UI normal ${DateTime.now().microsecondsSinceEpoch}';
      final pedidoId = await _createPedidoWithClienteUi(
        tester,
        service: service,
        title: title,
        modo: 'IMEDIATO',
        clienteId: client.uid,
      );

      final providerService =
          PedidoService(firestore: _providerDb, trackAnalytics: false);
      var pedido = await _pedido(_providerDb, pedidoId);
      await providerService.aceitarPedidoAberto(
        pedido: pedido,
        prestadorId: provider.uid,
      );
      pedido = await _pedido(_providerDb, pedidoId);
      await providerService.iniciarServico(
        pedido: pedido,
        prestadorId: provider.uid,
      );
      pedido = await _pedido(_providerDb, pedidoId);
      await providerService.proporValorFinal(
        pedido: pedido,
        prestadorId: provider.uid,
        valorFinal: 25,
      );

      await _clientConfirmsValueUi(tester, pedidoId);

      final finalPedido = await _pedido(_defaultDb, pedidoId);
      expect(finalPedido.estado, 'concluido');
      expect(finalPedido.status, 'concluido');
      expect(finalPedido.statusConfirmacaoValor, 'confirmado_cliente');
      _expectMoney(finalPedido, 25);
      _expectHistory(finalPedido, [
        'pedido_aceite',
        'servico_iniciado',
        'valor_proposto',
        'concluido',
      ]);
    },
    skip: !_shouldRun,
  );

  testWidgets(
    'Prestador Android UI conclui pedido normal com cliente simulado',
    (tester) async {
      if (!_shouldRun) return;
      _registerWidgetCleanup(tester);

      final provider = await _signInDefaultAs('prestador');
      final service = _testService(
          'prestador_normal_${DateTime.now().microsecondsSinceEpoch}');
      await _seedProvider(db: _defaultDb, uid: provider.uid, service: service);
      final client = await _signIn(_clientAuth);
      await _seedUser(db: _clientDb, uid: client.uid, role: 'cliente');
      final pedidoId = await _createPedidoAsClient(
        db: _clientDb,
        clienteId: client.uid,
        service: service,
        title:
            'M2 Android Prestador UI normal ${DateTime.now().microsecondsSinceEpoch}',
        tipoPreco: 'a_combinar',
      );

      await _providerAcceptsFromHomeUi(tester, pedidoId);
      await _waitPedido(
        _defaultDb,
        pedidoId,
        (p) => p.estado == 'aceito' && p.prestadorId == provider.uid,
        'prestador aceitou pedido',
      );
      await _providerStartsAndSendsFinalUi(tester, pedidoId, value: 25);

      final clientService =
          PedidoService(firestore: _clientDb, trackAnalytics: false);
      final pending = await _pedido(_clientDb, pedidoId);
      await clientService.confirmarValorFinal(
        pedido: pending,
        clienteId: client.uid,
        valorFinal: 25,
      );

      final finalPedido = await _pedido(_defaultDb, pedidoId);
      expect(finalPedido.estado, 'concluido');
      expect(finalPedido.statusConfirmacaoValor, 'confirmado_cliente');
      _expectMoney(finalPedido, 25);
      _expectHistory(finalPedido, [
        'pedido_aceite',
        'servico_iniciado',
        'valor_proposto',
        'concluido',
      ]);
    },
    skip: !_shouldRun,
  );

  testWidgets(
    'Cliente Android UI conclui orcamento com prestador simulado',
    (tester) async {
      if (!_shouldRun) return;
      _registerWidgetCleanup(tester);

      final client = await _signInDefaultAs('cliente');
      final provider = await _signIn(_providerAuth);
      final service = _testService(
          'cliente_orcamento_${DateTime.now().microsecondsSinceEpoch}');
      await _seedUser(db: _providerDb, uid: provider.uid, role: 'prestador');
      await _seedProvider(db: _providerDb, uid: provider.uid, service: service);

      final pedidoId = await _createPedidoWithClienteUi(
        tester,
        service: service,
        title:
            'M2 Android Cliente UI orcamento ${DateTime.now().microsecondsSinceEpoch}',
        modo: 'ORCAMENTO',
        clienteId: client.uid,
      );

      final providerService =
          PedidoService(firestore: _providerDb, trackAnalytics: false);
      var pedido = await _pedido(_providerDb, pedidoId);
      await providerService.aceitarPedidoAberto(
        pedido: pedido,
        prestadorId: provider.uid,
      );
      pedido = await _pedido(_providerDb, pedidoId);
      await providerService.enviarPropostaFaixa(
        pedido: pedido,
        prestadorId: provider.uid,
        valorMin: 20,
        valorMax: 35,
      );

      await _clientAcceptsQuoteUi(tester, pedidoId);

      pedido = await _pedido(_providerDb, pedidoId);
      await providerService.iniciarServico(
        pedido: pedido,
        prestadorId: provider.uid,
      );
      pedido = await _pedido(_providerDb, pedidoId);
      await providerService.proporValorFinal(
        pedido: pedido,
        prestadorId: provider.uid,
        valorFinal: 30,
      );

      await _clientConfirmsValueUi(tester, pedidoId);

      final finalPedido = await _pedido(_defaultDb, pedidoId);
      expect(finalPedido.tipoPreco, 'por_orcamento');
      expect(finalPedido.valorMinEstimadoPrestador, 20);
      expect(finalPedido.valorMaxEstimadoPrestador, 35);
      expect(finalPedido.statusProposta, 'aceita_cliente');
      expect(finalPedido.statusConfirmacaoValor, 'confirmado_cliente');
      expect(finalPedido.estado, 'concluido');
      _expectMoney(finalPedido, 30);
    },
    skip: !_shouldRun,
  );

  testWidgets(
    'Prestador Android UI conclui orcamento com cliente simulado',
    (tester) async {
      if (!_shouldRun) return;
      _registerWidgetCleanup(tester);

      final provider = await _signInDefaultAs('prestador');
      final service = _testService(
          'prestador_orcamento_${DateTime.now().microsecondsSinceEpoch}');
      await _seedProvider(db: _defaultDb, uid: provider.uid, service: service);
      final client = await _signIn(_clientAuth);
      await _seedUser(db: _clientDb, uid: client.uid, role: 'cliente');
      final pedidoId = await _createPedidoAsClient(
        db: _clientDb,
        clienteId: client.uid,
        service: service,
        title:
            'M2 Android Prestador UI orcamento ${DateTime.now().microsecondsSinceEpoch}',
        tipoPreco: 'por_orcamento',
      );

      await _providerAcceptsFromHomeUi(
        tester,
        pedidoId,
        dismissQuoteDialog: true,
      );
      await _waitPedido(
        _defaultDb,
        pedidoId,
        (p) => p.estado == 'aceito' && p.prestadorId == provider.uid,
        'prestador aceitou orcamento',
      );

      await _providerSendsQuoteUi(tester, pedidoId);

      final clientService =
          PedidoService(firestore: _clientDb, trackAnalytics: false);
      var pedido = await _pedido(_clientDb, pedidoId);
      await clientService.aceitarProposta(
        pedido: pedido,
        clienteId: client.uid,
      );

      await _providerStartsAndSendsFinalUi(tester, pedidoId, value: 30);

      pedido = await _pedido(_clientDb, pedidoId);
      await clientService.confirmarValorFinal(
        pedido: pedido,
        clienteId: client.uid,
        valorFinal: 30,
      );

      final finalPedido = await _pedido(_defaultDb, pedidoId);
      expect(finalPedido.tipoPreco, 'por_orcamento');
      expect(finalPedido.valorMinEstimadoPrestador, 20);
      expect(finalPedido.valorMaxEstimadoPrestador, 35);
      expect(finalPedido.statusProposta, 'aceita_cliente');
      expect(finalPedido.statusConfirmacaoValor, 'confirmado_cliente');
      expect(finalPedido.estado, 'concluido');
      _expectMoney(finalPedido, 30);
    },
    skip: !_shouldRun,
  );

  testWidgets(
    'Chat com ator Android escreve e le mensagens do outro lado',
    (tester) async {
      if (!_shouldRun) return;
      _registerWidgetCleanup(tester);

      final client = await _signInDefaultAs('cliente');
      final provider = await _signIn(_providerAuth);
      final service =
          _testService('chat_${DateTime.now().microsecondsSinceEpoch}');
      await _seedUser(db: _providerDb, uid: provider.uid, role: 'prestador');
      await _seedProvider(db: _providerDb, uid: provider.uid, service: service);

      final pedidoId = await _createPedidoAsClient(
        db: _defaultDb,
        clienteId: client.uid,
        service: service,
        title: 'M2 Android Chat ${DateTime.now().microsecondsSinceEpoch}',
        tipoPreco: 'a_combinar',
      );
      await _defaultDb.collection('pedidos').doc(pedidoId).set(
        {'prestadorId': provider.uid},
        SetOptions(merge: true),
      );

      await ChatService(firestore: _defaultDb, auth: _defaultAuth).sendMessage(
        pedidoId: pedidoId,
        text: 'Mensagem cliente Android M2 Android',
        senderRole: 'cliente',
      );
      await ChatService(firestore: _providerDb, auth: _providerAuth)
          .sendMessage(
        pedidoId: pedidoId,
        text: 'Resposta prestador simulado M2 Android',
        senderRole: 'prestador',
      );

      final messages = await _eventually(
        () async {
          final qs = await _defaultDb
              .collection('chats')
              .doc(pedidoId)
              .collection('messages')
              .get();
          return qs.docs.length >= 2 ? qs.docs : null;
        },
        'mensagens do chat M2 Android',
      );

      final texts =
          messages.map((doc) => (doc.data()['text'] ?? '').toString()).toSet();
      expect(texts, contains('Mensagem cliente Android M2 Android'));
      expect(texts, contains('Resposta prestador simulado M2 Android'));
    },
    skip: !_shouldRun,
  );
}
