# M2.10 Visual Product System Status

Data: 2026-05-20

## Estado

```text
M2.9: fechado
M2.10: iniciado
M2.10.1: spec visual audit e design direction
M2.10.2: avancado com design system foundation
M2.10.3: avancado com Home Cliente redesign
M2.10.4: avancado com Home Prestador redesign
M2.10.5: avancado com Pedido, listas e detalhe polish
M2.10.6: iniciado com responsividade e QA visual
```

## Objetivo da M2.10

Tirar o ChegaJa do aspeto de prototipo e criar uma experiencia visual mais
profissional, organizada e responsiva para Web, Windows e Android.

## M2.10.2

Escopo:

```text
tokens responsivos
AppContentShell
AppPageScaffold
AppSectionHeader
AppStatusPill
AppMetricTile
AppActionPanel
AppResponsiveGrid
testes de componentes
documentacao de uso
```

Fora do escopo:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 76/76 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

## M2.10.3

Escopo:

```text
Home Cliente recomposta com AppPageScaffold e AppContentShell
hero operacional com CTA principal
servicos em tiles responsivos
secao de servicos sem altura fixa baseada no viewport
painel lateral de pendencias, pedidos ativos e mensagens
loading, empty e erro mais humanos
desktop/Web/Windows com composicao de dashboard
mobile preservado em uma coluna direta
```

Componentes criados:

```text
ClienteHomeHero
ClienteServicesSection
ClienteServiceTile
ClienteHomeOperationsPanel
ClienteHomeMessagesPanel
ClienteHomeEmptyServices
```

Fora do escopo mantido:

```text
Home Prestador
detalhe/listas inteiras
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia M2.10.3

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 82/82 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

## M2.10.4

Escopo:

```text
Home Prestador recomposta como painel operacional
disponibilidade online/offline como comando principal
metricas com AppMetricTile
trabalho em destaque com AppActionPanel
categorias como painel operacional
pedidos disponiveis em cards responsivos
desktop/Web/Windows com composicao em coluna principal e lateral
mobile preservado em uma coluna direta
keys Aceitar/Ignorar/orcamento preservadas
```

Componentes criados:

```text
PrestadorAvailabilityPanel
PrestadorMetricStrip
PrestadorNextWorkPanel
PrestadorCategoriesPanel
PrestadorCategoriesChips
PrestadorAvailableOrdersSection
PrestadorAvailableOrderCard
```

Fora do escopo mantido:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia M2.10.4

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 90/90 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

## M2.10.5

Escopo:

```text
PedidoDetailLayout responsivo para detalhe do pedido
rail lateral com status, proxima acao, valor e acoes
PedidoValueSummary para valor, estimativa e confirmacao
PedidoStatusSummary e PedidoNextActionCard alinhados com AppActionPanel
PedidoTimeline mais compacta e premium
acoes Cliente/Prestador agrupadas em AppActionPanel
PedidoListCard alinhado com AppStatusPill
estados finais concluido/cancelado com status pill
loading/erro/not found mais humanos no detalhe
desktop/Web/Windows com duas colunas
mobile preservado em uma coluna limpa
keys Cliente/Prestador preservadas
```

Fora do escopo mantido:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia M2.10.5

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 102/102 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
