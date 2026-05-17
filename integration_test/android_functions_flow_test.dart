import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';
import 'package:chegaja_v2/firebase_options.dart';

const bool _runEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);
const bool _runFunctionsEmulatorTests = bool.fromEnvironment(
  'RUN_FIREBASE_FUNCTIONS_EMULATOR_TESTS',
  defaultValue: false,
);

bool get _shouldRun =>
    _runEmulatorTests &&
    _runFunctionsEmulatorTests &&
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android;

late FirebaseAuth _auth;
late FirebaseFirestore _db;

Future<void> _initFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  _auth = FirebaseAuth.instance;
  _db = FirebaseFirestore.instance;

  final host = defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';

  try {
    await _auth.useAuthEmulator(host, 9099);
    _db.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion)
        .useFunctionsEmulator(host, 5001);
  } catch (_) {
    // A segunda execucao no mesmo processo pode ja ter os emuladores ligados.
  }

  try {
    _db.settings = const Settings(persistenceEnabled: false);
  } catch (_) {}
}

Future<User> _signInEmail(String label) async {
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final email = '$label.$suffix@functions.test';
  const password = 'Password123!';
  final credential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  return credential.user!;
}

Future<void> _seedUser({
  required String uid,
  required String role,
}) {
  return _db.collection('users').doc(uid).set(
    {
      'uid': uid,
      'activeRole': role,
      'roles.$role': true,
      'region': 'PT',
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}

Future<void> _seedProvider({
  required String uid,
  required String serviceId,
  required String serviceName,
}) {
  return _db.collection('prestadores').doc(uid).set(
    {
      'nome': 'Prestador Functions Emulator',
      'isOnline': true,
      'servicos': [serviceId],
      'servicosNomes': [serviceName],
      'radiusKm': 50,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}

Future<String> _createPedidoAsClient({
  required String clienteId,
  required String serviceId,
  required String serviceName,
}) async {
  final ref = await _db.collection('pedidos').add({
    'clienteId': clienteId,
    'prestadorId': null,
    'servicoId': serviceId,
    'servicoNome': serviceName,
    'categoria': serviceName,
    'titulo': 'Android Functions ${DateTime.now().microsecondsSinceEpoch}',
    'descricao': 'Pedido para validar Functions Emulator',
    'modo': 'IMEDIATO',
    'tipoPreco': 'a_combinar',
    'tipoPagamento': 'dinheiro',
    'estado': 'criado',
    'status': 'criado',
    'statusProposta': 'nenhuma',
    'statusConfirmacaoValor': 'nenhum',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'latitude': null,
    'longitude': null,
    'enderecoTexto': 'Rua de teste Functions',
  });
  return ref.id;
}

Future<Pedido> _pedido(String pedidoId) async {
  final snap = await _db.collection('pedidos').doc(pedidoId).get();
  final data = snap.data();
  if (data == null) throw StateError('Pedido $pedidoId nao encontrado');
  return Pedido.fromMap(snap.id, data);
}

Future<Map<String, dynamic>> _pedidoRaw(String pedidoId) async {
  final snap = await _db.collection('pedidos').doc(pedidoId).get();
  final data = snap.data();
  if (data == null) throw StateError('Pedido $pedidoId nao encontrado');
  return data;
}

Future<Pedido> _waitPedido(
  String pedidoId,
  bool Function(Pedido pedido) predicate,
  String label,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 75));
  Object? lastError;
  while (DateTime.now().isBefore(deadline)) {
    try {
      final pedido = await _pedido(pedidoId);
      if (predicate(pedido)) return pedido;
    } catch (error) {
      lastError = error;
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  throw TimeoutException('Timeout aguardando $label. Ultimo erro: $lastError');
}

void _expectMoney(Pedido pedido, double finalValue) {
  expect(pedido.precoFinal, finalValue);
  expect(pedido.earningsTotal, finalValue);
  expect(pedido.commissionPlatform, closeTo(finalValue * 0.15, 0.001));
  expect(pedido.earningsProvider, closeTo(finalValue * 0.85, 0.001));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (!_shouldRun) return;
    await _initFirebase();
  });

  tearDown(() async {
    if (!_shouldRun) return;
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }
  });

  testWidgets(
    'Android usa Functions Emulator para valor final autoritativo',
    (tester) async {
      if (!_shouldRun) return;

      final serviceId =
          'svc_functions_${DateTime.now().microsecondsSinceEpoch}';
      const serviceName = 'Eletricista Functions';

      final client = await _signInEmail('client');
      await _seedUser(uid: client.uid, role: 'cliente');
      final pedidoId = await _createPedidoAsClient(
        clienteId: client.uid,
        serviceId: serviceId,
        serviceName: serviceName,
      );
      await _auth.signOut();

      final provider = await _signInEmail('provider');
      await _seedUser(uid: provider.uid, role: 'prestador');
      await _seedProvider(
        uid: provider.uid,
        serviceId: serviceId,
        serviceName: serviceName,
      );

      var pedido = await _pedido(pedidoId);
      await PedidoService.instance.aceitarPedidoAberto(
        pedido: pedido,
        prestadorId: provider.uid,
      );
      pedido = await _pedido(pedidoId);
      await PedidoService.instance.iniciarServico(
        pedido: pedido,
        prestadorId: provider.uid,
      );
      pedido = await _pedido(pedidoId);
      await PedidoService.instance.proporValorFinal(
        pedido: pedido,
        prestadorId: provider.uid,
        valorFinal: 125,
      );

      pedido = await _waitPedido(
        pedidoId,
        (p) =>
            p.estado == 'aguarda_confirmacao_valor' &&
            p.statusConfirmacaoValor == 'pendente_cliente',
        'valor final proposto por Function',
      );
      var raw = await _pedidoRaw(pedidoId);
      expect(raw['lastAuthoritativeFunction'], 'proporValorFinalPedido');
      await _auth.signOut();

      await _auth.signInWithEmailAndPassword(
        email: client.email!,
        password: 'Password123!',
      );
      await PedidoService.instance.confirmarValorFinal(
        pedido: pedido,
        clienteId: client.uid,
        valorFinal: 125,
      );

      final finalPedido = await _waitPedido(
        pedidoId,
        (p) => p.estado == 'concluido',
        'pedido concluido por Function',
      );
      raw = await _pedidoRaw(pedidoId);

      expect(finalPedido.status, 'concluido');
      expect(finalPedido.statusConfirmacaoValor, 'confirmado_cliente');
      _expectMoney(finalPedido, 125);
      expect(raw['lastAuthoritativeFunction'], 'confirmarValorFinalPedido');
    },
    skip: !_shouldRun,
  );
}
