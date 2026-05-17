# Production Hardening Status - M2.7

Data: 2026-05-17

## Estado

M2.7 foi iniciada para endurecer a base de producao enquanto M2.6 continua
bloqueada por falta de Android fisico.

Estado oficial:

```text
M0: fechado
M2.5: parcial
M2.6: avancado tecnicamente, pendente de Android fisico
M2.7: iniciado / avancado em seguranca Firebase e preparacao de QA real
M2.7.1: avancado em estados, pedidos e valores
M2.7.2: avancado em Functions autoritativas para valores
M2.7.3: avancado em testes Android com Functions Emulator
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

O mapa de estados e campos protegidos esta documentado em:

```text
docs/PEDIDO_STATE_MACHINE.md
docs/FUNCTIONS_PEDIDOS.md
docs/ANDROID_FUNCTIONS_EMULATOR_TESTS.md
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
| Campos economicos em `pedidos` | backend autoritativo testado em Android/emulador | M2.7.3 prova um fluxo Android usando Functions Emulator; caminho direto permanece para fake/unitarios e scripts sem Functions. |
| Package id final | futuro | Definir antes de Play Store/Firebase Android final. |
| HTTPS App Links | futuro | Publicar `assetlinks.json` nos dominios reais. |

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

## Decisao

M2.7 nao fecha M2.6. Ela melhora seguranca, estabilidade e readiness enquanto a
validacao em Android fisico continua bloqueada.
