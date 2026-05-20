# M2.10.6 Visual QA Report

Data: 2026-05-20

## Objetivo

Validar responsividade e qualidade visual da M2.10 antes de fechar a fase,
olhando para a app como produto real em Web/Windows/Android.

## Ambiente local

| Item | Valor |
| --- | --- |
| Build | `flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true` |
| URL local | `http://127.0.0.1:63776` |
| Firebase Emulator Suite | Auth `9099`, Firestore `8080`, Storage `9199` |
| Screenshots matriz | `C:\Users\Jamal\AppData\Local\Temp\chegaja-m2106-visual-qa-final` |
| Screenshots E2E orcamento | `C:\Users\Jamal\AppData\Local\Temp\chegaja-m2106-visual-qa-e2e-after-auth\2026-05-20T03-50-24-762Z` |

## Matriz de screenshots

| Tela | Mobile 390x844 | Tablet 768x1024 | Desktop 1366x768 | Wide 1920x1080 |
| --- | --- | --- | --- | --- |
| Home Cliente | `home_cliente__mobile.png` | `home_cliente__tablet.png` | `home_cliente__desktop.png` | `home_cliente__wide.png` |
| Home Prestador | `home_prestador__mobile.png` | `home_prestador__tablet.png` | `home_prestador__desktop.png` | `home_prestador__wide.png` |
| Lista Cliente | Coberta parcialmente pelo fluxo E2E `e2e:ui:orcamento` | Nao capturada em tablet nesta rodada | Coberta pelo fluxo E2E `e2e:ui:orcamento` | Nao capturada em wide nesta rodada |
| Pedidos Prestador | Coberta pela Home Prestador e pelo fluxo E2E | Nao capturada em tablet nesta rodada | Coberta pelo fluxo E2E `e2e:ui:orcamento` | Coberta pela Home Prestador wide |
| Detalhe Cliente | Nao capturado em mobile nesta rodada | Nao capturado em tablet nesta rodada | `15_orcamento_client_confirmed.png` | Nao capturado em wide nesta rodada |
| Detalhe Prestador | Nao capturado em mobile nesta rodada | Nao capturado em tablet nesta rodada | `11_orcamento_provider_quote_sent.png`, `14_orcamento_provider_final_sent.png` | Nao capturado em wide nesta rodada |

## Problemas encontrados

| Severidade | Tela | Viewport | Problema | Decisao |
| --- | --- | --- | --- | --- |
| Bloqueador visual | Shell local em modo emulador | Mobile 390x844 | O banner vermelho do Firebase Auth Emulator tapava bottom navigation e podia esconder acoes. | Corrigido em `web/index.html` com badge compacto local-only no topo direito. |
| Regressao pequena de QA | Prestador, aba Meus trabalhos | Desktop E2E | No E2E de orcamento, a aba ficava presa em `A preparar sessao...` quando `currentUser` ainda vinha nulo no primeiro build. | Corrigido no widget da aba, aguardando `ensureSignedInAnonymously()` e forçando rebuild quando a sessao fica pronta. |
| Ajuste medio | Home Prestador | Desktop/wide sem pedidos | O estado vazio ainda deixa bastante area livre quando nao ha pedidos. | Aceitavel nesta fase porque nao bloqueia acao nem overflow; manter como melhoria futura com dados reais/metricas. |
| Aceitavel futuro | Detalhe/listas | Mobile/tablet/wide | E2E visual detalhado cobriu desktop; mobile/tablet/wide de detalhe ficam para QA visual seguinte com fixture dedicada. | Documentado; nao bloquear M2.10.6 porque widget/layout e desktop E2E passaram. |

## Correcoes aplicadas

| Ficheiro | Correcao | Evidencia |
| --- | --- | --- |
| `scripts/qa/capture_visual_matrix.js` | Harness Playwright read-only para capturar Home Cliente e Home Prestador em mobile/tablet/desktop/wide. | `npm.cmd run qa:visual:m2-10-6` gerou 8 screenshots finais. |
| `scripts/test/capture_visual_matrix.test.js` | Testes do parser/plano do harness e verificacao do normalizador local do banner. | `npm.cmd run test:scripts` passou. |
| `web/index.html` | Normalizador local-only do aviso Firebase Emulator para badge compacto `Emulador Firebase ativo`. | Screenshots mobile finais mostram bottom navigation e CTAs livres. |
| `lib/features/prestador/prestador_home_screen.dart` | Aba `Meus trabalhos` passou a aguardar a autenticacao anonima antes de ficar presa em loading. | `npm.cmd run e2e:ui:orcamento` passou apos a correcao. |

## Evidencia E2E local

Comando executado contra build Web local e emuladores:

```powershell
$env:TARGET_URL='http://127.0.0.1:63776'
$env:SHOT_DIR=Join-Path $env:TEMP 'chegaja-m2106-visual-qa-e2e-after-auth'
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
$env:FIREBASE_STORAGE_EMULATOR_HOST='127.0.0.1:9199'
npm.cmd run e2e:ui:orcamento
```

Resultado:

```text
ORCAMENTO MIN-MAX FLOW OK
pedido concluido
precoFinal=30
commissionPlatform=4.5
```

Screenshots gerados:

```text
01_client_home.png
01_provider_home.png
10_orcamento_client_order_created.png
11_orcamento_provider_quote_sent.png
12_orcamento_client_accept_provider.png
13_orcamento_provider_started.png
14_orcamento_provider_final_sent.png
15_orcamento_client_confirmed.png
```

## Validacoes finais

| Comando | Resultado |
| --- | --- |
| `flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true` | Passou; avisos Wasm dry run de `dart_webrtc` documentados, sem bloquear build Web standard. |
| `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:63776 --out-dir=%TEMP%\chegaja-m2106-visual-qa-final --wait-ms=12000` | Passou; 8 screenshots finais gerados. |
| `npm.cmd run e2e:ui:orcamento` | Passou contra emuladores locais. |
| `flutter test` | Passou, 102/102 |
| `npm.cmd run test:scripts` | Passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | Passou, 37/37 |
