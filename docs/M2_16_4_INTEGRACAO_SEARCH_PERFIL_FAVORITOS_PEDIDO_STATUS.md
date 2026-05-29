# M2.16.4 - Integracao Search, Perfil, Favoritos e Pedido

Data: 2026-05-29

## Estado

```text
M2.16.4: concluida
M2.16: em andamento
M2.16.5: proximo passo - Sugestoes compactas na Home Cliente
M2.15: fechada no escopo atual
Bloco F: parcial
Bloco H: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Resultado

A pesquisa manual continua a abrir o perfil publico unico do prestador e agora
permite favoritar/desfavoritar prestadores diretamente nos resultados.

Ficheiros principais:

```text
lib/features/cliente/discovery/provider_search_screen.dart
lib/features/cliente/discovery/widgets/provider_search_card.dart
test/features/cliente/discovery/provider_search_card_test.dart
test/features/cliente/discovery/provider_search_screen_test.dart
```

## Perfil Publico

O fluxo de abertura de perfil foi preservado:

```text
openPublicProfile
userId = profile.id
role = prestador
initialName = profile.displayName
initialPhotoUrl = profile.photoUrl
```

Nao foi criada tela duplicada de perfil publico.

## Favoritos

`ProviderSearchCard` passou a aceitar:

```text
isFavorite
onToggleFavorite
favoriteLoading
```

Comportamento:

```text
coracao contorno quando o prestador nao esta nos favoritos
coracao preenchido quando o prestador esta nos favoritos
loading bloqueia duplo clique durante a operacao
tap no coracao nao abre o perfil por acidente
tap no restante do card continua abrindo o perfil
erro mostra SnackBar simples
```

`ProviderSearchScreen` passou a aceitar injecoes opcionais para testes:

```text
favoriteIdsStream
onToggleFavorite
enableFavoriteActions
```

No runtime, a screen usa `FavoritesService.instance.getFavoritesStream()` e
`FavoritesService.instance.toggleFavorite()` quando nao ha injecao.

## Pedido Direto

Pedido direto a partir da pesquisa foi auditado e adiado.

Motivo:

```text
NovoPedidoScreen ainda parte de servico/categoria e depois permite escolher
prestador pelo fluxo existente de selecao. Forcar prestador pre-selecionado a
partir da discovery exigiria refatoracao maior de estado inicial, servico,
categoria e criacao do pedido.
```

Decisao:

```text
nao adicionar botao "Pedir servico" nesta fase
manter a pesquisa focada em ver perfil e guardar favorito
retomar pedido direto quando houver suporte limpo para prestador pre-selecionado
```

## Dados Privados

Os cards continuam sem mostrar:

```text
telefone
email
endereco
localizacao precisa
documentos
KYC
ratingSum
notas internas
comentarios publicos
```

## Testes

Cobertura adicionada/atualizada:

```text
card mostra botao de favorito quando callback existe
favorito false mostra coracao de contorno
favorito true mostra coracao preenchido
tap no favorito chama callback sem abrir perfil
loading bloqueia toggle favorito
screen mostra estado favorito correto
toggle favorito chama callback injetado
erro ao favoritar mostra feedback simples
pesquisa continua funcionando por nome/servico/cidade
card sem favorito continua abrindo perfil
```

## Validacoes Executadas

Resultado:

```text
git diff --check - passou
npm.cmd run test:scripts - passou
flutter test --no-pub test/features/cliente/discovery/provider_search_card_test.dart - passou
flutter test --no-pub test/features/cliente/discovery/provider_search_screen_test.dart - passou
flutter test --no-pub - passou, 239/239
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

Observacao:

```text
build Web manteve avisos conhecidos do dry run wasm em dart_webrtc, sem falhar o build.
E2E nao foi executado porque a fase nao alterou fluxo de pedido.
```

## Fora do Escopo Mantido

```text
redesign completo da Home Cliente
sugestoes compactas na Home
ranking complexo
patrocinados
pagamento/destaque
handle publico
link publico
QR Code
partilhar perfil
publicProfiles
providerSearchIndex
Trust & Safety implementation
moderacao
denuncias
KYC
pagamentos
Firestore Rules
Storage Rules
Cloud Functions
deploy
Android fisico
tester externo
fechar R
fechar M
fechar R1
fechar M2.6
```

## Decisao Final

A M2.16.4 fica concluida como integracao controlada entre pesquisa manual,
perfil publico e favoritos. Pedido direto foi adiado com motivo tecnico para
evitar refatoracao grande fora do escopo.

Proximo passo:

```text
M2.16.5 - Sugestoes compactas na Home Cliente
```
