import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/services/call_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';

class _FakeUser implements User {
  _FakeUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth implements FirebaseAuth {
  _FakeAuth(this._currentUser);

  final User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ChatService', () {
    test(
        'handles cliente/prestador messages with unread, delivered and seen flags',
        () async {
      final db = FakeFirebaseFirestore();
      final clienteAuth = _FakeAuth(_FakeUser('cliente_1'));
      final prestadorAuth = _FakeAuth(_FakeUser('prestador_1'));

      const pedidoId = 'pedido_1';

      await db.collection('pedidos').doc(pedidoId).set({
        'clienteId': 'cliente_1',
        'prestadorId': 'prestador_1',
        'titulo': 'Teste completo',
      });

      final chatCliente = ChatService(firestore: db, auth: clienteAuth);
      final chatPrestador = ChatService(firestore: db, auth: prestadorAuth);

      await chatCliente.sendMessage(
        pedidoId: pedidoId,
        text: 'Oi, preciso de ajuda hoje.',
        senderId: 'cliente_1',
        senderRole: 'cliente',
      );

      await chatPrestador.sendMessage(
        pedidoId: pedidoId,
        text: 'Perfeito, posso ir agora.',
        senderId: 'prestador_1',
        senderRole: 'prestador',
      );

      await chatPrestador.sendMessage(
        pedidoId: pedidoId,
        senderId: 'prestador_1',
        senderRole: 'prestador',
        extra: const <String, dynamic>{
          'type': 'call',
          'callType': 'video',
          'mediaUrl': 'https://example.com/call',
        },
      );

      final chatSnap = await db.collection('chats').doc(pedidoId).get();
      final chatData = chatSnap.data();

      expect(chatData, isNotNull);
      expect(chatData?['unreadByPrestador'], 1);
      expect(chatData?['unreadByCliente'], 2);
      expect(chatData?['hasUnreadPrestador'], isTrue);
      expect(chatData?['hasUnreadCliente'], isTrue);
      expect(chatData?['lastMessage'], 'Chamada de video');

      final threadsCliente = await chatCliente
          .streamThreadsForUser(uid: 'cliente_1', role: 'cliente')
          .first;
      final threadsPrestador = await chatPrestador
          .streamThreadsForUser(uid: 'prestador_1', role: 'prestador')
          .first;

      expect(threadsCliente.docs, hasLength(1));
      expect(threadsPrestador.docs, hasLength(1));

      await chatCliente.marcarEntreguesParaRole(
        pedidoId: pedidoId,
        role: 'cliente',
      );
      await chatCliente.marcarVistasParaRole(
        pedidoId: pedidoId,
        role: 'cliente',
      );

      final msgSnap = await db
          .collection('chats')
          .doc(pedidoId)
          .collection('messages')
          .orderBy('createdAt')
          .get();

      expect(msgSnap.docs, hasLength(3));

      final prestadorMsgs = msgSnap.docs
          .map((d) => d.data())
          .where((m) => m['senderRole'] == 'prestador')
          .toList();

      expect(prestadorMsgs, hasLength(2));
      for (final msg in prestadorMsgs) {
        expect(msg['deliveredToCliente'], isTrue);
        expect(msg['seenByCliente'], isTrue);
      }

      final chatAfterSeen =
          (await db.collection('chats').doc(pedidoId).get()).data();
      expect(chatAfterSeen?['hasUnreadCliente'], isFalse);
      expect(chatAfterSeen?['unreadByCliente'], 0);
    });

    test('marcarVistasParaRole backfills pedidoId when chat meta is missing',
        () async {
      final db = FakeFirebaseFirestore();
      final clienteAuth = _FakeAuth(_FakeUser('cliente_1'));
      final chatCliente = ChatService(firestore: db, auth: clienteAuth);

      const pedidoId = 'pedido_2';

      await db.collection('pedidos').doc(pedidoId).set({
        'clienteId': 'cliente_1',
        'prestadorId': 'prestador_1',
        'titulo': 'Pedido sem meta',
      });

      await db.collection('chats').doc(pedidoId).collection('messages').add({
        'senderRole': 'prestador',
        'seenByCliente': false,
        'createdAt': DateTime.now(),
      });

      await chatCliente.marcarVistasParaRole(
        pedidoId: pedidoId,
        role: 'cliente',
      );

      final chatData =
          (await db.collection('chats').doc(pedidoId).get()).data();
      expect(chatData, isNotNull);
      expect(chatData?['pedidoId'], pedidoId);
      expect(chatData?['hasUnreadCliente'], isFalse);
      expect(chatData?['unreadByCliente'], 0);
    });
  });

  group('CallService', () {
    test('creates call, accepts and ends', () async {
      final db = FakeFirebaseFirestore();
      final clienteAuth = _FakeAuth(_FakeUser('cliente_1'));
      final callService = CallService(firestore: db, auth: clienteAuth);

      const pedidoId = 'pedido_call_1';
      final callId = await callService.createCall(
        pedidoId: pedidoId,
        calleeId: 'prestador_1',
        callerRole: 'cliente',
        calleeRole: 'prestador',
        videoEnabled: true,
      );

      final incoming = await callService
          .streamIncomingCalls(pedidoId: pedidoId, calleeId: 'prestador_1')
          .first;
      expect(incoming.docs, hasLength(1));
      expect(incoming.docs.first.id, callId);

      await callService.updateStatus(callId, 'accepted');
      await callService.endCall(callId);

      final callSnap = await db.collection('calls').doc(callId).get();
      final callData = callSnap.data();

      expect(callData, isNotNull);
      expect(callData?['pedidoId'], pedidoId);
      expect(callData?['callerId'], 'cliente_1');
      expect(callData?['calleeId'], 'prestador_1');
      expect(callData?['videoEnabled'], isTrue);
      expect(callData?['status'], 'ended');
      expect(callData?['acceptedAt'], isNotNull);
      expect(callData?['endedAt'], isNotNull);
    });
  });
}
