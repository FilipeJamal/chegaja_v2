# M2.19.4 - Rota Publica por @handle

## Estado

```text
M2.19.4 - concluida
M2.19 - ativa
M2.19.5 - proximo passo
M2.18 - fechada no escopo atual
Bloco F - parcial
Bloco H - parcial
Bloco J - parcial
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo

Tornar funcional a rota publica:

```text
/p/{handle}
```

O fluxo implementado normaliza o handle, consulta
`handles/{handleNormalized}`, exige `status == active` e `role == prestador`,
obtem o `uid` e usa o `PublicProfileScreen` como tela final do perfil publico.

## Alteracoes Implementadas

Criado:

```text
lib/core/handles/public_handle_resolver.dart
lib/features/common/public_profile_by_handle_screen.dart
```

Alterado:

```text
lib/core/services/deep_link_service.dart
lib/core/navigation/app_navigator.dart
lib/app.dart
lib/features/common/perfil_publico_screen.dart
firebase.json
```

## Rota e Deep Link

`DeepLinkService` agora reconhece:

```text
/p/{handle}
chegaja://p/{handle}
?handle={handle}
```

As rotas antigas continuam preservadas:

```text
/pedido/{pedidoId}
/chat/{pedidoId}
chegaja://pedido/{pedidoId}
chegaja://chat/{pedidoId}
?pedidoId={pedidoId}
```

`ChegaJaApp` recebeu `onGenerateRoute` para abrir
`PublicProfileByHandleScreen` quando a rota for `/p/{handle}`. O app nao foi
migrado para `go_router` e nao foi criada uma segunda tela de perfil.

## Resolver de Handle

`PublicHandleResolver` consulta `handles/{handleNormalized}` como fonte de
verdade.

Resultados tratados:

```text
resolved
invalidHandle
notFound
inactive
invalidRole
invalidData
error
```

Se o handle nao existir, estiver inactive/released/blocked, tiver role
diferente de `prestador` ou dados insuficientes, a UI mostra uma mensagem
segura sem expor `uid` ou detalhes internos.

## Tela Wrapper

`PublicProfileByHandleScreen` e apenas uma tela de resolucao:

```text
loading: "A abrir perfil..."
not found: "Perfil nao encontrado"
inactive: "Este perfil nao esta disponivel"
error: "Nao foi possivel abrir este perfil"
success: PublicProfileScreen(userId: uid, role: prestador)
```

O `PublicProfileScreen` continua a ser a tela final do perfil publico.

## Privacidade

O `PublicProfileScreen` deixou de mostrar telefone por defeito.

Foi adicionado `showPublicContact`, com default `false`, para manter contacto
publico como decisao opt-in futura. Esta fase nao adicionou email, telefone,
KYC, reports, audit logs ou dados privados ao link publico.

## Firebase Hosting

`firebase.json` recebeu uma configuracao minima de Hosting SPA:

```text
public: build/web
rewrite: ** -> /index.html
```

Isto prepara refresh direto em `/p/{handle}` no Firebase Hosting. Nao foi feito
deploy.

## Testes Criados/Atualizados

Criado:

```text
test/core/public_handle_resolver_test.dart
test/features/common/public_profile_by_handle_screen_test.dart
test/app_public_handle_route_test.dart
```

Atualizado:

```text
test/core/deep_link_service_test.dart
test/features/common/perfil_publico_screen_test.dart
```

Cobertura principal:

```text
/p/{handle} parseia corretamente;
/pedido e /chat continuam intactos;
resolver retorna uid para handle active/prestador;
resolver bloqueia notFound/inactive/invalidRole/invalidData;
wrapper mostra loading, sucesso, 404, indisponivel e erro;
perfil publico nao expoe telefone por defeito.
```

## Validacoes

```text
git diff --check - passou
npm.cmd run test:scripts - passou
flutter test --no-pub test/core/deep_link_service_test.dart - passou, 6/6
flutter test --no-pub test/core/public_handle_resolver_test.dart - passou, 6/6
flutter test --no-pub test/features/common/public_profile_by_handle_screen_test.dart - passou, 6/6
flutter test --no-pub test/features/common/perfil_publico_screen_test.dart - passou, 21/21
flutter test --no-pub test/app_public_handle_route_test.dart - passou, 3/3
flutter test --no-pub - passou, 354/354
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

Observacao:

```text
O build Web manteve os avisos nao bloqueantes de Wasm dry run vindos de
dart_webrtc, ja conhecidos no projeto.
```

QA visual/headless:

```text
Nao foi criado fluxo visual novo alem da rota publica. A validacao da tela
wrapper, 404, erro, inactive e dark mode ficou coberta por widget tests, e o
build Web release passou. Sem dados reais/emulador semeado para /p/{handle},
o smoke visual real por link fica para M2.19.5/M2.19.6.
```

## Rules, Functions e Deploy

```text
Firestore Rules nao foram alteradas.
Storage Rules nao foram alteradas.
Cloud Functions nao foram alteradas.
Deploy nao foi feito.
```

## Fora do Escopo Mantido

```text
partilha social;
botao copiar link;
WhatsApp/Facebook/Instagram;
QR Code;
SEO/metatags dinamicas;
dominio customizado;
deploy;
KYC;
pagamentos;
Android fisico;
tester externo;
R/R1/M/M2.6.
```

## Proximo Passo

```text
M2.19.5 - Partilha social, copiar link e QR futuro
```
