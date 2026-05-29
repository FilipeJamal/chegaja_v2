# M2.16.2 - Modelo e Normalizacao de Perfil Pesquisavel

Data: 2026-05-29

## Estado

```text
M2.16.2: concluida
M2.16: em andamento
M2.16.3: proximo passo - UI de pesquisa manual estilo Instagram
M2.15: fechada no escopo atual
Bloco F: parcial
Bloco H: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Decisao

A M2.16.2 criou a base pura e testavel para a pesquisa manual de prestadores,
sem implementar UI nova e sem ligar a camada nova ao fluxo da Home Cliente.

Decisao tecnica:

```text
Fonte inicial: prestadores
Fonte principal rejeitada: users
publicProfiles/providerSearchIndex: futuro
UI de pesquisa: M2.16.3
Home Cliente: fase posterior da M2.16
```

Motivo:

```text
prestadores ja alimenta PublicProfileScreen, favoritos, selecao de prestador,
portfolio, area e reputacao leve.
users mistura conta/dados privados e nao tem portfolio/localizacao/rating
confiaveis para discovery.
publicProfiles/providerSearchIndex continuam desejaveis no futuro, mas seriam
escopo maior antes de validar a pesquisa manual.
```

## Ficheiros Criados

```text
lib/features/cliente/discovery/provider_search_profile.dart
lib/features/cliente/discovery/provider_search_normalizer.dart
lib/features/cliente/discovery/provider_search_matcher.dart
test/features/cliente/discovery/provider_search_profile_test.dart
test/features/cliente/discovery/provider_search_normalizer_test.dart
test/features/cliente/discovery/provider_search_matcher_test.dart
```

## Modelo Criado

`ProviderSearchProfile` representa apenas dados publicos e seguros para
discovery/search:

```text
id
displayName
photoUrl
bio
city
state
country
services
categories
portfolioPreviewUrls
ratingAvg
ratingCount
searchTerms
latitude/longitude opcionais
handle opcional/futuro
```

Campos privados nao entram no modelo:

```text
telefone
email
address
privateContacts
fcmTokens
KYC/documentos
payment/admin
ratingSum
notas internas de moderacao
```

## Normalizacao

`ProviderSearchNormalizer` normaliza texto para a pesquisa futura:

```text
lowercase
remocao de acentos
remocao de pontuacao/simbolos
normalizacao de espacos
deduplicacao de termos
preparacao simples para @handle futuro
```

Exemplo:

```text
"Confeiteira de Aniversario" -> "confeiteira de aniversario"
"@Meu-Perfil" -> "meu perfil"
```

## Matcher

`matchesProviderSearch` e `scoreProviderSearch` permitem procura textual pura
em:

```text
nome
servicos
categorias
bio
cidade
estado
pais
searchTerms calculados
```

Regras:

```text
query vazia ou curta nao retorna match
acentos e caixa nao impedem resultado
nome pontua acima de bio
servico/categoria pontuam acima de bio
rating leve pode desempatar, mas nao supera match textual principal
```

## Rating

Rating so e considerado valido quando:

```text
ratingCount > 0
ratingAvg >= 1
ratingAvg <= 5
```

`ratingSum` nao e usado no modelo de search nem na UI futura.

## Testes

Foram criados testes unitarios para:

```text
mapper de campos atuais e legados
whitelist de dados publicos
remocao de URLs vazios/duplicados
rating valido/invalido
regra local de perfil pesquisavel
normalizacao textual
match por nome/servico/categoria/cidade
score simples sem ranking complexo
```

## Fora do Escopo Mantido

```text
UI de pesquisa
redesign da Home Cliente
substituir PrestadorSearchDelegate
cards compactos de prestador
favoritos na search
abrir PublicProfileScreen pela nova search
publicProfiles
providerSearchIndex
handle publico real
link publico
partilha social
Trust & Safety implementation
moderacao
denuncias
KYC
pagamentos
ranking complexo
patrocinados
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

A M2.16.2 fica concluida como base de dados/modelo para a pesquisa manual. A
proxima fase deve usar esta camada para construir a primeira UI de discovery,
sem recuperar o `PrestadorSearchDelegate` antigo como base principal.

Proximo passo:

```text
M2.16.3 - UI de pesquisa manual estilo Instagram
```
