import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'core/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- CONFIGURAÇÃO DE EMULADORES (A2) ---
  if (kDebugMode) {
    // Mude para true se quiser usar o emulador local
    const bool useEmulators = false;

    if (useEmulators) {
      try {
        // 10.0.2.2 é o IP do host para o emulador Android
        final host = defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost';

        await FirebaseAuth.instance.useAuthEmulator(host, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        await FirebaseStorage.instance.useStorageEmulator(host, 9199);
        print('🔥 Firebase Emulators conectados! Host: $host (Auth:9099, Firestore:8080, Storage:9199)');
      } catch (e) {
        print('⚠️ Erro ao conectar aos emuladores: $e');
      }
    }
  }

  // Garante que existe um utilizador autenticado (login anónimo)
  try {
    await AuthService.ensureSignedInAnonymously();
  } catch (e, st) {
    // Não rebenta a app se der erro de permissões.
    // Apenas regista no log para investigação.
    // ignore: avoid_print
    print('Erro ao autenticar/gravar user anónimo: $e\n$st');
  }

  // Inicia a app
  runApp(const ChegaJaApp());
}
