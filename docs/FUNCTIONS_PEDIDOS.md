# Functions de Pedidos - M2.7.2

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
```

Validacao completa da fase:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage "cd functions && npm.cmd test"
flutter test
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"
flutter build apk --release
flutter build appbundle --release
```
