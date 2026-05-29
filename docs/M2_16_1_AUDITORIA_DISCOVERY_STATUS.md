# M2.16.1 - Auditoria Discovery/Search de Prestadores

Data: 2026-05-29

## Estado Executivo

```text
M2.16.1: concluida
M2.16: iniciada
M2.16.2: proximo passo
M2.15: fechada no escopo atual
Bloco F: parcial
Bloco H: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

Esta fase foi documental/auditoria. Nao houve implementacao de search, nao
houve redesign de Home, nao houve alteracao de Rules, Functions ou deploy.

## Ficheiros Analisados

| Ficheiro | Responsabilidade | Estado | Risco | Acao recomendada |
| --- | --- | --- | --- | --- |
| `docs/CHEGAJA_PRODUCT_MASTER_VISION.md` | Visao-mestre de produto | Atual | M2.16 toca varias frentes | Usar como norte, mas manter escopo pequeno |
| `docs/CHEGAJA_DISCOVERY_SEARCH_PROFILE_SPEC.md` | Spec macro de discovery | Atual | Ainda era futura/generica | Detalhar como M2.16 operacional |
| `docs/CHEGAJA_TRUST_SAFETY_POLICY_DRAFT.md` | Politica base de seguranca | Atual | Search pode expor conteudo indevido | Preparar visibilidade/moderacao futura |
| `docs/M2_15_FINAL_REPORT.md` | Fecho de avaliacoes/reputacao | Atual | Reputacao pode virar ranking cedo demais | Usar rating apenas como sinal leve |
| `docs/ROADMAP_A_T_CHEGAJA.md` | Roadmap A-T | Atualizado nesta fase | M2.16 precisava virar bloco ativo | Apontar M2.16.2 como proximo |
| `lib/features/cliente/prestador_search_delegate.dart` | Search antigo de prestadores | Fragil | Le `users`, nao `prestadores`; distancia/rating incompletos | Substituir/refatorar |
| `lib/features/cliente/selecionar_prestador_screen.dart` | Selecao manual para pedido | Parcialmente forte | Logica local nao reutilizavel; busca textual limitada | Reaproveitar mapeamento em modelo comum |
| `lib/features/cliente/favoritos_screen.dart` | Lista de favoritos | Parcial | UI antiga/dark mode; sem integracao com search | Integrar em M2.16.4 |
| `lib/core/services/favorites_service.dart` | Subcolecao de favoritos | Adequado | Sem cache/index | Reaproveitar |
| `lib/features/common/perfil_publico_screen.dart` | Perfil publico unico | Forte | Exibe telefone se existir no doc | Continuar tela unica; nao duplicar |
| `lib/features/common/utils/open_public_profile.dart` | Helper de abertura de perfil | Adequado | Pouco usado em telas antigas | Reaproveitar na UI nova |
| `lib/core/models/prestador.dart` | Modelo antigo de prestador | Parcial | Espera `lastLocation` como GeoPoint, mas dados atuais podem ser Map | Nao usar sem refatorar |
| `lib/core/repositories/prestador_repo.dart` | Repo geo/filtros | Parcial/fragil | Usa `geohash` raiz, enquanto dados atuais usam `geo.geohash`; `lastLocation` mismatch | Auditar/refatorar antes de discovery |
| `lib/core/services/smart_search_service.dart` | Fuzzy search generico | Parcial | Ligado ao `PrestadorRepo` fragil; normalizacao tem mojibake em comentarios/textos | Reaproveitar ideia, nao depender sem testes |
| `firestore.rules` | Visibilidade e permissao | Atual | `prestadores` e publico; `users` e legivel por autenticados | Search deve evitar `users` como fonte publica |
| `storage.rules` | Media de perfil/portfolio | Adequado para fase atual | Media publica do prestador | Sem alteracao agora |

## Estado Atual da Pesquisa

### PrestadorSearchDelegate

Classificacao:

```text
Substituir/refatorar antes de virar discovery principal.
```

Motivos:

```text
Le users com roles.prestador == true.
Nao usa a colecao prestadores, que contem os dados publicos reais.
Nao abre PublicProfileScreen a partir da Home.
O resultado retornado pelo showSearch nao e usado.
Rating vem de campo legado `rating`, nao de ratingAvg/ratingCount.
Distancia esta incompleta porque os dados de localizacao estao em prestadores.
Nao tem testes dedicados.
```

Conclusao:

```text
Nao construir M2.16 em cima deste delegate sem refatoracao.
```

### Pesquisa em SelecionarPrestadorScreen

Pontos fortes:

```text
Le prestadores.
Usa ratingAvg/ratingCount.
Calcula distancia quando ha coordenadas.
Abre PublicProfileScreen.
Permite favoritos.
Tem ordenacao balanceada/proximidade/avaliacao.
```

Limitacoes:

```text
E acoplada ao fluxo de pedido.
Busca textual nao usa servicosNomes/categories.
Nao cria uma experiencia de discovery livre.
Nao tem modelo publico reutilizavel.
```

Conclusao:

```text
Serve como referencia para M2.16.2/3, mas nao deve ser copiada inteira.
```

## Estado Atual dos Dados

### Colecao users

Campos relevantes encontrados:

```text
activeRole
roles
displayName/name
dados de conta e subcolecoes privadas
favorites
fcmTokens
notifications
```

Problema:

```text
Nao e a fonte correta para discovery publico.
```

### Colecao prestadores

Campos relevantes encontrados:

```text
nome/displayName/name
photoUrl/fotoUrl/avatarUrl
bio/descricao
city/cidade
state/province/region
country/pais
countryCode
radiusKm
servicosNomes
categories
servicos
portfolioUrls
ratingAvg
ratingCount
ratingSum
isOnline
available
lastLocation
geo.geohash
geo.geopoint
```

Lacunas:

```text
handle
isPublic
isSearchable
moderationStatus
suspendedAt/blockedAt
searchTerms
serviceKeywords
portfolioPreviewUrls separado
```

Risco:

```text
prestadores tem read publico. Qualquer campo privado futuro neste documento
ficara exposto se nao houver separacao.
```

## Decisao de Arquitetura Recomendada

Para M2.16 inicial:

```text
Usar prestadores como fonte de dados publica existente.
Criar modelo/mapper com whitelist de campos publicos.
Nao usar users como fonte principal.
Nao criar publicProfiles ainda.
Preparar migracao futura para publicProfiles/providerSearchIndex.
```

Para M2.16.2:

```text
Criar modelo testavel de perfil pesquisavel.
Centralizar normalizacao textual.
Centralizar criterio de perfil pesquisavel.
Centralizar validacao de rating.
Criar testes unitarios antes de UI.
```

Para futuro:

```text
Migrar para publicProfiles ou providerSearchIndex quando houver Trust & Safety,
admin/backoffice, KYC e moderacao suficientes.
```

## Regras de Visibilidade

Hoje:

```text
Nao ha isPublic/isSearchable/moderationStatus.
```

M2.16 deve iniciar com regra minima local:

```text
prestador precisa ter dados minimos de perfil;
rating so aparece se ratingCount > 0 e ratingAvg valido;
cards de pesquisa nao mostram telefone/email/localizacao precisa;
comentarios publicos continuam fora.
```

Futuro:

```text
isPublic == true
isSearchable == true
moderationStatus == approved
suspendedAt/blockedAt ausentes
servicos proibidos filtrados
```

## Home Cliente

Estado atual:

```text
Home Cliente ja tem hero e catalogo de servicos.
Hero abre PrestadorSearchDelegate.
Catalogo de servicos ja tem pesquisa propria por servico.
Stories existem.
Ainda ha muito peso de cards/categorias.
```

Recomendacao:

```text
Nao redesenhar a Home em M2.16.1/2.
M2.16.3 cria a UI de pesquisa manual.
M2.16.5 integra sugestoes compactas na Home.
```

## Favoritos

Estado:

```text
Favoritos existem e usam users/{uid}/favorites/{prestadorId}.
FavoritosScreen busca prestadores e abre perfil publico.
SelecionarPrestadorScreen ja permite favoritar.
```

Recomendacao:

```text
Integrar favoritos na M2.16.4 depois da UI de search.
Nao mudar o modelo de favoritos agora.
```

## Ranking Inicial

Permitido:

```text
match textual por nome, servico/categoria, bio e cidade;
rating leve como exibicao/desempate quando valido;
proximidade apenas quando dados forem consistentes;
estado vazio claro.
```

Fora:

```text
ranking complexo
ranking pago
patrocinados
ML
disponibilidade como promessa
servicos concluidos sem fonte consolidada
```

## Riscos Encontrados

```text
PrestadorSearchDelegate usa users e nao deve ser a base nova.
PrestadorRepo tem possivel mismatch entre `geohash` raiz e `geo.geohash`.
Prestador model espera lastLocation como GeoPoint, mas LocationService escreve Map em lastLocation e GeoPoint em geo.geopoint.
prestadores e publicamente legivel; campos privados futuros nao devem viver ali.
Nao ha campos de visibilidade/moderacao.
FavoritosScreen ainda tem UI antiga e algum hardcoded visual.
Home Cliente tem pesquisa de servicos separada da pesquisa de prestadores.
```

## Testes Necessarios

```text
ProviderSearchProfile mapeia campos legados e atuais.
Normalizacao remove acentos, simbolos e espacos duplicados.
Busca por nome encontra prestador.
Busca por servico/categoria encontra prestador.
Busca por cidade/pais encontra prestador.
Perfil sem dados minimos nao aparece.
Rating invalido nao aparece.
Cards de search nao exibem telefone/email.
Abre PublicProfileScreen via openPublicProfile.
Favoritar/desfavoritar no contexto de search.
Dark mode.
Responsividade mobile/tablet/desktop.
```

## Proximo Passo

```text
M2.16.2 - Modelo/normalizacao de perfil pesquisavel
```

Escopo recomendado da M2.16.2:

```text
criar modelo/helper puro e testavel;
usar prestadores como fonte inicial;
mapear apenas campos publicos permitidos;
criar testes unitarios;
nao mexer em UI grande ainda;
nao alterar Rules/Functions.
```

