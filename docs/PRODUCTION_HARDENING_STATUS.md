# Production Hardening Status - M2.7

Data: 2026-05-18

## Estado

M2.7 esta fechada. A fase endureceu a base de producao enquanto M2.6 continua
bloqueada por falta de Android fisico.

Estado oficial:

```text
M0: fechado
M2.5: parcial
M2.6: avancado tecnicamente, pendente de Android fisico
M2.7: fechado
M2.7.1: avancado em estados, pedidos e valores
M2.7.2: avancado em Functions autoritativas para valores
M2.7.3: avancado em testes Android com Functions Emulator
M2.7.4: avancado com deploy controlado Firebase e smoke real
M2.7.5: avancado com runtime Functions Node.js 22 e fecho tecnico
M2.8: iniciado em operacoes de producao, limpeza e observabilidade
M2.8.1: avancado em cleanup auditavel e validacao controlada
M2.8.2: avancado em health check de producao sem criar dados
M2.8.3: avancado em CI de validacao sem deploy
M2.8.4: em validacao remota do CI
```

## Alteracoes aplicadas

| Area | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- |
| Storage Rules | endurecido | `functions/test/storage.test.js` | O bucket deixou de ser publico. |
| Anexos de pedidos | endurecido | participantes podem ler/enviar; nao participantes sao negados | Caminho permitido: `pedidos/{pedidoId}/anexos/{file}`. |
| Anexos temporarios | endurecido | `temp/{uid}/anexos/{file}` | O upload antes de criar pedido deixou de usar pasta global `temp/anexos_*`. |
| Chat media | endurecido | participantes do pedido podem usar `chats/{pedidoId}/images|files` | Tipos e tamanho maximo validados por regras. |
| KYC | endurecido | owner/admin podem ler; terceiros negados | Caminho `kyc/{prestadorId}/{file}` nao fica publico. |
| Perfis/portfolio/stories | limitado | owner escreve; leitura publica apenas onde esperado | Imagens limitadas por tipo e tamanho. |
| Firestore pedidos | endurecido | teste bloqueia aceitar pedido para outro prestador | Prestador compativel so pode aceitar pedido aberto para o proprio UID. |
| Firestore estados de pedidos | endurecido M2.7.1 | `functions/test/firestore.test.js` | Regras espelham a state machine principal e bloqueiam reabrir pedidos finais. |
| Firestore valores de pedidos | endurecido M2.7.1 | `functions/test/firestore.test.js` | Preco final/comissao/ganhos so passam no fluxo de confirmacao com divisao esperada. |
| Functions de valores | avancado M2.7.2 | `functions/test/pedidoFunctions.test.js` | Prestador propoe valor final e cliente confirma por Cloud Functions/Admin SDK. |
| Android com Functions Emulator | avancado M2.7.3 | `integration_test/android_functions_flow_test.dart` | Fluxo Android valida proposta/confirmacao por callable no emulador. |
| Deploy Firebase real | avancado M2.7.4 | `docs/FIREBASE_DEPLOYMENT_STATUS.md` | Firestore Rules, Storage Rules e Functions publicados em `chegaja-ac88d`. |
| Smoke Firebase real | avancado M2.7.4 | `npm.cmd run smoke:firebase:production` | Fluxo pedido + Functions + Storage validado contra producao. |
| Runtime Functions | avancado M2.7.5 | `npx.cmd firebase functions:list --project chegaja-ac88d --json` | 27/27 Functions em `nodejs22`. |
| Dependencias Functions | avancado M2.7.5 | `functions/package.json` | `firebase-functions ^7.2.5` e `firebase-admin ^13.10.0`. |
| Fecho M2.7 | fechado | `docs/PRODUCTION_HARDENING_STATUS.md` | M2.7 fechada sem fechar M2.6. |
| Runbook producao | iniciado M2.8 | `docs/PRODUCTION_RUNBOOK.md` | Operacoes de deploy, smoke, cleanup, logs e troubleshooting. |
| Cleanup smoke | iniciado M2.8 | `scripts/admin/cleanup_smoke_data.js` | Dry-run por defeito, prefixo obrigatorio e delete so com `--confirm`. |
| Cleanup auditavel | avancado M2.8.1 | `scripts/test/cleanup_smoke_data.test.js` | `--verbose`, `--json` e `--confirm-prefix` cobertos por teste. |
| Health check producao | avancado M2.8.2 | `scripts/health/firebase_production_health.js` | Verifica Firebase CLI, projeto, Functions nodejs22 e audit sem escrever dados. |
| CI sem deploy | avancado M2.8.3 | `.github/workflows/ci.yml` | Roda scripts, Firebase Emulator Suite e Flutter tests sem tocar em producao. |
| CI remoto | em validacao M2.8.4 | GitHub Actions run `26020214617` | Falha inicial por Java 17; workflow atualizado para Java 21 exigido pelo Firebase Emulator Suite. |
| Smoke cleanup opcional | iniciado M2.8 | `scripts/smoke/firebase_production_smoke.js` | `--keep-evidence` mantem comportamento; `--cleanup` e opt-in. |
| Logs Functions pedidos | iniciado M2.8 | `functions/index.js` | Logs estruturados com UID mascarado e status anterior/novo. |
| Marcador backend autoritativo | endurecido M2.7.2 | `functions/test/firestore.test.js` | Cliente/prestador nao conseguem falsificar `lastAuthoritativeFunction`. |
| Auth bootstrap mobile | endurecido M2.7.1 | `npm.cmd run test:android:mvp` | Retry curto para primeira leitura/escrita Firestore apos login anonimo. |
| FCM tokens | coberto por teste | teste nega escrita em token de outro utilizador | Mantem `users/{uid}/fcmTokens/{token}` owner/admin. |
| Upload de anexos no app | ajustado | `StoragePathPolicy` | Sanitiza nomes, define MIME e bloqueia tipos nao suportados. |

## Regras Storage

Antes da M2.7, `storage.rules` tinha:

```text
allow read, write: if true;
```

Agora os acessos sao segmentados:

```text
pedidos/{pedidoId}/anexos/{file}
temp/{uid}/anexos/{file}
chats/{pedidoId}/images/{file}
chats/{pedidoId}/files/{file}
users/{uid}/{file}
prestadores/{uid}/{file}
prestadores/{uid}/portfolio/{file}
portfolio/{uid}/{file}
kyc/{uid}/{file}
stories/{uid}/{file}
```

Os uploads validam:

- utilizador autenticado quando aplicavel;
- owner/participante/admin conforme o caminho;
- tamanho maximo;
- `contentType` permitido.

Tipos permitidos para anexos:

```text
image/*
application/pdf
text/plain
```

## Regras Firestore

Foi adicionada validacao para a transicao de `prestadorId` em pedidos:

- pedido aberto com `prestadorId == null` pode continuar sem prestador;
- prestador compativel pode aceitar apenas se o novo `prestadorId` for o proprio UID;
- pedido ja atribuido nao pode trocar `prestadorId` por outro UID via cliente.
- cliente pode convidar manualmente um prestador a partir de `criado` para
  `aguarda_resposta_prestador`;
- cliente/prestador podem limpar `prestadorId` apenas nos fluxos previstos de
  rejeicao/desistencia para `criado`.

Isto reduz o risco de um prestador manipular um pedido aberto para atribui-lo a
outra conta.

M2.7.1 adicionou uma camada especifica para estados e valores:

- `status` e `estado`, quando ambos existem, devem ter o mesmo valor;
- transicoes finais de `concluido` e `cancelado` nao podem voltar para estados
  operacionais;
- cliente nao consegue alterar `earningsProvider`/ganhos do prestador;
- prestador nao consegue escrever diretamente `precoFinal`, comissao ou ganhos;
- confirmacao final so passa de `aguarda_confirmacao_valor` para `concluido`
  quando `precoFinal` bate com `precoPropostoPrestador` e a divisao 15%/85%
  esta consistente.

M2.7.2 adicionou o caminho backend autoritativo para valores finais:

- `proporValorFinalPedido` exige auth, confirma que o UID e o prestador do
  pedido, exige estado `em_andamento` e grava a proposta final via Admin SDK;
- `confirmarValorFinalPedido` exige auth, confirma que o UID e o cliente do
  pedido, exige `aguarda_confirmacao_valor` + `pendente_cliente`, calcula
  `precoFinal`, `preco`, `commissionPlatform`, `earningsProvider` e
  `earningsTotal` no backend e conclui o pedido;
- a app Flutter usa esse caminho nas instancias reais de `PedidoService`;
- testes com Firestore injetado continuam a usar o caminho direto validado
  pelas regras para preservar os fluxos de emulador sem Functions;
- `RUN_FIREBASE_EMULATOR_TESTS=true` mantem `PedidoService.instance` no caminho
  direto porque os scripts Android sobem Auth/Firestore/Storage, nao Functions;
- `lastAuthoritativeFunction` e escrito apenas pelo Admin SDK e nao pode ser
  falsificado por cliente/prestador nas regras Firestore.

M2.7.3 adicionou prova Android/emulador para esse caminho:

- `scripts/run_android_integration_test.js` aceita `--functions-emulator`;
- `npm.cmd run test:android:functions` executa
  `integration_test/android_functions_flow_test.dart`;
- o comando sobe Auth, Firestore, Storage e Functions Emulator;
- o app recebe `RUN_FIREBASE_EMULATOR_TESTS=true` e
  `RUN_FIREBASE_FUNCTIONS_EMULATOR_TESTS=true`;
- com a flag de Functions ativa, `PedidoService` chama as callables mesmo em
  ambiente de emulador;
- o teste valida `lastAuthoritativeFunction = proporValorFinalPedido` depois
  da proposta e `lastAuthoritativeFunction = confirmarValorFinalPedido` depois
  da conclusao.

M2.7.4 publicou esse hardening no Firebase real:

- `firestore.rules` foi publicado em `chegaja-ac88d`;
- `storage.rules` foi publicado em `chegaja-ac88d`;
- as Cloud Functions foram publicadas em `europe-west1`;
- `proporValorFinalPedido` e `confirmarValorFinalPedido` foram criadas no
  ambiente real;
- o service account do Firebase Storage recebeu
  `roles/firebaserules.firestoreServiceAgent` para permitir que Storage Rules
  avaliem participantes do pedido via Firestore;
- `npm.cmd run smoke:firebase:production` validou Auth, Firestore, Functions,
  Storage, split 15%/85% e bloqueios 403 em producao.

M2.7.5 migrou as Functions para runtime suportado:

- `functions/package.json` mudou `engines.node` de `20` para `22`;
- `firebase-functions` foi atualizado de `^5.0.1` para `^7.2.5`;
- `firebase-admin` foi atualizado de `^12.7.0` para `^13.10.0`;
- CommonJS foi mantido, sem migracao para ESM;
- `npx.cmd firebase deploy --only functions --project chegaja-ac88d`
  atualizou as Functions em Node.js 22 (2nd Gen);
- `npx.cmd firebase functions:list --project chegaja-ac88d --json` confirmou
  `FUNCTION_COUNT=27` e `RUNTIMES=nodejs22=27`;
- `npm.cmd run smoke:firebase:production` passou apos o deploy.

O mapa de estados e campos protegidos esta documentado em:

```text
docs/PEDIDO_STATE_MACHINE.md
docs/FUNCTIONS_PEDIDOS.md
docs/ANDROID_FUNCTIONS_EMULATOR_TESTS.md
docs/FIREBASE_DEPLOYMENT_STATUS.md
```

## Testes adicionados

```text
functions/test/storage.test.js
functions/test/firestore.test.js
functions/test/pedidoFunctions.test.js
integration_test/android_functions_flow_test.dart
test/core/storage_path_policy_test.dart
test/core/pedido_service_test.dart
scripts/test/run_android_integration_test.test.js
scripts/smoke/firebase_production_smoke.js
scripts/admin/cleanup_smoke_data.js
scripts/test/cleanup_smoke_data.test.js
scripts/health/firebase_production_health.js
scripts/test/firebase_production_health.test.js
.github/workflows/ci.yml
```

Cobertura nova:

- upload anonimo para caminho aleatorio e negado;
- participante consegue enviar/ler anexo de pedido;
- nao participante nao consegue enviar/ler anexo de pedido;
- tipo e tamanho de anexo sao validados;
- pasta temporaria exige UID autenticado;
- KYC nao e publico para outros utilizadores;
- caminhos e MIME de anexos sao normalizados no app.
- convite manual de cliente para prestador continua permitido;
- cliente nao consegue manipular ganhos do prestador;
- prestador nao consegue manipular preco final/comissao;
- pedidos `concluido` e `cancelado` nao reabrem;
- prestador consegue iniciar servico, enviar faixa de orcamento e propor valor
  final pelos ramos curtos das regras;
- cliente consegue aceitar proposta de orcamento pelo ramo curto das regras;
- confirmacao final com comissao adulterada e negada;
- confirmacao final correta continua permitida.
- prestador atribuido consegue propor valor final pela Function;
- outro prestador nao consegue propor valor final pela Function;
- cliente correto consegue confirmar valor final pela Function;
- a Function calcula 15%/85% e ignora campos economicos adulterados enviados
  pelo cliente;
- nao cliente nao consegue confirmar valor final pela Function;
- pedido fora de `aguarda_confirmacao_valor` nao conclui pela Function;
- cliente nao consegue falsificar `lastAuthoritativeFunction`.
- runner Android injeta `RUN_FIREBASE_FUNCTIONS_EMULATOR_TESTS=true` quando
  chamado com `--functions-emulator`;
- Android em emulador chama `proporValorFinalPedido` e
  `confirmarValorFinalPedido` via Functions Emulator.
- smoke real cria pedido, aceita, inicia, propoe valor final, confirma por
  Functions reais e valida `lastAuthoritativeFunction`;
- smoke real confirma `commissionPlatform = 15%` e `earningsProvider = 85%`;
- smoke real confirma upload permitido em `temp/{uid}/anexos`;
- smoke real confirma upload permitido em `pedidos/{pedidoId}/anexos` para
  participante e negado para outsider.
- cleanup de smoke exige prefixo explicito, faz dry-run por defeito e bloqueia
  delete sem `--confirm`;
- smoke de producao aceita `--keep-evidence` e `--cleanup` sem alterar o modo
  padrao de manter evidencia;
- logs de `proporValorFinalPedido` e `confirmarValorFinalPedido` usam UID
  mascarado e campos estruturados.
- health check de producao valida CLI/projeto/Functions/audit sem criar dados.
- CI sem deploy valida scripts, regras/Functions em emulador e Flutter tests em
  push/PR para `main`.

## M2.8 - Operacoes de producao

M2.8 foi iniciada depois do fecho da M2.7 para melhorar manutencao segura em
producao, sem adicionar funcionalidades grandes.

Entrou nesta primeira etapa:

- `docs/PRODUCTION_RUNBOOK.md` com login Firebase, pre-checks, deploy separado,
  smoke real, cleanup, functions:list, logs e troubleshooting;
- `scripts/admin/cleanup_smoke_data.js` para limpeza admin de dados de smoke;
- scripts npm `admin:cleanup:smoke:dry` e `admin:cleanup:smoke`;
- `npm.cmd run smoke:firebase:production -- --keep-evidence`;
- `npm.cmd run smoke:firebase:production -- --cleanup`;
- campos `smokeRunId` e `smokePrefix` no smoke para permitir cleanup futuro;
- logs estruturados e com UIDs mascarados nas Functions autoritativas de
  valores.

Nao houve deploy real nesta etapa da M2.8.

M2.8.1 reforcou o cleanup antes de qualquer uso destrutivo:

- `--verbose` lista cada Firestore doc, Storage file e Auth uid;
- `--json` gera o plano completo em formato parseavel;
- `--confirm` agora exige `--confirm-prefix=<prefixo>` igual ao `--prefix`;
- `admin:cleanup:smoke:dry` passou a usar `--verbose`;
- foi adicionado `admin:cleanup:smoke:json`;
- o smoke `--cleanup` passa `confirmPrefix` internamente com o `runId`;
- testes cobrem prefixo obrigatorio, prefixo curto, prefixo com path/pattern,
  argumento desconhecido, dry-run sem delete, JSON/verbose e confirm-prefix.

Nao foi executado cleanup real com `--confirm` nesta etapa.

M2.8.2 adicionou um health check read-only para producao:

- `npm.cmd run health:firebase:production`;
- valida `firebase login:list`;
- valida projeto ativo `chegaja-ac88d`;
- valida `functions:list --json`;
- exige 27 Functions em `nodejs22`;
- executa `npm audit --omit=dev --json` em `functions`;
- falha se houver vulnerabilidade critical/high/moderate;
- aceita lows como divida documentada;
- nao cria pedidos, nao faz upload e nao apaga dados.

M2.8.3 adicionou CI de validacao sem deploy:

- workflow `.github/workflows/ci.yml`;
- dispara em `push` e `pull_request` para `main`;
- configura Node.js 22, Java 21 e Flutter stable;
- usa `npm ci`, `cd functions && npm ci` e `flutter pub get`;
- roda `npm run test:scripts`;
- roda `npx firebase emulators:exec --only firestore,storage,functions "cd functions && npm test"`;
- roda `flutter test --no-pub`;
- nao faz deploy, smoke real, health real, cleanup real nem Android emulator.

M2.8.4 iniciou a validacao remota do CI:

- run GitHub Actions `26020214617` executou o workflow `CI sem deploy` no commit
  `19512aac9958604f7073f8e4d974f4b33c7edbc1`;
- a falha ocorreu no passo Firebase Emulator Suite porque `firebase-tools`
  exige Java 21 ou superior;
- o workflow foi ajustado de Java 17 para Java 21, mantendo CI sem deploy e sem
  credenciais de producao.

## Hardening de bootstrap Auth/Firestore

Durante os testes Android em emulador, o primeiro acesso Firestore apos
`signInAnonymously` pode devolver `cloud_firestore/unavailable` enquanto o
emulador ainda estabiliza a ligacao. M2.7.1 adicionou retry curto apenas para a
leitura/escrita inicial de `users/{uid}` no `AuthService`.

Isto nao altera permissoes nem identidade do utilizador; apenas evita falha
transitoria no arranque local/mobile.

## Riscos restantes

| Risco | Estado | Proxima acao |
| --- | --- | --- |
| Push real Android | pendente M2.6 | Validar em telemovel fisico. |
| Picker/upload real Android | pendente M2.6 | Validar em telemovel fisico com Storage real/emulado. |
| Permissoes nativas negadas | pendente M2.6 | Validar notificacoes, galeria e camera negadas. |
| Campos economicos em `pedidos` | fechado M2.7 | Functions autoritativas, testes de regras, Android Functions Emulator e smoke real passaram. |
| Deploy real Firebase | fechado M2.7 | Firestore Rules, Storage Rules e Functions publicados; smoke real passou. |
| Node.js 20 Functions | resolvido M2.7.5 | Runtime migrado para Node.js 22 e 27/27 Functions confirmadas em `nodejs22`. |
| `firebase-functions` desatualizado | resolvido M2.7.5 | Atualizado para `^7.2.5`; smoke real passou. |
| Audit prod Functions | divida futura, nao bloqueante | `npm audit --omit=dev` sem critico/alto/moderado; restam 9 lows que exigem `--force` com downgrade/breaking change. |
| Package id final | futuro, nao bloqueante para M2.7 | Definir antes de Play Store/Firebase Android final. |
| HTTPS App Links | futuro, nao bloqueante para M2.7 | Publicar `assetlinks.json` nos dominios reais. |
| Play Store | futuro, nao bloqueante para M2.7 | Preparar depois de Android fisico e package id final. |
| Limpeza de dados de smoke antigos | iniciado M2.8 | Script admin criado; executar primeiro em dry-run antes de qualquer delete real. |
| Plano de cleanup visivel | avancado M2.8.1 | Dry-run verbose/json lista docs, files e uids antes de qualquer delete. |
| Health check sem escrita | avancado M2.8.2 | `health:firebase:production` valida producao sem criar dados reais. |
| CI automatico sem deploy | avancado M2.8.3 | Workflow valida push/PR sem credenciais de producao. |
| CI remoto | em validacao M2.8.4 | Falha inicial por Java 17 corrigida para Java 21. |
| Observabilidade Functions | iniciado M2.8 | Logs estruturados adicionados para proposta/confirmacao de valor. |

## Comandos de validacao M2.7

Usar Firestore e Storage em conjunto para os testes de regras:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage "cd functions && npm.cmd test"
flutter test
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"
npx.cmd firebase emulators:exec --only auth,firestore,storage,functions "npm.cmd run test:android:functions"
flutter build apk --release
flutter build appbundle --release
```

Ultima bateria M2.7.3:

| Comando | Resultado |
| --- | --- |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
| `flutter test` | passou, 49/49 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"` | passou, 5/5 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"` | passou, 4/4 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage,functions "npm.cmd run test:android:functions"` | passou, 1/1 |
| `flutter build apk --release` | passou, `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build appbundle --release` | passou, `build/app/outputs/bundle/release/app-release.aab` |

Validacao M2.7.4:

| Comando | Resultado |
| --- | --- |
| `npx.cmd firebase login:list` | passou, conta `bentojamalfilipe@gmail.com` |
| `npx.cmd firebase use` | passou, projeto `chegaja-ac88d` |
| `npx.cmd firebase deploy --only firestore:rules --project chegaja-ac88d` | passou |
| `npx.cmd firebase deploy --only storage --project chegaja-ac88d` | passou |
| `npx.cmd firebase deploy --only functions --project chegaja-ac88d` | passou |
| IAM `roles/firebaserules.firestoreServiceAgent` para Firebase Storage service account | aplicado |
| `npm.cmd run smoke:firebase:production` | passou |

Validacao M2.7.5:

| Comando | Resultado |
| --- | --- |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
| `flutter test` | passou, 49/49 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"` | passou, 5/5 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"` | passou, 4/4 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage,functions "npm.cmd run test:android:functions"` | passou, 1/1 |
| `flutter build apk --release` | passou, `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build appbundle --release` | passou, `build/app/outputs/bundle/release/app-release.aab` |
| `npx.cmd firebase deploy --only functions --project chegaja-ac88d` | passou, Node.js 22 (2nd Gen) |
| `npx.cmd firebase functions:list --project chegaja-ac88d --json` | passou, 27/27 em `nodejs22` |
| `npm.cmd run smoke:firebase:production` | passou |
| `npm.cmd audit --omit=dev --json` | sem critico/alto/moderado; 9 lows restantes |

Validacao inicial M2.8:

| Comando | Resultado |
| --- | --- |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
| `flutter test` | passou, 49/49 |

Observacao: smoke real de producao nao foi repetido nesta etapa para evitar
criar dados reais sem necessidade. O modo `--cleanup` ficou preparado, mas deve
ser usado apenas quando houver credencial Admin SDK local segura e intencao
explicita de apagar dados de teste.

Validacao M2.8.1:

| Comando | Resultado |
| --- | --- |
| `node scripts/test/cleanup_smoke_data.test.js` | passou |
| `npm.cmd run test:scripts` | passou |

Validacao M2.8.2:

| Comando | Resultado |
| --- | --- |
| `node scripts/test/firebase_production_health.test.js` | passou |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
| `flutter test` | passou, 49/49 |
| `npm.cmd run health:firebase:production` | passou, read-only, 27 Functions em `nodejs22`, audit sem critical/high/moderate |

Validacao M2.8.3:

| Comando | Resultado |
| --- | --- |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
| `flutter test` | passou, 49/49 |

Validacao M2.8.4:

| Comando/evidencia | Resultado |
| --- | --- |
| GitHub Actions run `26020214617` para commit `19512aac9958604f7073f8e4d974f4b33c7edbc1` | falhou no Firebase Emulator Suite por Java 17 |
| Ajuste `.github/workflows/ci.yml` | Java atualizado para 21, sem adicionar deploy/smoke/health/cleanup/Android emulator |

## Decisao

M2.7 fica fechada em 2026-05-18.

Motivo do fecho:

- Storage deixou de ser publico e passou a ser protegido por caminhos, owner,
  participante/admin, tipo e tamanho;
- Firestore Rules passaram a bloquear manipulacoes perigosas de pedidos,
  estados, prestador e valores;
- valores finais, comissao e ganhos passaram para Functions autoritativas;
- Android/emulador passou a validar o caminho `PedidoService -> Cloud Functions
  callable -> Admin SDK -> Firestore`;
- Firestore Rules, Storage Rules e Functions foram publicados em
  `chegaja-ac88d`;
- smoke real de producao validou o fluxo pedido + Functions + Storage;
- runtime Functions foi migrado para Node.js 22 e 27/27 Functions ficaram em
  `nodejs22`;
- `firebase-functions` e `firebase-admin` foram atualizados sem trocar o projeto
  para ESM.

M2.7 nao fecha M2.6. A validacao em Android fisico continua pendente para push
real, upload nativo real de anexos e permissoes nativas negadas.

As dividas restantes nao bloqueiam o fecho da M2.7: 9 lows no audit de
dependencias de producao sem critico/alto/moderado, package id final, HTTPS App
Links e Play Store ficam para fases futuras.
