import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chegaja_v2/core/navigation/app_navigator.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/deep_link_service.dart';
import 'package:chegaja_v2/core/services/notification_service.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';
import 'package:chegaja_v2/features/common/pedido_detalhe_auto_screen.dart';
import 'package:chegaja_v2/features/common/widgets/pedido_anexos_widget.dart';
import 'package:chegaja_v2/firebase_options.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

const bool _runEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

bool get _shouldRun =>
    _runEmulatorTests &&
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android;

late FirebaseApp _providerApp;
late FirebaseAuth _defaultAuth;
late FirebaseAuth _providerAuth;
late FirebaseFirestore _defaultDb;
late FirebaseFirestore _providerDb;

Future<void> _initFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  _providerApp = await _getOrCreateApp('m25_android_prestador');
  _defaultAuth = FirebaseAuth.instance;
  _providerAuth = FirebaseAuth.instanceFor(app: _providerApp);
  _defaultDb = FirebaseFirestore.instance;
  _providerDb = FirebaseFirestore.instanceFor(app: _providerApp);

  const host = '10.0.2.2';
  try {
    await _defaultAuth.useAuthEmulator(host, 9099);
    await _providerAuth.useAuthEmulator(host, 9099);
    _defaultDb.useFirestoreEmulator(host, 8080);
    _providerDb.useFirestoreEmulator(host, 8080);
  } catch (_) {
    // A segunda execucao no mesmo processo pode ja ter os emuladores ligados.
  }

  try {
    _defaultDb.settings = const Settings(persistenceEnabled: false);
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
  if (_providerAuth.currentUser != null) await _providerAuth.signOut();
}

Future<User> _signInDefaultClient() async {
  final user = await _eventually(
    () async {
      return AuthService.ensureSignedInAnonymously().timeout(
        const Duration(seconds: 60),
      );
    },
    'auth anonimo cliente',
  );
  await AuthService.setActiveRole('cliente');
  await _seedUser(db: _defaultDb, uid: user.uid, role: 'cliente');
  return user;
}

Future<User> _signInProvider() async {
  final credential = await _eventually(
    () {
      return _providerAuth.signInAnonymously().timeout(
            const Duration(seconds: 60),
          );
    },
    'auth anonimo prestador',
  );
  final user = credential.user!;
  await _seedUser(db: _providerDb, uid: user.uid, role: 'prestador');
  return user;
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

Future<String> _seedAcceptedPedido({
  required String clienteId,
  required String prestadorId,
}) async {
  final ref = await _defaultDb.collection('pedidos').add({
    'clienteId': clienteId,
    'prestadorId': prestadorId,
    'servicoId': 'svc_m25_deeplink',
    'servicoNome': 'Canalizador M2.5',
    'categoria': 'Canalizador M2.5',
    'titulo': 'Pedido M2.5 ${DateTime.now().microsecondsSinceEpoch}',
    'descricao': 'Pedido criado para validar deep link Android M2.5',
    'modo': 'IMEDIATO',
    'tipoPreco': 'a_combinar',
    'tipoPagamento': 'dinheiro',
    'estado': 'aceito',
    'status': 'aceito',
    'statusProposta': 'nenhuma',
    'statusConfirmacaoValor': 'nenhum',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'latitude': null,
    'longitude': null,
    'enderecoTexto': 'Rua de teste M2.5 Android',
  });

  await _defaultDb.collection('chats').doc(ref.id).set(
    {
      'pedidoId': ref.id,
      'clienteId': clienteId,
      'prestadorId': prestadorId,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );

  return ref.id;
}

Future<T> _eventually<T>(
  FutureOr<T?> Function() body,
  String label, {
  Duration timeout = const Duration(seconds: 45),
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw TimeoutException('Timeout aguardando $label. Ultimo erro: $lastError');
}

Future<void> _pumpNavigatorHarness(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.navigatorKey,
      scaffoldMessengerKey: AppNavigator.messengerKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('M2.5 Android harness')),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void _registerCleanup(WidgetTester tester) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder,
  String label, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Widget nao encontrado: $label');
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

  testWidgets('Deep link Android abre pedido existente', (tester) async {
    if (!_shouldRun) return;
    _registerCleanup(tester);

    final client = await _signInDefaultClient();
    final provider = await _signInProvider();
    final pedidoId = await _seedAcceptedPedido(
      clienteId: client.uid,
      prestadorId: provider.uid,
    );

    await _pumpNavigatorHarness(tester);
    DeepLinkService.instance.handleUriForTesting(
      Uri.parse('chegaja://pedido/$pedidoId'),
    );

    await _pumpUntilFound(
      tester,
      find.byType(PedidoDetalheAutoScreen),
      'detalhe de pedido por deep link',
    );
  }, skip: !_shouldRun);

  testWidgets('Deep link Android abre chat de pedido existente',
      (tester) async {
    if (!_shouldRun) return;
    _registerCleanup(tester);

    final client = await _signInDefaultClient();
    final provider = await _signInProvider();
    final pedidoId = await _seedAcceptedPedido(
      clienteId: client.uid,
      prestadorId: provider.uid,
    );

    await _pumpNavigatorHarness(tester);
    DeepLinkService.instance.handleUriForTesting(
      Uri.parse('chegaja://chat/$pedidoId'),
    );

    await _pumpUntilFound(
      tester,
      find.byType(ChatThreadScreen),
      'chat por deep link',
    );
  }, skip: !_shouldRun);

  testWidgets('Token FCM Android e gravado no formato usado pelas Functions',
      (tester) async {
    if (!_shouldRun) return;

    final client = await _signInDefaultClient();
    const token = 'm25_android_fake_token';

    await NotificationService.saveTokenRecordForTesting(
      firestore: _defaultDb,
      uid: client.uid,
      token: token,
    );

    final userDoc = await _defaultDb.collection('users').doc(client.uid).get();
    expect(userDoc.data()?['fcmToken'], token);

    final tokenDoc = await _defaultDb
        .collection('users')
        .doc(client.uid)
        .collection('fcmTokens')
        .doc(token)
        .get();
    expect(tokenDoc.exists, isTrue);
    expect(tokenDoc.data()?['platform'], 'android');
  }, skip: !_shouldRun);

  testWidgets('UI de anexos Android renderiza fallback sem abrir picker',
      (tester) async {
    if (!_shouldRun) return;
    _registerCleanup(tester);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: PedidoAnexosWidget(
            initialUrls: const [],
            onChanged: (_) {},
            pedidoId: 'pedido_m25',
          ),
        ),
      ),
    );

    expect(
        find.byKey(const Key('pedido_anexo_galeria_button')), findsOneWidget);
    expect(find.byKey(const Key('pedido_anexo_camera_button')), findsOneWidget);
    expect(
        find.byKey(const Key('pedido_anexo_arquivo_button')), findsOneWidget);
  }, skip: !_shouldRun);
}
