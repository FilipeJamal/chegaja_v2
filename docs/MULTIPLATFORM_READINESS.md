# ChegaJa v2 - M0 Multiplatform Readiness

Data: 2026-05-14

Commit de referencia: `326735315be9221d24f73bf87b034342928cbe1c`

Escopo desta auditoria:

- Web ja validado pelos fluxos L1 e L2.
- Preparar a app para Windows, Android, iOS e macOS.
- Nao adicionar funcionalidades novas nesta fase.
- Identificar riscos por plataforma, comandos de teste/build e correcoes P0/P1/P2.

## Resumo executivo

O ChegaJa ja tem base Flutter/Firebase suficiente para ser multiplataforma, mas ainda nao esta pronto para tratar Windows, Android, iOS e macOS como alvos equivalentes.

Pequenos ajustes seguros aplicados durante M0:

- Android: `android.permission.INTERNET` foi adicionado ao manifest principal para builds release.
- macOS: `com.apple.security.network.client` foi adicionado aos entitlements de debug/profile e release.

O estado real e:

| Plataforma | Estado | Decisao M0 |
| --- | --- | --- |
| Web | Validado no fluxo principal e orcamento | Manter como baseline. Nao quebrar. |
| Windows | Estrutura existe e Firebase Core/Auth/Firestore/Storage aparecem registrados | Proximo alvo pratico. Precisa testar build e criar fallbacks para push, Stripe, Maps e Cloud Functions onde necessario. |
| Android | Estrutura existe, `google-services.json` esta versionado e permissoes principais estao declaradas | Alvo mobile real depois do Windows. Precisa corrigir manifest release e IDs antes de release. |
| iOS | Estrutura existe, Info.plist tem camera/mic/localizacao/deep link | Precisa Mac/Xcode, bundle id real, assinatura e `GoogleService-Info.plist`. |
| macOS | Estrutura existe, plugins sao gerados, mas entitlements estao incompletos | Precisa Mac/Xcode e ajustar sandbox/network/permissoes antes de validar Firebase e anexos. |
| Linux | Nao configurado no `firebase_options.dart` | Fora do MVP multiplataforma imediato. |

## Evidencia inspecionada

- `pubspec.yaml`
- `pubspec.lock`
- `lib/firebase_options.dart`
- `lib/main.dart`
- `lib/core/utils/platform_caps.dart`
- `lib/core/services/payment_service.dart`
- `lib/core/services/notification_service.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/profile/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `ios/Runner/Info.plist`
- `ios/Runner/Runner.entitlements`
- `ios/Podfile`
- `macos/Runner/Info.plist`
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`
- `windows/flutter/generated_plugin_registrant.cc`
- `macos/Flutter/GeneratedPluginRegistrant.swift`

## Dependencias com risco por plataforma

| Area | Packages principais | Estado / risco |
| --- | --- | --- |
| Firebase base | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` | Web validado. Windows registra Core/Auth/Firestore/Storage. Android/iOS/macOS precisam teste real. |
| Cloud Functions | `cloud_functions` | Usado por pagamentos, Places/routing e servicos server-side. macOS registra plugin. Windows nao aparece no registrant, entao chamadas podem falhar com `MissingPluginException`; precisa fallback ou gate. |
| Push | `firebase_messaging`, `flutter_local_notifications` | Codigo ja limita FCM a Web/Android/iOS. Desktop deve usar fallback in-app/local, nao FCM real. macOS registra messaging, mas APNs/FCM precisa configuracao Apple. |
| Observability | `firebase_analytics`, `firebase_crashlytics`, `firebase_performance`, `firebase_remote_config`, `firebase_app_check` | Web/mobile mais provaveis. Desktop tem risco de plugin/config. `PlatformCaps` ja expressa parte das limitacoes, mas nem todo codigo usa esse helper. |
| Stripe | `flutter_stripe` | Adequado para Android/iOS. Nao aparece no registrant Windows/macOS. Desktop deve abrir checkout/link externo via `url_launcher`; PaymentSheet nao deve ser chamado no desktop. |
| Mapas | `google_maps_flutter`, `flutter_map`, `latlong2` | `google_maps_flutter` tem Android/iOS/Web, mas nao Windows/macOS. Telas desktop devem usar `flutter_map`/OSM ou fallback textual/manual. |
| Localizacao | `geolocator` | Web/Android/iOS/macOS/Windows existem. Windows/macOS ainda precisam teste de permissao e fallback para morada manual. |
| Anexos | `file_picker`, `image_picker`, `path_provider` | Bom potencial multiplataforma. iOS/macOS precisam descricoes de privacidade adequadas; desktop precisa validar sandbox e caminhos. |
| Camera/microfone/chamadas | `flutter_webrtc`, `permission_handler`, `record`, `just_audio` | Web/mobile precisam teste. Windows/macOS registram WebRTC/record/audio em parte, mas exigem permissao/sandbox/fallback chat-only. |
| Deep links | `app_links`, `url_launcher` | Android/iOS/Web configurados parcialmente. Windows/macOS precisam teste e fallback de roteamento manual/in-app. |
| Config local | `flutter_dotenv`, asset `.env` | `.env` esta ignorado no Git, mas esta declarado como asset. Nao guardar segredos nele porque pode ir no bundle local. Apenas valores publicos. |

## Firebase por plataforma

| Item | Estado |
| --- | --- |
| `firebase_options.dart` | Configurado para Web, Android, iOS, macOS e Windows. Linux nao configurado. |
| Android `android/app/google-services.json` | Existe e esta versionado. |
| iOS `ios/Runner/GoogleService-Info.plist` | Nao existe no repo. Precisa ser gerado/adicionado para build iOS real, especialmente Auth/FCM/APNs. |
| macOS `macos/Runner/GoogleService-Info.plist` | Nao existe no repo. Precisa ser gerado/adicionado se a build macOS usar configuracao nativa. |
| Android package id | Ainda esta `com.example.chegaja_v2`. Precisa package id final antes de Firebase/App Store/Play Store. |
| iOS/macOS bundle id | `firebase_options.dart` aponta para bundle generico `com.example.chegajaV2`. Precisa bundle id final. |
| Windows Firebase options | Existem, usando configuracao web-style. Precisa teste real de Auth/Firestore/Storage. |

Nota: as chaves em `firebase_options.dart` e `google-services.json` sao configuracao publica Firebase, nao secrets de servidor. Ainda assim, nao publicar `.env`, chaves Stripe secretas, keystores ou credenciais administrativas.

## Permissoes e manifests

### Android

Pronto/parcial:

- Localizacao: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.
- Notificacoes Android 13+: `POST_NOTIFICATIONS`.
- Camera/microfone/WebRTC: `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, Bluetooth.
- Internet: `android.permission.INTERNET` no manifest principal.
- Google Maps API key via `${GOOGLE_MAPS_API_KEY}`.
- Deep links: `chegaja://...` e HTTPS para `app.chegaja.pt` / `chegaja.pt`.
- `android/key.properties`, `android/local.properties` e `.env` estao ignorados.

Riscos:

- App label ainda e `chegaja_v2`.
- `namespace` e `applicationId` ainda sao `com.example.chegaja_v2`.
- App Links HTTPS exigem `assetlinks.json` publicado nos dominios.

### iOS

Pronto/parcial:

- `NSCameraUsageDescription`.
- `NSMicrophoneUsageDescription`.
- `NSLocationWhenInUseUsageDescription`.
- Google Maps API key via `$(GOOGLE_MAPS_API_KEY)`.
- Custom scheme `chegaja://`.
- Associated Domains em `Runner.entitlements`: `applinks:app.chegaja.pt`.
- Podfile em iOS 12.

Riscos:

- Display name ainda e `Chegaja V2`; `CFBundleName` ainda e `chegaja_v2`.
- Bundle id ainda precisa ser final.
- Falta `GoogleService-Info.plist`.
- Falta confirmar assinatura Apple Developer.
- Para upload/galeria, pode ser necessario adicionar `NSPhotoLibraryUsageDescription`.
- Push iOS exige APNs configurado no Firebase e permissao real em dispositivo.

### macOS

Pronto/parcial:

- Pasta macOS existe.
- Generated registrant inclui varios plugins: Firebase, app links, file picker, local notifications, WebRTC, geolocator, audio, shared preferences e url launcher.
- Entitlements de debug/profile e release permitem rede de saida com `com.apple.security.network.client`.

Riscos:

- `Info.plist` ainda nao declara camera, microfone, localizacao ou acesso a ficheiros.
- Falta `GoogleService-Info.plist`.
- Push macOS via FCM/APNs nao deve ser assumido pronto.

### Windows

Pronto/parcial:

- Pasta Windows existe.
- Janela abre com titulo `chegaja_v2`.
- Generated registrant inclui `app_links`, `cloud_firestore`, `file_selector_windows`, `firebase_auth`, `firebase_core`, `firebase_storage`, `flutter_webrtc`, `geolocator_windows`, `permission_handler_windows`, `record_windows`, `url_launcher_windows`.

Riscos:

- `cloud_functions` nao aparece no registrant Windows. Qualquer fluxo que dependa de callable Functions precisa fallback/gate.
- `firebase_messaging` nao aparece no registrant Windows. Push real deve virar notificacao in-app/local.
- `flutter_stripe` nao aparece no registrant Windows. Usar checkout/link externo.
- `google_maps_flutter` nao aparece no registrant Windows. Usar OSM/FlutterMap ou fallback textual.
- Camera/microfone/WebRTC precisam teste real no Windows.

## Estado por funcionalidade

| Funcionalidade | Web | Android | Windows | iOS | macOS |
| --- | --- | --- | --- | --- | --- |
| Auth anonimo | Validado | Testar | Testar | Testar | Testar |
| Firestore | Validado | Testar | Testar | Testar | Testar |
| Storage/anexos | Validado em fluxos web principais | Testar | Testar | Testar | Testar |
| Pedidos L1/L2 | Validado | Testar | Testar | Testar | Testar |
| Chat | Validado no E2E L1 | Testar | Testar | Testar | Testar |
| Push/FCM | Parcial | Testar | Fallback | Testar | Fallback/Apple |
| Notificacao local | Parcial | Testar | Testar | Testar | Testar |
| Deep links | Parcial | Testar | Testar/fallback | Testar | Testar/fallback |
| Mapas | Web usa mapas | Testar | Fallback GoogleMap | Testar | Fallback GoogleMap |
| Localizacao | Parcial | Testar | Testar/fallback | Testar | Testar/fallback |
| Stripe | Parcial | Mobile PaymentSheet | Checkout/link | Mobile PaymentSheet | Checkout/link |
| WebRTC/chamadas | Parcial | Testar | Testar/fallback | Testar | Testar/fallback |
| Admin | Web testado indiretamente | Testar | Testar | Testar | Testar |

## Correcoes P0

Estas bloqueiam ou podem bloquear builds/uso real nas plataformas alvo:

1. Android/iOS/macOS: trocar IDs genericos (`com.example...`) para IDs finais do produto.
2. iOS/macOS: gerar e validar `GoogleService-Info.plist` para os bundle IDs finais.
3. Desktop: impedir chamadas diretas a Stripe PaymentSheet fora de Android/iOS.
4. Desktop: impedir uso direto de `GoogleMap` em Windows/macOS; usar `flutter_map` ou fallback.
5. Windows: gate/fallback para qualquer chamada `cloud_functions` em fluxos essenciais, porque o plugin nao aparece registrado.
6. Garantir que `.env` nao contenha secrets, ja que esta declarado como asset Flutter.

## Correcoes P1

Importantes para MVP distribuivel:

1. Ajustar nomes visiveis:
   - Android label: `ChegaJa`.
   - iOS display name: `ChegaJa`.
   - Windows title: `ChegaJa`.
2. Android App Links: publicar/validar `assetlinks.json` para `app.chegaja.pt` e `chegaja.pt`.
3. iOS Universal Links: publicar/validar `apple-app-site-association`.
4. iOS: adicionar descricoes de galeria/fotos se KYC/anexos usarem `image_picker` com galeria.
5. macOS: adicionar descricoes de camera/microfone/localizacao se chamadas/localizacao forem mantidas.
6. Criar fallback de localizacao manual para Windows/macOS quando permissao/servico falhar.
7. Criar fallback chat-only quando WebRTC nao estiver disponivel.
8. Centralizar checks de plataforma em `PlatformCaps` e usar esse helper nas services/telas de risco.

## Correcoes P2

Melhorias depois do MVP multiplataforma:

1. Criar matriz de CI para Web, Android debug e Windows build.
2. Criar pagina de diagnostico interno por plataforma.
3. Rever Linux depois de Windows/Android/iOS/macOS.
4. Rever icones/splash/nome final em todas as plataformas.
5. Documentar setup de cada plataforma em `README.md`.

## Comandos de verificacao geral

Executar na raiz:

```bash
flutter pub get
flutter test
node --check scripts/e2e/full_ui_dual_role_e2e.js
npm run e2e:ui:dual
npm run e2e:ui:orcamento
```

Executar em `functions/`:

```bash
npm.cmd test
```

## M1 - Checklist Windows

Comandos:

```bash
flutter clean
flutter pub get
flutter config --enable-windows-desktop
flutter devices
flutter run -d windows --dart-define=DEFAULT_ROLE=cliente
flutter run -d windows --dart-define=DEFAULT_ROLE=prestador
flutter build windows --release
```

Checklist:

- [ ] App abre.
- [ ] Cliente entra.
- [ ] Prestador entra.
- [ ] Firebase inicializa.
- [ ] Auth anonimo funciona.
- [ ] Firestore carrega dados.
- [ ] Cliente cria pedido.
- [ ] Prestador ve pedido.
- [ ] Prestador aceita.
- [ ] Chat funciona.
- [ ] Pedido conclui.
- [ ] App nao crasha por push ausente.
- [ ] App nao chama PaymentSheet.
- [ ] App nao tenta renderizar `GoogleMap` nativo.
- [ ] Quando localizacao falhar, app oferece fallback manual.

Decisao para Windows:

- Push real: fallback in-app/local.
- Pagamento online: checkout/link externo.
- Mapa: `flutter_map`/OSM ou resumo textual.
- Cloud Functions: validar plugin; se falhar, gate/fallback por funcionalidade.

## M2 - Checklist Android

Comandos:

```bash
flutter doctor -v
flutter devices
flutter build apk --debug
flutter run -d android --dart-define=DEFAULT_ROLE=cliente
flutter run -d android --dart-define=DEFAULT_ROLE=prestador
```

Checklist:

- [ ] App abre.
- [ ] Auth funciona.
- [ ] Firestore funciona.
- [ ] Storage/anexos funciona.
- [ ] Cliente cria pedido.
- [ ] Prestador aceita.
- [ ] Chat funciona.
- [ ] Localizacao pede permissao.
- [ ] Upload/anexos funciona.
- [ ] Notificacoes funcionam.
- [ ] Deep link abre pedido/chat correto.
- [ ] Pedido conclui.
- [ ] Build release tem internet.
- [ ] Package id final esta alinhado com Firebase.

## M3 - Checklist iOS

Pre-requisitos:

- Mac.
- Xcode.
- CocoaPods.
- Apple Developer Account.
- Firebase app iOS configurada.
- `GoogleService-Info.plist` correto.

Comandos:

```bash
flutter doctor -v
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios --dart-define=DEFAULT_ROLE=cliente
flutter build ipa
```

Checklist:

- [ ] Bundle ID final.
- [ ] Assinatura Apple configurada.
- [ ] `GoogleService-Info.plist` correto.
- [ ] App abre no simulador.
- [ ] App abre em iPhone real.
- [ ] Auth funciona.
- [ ] Firestore funciona.
- [ ] Storage/anexos funciona.
- [ ] Localizacao funciona.
- [ ] Camera/microfone funcionam.
- [ ] Push via APNs/FCM funciona.
- [ ] Deep link `chegaja://` abre pedido/chat.
- [ ] Universal link abre pedido/chat.
- [ ] Fluxo Cliente/Prestador conclui.

## M4 - Checklist macOS

Pre-requisitos:

- Mac.
- Xcode.
- CocoaPods se necessario.
- Firebase configurado para bundle id macOS.
- Entitlements ajustados.

Comandos:

```bash
flutter config --enable-macos-desktop
flutter pub get
flutter run -d macos --dart-define=DEFAULT_ROLE=cliente
flutter build macos --release
```

Checklist:

- [ ] App abre.
- [ ] Sandbox permite rede de saida.
- [ ] Firebase inicializa.
- [ ] Auth funciona.
- [ ] Firestore funciona.
- [ ] Storage/anexos funciona.
- [ ] Chat funciona.
- [ ] Cliente cria pedido.
- [ ] Prestador aceita.
- [ ] App nao crasha por push.
- [ ] App nao chama PaymentSheet.
- [ ] App nao tenta renderizar `GoogleMap` nativo.
- [ ] Localizacao tem fallback.
- [ ] Pedido conclui.

## Proxima decisao tecnica

A sequencia recomendada depois desta auditoria:

1. Corrigir P0 minimo para M1/M2 sem mexer no fluxo web validado.
2. Rodar build Windows e corrigir crashes reais.
3. Rodar build Android debug e corrigir manifest/permissoes.
4. Preparar bundle IDs e Firebase plist para iOS/macOS quando houver Mac/Xcode.

Regra daqui para frente:

- Nao quebrar Web.
- Nao quebrar Windows.
- Nao quebrar Android.
- Preparar iOS/macOS.
- Se uma funcionalidade nao existir numa plataforma, usar fallback seguro em vez de remover a funcionalidade.
