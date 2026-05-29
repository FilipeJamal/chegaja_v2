# M2.15.5 - QA Final de Avaliacoes e Reputacao Leve

Data: 2026-05-29

## Estado

```text
M2.15.5: concluida
M2.15: fechada no escopo atual de avaliacoes e reputacao leve
Bloco H: parcial
Bloco F: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Decisao Final

A M2.15 fica fechada no escopo atual:

```text
Cliente pode avaliar o prestador depois de pedido concluido.
Rules impedem avaliacao indevida e escrita direta de agregados.
Cloud Function atualiza ratingCount/ratingSum/ratingAvg de forma autoritativa.
A UI de avaliacao pos-servico foi validada.
O perfil publico mostra reputacao leve apenas com ratingAvg/ratingCount validos.
Comentarios publicos, reviews completas, ranking e moderacao continuam fora.
```

O Bloco H nao fica fechado por completo, porque ainda faltam reviews publicas
completas, comentarios publicos moderados, denuncias, moderacao e reputacao
avancada.

## Comandos Executados

```text
git diff --check
npm.cmd run test:scripts
flutter test --no-pub test/features/cliente/widgets/avaliacao_pedido_card_test.dart
flutter test --no-pub test/features/common/perfil_publico_screen_test.dart
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'; $env:GCLOUD_PROJECT='chegaja-ac88d'; npm.cmd test
flutter test --no-pub
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m2155-visual-qa --wait-ms=12000
```

## Resultados

```text
git diff --check: passou
npm.cmd run test:scripts: passou
avaliacao_pedido_card_test.dart: passou
perfil_publico_screen_test.dart: passou
functions npm test: 88 passing
flutter test --no-pub: 203/203 passou
build Web release: passou
e2e:ui:dual: FULL MULTI-SCENARIO FLOW OK
e2e:ui:orcamento: ORCAMENTO MIN-MAX FLOW OK
QA visual: 8 screenshots gerados
```

Nota tecnica: a primeira execucao de `npm.cmd test` em `functions/` falhou no
hook de `pedidoFunctions.test.js` por falta de credenciais padrao do Admin SDK.
A suite passou quando executada com `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080` e
`GCLOUD_PROJECT=chegaja-ac88d`, que e o contexto local correto para estes
testes.

## QA Visual

A matriz visual foi executada contra o build Web estatico em
`http://127.0.0.1:5174`.

Screenshots gerados em:

```text
C:\Users\Jamal\AppData\Local\Temp\chegaja-m2155-visual-qa
```

Cobertura do script:

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

Limitacao documentada: este script cobre Home Cliente e Home Prestador. A
validacao direta de card de avaliacao e reputacao no perfil publico ficou
coberta por testes focados e E2E principais, nao por screenshot dedicado nesta
fase.

## Fora do Escopo Mantido

```text
comentarios publicos
reviews publicas completas
moderacao
denuncias
ranking
pesquisa estilo Instagram
Trust & Safety implementation
admin/backoffice
KYC
pagamentos reais
alteracao de Firestore Rules nesta fase
alteracao de Storage Rules
alteracao de Cloud Functions nesta fase
deploy
Android fisico
tester externo
fechar R
fechar R1
fechar M
fechar M2.6
```

## Proximo Passo Recomendado

```text
M2.16 - Pesquisa manual e descoberta de prestadores estilo Instagram
```

