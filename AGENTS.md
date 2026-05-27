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
- Nao apagar nem commitar alteracoes acidentais nos ficheiros temporarios `~$...pptx`.
- Nao alterar Firestore Rules, Storage Rules ou Cloud Functions sem necessidade explicita.
- Nao dizer que teste, build, deploy, commit ou push foi feito sem prova real no terminal.
- Preservar os fluxos Cliente/Prestador e validar os dois lados quando a mudanca tocar pedido, chat, orcamento, valor final ou estados.

**Workflow Codex App inspirado no video**
- Metodo principal: `docs/codex_app_workflow/CODEX_APP_WORKFLOW_FROM_VIDEO.md`.
- Ciclo de feature: `docs/codex_app_workflow/CHEGAJA_FEATURE_CYCLE.md`.
- Prototipo antes de mexer em UI/fluxo incerto: `docs/codex_app_workflow/PROTOTYPE_FIRST_METHOD.md`.
- QA visual por screenshot: `docs/codex_app_workflow/VISUAL_QA_SCREENSHOT_PLAYBOOK.md`.
- Regras de teste/commit: `docs/codex_app_workflow/COMMIT_AND_TEST_RULES.md`.
- Prompts prontos: `docs/codex_app_workflow/prompts/`.
- Checklists: `docs/codex_app_workflow/checklists/`.

Para tarefas visuais ou de produto, trabalhar em ciclos pequenos:
1. entender objetivo;
2. identificar ficheiros provaveis;
3. declarar riscos;
4. implementar escopo limitado;
5. validar com testes/screenshot quando aplicavel;
6. fazer commit antes de avancar para outro bloco.

**Comandos uteis**
- `flutter pub get`
- `flutter run -d chrome`
- `flutter test`
- `dart format .`
- `firebase emulators:start`
- `powershell -ExecutionPolicy Bypass -File scripts\chegaja_preflight_windows.ps1`
