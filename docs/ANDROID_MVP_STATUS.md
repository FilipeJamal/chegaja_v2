# Android MVP Status

Data: 2026-05-15

## Estado M2

M2 Android MVP esta fechado para validacao tecnica do fluxo principal.

O Android foi validado com build debug, emulador Android ativo e `integration_test`
nativo do Flutter contra Firebase Auth/Firestore Emulator. Publicacao Play Store,
assinatura real, push real, anexos nativos e release final ficam fora deste bloco.

## Ambiente

Comandos executados:

```bash
git status --short --branch
git log --oneline -3
flutter doctor -v
flutter devices
flutter clean
flutter pub get
```

Resultado de ambiente:

```text
Flutter 3.38.9 stable
Android SDK 36.0.0
Java 17 via JAVA_HOME
Android emulator: emulator-5554, Android 14 API 34
flutter doctor: No issues found
```

Firebase Emulator usado para os testes Android:

```text
Auth: 127.0.0.1:9099
Firestore: 127.0.0.1:8080
Android app: 10.0.2.2:9099 / 10.0.2.2:8080
```

## Builds

| Comando | Estado | Observacoes |
| --- | --- | --- |
| `flutter build apk --debug` | passou/parcial | Build debug direto passou no inicio do M2. O `integration_test` Android tambem executou `assembleDebug` e gerou APK debug apos as correcoes. Uma repeticao final explicita de `flutter build apk --debug` estourou timeout local depois de recriar transforms do Gradle em disco quase cheio. |
| `flutter build apk --release` | falhou | Falhou com pouco espaco em disco e regras R8 ausentes para classes opcionais de Stripe push provisioning. Nao bloqueia M2 MVP debug. |
| `flutter build appbundle --debug` | nao executado | Adiado por espaco em disco apertado apos os builds/testes Android. |

Nota:

```text
android.enableJetifier=false
```

Foi usado para reduzir o volume de transforms AndroidX durante builds locais. O
build debug e o teste Android passaram com Jetifier desativado.

## Runtime Android

Runtime Android foi validado por `integration_test` rodando no emulador Android.
Nao foi feito teste manual separado via `flutter run`, porque o objetivo do M2 foi
evitar dependencia de QA manual.

Script adicionado:

```bash
npm.cmd run test:android:mvp
```

Comando real:

```bash
flutter test --ignore-timeouts integration_test/android_mvp_flow_test.dart -d android --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Resultado:

```text
5/5 passou
```

## Integration Tests

Novo teste:

```text
integration_test/android_mvp_flow_test.dart
```

Tabela M2:

| Fluxo | Metodo | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- | --- |
| Cliente Android UI + Prestador simulado pedido normal | integration_test Android | passou | `Cliente Android UI conclui pedido normal com prestador simulado` | UI cliente cria pedido, prestador simulado aceita/inicia/propoe valor, UI cliente confirma. |
| Prestador Android UI + Cliente simulado pedido normal | integration_test Android | passou | `Prestador Android UI conclui pedido normal com cliente simulado` | UI prestador ve pedido, aceita, inicia e lanca valor final; cliente simulado confirma. |
| Cliente Android UI + Prestador simulado orcamento | integration_test Android | passou | `Cliente Android UI conclui orcamento com prestador simulado` | UI cliente aceita proposta min/max e confirma valor final. |
| Prestador Android UI + Cliente simulado orcamento | integration_test Android | passou | `Prestador Android UI conclui orcamento com cliente simulado` | UI prestador envia faixa `20/35`, inicia e lanca `30`; cliente simulado confirma. |
| Chat com um lado Android | integration_test/servico | passou | `Chat com ator Android escreve e le mensagens do outro lado` | Valida escrita/leitura em `chats/{pedidoId}/messages`. |
| Anexos Android | documentado | pendente nao bloqueante | Nao testado neste bloco | File picker/camera/galeria ficam para M2.5 QA mobile. |

Campos validados nos pedidos:

```text
estado = concluido
status = concluido
statusConfirmacaoValor = confirmado_cliente
precoFinal preenchido
commissionPlatform preenchido
earningsProvider preenchido
earningsTotal preenchido
historico com pedido_aceite / servico_iniciado / valor_proposto / concluido
tipoPreco = por_orcamento nos fluxos de orcamento
valorMinEstimadoPrestador = 20
valorMaxEstimadoPrestador = 35
statusProposta = aceita_cliente
```

## Permissoes

Manifest principal contem:

```text
INTERNET
ACCESS_FINE_LOCATION
ACCESS_COARSE_LOCATION
POST_NOTIFICATIONS
CAMERA
RECORD_AUDIO
MODIFY_AUDIO_SETTINGS
BLUETOOTH
BLUETOOTH_ADMIN
BLUETOOTH_CONNECT
```

Android debug/profile agora permitem cleartext traffic para desenvolvimento com
Firebase Emulator. Release nao foi aberto para cleartext por esta alteracao.

## Firebase

O `applicationId` permanece:

```text
com.example.chegaja_v2
```

Nao foi alterado no M2 porque `android/app/google-services.json` ja contem uma
entrada para `com.example.chegaja_v2`. O package final de producao deve ser
definido depois com app Android correspondente no Firebase.

## Deep Links

O manifest contem:

```text
chegaja://
https://app.chegaja.pt
https://chegaja.pt
```

Comando executado apos instalar o APK debug:

```bash
adb shell am start -a android.intent.action.VIEW -d "chegaja://pedido/teste" com.example.chegaja_v2
```

Resultado:

```text
Starting: Intent { act=android.intent.action.VIEW dat=chegaja://pedido/... pkg=com.example.chegaja_v2 }
```

O teste valida resolucao/abertura basica do intent. Navegacao para pedido real
via deep link fica para M2.5/Mobile Notifications.

## Notificacoes

`POST_NOTIFICATIONS` existe no manifest. Push real FCM nao foi validado neste
bloco. O teste Android confirmou que o fluxo principal nao crasha por FCM,
App Check, Remote Config, Crashlytics, Stripe, mapa ou localizacao durante os
cenarios exercitados.

## Correcoes Aplicadas

- Criado `integration_test/android_mvp_flow_test.dart`.
- Adicionado script `test:android:mvp`.
- Android debug/profile permitem cleartext traffic para Firebase Emulator.
- `_CompatDropdownButtonFormField` usa `isExpanded: true` para evitar overflow
  em Android estreito.
- Timeline do pedido passou a usar `Expanded` nos labels, evitando overflow
  horizontal em telas estreitas.
- `android.enableJetifier=false` para reduzir uso local de disco/caches.

## Pendencias

- Definir package id final de producao e criar app Android correspondente no Firebase.
- Ajustar nome/icone final do app Android.
- Configurar signing real para release/Play Store.
- Corrigir/validar release APK em ambiente com mais espaco; falha atual inclui
  espaco em disco e regras R8 para classes opcionais Stripe push provisioning.
- Testar push real FCM em dispositivo fisico.
- Testar deep links reais com dominio e navegacao para pedido/chat existente.
- Testar anexos, camera e galeria em Android.
- Testar permissoes negadas de localizacao/camera/microfone em device fisico.
- Avaliar politica de tiles do mapa antes de producao.

## Decisao

```text
M2 Android MVP: fechado para fluxo tecnico principal.
M2.5 recomendado: Mobile Notifications, anexos/camera/galeria, release signing e deep links reais.
```
