import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:chegaja_v2/core/config/app_config.dart';

class FirebaseHttpSecurityHeaders {
  const FirebaseHttpSecurityHeaders._();

  static Future<Map<String, String>> build() async {
    if (AppConfig.useFirebaseEmulators) return const <String, String>{};
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Autenticacao obrigatoria.');
    final results = await Future.wait<String?>([
      user.getIdToken(),
      FirebaseAppCheck.instance.getToken(),
    ]);
    final idToken = results[0]?.trim() ?? '';
    final appCheckToken = results[1]?.trim() ?? '';
    if (idToken.isEmpty || appCheckToken.isEmpty) {
      throw StateError('Nao foi possivel validar esta instalacao.');
    }
    return <String, String>{
      'Authorization': 'Bearer $idToken',
      'X-Firebase-AppCheck': appCheckToken,
    };
  }
}
