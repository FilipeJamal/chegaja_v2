# M2.9.2 Lista de Pedidos UX Design

Data: 2026-05-19

## Estado

M2.9 melhora a beta Web funcional para Cliente e Prestador enquanto a M2.6
continua pendente de Android fisico.

M2.9.1 avancou o detalhe do pedido. M2.9.2 foca a entrada para esse detalhe:
as listas e cards de pedidos.

## Objetivo

Melhorar a forma como Cliente e Prestador encontram, entendem e abrem pedidos.
Cada card de pedido deve responder rapidamente:

```text
1. O que e este pedido?
2. Qual e o estado atual?
3. Existe alguma acao pendente para mim?
4. Vale a pena abrir o detalhe agora?
```

## Escopo aprovado

Abordagem A2:

```text
Melhorar cards, agrupamento visual, estados, proxima acao resumida e empty
states nas listas existentes, reutilizando a logica de apresentacao criada na
M2.9.1 quando fizer sentido.
```

Esta subfase e uma continuacao de UX beta Web. Nao cria funcionalidades grandes
novas e nao muda backend.

## Nao objetivos

Esta subfase nao deve:

```text
alterar backend
alterar Firestore Rules
alterar Storage Rules
alterar Cloud Functions
fazer deploy
rodar smoke real
rodar cleanup real
rodar health real
adicionar pagamentos reais
mexer em Play Store
alterar package id final
alterar HTTPS App Links
usar Android fisico
fechar M2.6
redesenhar a app inteira
```

## Contexto atual

As listas principais estao hoje em:

```text
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
```

No Cliente:

```text
_ClientePedidosTab
_ListaPedidosCliente
_PedidoClienteCard
```

No Prestador:

```text
_PrestadorPedidosTab
_PrestadorListaPedidos
_PrestadorPedidoCard
_PedidoDisponivelCard
```

A M2.9.1 adicionou:

```text
PedidoStatusPresenter
PedidoStatusSummary
PedidoNextActionCard
```

O presenter ja deriva textos de `Pedido + role + estado`, incluindo estado,
proxima acao e timeline. A M2.9.2 deve reutilizar essa base para evitar uma
segunda fonte de verdade nos cards.

## Principios de UX

- O card deve destacar o estado antes de detalhes secundarios.
- A proxima acao deve aparecer de forma curta, sem substituir os botoes reais.
- Pedidos ativos devem parecer diferentes de concluidos e cancelados.
- O card deve ser escaneavel: titulo, categoria, estado, valor/resumo e acao.
- Empty states devem explicar o que esta a acontecer e qual e o proximo passo.
- Erros de carregamento devem ser humanos e nao despejar excecoes brutas.
- A tela deve manter a densidade util de uma app operacional, sem hero/landing
  page ou redesign grande.

## Proposta de produto

### 1. Card de pedido com estado claro

Criar ou adaptar um card reutilizavel para listas de pedido, com:

```text
titulo do pedido
categoria ou servico
chip de estado
resumo de proxima acao
valor ou faixa estimada quando existir
indicador de chat/mensagens quando ja existir
entrada clara para abrir detalhe
```

O card nao deve conter toda a timeline. A timeline fica no detalhe.

### 2. Proxima acao resumida no card

Usar o `PedidoStatusPresenter.nextActionFor` como base para mostrar uma linha
curta:

```text
Cliente:
"Reve e confirma o valor final"
"Aguarda resposta do prestador"
"Combina os detalhes com o prestador"

Prestador:
"Aceita ou recusa o convite"
"Envia o valor final quando terminares"
"Aguarda confirmacao do cliente"
```

O texto deve ser curto. Explicacoes mais longas continuam no detalhe.

### 3. Separacao entre ativos, concluidos e cancelados

Manter as tabs existentes:

```text
Cliente: pendentes, concluidos, cancelados
Prestador: em aberto, concluidos, cancelados
```

Melhorar a leitura interna:

```text
ativos: destaque de acao/estado
concluidos: tom final, sem urgencia
cancelados: tom neutro/perigo leve, sem chamada para agir
```

Nao adicionar filtros complexos nesta subfase.

### 4. Empty states melhores

Substituir textos soltos por blocos simples com icone, titulo e descricao.

Exemplos:

```text
Cliente sem pedidos pendentes:
"Sem pedidos ativos"
"Quando criares um pedido, ele aparece aqui ate ser concluido ou cancelado."

Prestador sem trabalhos em aberto:
"Sem trabalhos em aberto"
"Vai a Inicio para aceitar pedidos compativeis quando estiveres online."

Prestador offline:
"Estas offline"
"Ativa o modo online para receber pedidos compativeis."
```

### 5. Loading e erro

Loading deve continuar simples, mas com contexto quando a secao permite:

```text
"A carregar pedidos..."
```

Erros devem evitar:

```text
Erro a carregar pedidos: Exception(...)
```

Preferir:

```text
"Nao conseguimos carregar os pedidos agora. Tenta novamente daqui a pouco."
```

Detalhes tecnicos podem ficar em `debugPrint` quando necessario.

## Arquitetura proposta

Preferir extrair widgets pequenos em vez de aumentar ainda mais os home screens.

Arquivos candidatos:

```text
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/cliente/widgets/pedido_empty_state.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
test/features/cliente/widgets/pedido_list_card_test.dart
```

Se o card tiver muitas diferencas entre Cliente e Prestador, usar uma API com
role:

```text
PedidoListCard(
  pedido: pedido,
  role: PedidoViewerRole.cliente/prestador,
  onTap: ...,
  trailingActions: ...
)
```

Se o card disponivel do Prestador (`_PedidoDisponivelCard`) precisar de uma
versao propria, manter separado, mas reutilizar textos/helpers comuns para
estado e proxima acao.

## Dados e regras

Nao ha mudanca de schema.

Usar campos ja existentes:

```text
estado
statusProposta
statusConfirmacaoValor
tipoPreco
precoPropostoPrestador
precoFinal
valorMinEstimadoPrestador
valorMaxEstimadoPrestador
canceladoPor
prestadorId
clienteId
createdAt
categoria
servicoNome
modo
agendadoPara
tipoPagamento
```

## Testes esperados

Adicionar testes Flutter focados em presenter/widget para garantir:

```text
Cliente com valor final pendente mostra chip/acao resumida correta
Prestador com convite pendente mostra acao de aceitar/recusar
Pedido concluido nao mostra urgencia indevida
Pedido cancelado mostra estado final
Empty state de lista vazia mostra titulo e descricao humanos
Erro de lista nao expoe excecao bruta ao utilizador
```

Rodar validacoes:

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Se a implementacao ficar apenas em Flutter/UI, os testes Firebase continuam a
ser regressao local antes do commit final. Nao ha deploy.

## Criterios de aceitacao

M2.9.2 pode ser considerada avancada quando:

```text
Cliente ve cards de pedidos com estado claro
Prestador ve trabalhos/cards com estado claro
cards mostram proxima acao curta quando aplicavel
ativos, concluidos e cancelados ficam visualmente distinguiveis
empty states deixam de ser texto solto
erros principais deixam de expor excecoes brutas
testes Flutter cobrem helpers/widgets novos
flutter test passa
nao ha backend, regras, Functions, deploy, smoke real, cleanup real ou Android fisico
docs/status M2.9 atualizados
```

## Riscos

- `cliente_home_screen.dart` e `prestador_home_screen.dart` ja sao ficheiros
  grandes. A implementacao deve extrair widgets pequenos sem fazer refatoracao
  ampla fora do escopo.
- Existem helpers antigos de estado nas duas telas. A M2.9.2 deve reduzir
  duplicacao gradualmente, mas sem quebrar l10n ou fluxos existentes.
- Alguns textos atuais usam strings hardcoded. Pode manter esse padrao onde ja
  existe, mas deve evitar piorar a dispersao de textos quando o presenter puder
  ser reaproveitado.
- O card do Prestador para pedidos disponiveis tem acoes imediatas
  (`Aceitar`, `Ignorar`). Essa area deve preservar keys e comportamento dos
  testes Android/Web.

## Decisao

Avancar com M2.9.2 usando a abordagem A2:

```text
Listas e cards de pedidos com estado claro, proxima acao resumida, empty states
melhores e reuso do presenter da M2.9.1 quando fizer sentido.
```

Sem mudar backend, regras Firebase, Functions, deploy, pagamentos, Play Store
ou Android fisico.
