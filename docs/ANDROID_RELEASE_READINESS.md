# Android Release Readiness - M2.6

Data: 2026-05-16

## Resultado local

O Android agora gera os artefatos release principais neste ambiente local:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

O build release que antes ficava preso/sem artefato foi diagnosticado ate a
fase de packaging. A causa efetiva era configuracao de signing nao carregada
por encoding invalido no ficheiro local ignorado `android/key.properties`.

## Matriz de readiness

| Area | Estado | Evidencia | Pendencia |
| --- | --- | --- | --- |
| APK debug | passou | `flutter build apk --debug` -> `app-debug.apk` | Nenhuma local. |
| APK release | passou | `flutter build apk --release` -> `app-release.apk` 113.5MB | Validar instalacao em dispositivo fisico release. |
| AppBundle release | passou | `flutter build appbundle --release` -> `app-release.aab` 88.5MB | Submeter/testar na Play Console quando package id final existir. |
| Signing release | passou local | `:app:signingReport` confirmou keystore local e alias `upload` | Guardar keystore/passwords fora do Git e em cofre. |
| R8/ProGuard | passou | `flutter build apk --release` com shrink ativo | Monitorizar novos plugins nativos no futuro. |
| Release `--no-shrink` | passou | `flutter build apk --release --no-shrink` | Usado apenas como diagnostico. |
| Profile APK | passou | `flutter build apk --profile` | Usado apenas como diagnostico. |
| Flutter tests | passou | `flutter test` -> 43/43 | Nenhuma local. |
| Functions tests | passou | Firestore Emulator + `cd functions && npm.cmd test` -> 11/11 | Firebase CLI local avisou que nao estava autenticado, mas os testes passaram. |
| Android MVP | passou | Auth/Firestore/Storage Emulator + `npm.cmd run test:android:mvp` -> 5/5 | Nenhuma local. |
| Android mobile real test | passou | Auth/Firestore/Storage Emulator + `npm.cmd run test:android:mobile` -> 4/4 | Nao substitui dispositivo fisico para push/picker. |
| Deep link pedido | passou | Integration test Android | Validar App Links HTTPS em dominio real. |
| Deep link chat | passou | Integration test Android | Validar clique vindo de push real. |
| FCM token | passou parcial | `users/{uid}/fcmTokens/{token}` validado por teste | Provar FCM token real e entrega de push real. |
| Push real | pendente | Nao executado nesta maquina | Precisa dispositivo Android fisico com FCM real. |
| Anexos reais | pendente | UI/fallback passou; picker real nao foi aberto | Precisa escolher ficheiro/imagem e validar Storage. |
| Permissoes negadas | pendente | Nao executado em dialogos nativos | Precisa negar notificacoes e ficheiros/imagens. |

## Comandos de verificacao executados

```powershell
flutter clean
flutter pub get
flutter build apk --release --verbose
flutter build apk --release --no-shrink
flutter build apk --debug
flutter build apk --profile
flutter build apk --release
flutter build appbundle --release
flutter test
npx.cmd firebase emulators:exec --only firestore "cd functions && npm.cmd test"
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"
```

## Diagnostico do timeout release

O log verbose foi guardado fora do repositorio:

```text
C:\Users\Jamal\AppData\Local\Temp\chegaja_m26_release_verbose_20260516_164339.log
```

Observacoes relevantes:

- `kernel_snapshot_program` terminou;
- snapshots AOT para `android-arm`, `android-arm64` e `android-x64`
  terminaram;
- `:app:minifyReleaseWithR8` terminou apos varios minutos;
- os avisos R8 observados eram informativos;
- a falha final era `:app:packageRelease` sem `storeFile` no signing config.

Depois de corrigir o encoding local de `android/key.properties`, o APK release
e o AAB release passaram.

## Criterio de fecho

Esta readiness local prova que a app Android ja consegue gerar artefatos
release. Ainda nao prova que M2.6 esta totalmente fechado, porque o criterio
funcional exige evidencias reais de:

- push Android recebido em dispositivo fisico;
- clique no push abrindo pedido/chat correto;
- upload real de anexos;
- comportamento com permissoes nativas negadas.
