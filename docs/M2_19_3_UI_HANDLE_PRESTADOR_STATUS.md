# M2.19.3 - UI de @handle no Perfil do Prestador

## Estado

```text
M2.19.3 - concluida
M2.19 - ativa
M2.19.4 - proximo passo
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

Criar a primeira experiencia visual para o prestador escolher e editar o seu
`@handle`, usando a base tecnica criada na M2.19.2:

```text
HandleNormalizer
HandleValidator
HandleService.checkAvailability
HandleService.reserveProviderHandle
prestadores/{uid}.handle
prestadores/{uid}.handleDisplay
prestadores/{uid}.handleUpdatedAt
```

Esta fase nao criou rota publica, partilha social, QR Code, SEO/metatags,
deploy, KYC ou pagamentos.

## Alteracoes Implementadas

### PrestadorHandleSection

Criado:

```text
lib/features/prestador/widgets/prestador_handle_section.dart
```

A seccao mostra:

```text
Titulo "Pagina publica"
texto curto explicando o @handle
campo com prefixo visual @
validacao local
botao "Verificar disponibilidade"
botao "Guardar @handle"
estado do handle atual
preview do futuro link publico
feedback inline
SnackBar de sucesso/erro
loading durante check/reserva
```

O preview usa:

```text
chegaja-ac88d.web.app/p/{handle}
```

mas deixa claro:

```text
Este sera o teu link publico quando a partilha for ativada.
```

Isto evita prometer que a rota publica ja funciona nesta fase.

### Integracao no PrestadorPerfilScreen

Alterado:

```text
lib/features/prestador/prestador_perfil_screen.dart
```

O perfil do prestador agora:

```text
le handle/handleDisplay do documento prestadores/{uid}
mostra a seccao "Pagina publica"
usa HandleService.instance.checkAvailability
usa HandleService.instance.reserveProviderHandle
atualiza estado local depois de reserva bem sucedida
mantem o save normal do perfil separado do save de @handle
```

### PublicProfileScreen

Alterado:

```text
lib/features/common/perfil_publico_screen.dart
```

O perfil publico mostra `@handle` abaixo do nome quando o campo existe no
documento publico do prestador.

Nao foi criada rota por handle. O perfil publico continua a abrir por `userId`.

### ProviderSearchCard

Alterado:

```text
lib/features/cliente/discovery/widgets/provider_search_card.dart
```

O card de discovery mostra `@handle` de forma discreta quando
`ProviderSearchProfile.handle` existe.

Como a M2.19.2 ja incluiu `handle` nos termos pesquisaveis, isto prepara a
leitura social sem alterar a regra de discovery.

## Validacao Local

A UI valida localmente antes de chamar Function:

```text
3 a 30 caracteres
apenas letras, numeros, ponto, underline e hifen
sem separador no inicio/fim
sem separadores repetidos
handles reservados bloqueados
TrustSafetyClassifier bloqueia handles proibidos
```

Mensagens ao utilizador sao seguras e nao expoem a lista interna de termos.

## Testes Criados/Atualizados

Criado:

```text
test/features/prestador/prestador_handle_section_test.dart
```

Atualizados:

```text
test/features/common/perfil_publico_screen_test.dart
test/features/cliente/discovery/provider_search_card_test.dart
```

Cobertura principal:

```text
mostra handle atual;
mostra prefixo @;
mostra preview de link publico em preparacao;
valida handle curto;
valida caracteres invalidos;
bloqueia handle reservado;
verificar disponibilidade chama callback;
resultado disponivel mostra mensagem positiva;
resultado indisponivel mostra mensagem segura;
guardar chama callback;
loading bloqueia duplo clique;
erro de reserva mostra feedback seguro;
dark mode renderiza;
PublicProfileScreen mostra @handle quando existe;
ProviderSearchCard mostra @handle quando existe.
```

## Validacoes

```text
git diff --check - passou
npm.cmd run test:scripts - passou
flutter test --no-pub test/features/prestador/prestador_handle_section_test.dart - passou, 8/8
flutter test --no-pub test/features/common/perfil_publico_screen_test.dart - passou, 20/20
flutter test --no-pub test/features/cliente/discovery/provider_search_card_test.dart - passou, 10/10
flutter test --no-pub test/features/prestador/prestador_perfil_portfolio_test.dart - passou, 6/6
flutter test --no-pub - passou, 336/336
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

Observacao:

```text
O build Web manteve avisos nao bloqueantes de Wasm dry run vindos de dart_webrtc,
ja conhecidos no projeto.
```

QA visual/browser:

```text
A M2.19.3 nao exigia E2E/QA visual porque nao criou rota publica nem alterou
fluxo principal Cliente/Prestador. Foi tentado um smoke rapido no in-app
browser local, mas o runtime do plugin Browser falhou ao preparar assets do
kernel no ambiente atual. A validacao da fase ficou coberta por widget tests
focados, Flutter completo e build Web release.
```

## Rules e Functions

Nao foram alteradas nesta fase.

A M2.19.3 usa as callables ja criadas na M2.19.2:

```text
handle_checkAvailability
handle_reserveProviderHandle
```

## Fora do Escopo Mantido

```text
rota publica /p/{handle};
resolver handle para uid;
Firebase Hosting rewrite;
partilha WhatsApp/Facebook/Instagram;
copiar link;
QR Code;
SEO/metatags;
deploy;
KYC;
pagamentos;
Android fisico;
tester externo;
fechar R;
fechar R1;
fechar M;
fechar M2.6.
```

## Riscos Remanescentes

```text
rota publica /p/{handle} ainda nao existe;
link mostrado e apenas preview em preparacao;
PublicProfileScreen ainda pode precisar de revisao futura de contacto publico;
Hosting rewrite para refresh direto ainda nao existe;
SEO/social preview real continua limitado por Flutter Web SPA;
politica definitiva de troca/liberacao de handles antigos continua futura.
```

## Proximo Passo

```text
M2.19.4 - Rota publica/deep link por @handle
```
