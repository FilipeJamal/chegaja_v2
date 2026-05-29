# ChegaJa - Discovery, Pesquisa Manual e Perfis Pesquisaveis

Data: 2026-05-29

## Estado

Spec de produto para uma fase futura, recomendada como M2.16 depois de fechar
M2.15. Nao e implementacao atual.

## Objetivo

Permitir que o Cliente encontre prestadores manualmente, como numa pesquisa de
perfil social, sem depender apenas do fluxo automatico de pedidos.

Visao:

```text
Cliente pesquisa por nome, handle, categoria ou cidade.
App mostra prestadores publicos, ativos e seguros para exibir.
Cliente abre o perfil publico.
Cliente ve foto, bio, portfolio, servicos e reputacao leve.
Cliente pode favoritar ou iniciar pedido/conversa quando permitido.
```

## Motivacao

O Prestador deve poder divulgar a propria pagina do ChegaJa em:

```text
Instagram
Facebook
WhatsApp
site proprio
cartao digital
link partilhado
```

O Cliente deve conseguir procurar esse prestador diretamente.

## Escopo Futuro Recomendado

```text
handle publico unico
perfil pesquisavel
search por nome/handle/categoria/cidade
cards compactos de prestador
filtros leves
favoritar a partir do perfil/search
partilhar perfil
link publico futuro
```

## Fora do Escopo Inicial

```text
ranking complexo
patrocinados/destaques pagos
KYC completo
comentarios publicos
videos no portfolio
moderacao pesada
pagamentos reais
algoritmo estilo rede social completo
```

## Dados Publicos vs Privados

Separacao recomendada:

```text
prestadores/{uid}: dados operacionais atuais
publicProfiles/{uid}: dados publicos e pesquisaveis futuros
privateContacts/{uid}: telefone/email/contacto sensivel
providerRatingStats/{uid}: agregados de reputacao server-side futuros
moderationQueue/{id}: denuncias e revisoes
kycCases/{uid}: dados/documentos privados de verificacao futura
```

Regra de ouro:

```text
Se um campo nao deve ser visto por todos, nao deve viver no mesmo documento
publico do perfil pesquisavel.
```

## Campos de Perfil Pesquisavel Futuro

```text
uid
handle
displayName
bio
avatarUrl
coverPhotoUrl futuro
city
country
services[]
serviceKeywords[]
portfolioPreviewUrls[]
ratingAvg
ratingCount
isPublic
isSearchable
moderationStatus
createdAt
updatedAt
```

## Regras de Visibilidade

Um prestador so deve aparecer na pesquisa se:

```text
isPublic == true
isSearchable == true
moderationStatus == approved ou equivalente seguro
nao estiver bloqueado/suspenso
perfil tiver dados minimos
```

Dados de reputacao so entram quando:

```text
ratingCount > 0
agregados sao autoritativos
sem suspeita de manipulacao
```

## Ranking Base Futuro

Ranking organico deve considerar:

```text
proximidade
categoria/servico
perfil completo
reputacao real
atividade recente
disponibilidade real futura
equilibrio para novos prestadores
```

Nao deve considerar como "qualidade":

```text
pagamento por destaque
badge comprado
promessa de verificacao sem KYC
```

Se houver pago:

```text
rotular como patrocinado
separar de ranking organico
validar regras Apple/Google antes
```

## UI Recomendada

Home Cliente futura:

```text
search dominante
acoes rapidas: imediato, agendado, orcamento
sugestoes compactas de prestadores proximos
favoritos recentes
pedidos ativos/resumo
menos cards de categorias soltos
```

Search:

```text
campo de pesquisa por nome, @handle, categoria ou cidade
lista compacta de prestadores
chips de categoria/cidade
estado vazio util
estado sem resultados com sugestao de criar pedido normal
```

Perfil:

```text
abrir em 1 toque
ver portfolio
ver reputacao leve
favoritar
pedir servico
partilhar link futuro
```

## Dependencias

Antes desta fase:

```text
M2.15.3 - UI de avaliacao pos-servico
M2.15.4 - reputacao leve no perfil publico
M2.15.5 - QA final da M2.15
```

Depois ou em paralelo controlado:

```text
Trust & Safety base
admin/backoffice leve
politica de conteudo proibido
denuncia/bloqueio
```

## Testes Recomendados

```text
normalizacao de handle
busca por nome
busca por categoria
busca por cidade
perfil nao publico nao aparece
perfil bloqueado/moderado nao aparece
rating so aparece com ratingCount > 0
estado vazio da search
dark mode
responsividade mobile/desktop
```

## Referencias Externas Verificadas

```text
Firebase field-level access guidance:
https://firebase.google.com/docs/firestore/security/rules-fields
```
