# M2.16.6 - QA Final Discovery Status

Data: 2026-05-29

## Estado

```text
M2.16.6: concluida
M2.16: fechada no escopo atual de pesquisa manual e discovery
M2.15: fechada no escopo atual de avaliacoes e reputacao leve
Bloco F: parcial
Bloco H: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Resultado

A M2.16 foi fechada no escopo atual:

```text
spec e auditoria da pesquisa manual;
modelo seguro de perfil pesquisavel;
normalizacao textual e matcher/score;
UI de pesquisa manual de prestadores;
abertura do PublicProfileScreen;
favoritos na pesquisa;
sugestoes compactas na Home Cliente;
QA final, E2E e documentacao.
```

Nao foram criadas features novas nesta fase de fecho. A unica alteracao tecnica
foi no runner E2E `scripts/e2e/full_ui_dual_role_e2e.js`: o script antigo
clicava em qualquer card com nome de servico e passou a abrir uma sugestao de
prestador introduzida na M2.16.5. O runner agora usa o CTA "Escolher servico" e
volta do perfil publico caso caia nele por engano, mantendo o teste alinhado com
a Home atual.

## Comandos Executados

| Comando | Resultado |
| --- | --- |
| `git status --short` | executado; havia apenas estado sujo pre-existente dos `~$*.pptx` e `.superpowers/` |
| `git diff --check` | passou |
| `npm.cmd run test:scripts` | passou |
| `node --check scripts/e2e/full_ui_dual_role_e2e.js` | passou |
| `flutter test --no-pub test/features/cliente/discovery/provider_search_profile_test.dart test/features/cliente/discovery/provider_search_normalizer_test.dart test/features/cliente/discovery/provider_search_matcher_test.dart` | passou, 15/15 |
| `flutter test --no-pub test/features/cliente/discovery/provider_search_card_test.dart test/features/cliente/discovery/provider_search_screen_test.dart test/features/cliente/widgets/provider_suggestions_section_test.dart` | passou, 29/29 |
| `flutter test --no-pub test/features/cliente/widgets/cliente_home_components_test.dart test/features/cliente/cliente_home_redesign_test.dart` | passou, 9/9 |
| `flutter test --no-pub` | passou, 248/248 |
| `flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release` | passou |
| `$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'; $env:GCLOUD_PROJECT='chegaja-ac88d'; npm.cmd test` em `functions/` | passou, 88/88 |
| `$env:TARGET_URL='http://127.0.0.1:5174'; npm.cmd run e2e:ui:dual` | passou, `FULL MULTI-SCENARIO FLOW OK` |
| `$env:TARGET_URL='http://127.0.0.1:5174'; npm.cmd run e2e:ui:orcamento` | passou, `ORCAMENTO MIN-MAX FLOW OK` |
| `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m2166-visual-qa --wait-ms=12000` | passou, 8 screenshots |

## Observacoes Tecnicas

O comando direto `npm.cmd --prefix functions test` foi tentado e falhou na parte
`Pedido value Functions` porque o Admin SDK tentou usar credenciais padrao sem
`FIRESTORE_EMULATOR_HOST`. Este e um requisito ambiental do teste, ja observado
em fases anteriores. A suite passou quando executada com:

```text
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
GCLOUD_PROJECT=chegaja-ac88d
```

O build Web passou com avisos conhecidos do dry-run WASM em `dart_webrtc`; isto
nao bloqueou o build release JS.

## QA Visual

O browser integrado voltou a falhar por limitacao de runtime antes de ligar a
pagina local. Foi usado fallback com Playwright headless contra:

```text
http://127.0.0.1:5174/?role=cliente
```

Resultado:

```text
title: ChegaJa
console_errors: 0
hasHomeText: true
hasProviderSuggestionsText: true
hasSearchCtaText: true
screenshot: C:\Users\Jamal\AppData\Local\Temp\chegaja-m2166-home-cliente.png
```

A matriz visual tambem gerou 8 screenshots:

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

Diretorio:

```text
C:\Users\Jamal\AppData\Local\Temp\chegaja-m2166-visual-qa
```

## Fora do Escopo Mantido

```text
ranking complexo
patrocinados
pagamentos
KYC
Trust & Safety implementation
moderacao
denuncias
admin/backoffice completo
publicProfiles
providerSearchIndex
handle publico real
link publico
partilha social
alteracao de Firestore Rules
alteracao de Storage Rules
alteracao de Cloud Functions
deploy
Android fisico
tester externo
fechar R
fechar M
fechar R1
fechar M2.6
```

## Decisao Final

A M2.16 fica fechada no escopo atual de pesquisa manual e discovery de
prestadores.

Proximo passo recomendado:

```text
M2.17 - Trust & Safety, servicos proibidos e moderacao basica
```
