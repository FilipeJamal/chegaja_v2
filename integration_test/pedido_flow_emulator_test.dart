import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chegaja_v2/firebase_options.dart';

const bool _runEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

late FirebaseApp _providerApp;
late FirebaseApp _clientApp;
late FirebaseAuth _providerAuth;
late FirebaseAuth _clientAuth;
late FirebaseFirestore _providerDb;
late FirebaseFirestore _clientDb;

String _emulatorHost() {
  if (kIsWeb) return 'localhost';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}

Future<void> _initFirebaseApps() async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[TEST] Firebase initialized');
    } catch (e) {
      debugPrint('[TEST] Error initializing Firebase: $e');
      rethrow;
    }
  } else {
    debugPrint('[TEST] Firebase already initialized');
  }

  _providerApp = await _getOrCreateApp('e2e_prestador');
  _clientApp = await _getOrCreateApp('e2e_cliente');

  _providerAuth = FirebaseAuth.instanceFor(app: _providerApp);
  _clientAuth = FirebaseAuth.instanceFor(app: _clientApp);
  _providerDb = FirebaseFirestore.instanceFor(app: _providerApp);
  _clientDb = FirebaseFirestore.instanceFor(app: _clientApp);

  final host = _emulatorHost();
  try {
    await _providerAuth.useAuthEmulator(host, 9099);
    await _clientAuth.useAuthEmulator(host, 9099);
    _providerDb.useFirestoreEmulator(host, 8080);
    _clientDb.useFirestoreEmulator(host, 8080);
    debugPrint('[TEST] Emulators configured on $host');
  } catch (e) {
    // Ignore if already configured
    debugPrint('[TEST] Emulators config warning: $e');
  }

  try {
    _providerDb.settings = const Settings(persistenceEnabled: false);
    _clientDb.settings = const Settings(persistenceEnabled: false);
  } catch (e) {
    debugPrint('[TEST] Firestore settings warning: $e');
  }
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

Future<T> _withTimeout<T>(Future<T> future, String label) {
  return future.timeout(
    const Duration(seconds: 30),
    onTimeout: () {
      debugPrint('[TEST] TIMEOUT: $label');
      throw TimeoutException('Timeout during $label');
    },
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!_runEmulatorTests) return;
    await _initFirebaseApps();
  });

  setUp(() async {
    if (!_runEmulatorTests) return;
    // Ensure clean state
    if (_providerAuth.currentUser != null) {
      await _providerAuth.signOut();
    }
    if (_clientAuth.currentUser != null) {
      await _clientAuth.signOut();
    }
  });

  testWidgets(
    'automatic flow: prestador accepts open pedido',
    (tester) async {
      if (!_runEmulatorTests) return;
      await tester.pump();

      debugPrint('[TEST] Step 1: Prestador creates account');
      await _withTimeout(
          _providerAuth.signInAnonymously(), 'prestador sign-in',);
      final prestadorId = _providerAuth.currentUser!.uid;

      await _withTimeout(
        _providerDb.collection('prestadores').doc(prestadorId).set({
          'nome': 'Prestador Teste',
          'servicos': ['s1'],
          'servicosNomes': ['Canalizador'],
          'createdAt': FieldValue.serverTimestamp(),
        }),
        'create prestador',
      );

      debugPrint('[TEST] Step 2: Client creates pedido');
      await _withTimeout(_clientAuth.signInAnonymously(), 'client sign-in');
      final clienteId = _clientAuth.currentUser!.uid;

      final pedidoRef = await _withTimeout(
        _clientDb.collection('pedidos').add({
          'clienteId': clienteId,
          'prestadorId': null,
          'servicoId': 's1',
          'servicoNome': 'Canalizador',
          'categoria': 'Canalizador',
          'titulo': 'Pedido automatico',
          'descricao': 'Teste automatico',
          'modo': 'IMEDIATO',
          'tipoPreco': 'a_combinar',
          'tipoPagamento': 'dinheiro',
          'estado': 'criado',
          'status': 'criado',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        'create pedido',
      );

      debugPrint('[TEST] Step 3: Prestador accepts');
      await _withTimeout(
        _providerDb.collection('pedidos').doc(pedidoRef.id).update({
          'prestadorId': prestadorId,
          'estado': 'aceito',
          'status': 'aceito',
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        'accept pedido',
      );

      debugPrint('[TEST] Step 4: Verification');
      final snap = await _withTimeout(
        _clientDb.collection('pedidos').doc(pedidoRef.id).get(),
        'load pedido',
      );
      expect(snap.data()?['status'], 'aceito', reason: 'status must be aceito');
      expect(
        snap.data()?['prestadorId'],
        prestadorId,
        reason: 'pedido must keep accepting provider uid',
      );
    },
    skip: !_runEmulatorTests,
  );

  testWidgets(
    'manual flow: prestador accepts convite',
    (tester) async {
      if (!_runEmulatorTests) return;
      await tester.pump();

      debugPrint('[TEST] Step 1: Prestador Setup');
      await _withTimeout(
          _providerAuth.signInAnonymously(), 'prestador sign-in',);
      final prestadorId = _providerAuth.currentUser!.uid;

      await _withTimeout(
        _providerDb.collection('prestadores').doc(prestadorId).set({
          'nome': 'Prestador Teste',
          'servicos': ['s1'],
          'servicosNomes': ['Canalizador'],
          'createdAt': FieldValue.serverTimestamp(),
        }),
        'create prestador manual',
      );

      debugPrint('[TEST] Step 2: Client Request');
      await _withTimeout(_clientAuth.signInAnonymously(), 'client sign-in');
      final clienteId = _clientAuth.currentUser!.uid;

      final pedidoRef = await _withTimeout(
        _clientDb.collection('pedidos').add({
          'clienteId': clienteId,
          'prestadorId': prestadorId,
          'servicoId': 's1',
          'servicoNome': 'Canalizador',
          'categoria': 'Canalizador',
          'titulo': 'Pedido manual',
          'descricao': 'Teste manual',
          'modo': 'IMEDIATO',
          'tipoPreco': 'a_combinar',
          'tipoPagamento': 'dinheiro',
          'estado': 'aguarda_resposta_prestador',
          'status': 'aguarda_resposta_prestador',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        'create pedido manual',
      );

      debugPrint('[TEST] Step 3: Prestador Response');
      await _withTimeout(
        _providerDb.collection('pedidos').doc(pedidoRef.id).update({
          'estado': 'aceito',
          'status': 'aceito',
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        'accept pedido manual',
      );

      debugPrint('[TEST] Step 4: Validate');
      final snap = await _withTimeout(
        _clientDb.collection('pedidos').doc(pedidoRef.id).get(),
        'load pedido manual',
      );
      expect(
        snap.data()?['status'],
        'aceito',
        reason: 'manual pedido status must be aceito',
      );
      expect(
        snap.data()?['prestadorId'],
        prestadorId,
        reason: 'manual pedido must keep selected provider uid',
      );
    },
    skip: !_runEmulatorTests,
  );
}
