# M2.19.6 - QA Final Link Publico, @handle e Partilha Social

Data: 2026-05-31

## Estado

M2.19.6 concluida.

```text
M2.19 - FECHADA no escopo atual de link publico, @handle e partilha social
M2.19.1 - FECHADA
M2.19.2 - FECHADA
M2.19.3 - FECHADA
M2.19.4 - FECHADA
M2.19.5 - FECHADA
M2.19.6 - FECHADA
M2.18 - FECHADA no escopo atual
Bloco F - PARCIAL
Bloco H - PARCIAL
Bloco J - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo

Fechar a M2.19 com testes, E2E, QA visual e documentacao final, sem criar
feature nova.

## Escopo Validado

```text
normalizacao e validacao de @handle;
reserva/unicidade de handle;
HandleService;
rota publica /p/{handle};
DeepLinkService;
PublicHandleResolver;
PublicProfileByHandleScreen;
404 amigavel;
UI de handle no perfil do prestador;
display de @handle no perfil publico e discovery;
copiar link;
partilha WhatsApp/Facebook por URL;
Instagram tratado como copiar link;
telefone oculto por defeito no perfil publico.
```

## Comandos Executados

```text
git status
git diff --check
npm.cmd run test:scripts
node --check functions/index.js
npm.cmd --prefix functions test
npm.cmd --prefix functions test com FIRESTORE_EMULATOR_HOST/FIREBASE_STORAGE_EMULATOR_HOST/GCLOUD_PROJECT
flutter test --no-pub test/core/handle_normalizer_test.dart
flutter test --no-pub test/core/handle_validator_test.dart
flutter test --no-pub test/core/public_handle_test.dart
flutter test --no-pub test/core/handle_service_test.dart
flutter test --no-pub test/core/public_handle_resolver_test.dart
flutter test --no-pub test/core/public_profile_link_service_test.dart
flutter test --no-pub test/core/deep_link_service_test.dart
flutter test --no-pub test/features/prestador/prestador_handle_section_test.dart
flutter test --no-pub test/features/common/perfil_publico_screen_test.dart
flutter test --no-pub test/features/common/public_profile_by_handle_screen_test.dart
flutter test --no-pub test/features/common/widgets/public_profile_share_actions_test.dart
flutter test --no-pub test/features/cliente/discovery/provider_search_profile_test.dart
flutter test --no-pub test/features/cliente/discovery/provider_search_card_test.dart
flutter test --no-pub test/app_public_handle_route_test.dart
flutter test --no-pub
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m2196-visual-qa --wait-ms=12000
Playwright headless em http://127.0.0.1:5174/p/handle-inexistente
```

## Resultados

```text
git diff --check - passou
npm.cmd run test:scripts - passou
node --check functions/index.js - passou
Functions tests - passaram com emulador configurado, 134 passing
testes focados de handle/rota/partilha - passaram
test/app_public_handle_route_test.dart - passou, 4/4
flutter test --no-pub - passou, 371/371
build Web release - passou
e2e:ui:dual - passou, FULL MULTI-SCENARIO FLOW OK
e2e:ui:orcamento - passou, ORCAMENTO MIN-MAX FLOW OK
QA visual - passou, 8 screenshots
/p/handle-inexistente - 404 amigavel validado, consoleErrors = 0
```

## Observacoes Tecnicas

O comando cru `npm.cmd --prefix functions test`, executado sem variaveis de
emulador, falhou por credenciais default ausentes. A validacao correta foi feita
com:

```text
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199
GCLOUD_PROJECT=chegaja-ac88d
```

Com esse ambiente, os testes de Functions passaram com `134 passing`.

Durante o QA especifico de link publico, a abertura direta de
`/p/handle-inexistente` inicialmente caia no seletor de perfil porque o
`MaterialApp` usava `home` e a rota inicial do browser nao era aplicada ao
`onGenerateRoute`. A correcao ficou limitada a `lib/app.dart`:

```text
publicProfileHandleFromRouteName(...)
home inicial usa PublicProfileByHandleScreen quando Uri.base aponta para /p/{handle}
```

O teste `test/app_public_handle_route_test.dart` foi ampliado para cobrir rota
relativa e URL absoluta. Depois da correcao, `/p/handle-inexistente` mostrou o
404 amigavel com `consoleErrors = 0`.

O build Web passou com avisos nao bloqueantes ja conhecidos do dry-run Wasm em
`dart_webrtc`.

## QA Visual

O QA visual geral gerou 8 screenshots em:

```text
C:\Users\Jamal\AppData\Local\Temp\chegaja-m2196-visual-qa
```

Tambem foi validado headless:

```text
http://127.0.0.1:5174/p/handle-inexistente
```

Resultado:

```text
Perfil nao encontrado renderizado;
mensagem amigavel renderizada;
consoleErrors = 0.
```

Nao havia dado semeado estavel de handle valido para abrir um perfil real por
URL durante este QA. Essa parte ficou coberta por `PublicHandleResolver`,
`PublicProfileByHandleScreen`, `app_public_handle_route_test` e testes do perfil
publico/partilha.

## Fora do Escopo Mantido

```text
feature nova
QR Code real
SEO/metatags dinamicas
dominio customizado
deploy
App Links/Universal Links reais
Firebase Dynamic Links
analytics de partilha
nova dependencia de partilha nativa
KYC
pagamentos
Android fisico
tester externo
fechar R
fechar R1
fechar M
fechar M2.6
iniciar M2.20
```

## Rules, Functions e Deploy

```text
Firestore Rules nao foram alteradas nesta fase.
Storage Rules nao foram alteradas nesta fase.
Cloud Functions nao foram alteradas nesta fase.
Deploy nao foi feito.
```

## Decisao Final

M2.19 fica fechada no escopo atual de link publico, @handle e partilha social.

Proximo bloco recomendado:

```text
M2.20 - Categorias sensiveis e comprovativos profissionais
```

Nao iniciar M2.20 neste fecho.
