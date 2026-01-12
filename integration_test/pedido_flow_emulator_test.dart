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

late FirebaseApp _app;
late FirebaseAuth _auth;
late FirebaseFirestore _db;

String _emulatorHost() {
  if (kIsWeb) return 'localhost';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return '10.0.2.2';
  }
  return 'localhost';
}

Future<void> _initFirebaseApps() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  _app = Firebase.app();
  _auth = FirebaseAuth.instanceFor(app: _app);
  _db = FirebaseFirestore.instanceFor(app: _app);

  final host = _emulatorHost();
  _auth.useAuthEmulator(host, 9099);
  _db.useFirestoreEmulator(host, 8080);

  _db.settings = const Settings(persistenceEnabled: false);
}

Future<T> _withTimeout<T>(Future<T> future, String label) {
  return future.timeout(
    const Duration(seconds: 20),
    onTimeout: () => throw TimeoutException('Timeout during $label'),
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
    await _auth.signOut();
  });

  testWidgets(
    'automatic flow: prestador accepts open pedido',
    (tester) async {
      if (!_runEmulatorTests) return;
      await tester.pump();

      await _withTimeout(_auth.signInAnonymously(), 'prestador sign-in');
      final prestadorId = _auth.currentUser!.uid;

      await _withTimeout(
        _db.collection('prestadores').doc(prestadorId).set({
          'nome': 'Prestador Teste',
          'createdAt': FieldValue.serverTimestamp(),
        }),
        'create prestador',
      );

      await _withTimeout(_auth.signOut(), 'prestador sign-out');
      await _withTimeout(_auth.signInAnonymously(), 'client sign-in');
      final clienteId = _auth.currentUser!.uid;

      final pedidoRef = await _withTimeout(
        _db.collection('pedidos').add({
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

      await _withTimeout(
        _auth.signOut(),
        'client sign-out',
      );
      await _withTimeout(_auth.signInAnonymously(), 'prestador sign-in accept');

      await _withTimeout(
        _db.collection('pedidos').doc(pedidoRef.id).update({
          'prestadorId': prestadorId,
          'estado': 'aceito',
          'status': 'aceito',
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        'accept pedido',
      );

      await _withTimeout(
        _auth.signOut(),
        'prestador sign-out',
      );
      await _withTimeout(_auth.signInAnonymously(), 'client sign-in validate');

      final snap = await _withTimeout(
        _db.collection('pedidos').doc(pedidoRef.id).get(),
        'load pedido',
      );
      expect(snap.data()?['status'], 'aceito');
      expect(snap.data()?['prestadorId'], prestadorId);
    },
    skip: !_runEmulatorTests,
  );

  testWidgets(
    'manual flow: prestador accepts convite',
    (tester) async {
      if (!_runEmulatorTests) return;
      await tester.pump();

      await _withTimeout(_auth.signInAnonymously(), 'prestador sign-in');
      final prestadorId = _auth.currentUser!.uid;

      await _withTimeout(
        _db.collection('prestadores').doc(prestadorId).set({
          'nome': 'Prestador Teste',
          'createdAt': FieldValue.serverTimestamp(),
        }),
        'create prestador manual',
      );

      await _withTimeout(_auth.signOut(), 'prestador sign-out');
      await _withTimeout(_auth.signInAnonymously(), 'client sign-in');
      final clienteId = _auth.currentUser!.uid;

      final pedidoRef = await _withTimeout(
        _db.collection('pedidos').add({
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

      await _withTimeout(
        _auth.signOut(),
        'client sign-out',
      );
      await _withTimeout(_auth.signInAnonymously(), 'prestador sign-in accept');

      await _withTimeout(
        _db.collection('pedidos').doc(pedidoRef.id).update({
          'estado': 'aceito',
          'status': 'aceito',
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        'accept pedido manual',
      );

      await _withTimeout(
        _auth.signOut(),
        'prestador sign-out',
      );
      await _withTimeout(_auth.signInAnonymously(), 'client sign-in validate');

      final snap = await _withTimeout(
        _db.collection('pedidos').doc(pedidoRef.id).get(),
        'load pedido manual',
      );
      expect(snap.data()?['status'], 'aceito');
      expect(snap.data()?['prestadorId'], prestadorId);
    },
    skip: !_runEmulatorTests,
  );
}
