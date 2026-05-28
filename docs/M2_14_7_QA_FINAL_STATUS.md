# M2.14.7 - QA Final Perfil, Portfolio e Confianca

Data: 2026-05-28

## Estado

```text
M2.14.7: concluida
M2.14: fechada no escopo atual de perfil, portfolio e confianca leve
Bloco F: parcial
Bloco R: pausado por falta de tester humano real
Bloco M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Decisao

A M2.14 fica fechada no escopo de:

```text
perfil publico do prestador
gestao do portfolio pelo prestador
badges leves de confianca sem KYC
integracao do perfil publico no detalhe do pedido Cliente
testes e QA final do bloco
```

O Bloco F continua parcial porque ainda faltam KYC real, verificacao
documental, reviews/reputacao publica completa, moderacao e perfil publico
premium total.

## Validacoes Executadas

| Comando | Resultado |
| --- | --- |
| `git status --short` | Passou; apenas pendencias antigas nao versionadas/deletadas fora do escopo: `.superpowers/` e ficheiros temporarios `~$...pptx`. |
| `flutter test --no-pub test/features/common/perfil_publico_screen_test.dart` | Passou: 9/9. |
| `flutter test --no-pub test/features/prestador/prestador_perfil_portfolio_test.dart` | Passou: 6/6. |
| `flutter test --no-pub test/features/cliente/widgets/pedido_provider_profile_action_test.dart` | Passou: 4/4. |
| `npm.cmd run test:scripts` | Passou. |
| `flutter test --no-pub` | Passou: 183/183. |
| `flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release` | Passou. |
| `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual` | Passou: `FULL MULTI-SCENARIO FLOW OK`. |
| `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento` | Passou: `ORCAMENTO MIN-MAX FLOW OK`. |
| `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\\chegaja-m2147-visual-qa --wait-ms=12000` | Passou; gerou matriz visual base Cliente/Prestador. |

Observacao da build Web:

```text
A build release passou. O Flutter reportou apenas avisos de Wasm dry-run em
dart_webrtc 1.7.0. Esses avisos nao bloquearam o build JS gerado em
build/web_manual_release.
```

## Evidencia E2E

```text
e2e:ui:dual
Target: http://127.0.0.1:5174
Resultado: FULL MULTI-SCENARIO FLOW OK
Screenshots:
C:\Users\Jamal\AppData\Local\Temp\chegaja-e2e-full-ui\2026-05-28T14-22-06-799Z

e2e:ui:orcamento
Target: http://127.0.0.1:5174
Resultado: ORCAMENTO MIN-MAX FLOW OK
Screenshots:
C:\Users\Jamal\AppData\Local\Temp\chegaja-e2e-full-ui\2026-05-28T14-30-56-085Z
```

## QA Visual

QA visual local registado:

```text
C:\Users\Jamal\AppData\Local\Temp\chegaja-m2147-visual-qa
```

Ficheiros gerados:

```text
home_cliente__mobile.png
home_cliente__tablet.png
home_cliente__desktop.png
home_cliente__wide.png
home_prestador__mobile.png
home_prestador__tablet.png
home_prestador__desktop.png
home_prestador__wide.png
```

Cobertura M2.14 por testes dedicados:

```text
Perfil publico com portfolio
Perfil publico sem portfolio
Perfil publico em dark mode
Badges leves permitidos
Ausencia de badges proibidos
Imagem quebrada no portfolio sem quebrar a tela
Abertura de foto/avatar e portfolio por MediaViewerScreen
Gestao de portfolio vazia e com imagens
Dialogo de confirmacao antes de remover imagem
Bloqueio de upload enquanto carregamento esta ativo
Detalhe do pedido Cliente com acao Ver perfil quando ha prestadorId
Ausencia de Ver perfil quando nao ha prestador associado
```

Nota: nao foi criada rota/debug fixture nova apenas para screenshots diretas do
perfil publico. A M2.14.7 e uma fase de fecho; a validacao visual especifica do
perfil ficou coberta por widget tests dedicados, E2E dos fluxos principais e
matriz visual base do app.

## Fora do Escopo Mantido

```text
KYC real
verificacao documental
pagamentos reais
reviews completas
moderacao
denuncias
rankings
alteracao de Firestore Rules
alteracao de Storage Rules
alteracao de Cloud Functions
deploy
Android fisico
tester externo
fechar R
fechar R1
fechar M
fechar M2.6
Play Store
```

## Riscos Remanescentes

```text
Bloco F ainda nao tem KYC/verificacao oficial.
Reviews e reputacao publica continuam futuras.
Disponibilidade real e servicos concluidos continuam fora dos badges.
Android fisico ainda precisa de validacao real.
Beta externa continua dependente de tester humano.
```

## Proximo Passo Recomendado

Nao iniciar automaticamente nova feature neste commit. Proximas opcoes:

```text
M2.15 - Avaliacoes e reputacao leve pos-servico
J/Admin - backoffice leve para gestao interna
D/Mapa - melhorar localizacao, raio e ETA
R - retomar quando houver tester humano real
M - retomar quando houver Android fisico real
```
