# Android Mobile Real Status - M2.5

Data: 2026-05-15

## Estado resumido

M2.5 avancou como validacao parcial de Android mobile real.

O Android agora tem:

- teste automatizado separado para deep links, token FCM e anexos;
- deep link para pedido/chat existente validado por `integration_test` Android;
- intent Android `chegaja://pedido/...` e `chegaja://chat/...` aceito pelo APK debug instalado;
- armazenamento de token FCM alinhado com as Cloud Functions;
- regra ProGuard para classes opcionais de Stripe push provisioning.

M2.5 nao deve ser marcado como fechado completo porque push real em dispositivo
fisico, upload real de anexos, release APK/AppBundle e permissao negada em
dialogos nativos continuam dependentes de ambiente/device/espaco.

## Ambiente

Ambiente observado:

```text
Flutter 3.38.9 stable
Android SDK 36.0.0
Android emulator: emulator-5554, Android 14 API 34
Firebase Auth Emulator: 127.0.0.1:9099
Firestore Emulator: 127.0.0.1:8080
Android app emulator host: 10.0.2.2
```

Espaco em disco foi um fator real. Depois do `test:android:mobile`, o disco
ficou perto de 1.24 GB livres. Builds Android release ficaram limitados por
espaco/tempo local.

## Release Readiness

| Item | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- |
| APK debug | passou | `npm.cmd run test:android:mobile` executou `assembleDebug`, instalou APK e passou 4/4 | APK debug gerado em `build/app/outputs/flutter-apk/app-debug.apk`. |
| APK release | parcial | `flutter build apk --release` estourou timeout de 40 minutos | Foi adicionada regra ProGuard para avisos opcionais do Stripe. A tentativa atual nao chegou a produzir APK nem erro R8 novo; ficou bloqueada por tempo/ambiente. |
| AppBundle debug/release | pendente | nao executado nesta rodada | Pendente por espaco local. |
| R8/ProGuard | avancado | `android/app/proguard-rules.pro` criado | Cobre classes opcionais `com.stripe.android.pushProvisioning.*`. |
| Signing | pendente | nao alterado | Nao foi criada keystore falsa. Signing real fica para readiness Play Store. |
| Package id | pendente futuro | mantido `com.example.chegaja_v2` | Nao trocar sem criar app Android/Firebase final. |

## FCM

| Item | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- |
| `POST_NOTIFICATIONS` | presente | Android Manifest ja contem permissao | Dialogo nativo nao foi automatizado. |
| Token obtido real | pendente | nao validado em dispositivo fisico | Nao foi marcado como push real. |
| Token gravado no Firestore | passou por teste | `Token FCM Android e gravado no formato usado pelas Functions` | O teste grava token controlado em `users/{uid}.fcmToken` e `users/{uid}/fcmTokens/{token}`. |
| Push real recebido | pendente | nao testado | Precisa dispositivo/emulador com FCM real e envio backend. |
| Clique navega | parcial | deep link/navigation handler validado | Clique de push real ainda pendente. |
| Fallback in-app | mantido | fluxos Android continuam sem crash por FCM | Push nao bloqueia fluxo principal. |

Correcao aplicada:

```text
NotificationService agora grava tambem:
users/{uid}/fcmTokens/{token}
```

Isto alinha o cliente com `functions/index.js`, onde `sendPushToUser` le a
subcolecao `fcmTokens`.

## Deep Links

| Link | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- |
| `chegaja://pedido/<pedidoId>` | passou | `Deep link Android abre pedido existente` | Validado por `integration_test` Android com pedido real no Firestore Emulator. |
| `chegaja://chat/<pedidoId>` | passou | `Deep link Android abre chat de pedido existente` | Validado por `integration_test` Android com chat/pedido real no Firestore Emulator. |
| Intent Android custom scheme | passou | `adb shell am start ... chegaja://pedido/...` e `chegaja://chat/...` | APK debug instalado aceitou os intents. |
| HTTPS App Links | pendente | nao validado | Producao precisa `assetlinks.json` nos dominios. |
| Pedido inexistente | parcial | intent aceito com id inexistente | Fluxo seguro completo ainda deve ser revisado visualmente. |

Comandos executados:

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-debug.apk
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" shell am start -a android.intent.action.VIEW -d "chegaja://pedido/m25-nonexistent" com.example.chegaja_v2
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" shell am start -a android.intent.action.VIEW -d "chegaja://chat/m25-nonexistent" com.example.chegaja_v2
```

## Anexos

| Item | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- |
| UI de anexos Android | passou | `UI de anexos Android renderiza fallback sem abrir picker` | Botoes de galeria/camera/arquivo renderizam com keys estaveis. |
| File picker | pendente | nao abriu picker nativo no teste | Abrir picker nativo por integration_test pode bloquear automacao. |
| Galeria | pendente | nao testado upload real | Precisa device/emulador com imagem. |
| Camera | pendente | nao testado camera real | Precisa device/emulador com camera configurada. |
| Upload Storage | pendente | nao testado | Storage Emulator/Storage real deve ser validado em M2.6/QA mobile. |
| Cancelamento/fallback | parcial | UI renderiza sem crash | Cancelamento real do picker ainda pendente. |

Foi adicionada key estavel aos controles:

```text
pedido_anexo_galeria_button
pedido_anexo_camera_button
pedido_anexo_arquivo_button
```

## Permissoes Negadas

| Permissao | Estado | Observacoes |
| --- | --- | --- |
| Localizacao | parcial | Fluxo principal Android ja passa sem depender de GPS perfeito; dialogo negado ainda pendente. |
| Notificacao | parcial | Token policy/fallback sem crash validado; negacao do dialogo Android 13+ pendente. |
| Camera | pendente | Precisa teste real de picker/camera. |
| Microfone | pendente | Chamadas/WebRTC ficam fora do M2.5 automatizado. |

## Testes Executados

Comandos executados nesta rodada:

```bash
flutter pub get
flutter test
cd functions && npm.cmd test
node --check scripts/e2e/full_ui_dual_role_e2e.js
flutter test test/core/notification_service_test.dart test/core/deep_link_service_test.dart
npm.cmd run test:android:mobile
npm.cmd run e2e:ui:dual
npm.cmd run e2e:ui:orcamento
npm.cmd run test:windows:cross
flutter build windows --debug
flutter build windows --release
npm.cmd run test:android:mvp
flutter build apk --debug
flutter build apk --release
```

Resultados relevantes:

```text
flutter test: 43/43 passou.
functions npm test: 11/11 passou com Auth/Firestore Emulator ativo.
node --check e2e: passou.
e2e:ui:dual: passou contra build/web servido localmente.
e2e:ui:orcamento: passou contra build/web servido localmente.
test:windows:cross: 5/5 passou.
flutter build windows --debug: passou.
flutter build windows --release: passou.
test:android:mvp: 5/5 passou.
unit tests novos de notification/deep link: 6/6 passou.
test:android:mobile: 4/4 passou.
flutter build apk --debug: passou.
flutter build apk --release: timeout apos 40 minutos, sem APK release gerado.
```

Nota sobre Web E2E: `flutter run -d web-server` e `flutter run -d chrome`
ficaram presos no splash quando o Playwright abria uma segunda instancia.
Para a regressao final, foi usado `flutter build web` + servidor estatico local
em `http://localhost:5173`, que montou a UI corretamente e passou os dois E2E.

## Teste Android Mobile Real

Novo teste:

```text
integration_test/android_mobile_real_test.dart
```

Novo script:

```json
"test:android:mobile": "flutter test --ignore-timeouts integration_test/android_mobile_real_test.dart -d android --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true"
```

Tabela M2.5:

| Fluxo | Metodo | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- | --- |
| Deep link pedido existente | integration_test Android | passou | `Deep link Android abre pedido existente` | Usa `DeepLinkService` e `AppNavigator` com pedido real no Firestore Emulator. |
| Deep link chat existente | integration_test Android | passou | `Deep link Android abre chat de pedido existente` | Abre `ChatThreadScreen` para pedido com cliente/prestador. |
| Token FCM persistido | integration_test Android + unit test | passou | `Token FCM Android e gravado no formato usado pelas Functions` | Valida subcolecao `fcmTokens`. |
| UI anexos Android | integration_test Android | passou/parcial | `UI de anexos Android renderiza fallback sem abrir picker` | Nao testa upload real. |
| Push real | device/FCM real | pendente | nao executado | Precisa dispositivo/FCM real. |
| Upload real de anexo | device/Storage | pendente | nao executado | Precisa picker e Storage validos. |

## Ficheiros Alterados

```text
android/app/build.gradle.kts
android/app/proguard-rules.pro
integration_test/android_mobile_real_test.dart
lib/core/services/deep_link_service.dart
lib/core/services/notification_service.dart
lib/features/common/widgets/pedido_anexos_widget.dart
package.json
test/core/deep_link_service_test.dart
test/core/notification_service_test.dart
docs/ANDROID_MOBILE_REAL_STATUS.md
```

## Pendencias

- Validar push real FCM em dispositivo fisico ou emulador com Google Play Services.
- Confirmar clique em push real abrindo pedido/chat correto.
- Testar dialogo nativo de permissao negada para notificacoes/localizacao/camera/microfone.
- Testar galeria/camera/file picker e upload real para Storage.
- Validar APK release em ambiente com mais tempo/espaco para R8 finalizar.
- Validar AppBundle debug/release.
- Configurar keystore real e `key.properties` fora do Git.
- Definir package id final e criar app Firebase Android final.
- Configurar `assetlinks.json` para HTTPS App Links em producao.

## Decisao

```text
M2.5 Android Mobile Real: parcial, com avancos importantes automatizados.
Pode seguir para M2.6 Mobile QA/Release Readiness antes de iOS/macOS.
Nao marcar como fechado completo enquanto push real, anexos reais e release/AppBundle continuarem pendentes.
```
