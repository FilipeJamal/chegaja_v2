# ChegaJá v2 — Fix Emuladores (local)

Este patch faz 2 coisas:

1) Garante que, ao entrar no Home, a role ativa é definida (cliente/prestador) sem usar `AuthService()`.
2) Cria um ficheiro de regras **LOCAL** (`firestore.rules.local`) + `firebase.local.json` para o emulador,
   permitindo que a seed de categorias (coleção `servicos`) funcione no Firestore Emulator.

## Como usar (Windows)

1. Copia estes ficheiros para a raiz do teu projeto, mantendo as pastas:
   - `lib/features/cliente/cliente_home_screen.dart`
   - `lib/features/prestador/prestador_home_screen.dart`
   - `firestore.rules.local`
   - `firebase.local.json`

2. Arranca emuladores com o config local:

   `firebase.cmd emulators:start --config firebase.local.json --only auth,firestore,functions,storage --project chegaja-ac88d`

3. Corre o Flutter Web em modo emulador:

   `flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true`

Nota: **Nunca** faças deploy do `firestore.rules.local`.
