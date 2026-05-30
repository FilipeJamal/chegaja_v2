# M2.18.6 - QA Final Admin/backoffice Leve

Data: 2026-05-30

## Estado

M2.18.6 concluida.

```text
M2.18 - FECHADA no escopo atual de Admin/backoffice leve
M2.18.1 - FECHADA
M2.18.2 - FECHADA
M2.18.3 - FECHADA
M2.18.4 - FECHADA
M2.18.5 - FECHADA
M2.18.6 - FECHADA
M2.17 - FECHADA no escopo atual
Bloco F - PARCIAL
Bloco H - PARCIAL
Bloco J - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo

Fechar a M2.18 com testes, E2E, QA visual e documentacao final, sem criar feature
nova.

## Escopo Validado

```text
AdminPanel organizado;
Visao geral melhorada;
filas operacionais melhoradas;
reports/moderacao;
suporte;
no-show;
stories/conteudo;
financeiro/ledger;
auditoria leve/adminAuditLogs;
AdminService;
Cloud Functions admin.
```

## Comandos Executados

```text
git status
git diff --check
npm.cmd run test:scripts
node --check functions/index.js
npm.cmd --prefix functions test
flutter test --no-pub test/features/admin/admin_audit_logs_section_test.dart
flutter test --no-pub test/features/admin/admin_panel_navigation_test.dart
flutter test --no-pub test/features/admin/admin_queue_widgets_test.dart
flutter test --no-pub test/features/admin/admin_reports_section_test.dart
flutter test --no-pub test/features/admin/admin_operational_sections_test.dart
flutter test --no-pub test/features/admin/admin_overview_section_test.dart
flutter test --no-pub test/features/admin/admin_dashboard_metrics_test.dart
flutter test --no-pub
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m2186-visual-qa --wait-ms=12000
```

## Resultados

```text
git diff --check - passou
npm.cmd run test:scripts - passou
node --check functions/index.js - passou
npm.cmd --prefix functions test - passou, 123 passing
testes focados admin - passaram, 29 testes
flutter test --no-pub - passou, 314/314
flutter build web release - passou
e2e:ui:dual - passou, FULL MULTI-SCENARIO FLOW OK
e2e:ui:orcamento - passou, ORCAMENTO MIN-MAX FLOW OK
QA visual - passou, 8 screenshots
```

## Observacoes Tecnicas

Durante o E2E dual, o runner ficou preso no cenario de cancelamento porque
tentava encontrar o pedido por titulo enquanto a app ja estava no ecra
`A encontrar prestador`, onde o cancelamento deveria ocorrer. A correcao foi
limitada ao bloqueador encontrado:

```text
scripts/e2e/full_ui_dual_role_e2e.js
- antes de procurar detalhe por titulo, sai do formulario e reavalia o ecra;
- espera o botao real de confirmacao do dialog de cancelamento;
- reenquadra explicitamente a Home Cliente antes do cenario manual/chat/no-show.

lib/core/services/auth_service.dart
lib/features/cliente/aguardando_prestador_screen.dart
- o cancelamento em espera aguarda brevemente a sessao restaurada;
- se a sessao nao puder ser confirmada, mostra feedback em vez de falhar em silencio.
```

Nao houve alteracao em Firestore Rules, Storage Rules, Cloud Functions ou deploy.

O build Web passou com avisos nao bloqueantes do dry-run Wasm em `dart_webrtc`,
ja existentes no ambiente de build.

## QA Visual Admin

O QA visual geral executou as matrizes Cliente/Prestador e gerou 8 screenshots em:

```text
C:\Users\Jamal\AppData\Local\Temp\chegaja-m2186-visual-qa
```

Nao foi executado QA visual autenticado especifico do AdminPanel porque nao ha
rota/admin auth local simples e segura neste ambiente. A cobertura especifica do
Admin ficou nos widget tests focados, build Web, Functions tests e E2E principal.

## Fora do Escopo Mantido

```text
feature nova
nova callable
nova UI grande
alteracao Firestore Rules
alteracao Storage Rules
deploy
KYC
pagamentos
roles granulares
custom claims novos
export CSV/PDF
paginacao/cursor real
auditoria enterprise
admin enterprise completo
graficos avancados
analytics avancado
Android fisico
tester externo
fechar R
fechar R1
fechar M
fechar M2.6
iniciar M2.19
```

## Decisao Final

M2.18 fica fechada no escopo atual de Admin/backoffice leve.

Proximo bloco recomendado:

```text
M2.19 - Link publico, @handle e partilha social
```
