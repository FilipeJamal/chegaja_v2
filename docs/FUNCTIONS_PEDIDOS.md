# Functions de Pedidos - M2.7.2 / M2.7.3 / M2.7.4

Data: 2026-05-17

## Objetivo

M2.7.2 move o fluxo critico de valor final e conclusao de pedido para Cloud
Functions/Admin SDK.

Isto reduz a dependencia de escrita direta por cliente/prestador nos campos de
dinheiro:

```text
precoFinal
preco
commissionPlatform
earningsProvider
earningsTotal
statusConfirmacaoValor
status/estado = concluido
```

## Functions

### `proporValorFinalPedido`

Entrada:

```json
{
  "pedidoId": "pedido_123",
  "valorFinal": 100,
  "comentario": "Servico terminado"
}
```

Valida:

- utilizador autenticado;
- `auth.uid` e o `prestadorId` do pedido;
- pedido esta em `em_andamento`;
- `valorFinal` e numerico e maior que zero.

Escreve como Admin SDK:

```text
precoPropostoPrestador = valorFinal
statusConfirmacaoValor = pendente_cliente
status/estado = aguarda_confirmacao_valor
mensagemPropostaPrestador, se existir
lastAuthoritativeFunction = proporValorFinalPedido
```

### `confirmarValorFinalPedido`

Entrada:

```json
{
  "pedidoId": "pedido_123"
}
```

Valida:

- utilizador autenticado;
- `auth.uid` e o `clienteId` do pedido;
- pedido esta em `aguarda_confirmacao_valor`;
- `statusConfirmacaoValor` esta em `pendente_cliente`;
- `precoPropostoPrestador` existe e e maior que zero.

Calcula no backend:

```text
commissionPlatform = precoPropostoPrestador * 0.15
earningsProvider = precoPropostoPrestador * 0.85
earningsTotal = precoPropostoPrestador
precoFinal = precoPropostoPrestador
preco = precoPropostoPrestador
```

Escreve como Admin SDK:

```text
status/estado = concluido
statusConfirmacaoValor = confirmado_cliente
concluidoEm = serverTimestamp
lastAuthoritativeFunction = confirmarValorFinalPedido
```

Campos economicos enviados pelo cliente na chamada sao ignorados. O backend
usa sempre o valor proposto persistido no pedido.

## Flutter

`PedidoService.instance` usa as callables por defeito para:

```text
proporValorFinal
confirmarValorFinal
```

Quando `PedidoService` recebe um `FirebaseFirestore` injetado em testes, o
caminho direto continua ativo por compatibilidade com `fake_cloud_firestore` e
testes Android em emulador sem Functions.

Quando o app e iniciado com:

```text
--dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

o `PedidoService.instance` tambem usa o caminho direto validado por regras,
porque os scripts Android atuais sobem Auth/Firestore/Storage mas nao sobem o
emulador de Functions. Em builds normais, esse define nao existe e o caminho
autoritativo volta a ser Cloud Functions.

M2.7.3 adicionou uma flag separada:

```text
--dart-define=RUN_FIREBASE_FUNCTIONS_EMULATOR_TESTS=true
```

Quando esta flag esta ativa, `PedidoService` volta a usar o caminho
autoritativo mesmo com `RUN_FIREBASE_EMULATOR_TESTS=true`. Isto permite testar
Android contra Auth/Firestore/Storage/Functions Emulator.

O script dedicado e:

```powershell
npx.cmd firebase emulators:exec --only auth,firestore,storage,functions "npm.cmd run test:android:functions"
```

Detalhes em:

```text
docs/ANDROID_FUNCTIONS_EMULATOR_TESTS.md
```

## Deploy real M2.7.4

As Functions foram publicadas no Firebase real em `chegaja-ac88d`:

```powershell
npx.cmd firebase deploy --only functions --project chegaja-ac88d
```

No deploy M2.7.4, `proporValorFinalPedido` e
`confirmarValorFinalPedido` foram criadas em `europe-west1`. O smoke real
confirmou o caminho:

```text
PedidoService/REST smoke -> Cloud Functions callable -> Admin SDK -> Firestore
```

E validou:

- prestador atribuido chama `proporValorFinalPedido`;
- cliente do pedido chama `confirmarValorFinalPedido`;
- pedido termina em `concluido`;
- `commissionPlatform` fica em 15%;
- `earningsProvider` fica em 85%;
- `lastAuthoritativeFunction` fica em `confirmarValorFinalPedido`;
- tentativa direta de adulterar `commissionPlatform` e negada com 403.

Comando de smoke:

```powershell
npm.cmd run smoke:firebase:production
```

O script fica em:

```text
scripts/smoke/firebase_production_smoke.js
```

Detalhes completos do deploy:

```text
docs/FIREBASE_DEPLOYMENT_STATUS.md
```

## Firestore Rules

As regras continuam a validar o caminho direto legado para nao quebrar os
fluxos de teste que nao sobem o emulador de Functions.

O campo abaixo fica protegido:

```text
lastAuthoritativeFunction
```

Cliente/prestador nao podem criar ou alterar esse marcador. Apenas Admin SDK
consegue gravar o campo.

## Testes

Cobertura principal:

```powershell
npx.cmd firebase emulators:exec --only firestore "cd functions && npx.cmd mocha test/pedidoFunctions.test.js --exit --timeout 30000"
npx.cmd firebase emulators:exec --only firestore "cd functions && npx.cmd mocha test/firestore.test.js --grep spoofing --exit --timeout 30000"
flutter test test\core\pedido_service_test.dart --plain-name "usa Functions autoritativas"
flutter test test\core\pedido_service_test.dart --plain-name "flag de Functions Emulator" --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --dart-define=RUN_FIREBASE_FUNCTIONS_EMULATOR_TESTS=true
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only auth,firestore,storage,functions "npm.cmd run test:android:functions"
```

Validacao completa da fase:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage "cd functions && npm.cmd test"
flutter test
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"
npx.cmd firebase emulators:exec --only auth,firestore,storage,functions "npm.cmd run test:android:functions"
flutter build apk --release
flutter build appbundle --release
npm.cmd run smoke:firebase:production
```
