# M2.16.5 - Sugestoes Compactas na Home Cliente

Data: 2026-05-29

## Estado

```text
M2.16.5: concluida
M2.16: em andamento
M2.16.6: proximo passo - Testes, E2E, QA visual e documentacao final da M2.16
M2.15: fechada no escopo atual
Bloco F: parcial
Bloco H: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Resultado

A Home Cliente passou a ter uma seccao compacta de discovery:

```text
Prestadores para conhecer
```

Objetivo:

```text
aproximar a Home da experiencia de discovery;
dar acesso visual a poucos perfis de prestadores;
manter a pesquisa completa acessivel;
reduzir dependencia exclusiva do catalogo grande de servicos.
```

## Implementacao

Ficheiros criados:

```text
lib/features/cliente/discovery/widgets/provider_suggestions_section.dart
lib/features/cliente/discovery/widgets/provider_suggestion_compact_card.dart
test/features/cliente/widgets/provider_suggestions_section_test.dart
```

Ficheiros atualizados:

```text
lib/features/cliente/cliente_home_screen.dart
test/features/cliente/cliente_home_redesign_test.dart
docs/M2_16_DISCOVERY_SEARCH_SPEC.md
docs/ROADMAP_A_T_CHEGAJA.md
```

## Fonte de Dados

A seccao usa:

```text
colecao prestadores
ProviderSearchProfile.fromPrestadorDoc
ProviderSearchProfile.isSearchableLocal
ratingAvg/ratingCount apenas quando hasValidRating
```

Nao usa `users` como fonte principal.

Primeira versao:

```text
queryLimit = 16
visibleLimit = 6
ordenacao local simples por completude visual/perfil e rating leve como desempate
```

Isto nao e ranking complexo nem ranking pago.

## UI

Cada card compacto mostra apenas dados publicos:

```text
avatar/foto ou inicial
nome
servico/categoria principal
cidade/pais
rating leve quando valido
indicacao discreta de portfolio quando existe
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
comentarios publicos
disponibilidade como promessa
```

## Acoes

Tocar num card abre o perfil publico unico:

```text
openPublicProfile
role = prestador
userId = profile.id
initialName = profile.displayName
initialPhotoUrl = profile.photoUrl
```

O botao `Pesquisar prestadores` abre a pesquisa completa ja criada na M2.16.3.

## Estados

A seccao trata:

```text
loading discreto
erro discreto sem quebrar a Home
sem sugestoes escondendo a seccao
dark mode com ColorScheme/tokens existentes
```

## Fora do Escopo Mantido

```text
redesign completo da Home Cliente
remocao do catalogo de servicos
ranking complexo
patrocinados
destaque pago
pedido direto
favoritos dentro desta seccao
link publico
@handle real
partilha social
publicProfiles
providerSearchIndex
search server-side
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

## Validacoes Executadas

Resultado:

```text
git diff --check - passou
npm.cmd run test:scripts - passou
flutter test --no-pub test/features/cliente/widgets/provider_suggestions_section_test.dart - passou
flutter test --no-pub test/features/cliente/widgets/cliente_home_components_test.dart - passou
flutter test --no-pub test/features/cliente/cliente_home_redesign_test.dart - passou
flutter test --no-pub - passou, 248/248
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

QA visual:

```text
Browser plugin integrado falhou ao conectar neste ambiente.
Fallback headless abriu http://127.0.0.1:5174/?role=cliente.
screenshot: C:\Users\Jamal\AppData\Local\Temp\chegaja-m2165-home.png
screenshot_bytes: 219851
console_errors: 0
hasHomeText: true
```

Observacao:

```text
build Web manteve avisos conhecidos do dry run wasm em dart_webrtc, sem falhar o build.
E2E nao foi executado porque a fase nao alterou fluxo de pedido.
```

## Riscos Remanescentes

```text
Ainda nao ha isPublic/isSearchable/moderationStatus em prestadores.
A selecao local usa apenas completude visual/perfil e rating leve como desempate.
Nao ha ranking inteligente, proximidade confiavel ou patrocinados nesta fase.
Search server-side/providerSearchIndex ficam para futuro.
```

## Decisao Final

A M2.16.5 fica concluida como melhoria compacta de discovery na Home Cliente,
sem transformar a Home inteira e sem criar promessas de ranking, proximidade ou
verificacao.

Proximo passo:

```text
M2.16.6 - Testes, E2E, QA visual e documentacao final da M2.16
```
