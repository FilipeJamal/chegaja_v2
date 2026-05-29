# M2.16 - Pesquisa Manual e Discovery de Prestadores

Data: 2026-05-29

## Estado

```text
M2.16: iniciada
M2.16.1: concluida - spec e auditoria da pesquisa manual/discovery
M2.16.2: concluida - modelo e normalizacao de perfil pesquisavel
M2.16.3: proximo passo - UI de pesquisa manual estilo Instagram
M2.15: fechada no escopo atual
Bloco F: parcial
Bloco H: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Objetivo

Permitir que o Cliente encontre prestadores manualmente, como numa pesquisa de
perfil social, sem depender apenas do matching automatico de pedidos.

O Cliente deve conseguir pesquisar por:

```text
nome
handle futuro
categoria
servico
cidade
pais
palavras relacionadas
```

E depois abrir o perfil publico do prestador, ver foto, bio, portfolio,
servicos, area atendida e reputacao leve.

## Principios

```text
1. PublicProfileScreen continua a ser a tela unica de perfil publico.
2. A pesquisa nao deve expor dados privados.
3. A primeira versao deve ser simples, testavel e segura.
4. Ranking complexo fica fora da M2.16.
5. Reputacao pode aparecer como sinal leve, nunca como certificacao.
6. Trust & Safety futuro deve ser previsto desde o modelo.
7. Dados publicos, contacto privado, KYC e moderacao devem ficar separados no futuro.
```

## Estado Atual Confirmado

### PrestadorSearchDelegate

Ficheiro:

```text
lib/features/cliente/prestador_search_delegate.dart
```

Estado:

```text
Existe e e chamado na Home Cliente.
Le a colecao users.
Filtra por roles.prestador == true.
Pesquisa por displayName e servicos.
Tem filtros de relevancia, rating e distancia.
Retorna PrestadorSearchResult para o caller.
```

Limitacoes:

```text
O resultado do showSearch na Home Cliente nao e aproveitado.
A pesquisa nao abre perfil publico diretamente.
O delegate le users, mas perfil publico, portfolio, localizacao, raio e rating vivem em prestadores.
O proprio codigo tem comentarios a admitir que o ideal seria prestadores/publicProfile.
Ordenacao por distancia e incompleta, porque as coordenadas nao estao em users.
Usa rating legado de users, nao ratingAvg/ratingCount autoritativos.
Nao tem testes dedicados.
```

Decisao:

```text
Nao evoluir PrestadorSearchDelegate como base principal da M2.16.
Classificacao: substituir/refatorar.
Pode servir apenas como referencia de UX de SearchDelegate, nao como arquitetura de dados.
```

### SelecionarPrestadorScreen

Ficheiro:

```text
lib/features/cliente/selecionar_prestador_screen.dart
```

Estado:

```text
Le prestadores.
Filtra por categories quando ha servico/categoria.
Mostra nome, foto, cidade/estado/pais, distancia e ratingAvg/ratingCount.
Permite favoritar.
Abre PublicProfileScreen.
Permite selecionar prestador para pedido.
Calcula distancia quando existem coordenadas.
```

Limitacoes:

```text
A busca textual filtra nome e localizacao, mas ainda nao servicosNomes/categorias.
Nao e uma pesquisa livre estilo Instagram; e uma tela de selecao ligada ao pedido.
Tem logica local privada e dificil de reaproveitar como discovery geral.
Nao aplica visibilidade/moderacao porque esses campos ainda nao existem.
```

Decisao:

```text
Reaproveitar ideias e partes do mapeamento de dados, mas extrair uma base comum em M2.16.2 antes de criar UI nova.
```

### Favoritos

Ficheiros:

```text
lib/core/services/favorites_service.dart
lib/features/cliente/favoritos_screen.dart
```

Estado:

```text
Favoritos existem em users/{uid}/favorites/{prestadorId}.
FavoritosScreen carrega IDs favoritos e depois busca prestadores individualmente.
Abre PublicProfileScreen.
Mostra ratingAvg/ratingCount quando existem.
```

Limitacoes:

```text
FavoritosScreen ainda tem alguma UI antiga e cores hardcoded.
Nao ha integracao com pesquisa manual geral.
Nao ha cache/index de prestadores favoritos.
```

Decisao:

```text
Favoritos devem integrar a M2.16.4, nao a M2.16.1/2.
```

### PublicProfileScreen

Ficheiro:

```text
lib/features/common/perfil_publico_screen.dart
```

Estado:

```text
Le prestadores/{userId} para role == prestador.
Mostra nome, foto, bio, localizacao, raio, servicos, portfolio e reputacao leve.
Aceita initialName e initialPhotoUrl.
Tem injeccao opcional de FirebaseFirestore para testes.
E a tela unica correta para perfil publico.
```

Decisao:

```text
Nao criar tela duplicada de perfil publico.
Toda a pesquisa/discovery deve abrir PublicProfileScreen ou usar openPublicProfile.
```

## Estado dos Dados

### users

Uso atual:

```text
roles.cliente/prestador
activeRole
displayName/name/email/telefone e dados de conta, dependendo do fluxo
favorites como subcolecao
notifications/fcmTokens como subcolecoes
```

Rules:

```text
users/{userId} tem read para signedIn ou admin.
```

Risco:

```text
users nao e a superficie certa para pesquisa publica de prestadores.
Pode misturar dados de conta/privados com dados publicos.
Nao contem de forma confiavel portfolio, area, radiusKm, ratingAvg/ratingCount e localizacao.
```

### prestadores

Uso atual:

```text
nome/displayName/name
photoUrl/fotoUrl/avatarUrl
bio/descricao
city/cidade
state/province/region
country/pais
countryCode
radiusKm
portfolioUrls/portfolioImages
servicosNomes
categories
servicos
ratingAvg/ratingCount/ratingSum
isOnline/available
lastLocation
geo.geohash/geo.geopoint
updatedAt/createdAt
```

Rules:

```text
prestadores/{prestadorId} tem read publico.
Owner pode editar campos normais, mas nao ratingCount/ratingSum/ratingAvg.
Admin/Function atualiza agregados.
```

Pontos fortes:

```text
Ja e usado pelo PublicProfileScreen.
Ja contem portfolio, reputacao leve e area.
Ja e usado por SelecionarPrestadorScreen e FavoritosScreen.
Ja e usado para matching/localizacao.
```

Riscos:

```text
read publico expõe tudo que viver no documento.
Telefone/contacto profissional, localizacao operacional e dados futuros de moderacao/KYC nao devem ficar misturados sem cuidado.
Nao ha isPublic/isSearchable/moderationStatus/suspended ate agora.
Nao ha handle publico.
Nao ha searchTerms normalizados.
```

## Estrategia de Dados

### Opcoes

| Opcao | Descricao | Vantagens | Riscos |
| --- | --- | --- | --- |
| A | Usar prestadores diretamente | Simples, ja alimenta perfil/favoritos/selecao, contem portfolio e rating | Documento e publico; precisa whitelist no cliente e evolucao futura para separar privado |
| B | Usar users diretamente | Ja tem roles; PrestadorSearchDelegate usa hoje | Mistura conta/privado, nao tem portfolio/localizacao/rating confiaveis, nao deve ser search principal |
| C | Criar publicProfiles | Melhor separacao publico/privado | Exige migracao, Rules, Functions/Sync e mais escopo |
| D | Criar providerSearchIndex | Melhor para ranking/search futuro | Exige indexacao e operacao; cedo demais para M2.16 inicial |

### Recomendacao

```text
M2.16 inicial: usar prestadores como fonte canonica publica existente.
M2.16.2: criar modelo/helper de perfil pesquisavel com whitelist de campos publicos.
Futuro: migrar para publicProfiles ou providerSearchIndex quando Trust & Safety/admin/KYC exigirem separacao mais forte.
```

Justificacao:

```text
PublicProfileScreen ja le prestadores.
SelecionarPrestadorScreen e FavoritosScreen ja leem prestadores.
ratingAvg/ratingCount protegidos ja estao em prestadores.
Criar publicProfiles agora aumentaria escopo antes de existir UI/search validada.
```

Guardrail:

```text
Mesmo usando prestadores, a UI de search deve mapear apenas campos publicos permitidos.
Nao mostrar telefone/contacto em cards de pesquisa.
Nao mostrar localizacao precisa em cards de pesquisa.
Nao mostrar dados de KYC/moderacao/operacao.
```

## Modelo Implementado na M2.16.2

A M2.16.2 criou uma camada pura e testavel em:

```text
lib/features/cliente/discovery/provider_search_profile.dart
lib/features/cliente/discovery/provider_search_normalizer.dart
lib/features/cliente/discovery/provider_search_matcher.dart
```

Modelo:

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

Helpers:

```text
ProviderSearchNormalizer.normalize
ProviderSearchNormalizer.normalizeTerms
ProviderSearchProfile.fromPrestadorDoc
matchesProviderSearch
scoreProviderSearch
```

Comportamento implementado:

```text
normaliza texto
extrair nome/foto de campos legados
extrair servicos de servicosNomes/categories/servicos
validar ratingAvg/ratingCount
decidir se perfil tem dados minimos
calcular searchTerms/searchText local
ignorar campos privados por whitelist
```

Campos futuros:

```text
handle
isPublic
isSearchable
moderationStatus
suspendedAt
blockedAt
searchTerms
serviceKeywords
```

## Campos Pesquisaveis

Entram na M2.16:

```text
displayName/nome/name
handle futuro, se existir
bio
servicosNomes
categories
city/cidade
state/province/region
country/pais
```

Podem entrar como sinal leve:

```text
ratingAvg/ratingCount, apenas se ratingCount > 0 e ratingAvg entre 1 e 5
distancia aproximada, apenas quando houver coordenadas seguras e contexto de pedido/localizacao
```

Ficam fora:

```text
telefone
email
lastLocation precisa
KYC
documentos
dados internos de pagamento
moderacao interna
```

## Regras de Visibilidade

Na M2.16 inicial, como campos de moderacao ainda nao existem, aplicar regra
minima no cliente:

```text
mostrar apenas prestadores com dados minimos:
- nome ou displayName;
- pelo menos um de: bio, foto, servico, cidade/pais, portfolio ou rating valido.
```

Preparar futuro:

```text
isPublic == true
isSearchable == true
moderationStatus == approved
suspendedAt ausente
blockedAt ausente
conteudo proibido ausente
```

Quando estes campos forem introduzidos, a pesquisa deve excluir perfis que nao
cumpram a visibilidade.

## Home Cliente

Estado atual:

```text
Home Cliente ja tem hero, StoriesCarouselWidget e catalogo de servicos.
Hero chama PrestadorSearchDelegate.
Catalogo de servicos tem pesquisa propria e renderizacao limitada.
Ainda ha muitos cards/categorias quando a lista cresce.
```

Direcao da M2.16:

```text
search dominante para prestadores/servicos;
acoes rapidas: imediato, agendado, orcamento;
sugestoes compactas de prestadores;
favoritos/recentes;
pedidos ativos;
categorias mais compactas.
```

M2.16.1 nao redesenha a Home. M2.16.5 deve tratar sugestoes compactas.

## Ranking Inicial

Permitido na M2.16:

```text
relevancia textual;
match por nome/servico/cidade;
rating leve como desempate, apenas se ratingCount > 0;
proximidade aproximada apenas se dados forem consistentes.
```

Fora da M2.16:

```text
ranking complexo;
ranking pago;
patrocinados;
ML;
boost social;
taxa de conclusao sem fonte consolidada;
disponibilidade real se nao houver dado seguro.
```

Ranking inteligente fica para M2.22.

## Trust & Safety

M2.16 deve respeitar a futura M2.17:

```text
nao mostrar perfis suspensos/bloqueados quando os campos existirem;
nao mostrar conteudo em moderacao pendente quando os campos existirem;
nao mostrar servicos proibidos;
nao mostrar textos de verificacao/certificacao sem KYC real;
nao abrir comentarios publicos sem moderacao.
```

## Testes Necessarios

M2.16.2:

```text
normalizacao de texto - coberto;
mapeamento de prestadores para ProviderSearchProfile - coberto;
rating valido/invalido - coberto;
perfil com dados minimos - coberto;
campos privados nao entram no modelo de search - coberto;
matcher e score simples - coberto.
```

M2.16.3:

```text
busca por nome;
busca por servico/categoria;
busca por cidade;
estado vazio;
loading/erro;
dark mode;
responsividade.
```

M2.16.4:

```text
abrir PublicProfileScreen;
favoritar/desfavoritar;
iniciar pedido ou selecionar prestador, se aplicavel.
```

M2.16.5:

```text
sugestoes compactas na Home;
sem sugestoes quando nao ha perfis publicos;
rating so aparece quando valido;
cards nao mostram dados privados.
```

## Subfases

```text
M2.16.1 - Spec e auditoria da pesquisa manual/discovery - concluida
M2.16.2 - Modelo/normalizacao de perfil pesquisavel - concluida
M2.16.3 - UI de pesquisa manual estilo Instagram - proximo passo
M2.16.4 - Integracao com perfil publico, favoritos e pedido
M2.16.5 - Sugestoes compactas na Home Cliente
M2.16.6 - Testes, E2E, QA visual e documentacao final
```

## Fecho da M2.16.2

A M2.16.2 criou o modelo de perfil pesquisavel, normalizador textual e matcher
de busca sem alterar UI, Rules, Functions ou deploy.

Ficheiro de status:

```text
docs/M2_16_2_MODELO_PERFIL_PESQUISAVEL_STATUS.md
```

Proximo passo:

```text
M2.16.3 - UI de pesquisa manual estilo Instagram
```

## Fora do Escopo da M2.16.1

```text
implementar pesquisa
redesenhar Home Cliente
criar publicProfiles sem decisao de implementacao
alterar Firestore Rules
alterar Storage Rules
alterar Cloud Functions
criar ranking complexo
criar patrocinados
criar pagamentos
criar KYC
criar Trust & Safety completo
criar admin/backoffice
criar videos
deploy
Android fisico
tester externo
fechar R
fechar M
fechar R1
fechar M2.6
```
