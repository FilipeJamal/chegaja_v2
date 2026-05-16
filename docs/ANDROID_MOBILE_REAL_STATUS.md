# Android Mobile Real Status - M2.6

Data: 2026-05-16

## Estado resumido

M2.5 continua registado como parcial. M2.6 avancou a parte local de
Android release readiness: o build release foi desbloqueado, o signing local
foi validado sem commitar segredos, o APK release foi gerado e o AppBundle
release tambem foi gerado.

M2.6 ainda nao deve ser marcado como fechado completo porque estes itens
continuam a exigir prova em dispositivo Android fisico ou ambiente FCM/Storage
real:

- push real recebido por prestador;
- clique em push real abrindo pedido/chat correto;
- upload real de anexos pelo picker nativo;
- permissao nativa negada para notificacoes e ficheiros/imagens.

## Ambiente validado

```text
Flutter 3.38.9 stable
Android emulator: emulator-5554, Android 14 API 34
Firebase Auth Emulator: 127.0.0.1:9099
Firestore Emulator: 127.0.0.1:8080
Storage Emulator: 127.0.0.1:9199
Android app emulator host: 10.0.2.2
GitHub CLI: autenticado como FilipeJamal
```

## Evidencias M2.6

| Area | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- |
| APK debug | passou | `flutter build apk --debug` | Gerou `build/app/outputs/flutter-apk/app-debug.apk`. |
| APK release | passou | `flutter build apk --release` | Gerou `build/app/outputs/flutter-apk/app-release.apk` com 113.5MB. |
| AppBundle release | passou | `flutter build appbundle --release` | Gerou `build/app/outputs/bundle/release/app-release.aab` com 88.5MB. |
| Release signing | passou local | `android/key.properties` ignorado + `android/app/upload-keystore.jks` ignorado | `:app:signingReport` confirmou keystore local e alias `upload`. Segredos nao foram commitados. |
| R8/ProGuard | passou | `flutter build apk --release --verbose` e build release normal | R8 terminou; a falha real era signing sem `storeFile` por encoding invalido de `key.properties`. |
| `--no-shrink` | passou | `flutter build apk --release --no-shrink` | Variante usada para isolar R8; nao ficou como artefato final. |
| Profile APK | passou | `flutter build apk --profile` | Variante usada para comparar debug/profile/release. |
| Flutter tests | passou | `flutter test` | 43/43 passou. |
| Functions tests | passou | `npx.cmd firebase emulators:exec --only firestore "cd functions && npm.cmd test"` | 11/11 passou. |
| Android MVP | passou | `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"` | 5/5 passou no `emulator-5554`. |
| Android mobile real test | passou | `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"` | 4/4 passou no `emulator-5554`. |
| Deep link pedido | passou | `Deep link Android abre pedido existente` | Integration test Android com Firestore Emulator. |
| Deep link chat | passou | `Deep link Android abre chat de pedido existente` | Integration test Android com Firestore Emulator. |
| FCM token | passou parcial | `Token FCM Android e gravado no formato usado pelas Functions` | Valida `users/{uid}/fcmTokens/{token}` com token controlado; nao e push real. |
| Push real | pendente | sem dispositivo fisico/FCM real nesta rodada | Precisa provar notificacao recebida e clique. |
| Anexos Android | pendente real | `UI de anexos Android renderiza fallback sem abrir picker` | UI/fallback passou; upload real pelo picker nativo continua pendente. |
| Permissoes negadas | pendente real | nao executado em dialogos nativos | Precisa testar notificacoes e ficheiros/imagens negados. |

## Causa do build release

O timeout anterior escondia duas fases diferentes:

1. O build release em modo `--verbose` mostrou que o AOT e o R8 chegaram a
   terminar. O R8 emitiu avisos informativos, mas nao foi a causa final.
2. A falha ocorreu em `:app:packageRelease` com:

```text
SigningConfig "release" is missing required property "storeFile"
```

A causa raiz local era o ficheiro ignorado `android/key.properties` em UTF-16
LE. O Gradle carrega esse ficheiro com `java.util.Properties`; com UTF-16, as
chaves nao eram lidas como `storeFile`, `keyAlias`, `keyPassword` e
`storePassword`. O ficheiro local foi convertido para UTF-8/ASCII sem expor
valores no Git.

## Alteracoes de teste Android

O alias `-d android` nao foi resolvido pelo Flutter 3.38.9 neste ambiente,
apesar de existir `emulator-5554`. Os scripts Android agora usam:

```text
scripts/run_android_integration_test.js
```

Esse runner escolhe automaticamente o primeiro device Android suportado via
`flutter devices --machine`, ou usa `ANDROID_DEVICE_ID` quando definido.

O teste `integration_test/android_mvp_flow_test.dart` tambem foi ajustado para
finalizar o campo de texto antes do submit e tocar apenas quando o botao esta
hit-testable. Isto removeu a falha intermitente em Android onde o pedido nao
era criado pela UI do cliente.

## Pendencias para fechar M2.6 completo

| Item | Estado | Proxima prova |
| --- | --- | --- |
| Push real Android | pendente | Instalar APK em dispositivo fisico, login cliente/prestador, criar pedido e confirmar push recebido pelo prestador. |
| Clique em notificacao | pendente | Tocar no push real e confirmar abertura do pedido/chat correto. |
| Upload real de anexos | pendente | Escolher imagem/ficheiro no Android, enviar para Storage e reabrir o anexo depois. |
| Permissao de notificacao negada | pendente | Negar permissao Android 13+ e confirmar que a app nao crasha e mostra fallback claro. |
| Permissao de ficheiros/imagens negada | pendente | Negar picker/galeria e confirmar mensagem clara sem crash. |
| Package id final | pendente futuro | Trocar `com.example.chegaja_v2` apenas quando houver app Firebase/Play final. |
| HTTPS App Links | pendente futuro | Publicar `assetlinks.json` nos dominios finais. |

## Decisao

```text
M0: fechado.
M2.5: parcial, commitado.
M2.6: release build/signing/AppBundle local passou; QA real em dispositivo
Android fisico ainda pendente.
```
