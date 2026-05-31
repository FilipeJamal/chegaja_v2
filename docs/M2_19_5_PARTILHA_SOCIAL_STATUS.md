# M2.19.5 - Partilha Social, Copiar Link e QR Futuro

## Estado

```text
M2.19.5 - concluida
M2.19 - ativa
M2.19.6 - proximo passo
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

Adicionar acoes simples e seguras para o prestador e clientes partilharem o
perfil publico criado nas fases anteriores:

```text
copiar link publico;
abrir partilha por WhatsApp;
abrir partilha por Facebook;
orientar Instagram como copiar link;
documentar QR Code como futuro.
```

## Alteracoes Implementadas

Criado:

```text
lib/core/services/public_profile_link_service.dart
lib/features/common/widgets/public_profile_share_actions.dart
```

Alterado:

```text
lib/features/prestador/widgets/prestador_handle_section.dart
lib/features/common/perfil_publico_screen.dart
docs/M2_19_PUBLIC_LINK_HANDLE_SPEC.md
docs/ROADMAP_A_T_CHEGAJA.md
```

## PublicProfileLinkService

O link publico ficou centralizado em `PublicProfileLinkService`.

Funcoes principais:

```text
publicPathForHandle(handle) -> /p/{handle}
publicUrlForHandle(handle) -> https://chegaja-ac88d.web.app/p/{handle}
displayUrlForHandle(handle) -> chegaja-ac88d.web.app/p/{handle}
shareTextForProvider(...)
whatsAppShareUri(...)
facebookShareUri(...)
```

O base URL usado nesta fase e:

```text
https://chegaja-ac88d.web.app
```

Dominio customizado continua futuro.

## PublicProfileShareActions

Criado widget reutilizavel para acoes de partilha:

```text
Copiar link
WhatsApp
Facebook
instrucao para Instagram
```

As acoes sao testaveis por callbacks injetaveis:

```text
onCopyLink
onOpenWhatsApp
onOpenFacebook
```

Em runtime, quando nao ha callback injetado:

```text
Copiar link usa Clipboard.setData.
WhatsApp usa https://wa.me/?text=...
Facebook usa https://www.facebook.com/sharer/sharer.php?u=...
```

Se uma abertura externa falhar, a UI tenta copiar o link como fallback.

## Perfil do Prestador

`PrestadorHandleSection` agora mostra o link publico real quando o prestador ja
tem handle:

```text
chegaja-ac88d.web.app/p/{handle}
```

O texto "link publico em preparacao" deixou de aparecer quando a rota ja esta
funcional. Sem handle guardado, a UI continua a orientar o prestador a escolher
e guardar um `@handle`.

## Perfil Publico

`PublicProfileScreen` mostra acoes de partilha apenas quando:

```text
role == prestador
handle existe
handle e valido
```

Cliente sem perfil de prestador e prestador sem handle nao veem acoes de
partilha. A partilha nao mostra telefone, email, KYC, reports, audit logs,
"verificado", "certificado", "garantido" ou promessas de pagamento seguro.

## WhatsApp, Facebook, Instagram e QR

Implementado:

```text
WhatsApp via https://wa.me/?text=...
Facebook via https://www.facebook.com/sharer/sharer.php?u=...
Instagram tratado como copiar link e colar na bio, story ou mensagem.
```

Ficou fora:

```text
SDK de Facebook;
SDK de Instagram;
partilha nativa com nova dependencia;
QR Code real;
SEO/metatags dinamicas;
dominio customizado;
analytics de partilha.
```

## Testes Criados/Atualizados

Criado:

```text
test/core/public_profile_link_service_test.dart
test/features/common/widgets/public_profile_share_actions_test.dart
```

Atualizado:

```text
test/features/prestador/prestador_handle_section_test.dart
test/features/common/perfil_publico_screen_test.dart
```

Cobertura principal:

```text
gera path /p/{handle};
gera URL absoluta;
gera texto de partilha seguro;
rejeita handle invalido;
gera URIs de WhatsApp/Facebook;
widget mostra copiar/WhatsApp/Facebook;
callbacks sao chamados;
handle ausente nao renderiza acoes;
PrestadorHandleSection mostra link real e copia link;
PublicProfileScreen mostra partilha so para prestador com handle.
```

## Validacoes

```text
git diff --check - passou
npm.cmd run test:scripts - passou
flutter test --no-pub test/core/public_profile_link_service_test.dart - passou, 5/5
flutter test --no-pub test/features/common/widgets/public_profile_share_actions_test.dart - passou, 5/5
flutter test --no-pub test/features/common/perfil_publico_screen_test.dart - passou, 25/25
flutter test --no-pub test/features/prestador/prestador_handle_section_test.dart - passou, 10/10
flutter test --no-pub - passou, 370/370
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

Observacao:

```text
O build Web manteve avisos nao bloqueantes de Wasm dry run vindos de
dart_webrtc, ja conhecidos no projeto.
```

QA visual/headless:

```text
Nao foi executado E2E/QA visual dedicado porque a fase adicionou acoes de
partilha testadas por widget tests e nao alterou fluxo principal Cliente/
Prestador. O build Web release passou.
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
QR Code real;
SEO/metatags dinamicas;
dominio customizado;
Firebase Dynamic Links;
App Links/Universal Links reais;
partilha nativa com nova dependencia;
analytics de partilha;
KYC;
pagamentos;
Android fisico;
tester externo;
R/R1/M/M2.6.
```

## Proximo Passo

```text
M2.19.6 - Testes, E2E, QA visual e documentacao final
```
