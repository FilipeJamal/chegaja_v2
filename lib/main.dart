import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'core/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
