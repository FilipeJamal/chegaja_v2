# M2.20.6 - QA Final Categorias Sensiveis

Data: 2026-06-01

## Estado

M2.20.6 concluida.

```text
M2.20 - FECHADA no escopo atual de categorias sensiveis e comprovativos profissionais
M2.20.1 - FECHADA
M2.20.2 - FECHADA
M2.20.3 - FECHADA
M2.20.4 - FECHADA
M2.20.5 - FECHADA
M2.20.6 - FECHADA
M2.19 - FECHADA no escopo atual
Bloco F - PARCIAL
Bloco H - PARCIAL
Bloco J - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo

Fechar a M2.20 com validacao final, E2E, QA visual e documentacao, sem criar
feature nova.

## Resultado

A M2.20 fica fechada no escopo atual:

```text
modelo de categoria sensivel;
pedido de aprovacao do prestador;
admin leve para analise;
approval por categoria;
audit log leve;
resumo publico seguro;
perfil/discovery/pedido integrados;
matching respeitando approval onde implementado.
```

## Comandos Executados

```text
git status - executado
git diff --check - passou
npm.cmd run test:scripts - passou
node --check functions/index.js - passou
npm.cmd --prefix functions test - passou dentro do Firestore/Storage Emulator, 151 passing
flutter test --no-pub test/core/category_requirement_test.dart - passou
flutter test --no-pub test/core/sensitive_category_request_test.dart - passou
flutter test --no-pub test/core/provider_category_approval_test.dart - passou
flutter test --no-pub test/core/category_approval_service_test.dart - passou
flutter test --no-pub test/core/pedido_service_test.dart - passou
flutter test --no-pub test/features/prestador/prestador_sensitive_categories_section_test.dart - passou
flutter test --no-pub test/features/prestador/sensitive_category_request_sheet_test.dart - passou
flutter test --no-pub test/features/prestador/prestador_settings_sensitive_categories_test.dart - passou
flutter test --no-pub test/features/admin/admin_sensitive_category_requests_section_test.dart - passou
flutter test --no-pub test/features/admin/admin_sensitive_category_decision_sheet_test.dart - passou
flutter test --no-pub test/features/admin/admin_panel_navigation_test.dart - passou
flutter test --no-pub test/features/common/perfil_publico_screen_test.dart - passou
flutter test --no-pub test/features/cliente/discovery/provider_search_profile_test.dart - passou
flutter test --no-pub test/features/cliente/discovery/provider_search_card_test.dart - passou
flutter test --no-pub test/features/cliente/widgets/provider_suggestions_section_test.dart - passou
flutter test --no-pub test/features/cliente/novo_pedido_screen_test.dart - passou
flutter test --no-pub - passou, 414/414
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual - passou, FULL MULTI-SCENARIO FLOW OK
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento - passou, ORCAMENTO MIN-MAX FLOW OK
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m2206-visual-qa --wait-ms=12000 - passou com emuladores Auth/Firestore/Storage, 8 screenshots
```

## Resultado dos Testes Dart/Flutter

Os testes focados de modelos, services, UI do prestador, admin,
perfil/discovery e pedido passaram. O Flutter completo tambem passou:

```text
flutter test --no-pub - 414/414
```

## Resultado das Functions/Rules

As Functions/Rules passaram no Emulator Suite:

```text
npm.cmd --prefix functions test - 151 passing
```

As mensagens `PERMISSION_DENIED` no output pertencem aos testes negativos de
Rules.

## Resultado do Build Web

O build Web release passou:

```text
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release
```

Observacao: o build manteve os avisos conhecidos de Wasm dry run em
`dart_webrtc`, sem falhar o build.

## Resultado dos E2E

Os E2E obrigatorios passaram contra `http://127.0.0.1:5174` com emuladores
Auth/Firestore/Storage:

```text
e2e:ui:dual - FULL MULTI-SCENARIO FLOW OK
e2e:ui:orcamento - ORCAMENTO MIN-MAX FLOW OK
```

Observacao: no E2E de orcamento apareceu novamente o erro interno conhecido do
SDK Firestore no console do browser/emulator apos o envio do orcamento, mas o
pedido terminou concluido e o script passou.

## QA Visual

O QA visual passou com o build servido em `127.0.0.1:5174` e emuladores
Auth/Firestore/Storage:

```text
out-dir: %TEMP%\chegaja-m2206-visual-qa
screenshots: 8
```

A primeira tentativa sem emuladores gerou screenshots, mas falhou por
`consoleErrors` porque o build foi feito com `RUN_FIREBASE_EMULATOR_TESTS=true`
e a app tentava ligar a Firebase local sem Auth/Firestore/Storage ativos. A
repeticao com emuladores passou.

QA visual especifico de AdminPanel/PrestadorSettings com dados autenticados fica
limitado se nao houver rota local simples/autenticada para abrir esses estados
diretamente. Nesse caso, a cobertura final usa widget tests focados, build Web,
E2E principal e QA visual da matriz publica/local.

## Observacoes Tecnicas

```text
nao foi criada feature nova;
nao foi criado upload real;
nao foi criado KYC;
nao foram criados badges fortes;
nao foi criado ranking avancado;
nao foi feito deploy;
M2.21 nao foi iniciada.
```

## Decisao Final

M2.20 fechada no escopo atual de categorias sensiveis e comprovativos
profissionais.

Proximo bloco recomendado:

```text
M2.21 - Conta, definicoes e suporte premium
```
