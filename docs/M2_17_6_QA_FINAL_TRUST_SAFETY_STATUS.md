# M2.17.6 - QA Final Trust & Safety

Data: 2026-05-29

## Estado

M2.17.6 concluida.

```text
M2.17 - FECHADA no escopo atual de Trust & Safety basico
Bloco F - PARCIAL
Bloco H - PARCIAL
R - pausado por falta de tester humano real
M - pausado por falta de Android fisico real
R1 - pendente
M2.6 - pendente
```

## Objetivo

Fechar a M2.17 com prova tecnica, sem criar feature nova.

A fase validou:

```text
modelos de denuncias, bloqueios e moderacao;
Rules de reports e blockedUsers;
TrustSafetyService;
UI de denuncia/bloqueio;
denuncia de perfil, conversa, mensagem e imagem;
fila admin basica de reports;
filtros simples de servicos proibidos e categorias sensiveis;
fluxos principais Cliente/Prestador.
```

## Comandos Executados

```text
git status
git diff --check
npm.cmd run test:scripts
node --check functions/index.js
npm.cmd --prefix functions test
flutter test --no-pub test/core/trust_safety_models_test.dart
flutter test --no-pub test/core/trust_safety_service_test.dart
flutter test --no-pub test/core/trust_safety_text_normalizer_test.dart
flutter test --no-pub test/core/trust_safety_classifier_test.dart
flutter test --no-pub test/core/sensitive_categories_test.dart
flutter test --no-pub test/features/common/trust_safety/report_content_sheet_test.dart
flutter test --no-pub test/features/common/trust_safety/block_user_dialog_test.dart
flutter test --no-pub test/features/common/perfil_publico_trust_safety_actions_test.dart
flutter test --no-pub test/features/common/widgets/media_viewer_screen_test.dart
flutter test --no-pub test/features/admin/admin_reports_section_test.dart
flutter test --no-pub test/features/cliente/novo_pedido_screen_test.dart
flutter test --no-pub test/features/prestador/prestador_perfil_portfolio_test.dart
flutter test --no-pub
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m2176-visual-qa --wait-ms=12000
```

## Resultado dos Testes

```text
git diff --check - passou
npm.cmd run test:scripts - passou
node --check functions/index.js - passou
npm.cmd --prefix functions test - passou, 119 passing
testes focados de Trust & Safety - passaram
testes focados de UI denuncia/bloqueio - passaram
testes focados de media viewer/admin/perfil/novo pedido/perfil prestador - passaram
flutter test --no-pub - passou, 289/289
```

As mensagens `PERMISSION_DENIED` no output de Functions/Rules fazem parte dos
testes negativos esperados.

## Build Web

```text
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release
```

Resultado: passou.

Observacao: o build mostrou avisos de dry run WebAssembly em dependencia
`dart_webrtc`. Isto nao bloqueou o build Web release atual.

## E2E

```text
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual
```

Resultado: passou.

```text
FULL MULTI-SCENARIO FLOW OK
```

```text
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento
```

Resultado: passou.

```text
ORCAMENTO MIN-MAX FLOW OK
```

## QA Visual

Comando executado:

```text
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m2176-visual-qa --wait-ms=12000
```

Resultado: passou.

Screenshots gerados:

```text
home_cliente__mobile
home_cliente__tablet
home_cliente__desktop
home_cliente__wide
home_prestador__mobile
home_prestador__tablet
home_prestador__desktop
home_prestador__wide
```

Limitacao documentada: o script visual atual cobre Home Cliente e Home
Prestador. As superficies especificas de Trust & Safety, como sheet de
denuncia, dialog de bloqueio, MediaViewer e secao admin de reports, foram
validadas por testes de widget focados nesta fase.

## Observacoes Tecnicas

Nenhuma feature nova foi criada nesta fase.

Nao houve alteracao de:

```text
Dart funcional;
Firestore Rules;
Storage Rules;
Cloud Functions;
deploy;
KYC;
pagamentos;
Android fisico;
tester externo.
```

O bloqueio continua gravado em `users/{uid}/blockedUsers/{blockedUid}`, mas
enforcement completo no chat ainda fica para fase futura.

Os filtros de Trust & Safety continuam sendo camada preventiva client-side. A
validacao server-side de casos criticos continua necessaria antes de producao
publica em escala.

Conteudo denunciado ainda nao e ocultado automaticamente. Banimento automatico,
moderacao automatica/assistida, `moderationCases` automaticos e admin completo
continuam fora do escopo atual.

## Decisao Final

M2.17.6 concluida.

M2.17 fica fechada no escopo atual de Trust & Safety basico:

```text
denuncias;
bloqueios;
Rules e testes;
UI de denuncia/bloqueio;
fila admin basica;
filtros simples de servicos proibidos/categorias sensiveis;
QA final.
```

Proximo passo recomendado:

```text
M2.18 - Admin/backoffice leve para operacao interna
```
