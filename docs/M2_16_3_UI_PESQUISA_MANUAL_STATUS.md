# M2.16.3 - UI de Pesquisa Manual de Prestadores

Data: 2026-05-29

## Estado

```text
M2.16.3: concluida
M2.16: em andamento
M2.16.4: proximo passo - Integracao com perfil publico, favoritos e pedido
M2.15: fechada no escopo atual
Bloco F: parcial
Bloco H: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Resultado

A M2.16.3 criou a primeira UI real de pesquisa manual de prestadores, usando a
camada pura criada na M2.16.2.

Ficheiros principais:

```text
lib/features/cliente/discovery/provider_search_screen.dart
lib/features/cliente/discovery/widgets/provider_search_card.dart
lib/features/cliente/discovery/widgets/provider_search_empty_state.dart
```

Testes criados:

```text
test/features/cliente/discovery/provider_search_card_test.dart
test/features/cliente/discovery/provider_search_screen_test.dart
```

## Comportamento

`ProviderSearchScreen` permite ao Cliente pesquisar prestadores por:

```text
nome
servico
categoria
cidade
pais
```

O fluxo usa:

```text
ProviderSearchProfile.fromPrestadorDoc
ProviderSearchNormalizer
matchesProviderSearch
scoreProviderSearch
```

Fonte inicial:

```text
prestadores
```

Nao usa `users` como fonte principal.

## UI

A tela tem:

```text
campo de pesquisa
estado inicial orientativo
loading
erro
estado vazio
lista de resultados
cards compactos
```

Cada card mostra apenas dados publicos:

```text
foto/avatar ou inicial
nome
servicos principais
cidade/pais
rating leve quando valido
preview leve de portfolio quando existir
```

Nao mostra:

```text
telefone
email
endereco
localizacao precisa
ratingSum
KYC
documentos
notas internas
comentarios publicos
disponibilidade como promessa
```

## Abertura de Perfil

Tocar num card abre o perfil publico unico do prestador com `openPublicProfile`:

```text
userId = profile.id
role = prestador
initialName = profile.displayName
initialPhotoUrl = profile.photoUrl
```

Nao foi criada tela duplicada de perfil publico.

## Integracao na Home Cliente

A Home Cliente foi integrada de forma minima:

```text
CTA "Pesquisar prestadores" abre ProviderSearchScreen
```

O `PrestadorSearchDelegate` antigo foi mantido no codigo para evitar remocao
prematura, mas deixou de ser usado pelo CTA principal da Home Cliente.

## Decisao de Dados

A M2.16.3 carrega ate 80 documentos de `prestadores` e aplica filtro/score no
cliente.

Decisao:

```text
aceitavel para a primeira UI manual
providerSearchIndex/search server-side ficam para futuro
ranking complexo continua fora
```

## Testes

Cobertura adicionada:

```text
card mostra nome, servicos, cidade/pais e rating valido
card oculta rating invalido
card nao mostra telefone/email
tap no card chama callback
dark mode renderiza sem erro
screen mostra estado inicial
screen mostra loading
screen mostra erro
query por nome mostra resultado
query por servico mostra resultado
query por cidade mostra resultado
query sem resultado mostra vazio
tap no resultado chama abertura de perfil
screen usa prestadores e nao users como fonte Firestore
CTA da Home chama callback dedicado
```

## Validacoes Executadas

```text
git diff --check - passou
npm.cmd run test:scripts - passou
flutter test --no-pub test/features/cliente/discovery/provider_search_card_test.dart test/features/cliente/discovery/provider_search_screen_test.dart - passou
flutter test --no-pub test/features/cliente/discovery/provider_search_card_test.dart test/features/cliente/discovery/provider_search_screen_test.dart test/features/cliente/discovery/provider_search_profile_test.dart test/features/cliente/discovery/provider_search_normalizer_test.dart test/features/cliente/discovery/provider_search_matcher_test.dart - passou
flutter test --no-pub test/features/cliente/widgets/cliente_home_components_test.dart test/features/cliente/cliente_home_redesign_test.dart - passou
flutter test --no-pub - passou
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

QA visual local:

```text
build Web estatico servido em http://127.0.0.1:5174
verificacao headless abriu /?role=cliente
screenshot_bytes=121464
channel_stdev=36.86,27.34,29.49
console_errors=0
```

Observacao:

```text
O plugin Browser do Codex falhou ao inicializar neste ambiente. Foi usado
fallback local headless com Playwright para confirmar renderizacao nao vazia.
```

## Fora do Escopo Mantido

```text
redesign completo da Home Cliente
sugestoes compactas na Home
favoritos dentro da search
botao pedir servico dentro da search
partilha de perfil
handle publico real
link publico
QR Code
publicProfiles
providerSearchIndex
search server-side avancado
ranking complexo
patrocinados
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

## Riscos Remanescentes

```text
Filtro client-side com limit 80 e suficiente para a primeira versao, mas nao escala.
Ainda nao existem isPublic/isSearchable/moderationStatus em prestadores.
Favoritos, pedido direto e partilha ficam para fases seguintes.
PrestadorSearchDelegate antigo ainda existe e deve ser removido/refatorado depois se nao houver uso.
```

## Decisao Final

A M2.16.3 fica concluida como primeira UI funcional de pesquisa manual. A
proxima fase deve ligar melhor discovery com favoritos, perfil publico e pedido,
sem transformar ainda a Home Cliente inteira.

Proximo passo:

```text
M2.16.4 - Integracao com perfil publico, favoritos e pedido
```
