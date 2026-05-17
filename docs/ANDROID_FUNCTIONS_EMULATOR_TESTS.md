# Android Functions Emulator Tests - M2.7.3

Data: 2026-05-17

## Objetivo

M2.7.3 prova que o Android em emulador consegue usar o mesmo caminho
autoritativo que builds normais usam para valores finais:

```text
PedidoService -> Cloud Functions callable -> Admin SDK -> Firestore
```

Isto cobre a lacuna deixada pela M2.7.2: os scripts Android antigos sobem
Auth/Firestore/Storage, mas nao sobem Functions.

## Flags

O runner Android continua sempre a passar:

```text
--dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Para o teste com Functions, passa tambem:

```text
--dart-define=RUN_FIREBASE_FUNCTIONS_EMULATOR_TESTS=true
```

Com essa segunda flag ativa, `PedidoService` usa as callables mesmo em modo
emulador.

## Scripts

Scripts existentes mantidos:

```powershell
npm.cmd run test:android:mvp
npm.cmd run test:android:mobile
```

Novo script:

```powershell
npm.cmd run test:android:functions
```

Execucao completa com emuladores:

```powershell
npx.cmd firebase emulators:exec --only auth,firestore,storage,functions "npm.cmd run test:android:functions"
```

## Teste Coberto

Arquivo:

```text
integration_test/android_functions_flow_test.dart
```

Fluxo:

```text
1. Cliente cria pedido no Firestore Emulator.
2. Prestador aceita pedido.
3. Prestador inicia servico.
4. Prestador propoe valor final via `proporValorFinalPedido`.
5. Cliente confirma valor final via `confirmarValorFinalPedido`.
6. Pedido fica concluido.
7. `precoFinal` fica igual ao valor proposto.
8. `commissionPlatform` fica em 15%.
9. `earningsProvider` fica em 85%.
10. `lastAuthoritativeFunction` confirma a Function que escreveu o estado.
```

Evidencia esperada no log do Functions Emulator:

```text
Beginning execution of "europe-west1-proporValorFinalPedido"
Beginning execution of "europe-west1-confirmarValorFinalPedido"
```

## Compatibilidade

O caminho direto continua disponivel para:

```text
fake_cloud_firestore
testes unitarios
testes Android antigos sem Functions Emulator
testes de regras Firestore
```

Isto evita misturar a validacao de regras com a validacao de callable. O teste
novo cobre especificamente a integracao Android + Functions Emulator.
