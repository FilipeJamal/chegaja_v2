# ChegaJa v2 - M1 Windows MVP Status

Data: 2026-05-14

Base inicial: `c8e93f0 Adicionar auditoria M0 multiplataforma`

## Resultado M1

Estado atual:

| Item | Estado |
| --- | --- |
| `flutter doctor -v` | Passou sem issues. Visual Studio Build Tools 2022 detectado. |
| `flutter config --enable-windows-desktop` | Executado. |
| `flutter clean` / `flutter pub get` | Executados. |
| `flutter build windows --debug` | Passou. |
| `flutter build windows --release` | Passou. |
| `flutter test` | Passou: 37/37. |
| `cd functions && npm.cmd test` | Passou: 11/11. |
| `node --check scripts/e2e/full_ui_dual_role_e2e.js` | Passou. |
| `npm run e2e:ui:dual` | Passou apos restart limpo dos emuladores/web-server. |
| `npm run e2e:ui:orcamento` | Passou. |
| App Windows Cliente | Abriu e ficou viva em debug. |
| App Windows Prestador | Abriu e ficou viva em debug. |
| MissingPluginException no arranque | Corrigido para App Check e Stripe. |
| Push/FCM Windows | Fallback: FCM real desativado; app usa streams/in-app. |
| Notificacao local Windows | Fallback: no-op local para nao exigir ATL/native toast no MVP. |
| Stripe PaymentSheet Windows | Fallback: nao inicializa nem chama PaymentSheet no Windows. |
| Remote Config Windows | Desativado por gate de plataforma no arranque. |
| Firebase Storage Emulator Windows | O SDK informa que o emulator nao esta disponivel no Windows; app continua sem crash. |

## Comandos executados

Ambiente:

```bash
git status --short --branch
git log --oneline -1
flutter doctor -v
flutter config --enable-windows-desktop
flutter clean
flutter pub get
```

Build:

```bash
flutter build windows --debug
flutter build windows --release
```

Neste ambiente local foi necessario apontar o Firebase C++ SDK para um cache reduzido por falta de espaco no disco:

```bash
set FIREBASE_CPP_SDK_DIR=%USERPROFILE%\.cache\chegaja\firebase_cpp_sdk_windows_12.7.0
```

Runtime:

```bash
flutter run -d windows --dart-define=DEFAULT_ROLE=cliente
flutter run -d windows --dart-define=DEFAULT_ROLE=prestador
```

Verificacao regressiva:

```bash
flutter test
cd functions && npm.cmd test
node --check scripts/e2e/full_ui_dual_role_e2e.js
npm run e2e:ui:dual
npm run e2e:ui:orcamento
flutter build windows --debug
flutter build windows --release
```

## Erros encontrados

### 1. Disco sem espaco durante extracao do Firebase C++ SDK

Erro:

```text
CMake Error: Problem with archive_write_finish_entry(): File size could not be restored
file failed to extract:
build/windows/x64/firebase_cpp_sdk_windows_12.7.0.zip
```

Causa:

- O drive `C:` chegou a `0` bytes livres.
- O SDK Firebase C++ para Windows baixou um ZIP de ~806 MB e extraiu mais de 7 GB de bibliotecas.

Acao local:

- Foi criado um cache local do SDK Firebase C++ em:

```text
%USERPROFILE%\.cache\chegaja\firebase_cpp_sdk_windows_12.7.0
```

- O cache foi reduzido para o alvo usado pelo Flutter Windows x64 com runtime `MD`.
- O build deve ser executado com `FIREBASE_CPP_SDK_DIR` nesse ambiente quando o disco estiver apertado.

### 2. `flutter_local_notifications_windows` exigia ATL

Erro:

```text
fatal error C1083: cannot open include file: 'atlbase.h'
```

Causa:

- O componente ATL/MFC do Visual Studio Build Tools nao esta disponivel nesta instalacao.
- A tentativa de instalar via Visual Studio Installer falhou porque a sessao nao iniciou elevada para operacao `--quiet`.

Correcao aplicada:

- Adicionado pacote local:

```text
packages/flutter_local_notifications_windows_stub
```

- `pubspec.yaml` agora faz override de `flutter_local_notifications_windows` para esse stub.
- O stub mantem os tipos Dart de Windows, mas registra implementacao no-op e nao compila DLL nativa.

Decisao:

- Para M1, Windows nao precisa toast nativo.
- Push real no Windows fica fora do MVP; a app usa streams Firestore/in-app.

### 3. App Check e Stripe eram inicializados no Windows

Erros:

```text
MissingPluginException(... FirebaseAppCheck#registerTokenListener ...)
MissingPluginException(... flutter.stripe/payments ...)
```

Correcao aplicada:

- `main.dart` usa `PlatformCaps.supportsAppCheck` antes de ativar App Check.
- `main.dart` usa `PlatformCaps.supportsStripe` antes de inicializar Stripe.
- `PaymentService.payPedido` retorna fallback seguro fora de Android/iOS.
- `PaymentService.startPrestadorOnboarding` bloqueia plataformas sem Cloud Functions suportado.

### 4. Remote Config emitia erro no Windows

Erro:

```text
[RemoteConfig] Error initializing: type 'Null' is not a subtype of type 'int'
```

Correcao aplicada:

- `PlatformCaps.supportsRemoteConfig` criado.
- `main.dart` nao inicializa Remote Config no Windows.

## Correcoes aplicadas

Arquivos principais:

- `pubspec.yaml`
- `pubspec.lock`
- `windows/flutter/generated_plugins.cmake`
- `lib/main.dart`
- `lib/core/utils/platform_caps.dart`
- `lib/core/services/payment_service.dart`
- `packages/flutter_local_notifications_windows_stub/**`

Resumo tecnico:

- App Check: Web/Android/iOS.
- Crashlytics: Android/iOS.
- Remote Config: Web/Android/iOS/macOS.
- Stripe PaymentSheet: Android/iOS.
- Windows local notifications: no-op fallback.
- Desktop sem FCM: sem crash; continua com streams/in-app.

## Funcionalidades verificadas no Windows

Verificado por arranque controlado:

- App Windows compila em debug.
- App Windows compila em release.
- Cliente Windows abre.
- Prestador Windows abre.
- Firebase inicializa.
- Auth nao bloqueia o arranque depois do timeout desktop ajustado.
- FCM ausente nao causa crash.
- Stripe ausente nao causa crash.
- App Check ausente nao causa crash.
- Remote Config ausente nao causa crash.

Logs residuais conhecidos:

```text
The Storage Emulator is not available on Windows.
FCM nao suportado neste OS.
Firestore native plugin: non-platform thread warning.
```

Esses logs nao bloquearam o arranque da app Windows.

Durante os E2E Web com emuladores, tambem apareceu intermitentemente:

```text
FIRESTORE (12.3.0) INTERNAL ASSERTION FAILED: Unexpected state
```

O fluxo passou apos restart limpo dos emuladores e do web-server. Tratar como risco de ambiente/emulador Web a observar, nao como bloqueio de M1 Windows.

## M1.5 — Validacao cruzada Windows/Web

Estado: parcial.

M1.5 encontrou e corrigiu um bloqueio real antes dos fluxos cruzados: no Windows com emuladores, `AuthService.ensureSignedInAnonymously()` podia demorar mais do que os timeouts da UI Cliente e do bootstrap global. A causa pratica era a `ClienteHomeScreen` iniciar o stream de servicos antes de haver utilizador autenticado; no SDK Windows, stream Firestore pre-auth pode prender o cliente nativo. O Cliente Windows ficava com:

```text
[ClienteHome] auth bootstrap error: TimeoutException after 0:00:12.000000
[Auth] ensureSignedInAnonymously falhou/timeout: TimeoutException after 0:00:20.000000
```

Correcoes aplicadas:

- `AppConfig.emulatorHost` normaliza `127.0.0.1`/`::1` para `localhost` no Windows, sem editar `.env`.
- `AuthService` nao faz pre-wait em `authStateChanges()` antes do primeiro sign-in anonimo no Windows.
- Timeout de auth no bootstrap Windows subiu para 45s.
- Timeout de auth da `ClienteHomeScreen` no Windows subiu para 45s.
- `ClienteHomeScreen` so inicia o stream de servicos depois de existir utilizador autenticado.
- `integration_test/pedido_flow_emulator_test.dart` ganhou regressao para `AuthService` no app default e abertura de stream Firestore depois do sign-in.

Evidencia automatizada adicional:

```bash
flutter test integration_test/pedido_flow_emulator_test.dart -d windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Resultado:

```text
4/4 passou:
- AuthService ensures anonymous default user on emulator
- AuthService completes before Firestore streams start
- automatic flow: prestador accepts open pedido
- manual flow: prestador accepts convite
```

Arranque runtime Windows apos correcao:

| App Windows | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- |
| Cliente | passou | `Emuladores: true (localhost)`, sem `AuthService` timeout, sem `MissingPluginException`, bootstrap terminou em ~38s | Ainda aparecem warnings do plugin Firestore sobre non-platform thread. |
| Prestador | passou | `Emuladores: true (localhost)`, sem `AuthService` timeout, sem `MissingPluginException`, bootstrap terminou em ~4s | Ainda aparecem warnings do plugin Firestore sobre non-platform thread. |

Tabela dos fluxos M1.5:

| Fluxo | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- |
| Cliente Windows + Prestador Web pedido normal | pendente manual | UI nativa Windows nao exposta para automacao; Windows Cliente arranca sem timeout e Web E2E normal segue como baseline | Precisa execucao manual com duas janelas. |
| Cliente Web + Prestador Windows pedido normal | pendente manual | UI nativa Windows nao exposta para automacao; Windows Prestador arranca sem timeout; integration test Windows valida Auth/Firestore e aceite de pedido por codigo | Este continua sendo o fluxo critico para fechar Windows como app operacional. |
| Cliente Windows + Prestador Web orcamento | pendente manual | Web E2E orcamento segue como baseline; Windows Cliente arranca sem timeout | Precisa execucao manual do fluxo L2 com Cliente Windows. |
| Cliente Web + Prestador Windows orcamento | pendente manual | Windows Prestador arranca sem timeout; sem automacao nativa para clicar aceitar/enviar faixa/valor final | Precisa execucao manual do fluxo L2 com Prestador Windows. |
| Chat com Cliente Windows | pendente manual | Fluxo Web chat/no-show passou no E2E dual; Windows Cliente Auth/Firestore OK em integration test | Precisa confirmar UI de chat nativa. |
| Chat com Prestador Windows | pendente manual | Fluxo Web chat/no-show passou no E2E dual; Windows Prestador arranca sem timeout | Precisa confirmar UI de chat nativa. |
| Anexos Windows | pendente | Log runtime: `The Storage Emulator is not available on Windows.` | Anexos nao bloqueiam pedido/orcamento/chat, mas precisam fallback/teste manual fora do Storage Emulator Windows. |

Limite de automacao encontrado:

```text
Windows UI Automation ve apenas:
- Window: chegaja_v2
- Pane: FLUTTERVIEW
```

Ou seja, botoes/textos Flutter da app Windows nao ficaram acessiveis para clique automatizado por UI Automation neste ambiente. Por isso, os fluxos cruzados reais nao foram marcados como passados.

Comandos executados nesta fase:

```bash
flutter pub get
flutter config --enable-windows-desktop
flutter build windows --debug
flutter build windows --release
flutter test integration_test/pedido_flow_emulator_test.dart -d windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter run -d windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --dart-define=DEFAULT_ROLE=cliente
flutter run -d windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --dart-define=DEFAULT_ROLE=prestador
```

Validacao final apos as correcoes:

| Comando | Estado | Observacoes |
| --- | --- | --- |
| `flutter test` | passou | 37/37 |
| `cd functions && npm.cmd test` | passou | 11/11 |
| `node --check scripts/e2e/full_ui_dual_role_e2e.js` | passou | Sem output. |
| `npm.cmd run e2e:ui:dual` | passou | Fluxos Web L1/chat/no-show continuam validos. |
| `npm.cmd run e2e:ui:orcamento` | passou | Fluxo Web L2 concluiu com `ORCAMENTO MIN-MAX FLOW OK`. |
| `flutter test integration_test/pedido_flow_emulator_test.dart -d windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true` | passou | 4/4. |
| `flutter build windows --debug` | passou | Build gerado em `build\windows\x64\runner\Debug\chegaja_v2.exe`. |
| `flutter build windows --release` | passou | Build gerado em `build\windows\x64\runner\Release\chegaja_v2.exe`. |

Observacao: os E2E Web ainda podem imprimir `FIRESTORE (12.3.0) INTERNAL ASSERTION FAILED: Unexpected state` no console do browser quando usados com emulador. Os cenarios finalizaram corretamente, entao isto fica como warning residual a observar.

Ficheiros alterados nesta fase:

- `lib/core/config/app_config.dart`
- `lib/core/services/auth_service.dart`
- `lib/main.dart`
- `lib/features/cliente/cliente_home_screen.dart`
- `integration_test/pedido_flow_emulator_test.dart`
- `docs/WINDOWS_MVP_STATUS.md`

Decisao:

```text
M1.5 parcial.
Nao avancar para M2 Android como "Windows fechado" enquanto Cliente Web + Prestador Windows nao for testado manualmente.
```

## Fallbacks Windows ativos

| Area | Fallback |
| --- | --- |
| Push real / FCM | Desativado no Windows; usar streams Firestore, badges e in-app. |
| Notificacao local nativa | Stub no-op para evitar dependencia ATL no MVP. |
| Stripe PaymentSheet | Nao inicializa no Windows; pagamento online deve usar link/checkout externo em fase posterior. |
| App Check | Desativado no Windows. |
| Remote Config | Desativado no Windows. |
| Cloud Functions para pagamentos | Bloqueado em `PaymentService` quando a plataforma nao suporta. |

## Pendente depois de M1.5 parcial

Ainda precisa de teste manual/automacao nativa:

- [ ] Cliente Windows + Prestador Web concluem pedido normal.
- [ ] Cliente Web + Prestador Windows concluem pedido normal.
- [ ] Orcamento min/max com Cliente Windows + Prestador Web.
- [ ] Orcamento min/max com Cliente Web + Prestador Windows.
- [ ] Testar criacao de pedido no Windows com morada/manual quando GPS falhar.
- [ ] Testar chat com um lado Windows.
- [ ] Testar upload/anexos no Windows.
- [ ] Decidir fallback definitivo para Storage Emulator em Windows local.
- [ ] Avaliar se os warnings de Firestore Windows exigem issue upstream ou upgrade FlutterFire.

## Proxima fase

Antes de M2 Android, a recomendacao e:

1. Rodar os quatro fluxos cruzados M1.5 manualmente.
2. Se houver bloqueio de UI Windows, corrigir antes de Android.
3. Manter Web como baseline com E2E dual e orcamento.
