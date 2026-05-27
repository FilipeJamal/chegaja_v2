import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/chat_message.dart';

void main() {
  test('ChatMessage parses legacy latitude longitude fields as location',
      () async {
    final db = FakeFirebaseFirestore();
    final ref =
        db.collection('chats').doc('p1').collection('messages').doc('m1');
    await ref.set({
      'pedidoId': 'p1',
      'text': 'Localizacao aproximada: https://maps.google.com/?q=40.1,-8.2',
      'senderRole': 'cliente',
      'senderId': 'client1',
      'createdAt': Timestamp.fromDate(DateTime(2026, 5, 27)),
      'seenByCliente': true,
      'seenByPrestador': false,
      'deliveredToCliente': true,
      'deliveredToPrestador': true,
      'type': 'location',
      'latitude': 40.1,
      'longitude': -8.2,
    });

    final snapshot = await db
        .collection('chats')
        .doc('p1')
        .collection('messages')
        .limit(1)
        .get();
    final message = ChatMessage.fromFirestore(snapshot.docs.single);

    expect(message.isLocation, isTrue);
    expect(message.mapsUri?.toString(), 'https://maps.google.com/?q=40.1,-8.2');
  });
}
