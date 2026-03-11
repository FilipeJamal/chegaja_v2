# AGENTS.md - ChegaJa v2

Este arquivo orienta como os agentes devem trabalhar neste repositorio.

**Skills a usar (quando aplicavel)**
- `flutter-expert` para Flutter/Dart, widgets, arquitetura e performance.
- `mobile-developer` para integracoes mobile e multi-plataforma.
- `mobile-design` para UX mobile, navegacao e gestos.
- `firebase` para Auth, Firestore, Functions, Storage, regras e indexes.
- `backend-dev-guidelines` e `nodejs-backend-patterns` para Functions (Node) e APIs.
- `testing-patterns` para testes unitarios e de integracao.
- `debugging-strategies` ou `error-detective` para bugs e investigacao de erros.
- `application-performance-performance-optimization` para performance.
- `mobile-security-coder` para hardening e seguranca mobile.
- `code-reviewer` ou `codex-review` para revisoes de codigo.

**Regras do projeto**
- Rodar `flutter pub get` apos mudar dependencias.
- Nao commitar `.env` nem segredos; usar `.env.example`.
- Em dev local, preferir emuladores Firebase conforme `README.md`.
- Para Functions, trabalhar em `functions/` e usar `npm install` quando necessario.
- Respeitar a estrutura existente em `lib/` e evitar reformatar arquivos fora do escopo.

**Comandos uteis**
- `flutter pub get`
- `flutter run -d chrome`
- `flutter test`
- `dart format .`
- `firebase emulators:start`
