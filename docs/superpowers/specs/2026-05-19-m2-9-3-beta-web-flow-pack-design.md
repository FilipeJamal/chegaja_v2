# M2.9.3 Beta Web Flow Pack Design

Data: 2026-05-19

## Estado

M2.9 melhora a beta Web funcional para Cliente e Prestador enquanto a M2.6
continua pendente de Android fisico.

M2.9.1 avancou o detalhe do pedido. M2.9.2 avancou listas e cards de pedidos.
M2.9.3 deve melhorar a continuidade do fluxo completo Cliente <-> Prestador no
Web, sem mudar backend.

## Objetivo

Melhorar a experiencia ponta a ponta no Web, desde a criacao do pedido ate
conclusao ou cancelamento.

A beta Web deve responder melhor:

```text
1. O que aconteceu depois de criar um pedido?
2. O que Cliente e Prestador devem fazer agora?
3. Que etapa vem a seguir no fluxo?
4. O que mudou depois de aceitar, iniciar, propor valor, confirmar ou cancelar?
```

## Escopo aprovado

Abordagem A2:

```text
Melhorar microfluxos, feedback pos-acao, textos, navegacao e consistencia entre
lista e detalhe, sem adicionar funcionalidades grandes e sem mexer no backend.
```

Esta subfase e um pacote maior de UX/produto dentro da M2.9. Ela junta ajustes
pequenos e coordenados nos pontos mais importantes do fluxo Cliente/Prestador.

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
criar sistema novo de pagamentos
criar sistema novo de planos PRO
redesenhar a app inteira
```

## Contexto atual

As subfases anteriores ja entregaram:

```text
PedidoStatusPresenter
PedidoStatusSummary
PedidoNextActionCard
PedidoTimeline
PedidoListPresenter
PedidoListCard
PedidoEmptyState
```

Fluxos e telas relevantes:

```text
lib/features/cliente/novo_pedido_screen.dart
lib/features/cliente/aguardando_prestador_screen.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/cliente/pedido_detalhe_screen.dart
lib/features/cliente/widgets/cliente_pedido_acoes.dart
lib/features/prestador/prestador_home_screen.dart
lib/features/prestador/widgets/prestador_pedido_acoes.dart
lib/core/services/pedido_service.dart
```

A M2.9.3 deve consumir os servicos existentes e melhorar a camada de UX:
mensagens, feedback, labels, navegacao e consistencia visual. Regras de negocio
e autorizacao continuam no backend, rules e services existentes.

## Abordagens consideradas

### A1 - Ajustes pontuais por tela

Aplicar correcoes isoladas em cada tela. E rapido, mas tende a espalhar textos
e estados novamente.

### A2 - Flow pack coordenado

Melhorar os pontos principais do fluxo de forma coordenada, reutilizando os
presenters/widgets da M2.9.1 e M2.9.2. E a opcao recomendada porque melhora a
experiencia completa sem abrir uma feature grande.

### A3 - Wizard completo de pedido

Redesenhar o fluxo como wizard guiado. Tem impacto alto, mas e grande demais
para esta subfase e aumenta risco de regressao.

## Principios de UX

- Cada acao importante deve dar feedback claro e curto.
- A tela seguinte deve ser previsivel depois de criar, aceitar, iniciar,
  propor, confirmar, rejeitar ou cancelar.
- Lista e detalhe devem usar a mesma linguagem de estado.
- O valor final deve continuar claro: proposta/faixa nao e valor final, e a
  confirmacao final fica no fluxo ja existente.
- Estados finais devem parecer finais e nao sugerir acao indevida.
- Erros devem ser humanos para o utilizador e tecnicos apenas em debug/log.
- A beta Web deve ficar apresentavel sem virar landing page ou redesign grande.

## Proposta de produto

### 1. Criar pedido: feedback e pos-criacao

Melhorar o momento apos criar um pedido:

```text
mensagem de sucesso mais clara
direcionamento consistente para aguardando/detalhe/lista
explicacao curta do que acontece a seguir
erro humano quando a criacao falha
```

O objetivo nao e mudar o fluxo de criacao, mas reduzir incerteza depois do
cliente submeter o pedido.

### 2. Prestador: aceitar, iniciar e enviar valor

Melhorar feedback e textos nos passos do Prestador:

```text
aceitar pedido
recusar/ignorar pedido disponivel
iniciar trabalho
enviar faixa/orcamento quando aplicavel
enviar valor final
cancelar trabalho
```

Os botoes e keys existentes devem ser preservados. A mudanca deve focar textos,
SnackBars, confirmacoes e estados visuais.

### 3. Cliente: proposta, valor final e cancelamento

Melhorar clareza nos passos do Cliente:

```text
aceitar ou rejeitar proposta
confirmar valor final
rejeitar valor final
cancelar pedido
consultar pedido concluido/cancelado
```

Textos devem diferenciar:

```text
faixa estimada
proposta do prestador
valor final
confirmacao do cliente
pedido concluido
```

### 4. Historico simples apos estados finais

Sem criar backend novo, usar dados ja disponiveis para melhorar a consulta
apos conclusao/cancelamento:

```text
estado final claro
motivo/responsavel pelo cancelamento quando existir
datas principais quando existirem
valor final quando existir
entrada para chat/anexos apenas se ja existir no fluxo
```

Nao prometer avaliacao, pagamento ou suporte se a acao real nao estiver
disponivel naquele contexto.

### 5. Consistencia entre lista e detalhe

Garantir que lista e detalhe nao dizem coisas contraditorias:

```text
mesmo nome de estado
mesma proxima acao resumida
mesma interpretacao de valor final/proposta
mesmo tom para concluido e cancelado
```

Preferir ampliar presenters existentes se houver duplicacao evidente, mas sem
transformar a subfase numa refatoracao ampla.

### 6. Pequenos ajustes de navegacao

Melhorar navegacao apenas onde estiver diretamente ligada ao fluxo:

```text
apos criar pedido
apos aceitar/iniciar
apos confirmar/rejeitar valor final
ao voltar de detalhe para lista
```

Nao adicionar rotas grandes novas nem mudar arquitetura de navegacao.

## Arquitetura proposta

Usar os presenters/widgets existentes como fonte de linguagem do pedido:

```text
PedidoStatusPresenter
PedidoListPresenter
PedidoStatusSummary
PedidoNextActionCard
PedidoTimeline
PedidoListCard
PedidoEmptyState
```

Arquivos candidatos para alteracao:

```text
lib/features/cliente/novo_pedido_screen.dart
lib/features/cliente/aguardando_prestador_screen.dart
lib/features/cliente/pedido_detalhe_screen.dart
lib/features/cliente/widgets/cliente_pedido_acoes.dart
lib/features/prestador/widgets/prestador_pedido_acoes.dart
lib/features/cliente/widgets/pedido_status_presenter.dart
lib/features/cliente/widgets/pedido_list_presenter.dart
test/features/cliente/widgets/pedido_status_presenter_test.dart
test/features/cliente/widgets/pedido_list_presenter_test.dart
```

Se surgirem widgets novos, devem ser pequenos e focados. Evitar aumentar ainda
mais as telas grandes sem necessidade.

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
cancelamentoMotivo
clienteId
prestadorId
createdAt
aceitoEm
iniciadoEm
concluidoEm
canceladoEm
```

Nenhum campo economico deve passar a ser calculado na UI. O backend continua a
ser autoritativo para valores finais e split.

## Testes esperados

Adicionar ou ajustar testes Flutter para garantir:

```text
Cliente recebe mensagem/estado claro apos criar pedido
Cliente ve texto correto para aceitar/rejeitar proposta
Cliente ve texto correto para confirmar/rejeitar valor final
Prestador ve texto correto ao aceitar/iniciar/enviar valor final
Pedido concluido nao mostra proxima acao indevida
Pedido cancelado mostra contexto final sem acao indevida
Lista e detalhe usam labels compativeis para estados principais
Erros principais nao expoem excecao bruta ao utilizador
```

Rodar validacoes:

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Nao rodar smoke real, cleanup real, health real ou deploy nesta subfase.

## Criterios de aceitacao

M2.9.3 pode ser considerada avancada quando:

```text
criacao de pedido tem feedback e proximo passo claros
acoes principais do Prestador tem textos/feedback mais claros
acoes principais do Cliente tem textos/feedback mais claros
valor final e proposta ficam menos ambiguos
conclusao e cancelamento ficam claros como estados finais
lista e detalhe usam linguagem coerente
testes Flutter cobrem os helpers/widgets/textos alterados
flutter test passa
nao ha backend, rules, Functions, deploy, smoke real, cleanup real ou Android fisico
docs/status M2.9 atualizados
```

## Riscos

- As telas de Cliente e Prestador ja sao grandes. A implementacao deve tocar
  apenas nos pontos do fluxo e extrair helpers pequenos se isso reduzir
  duplicacao.
- Alguns textos ainda estao hardcoded. Pode manter esse padrao se for o padrao
  local, mas a fonte de verdade para estados deve continuar nos presenters
  sempre que possivel.
- Existem testes Android/Web que dependem de keys. Preservar keys existentes em
  botoes e cards de fluxo.
- Nao transformar a subfase num redesign completo de criacao de pedido.

## Decisao

Avancar com M2.9.3 usando a abordagem A2:

```text
Beta Web Flow Pack coordenado, focado em feedback, textos, proxima acao,
navegacao e consistencia entre lista e detalhe.
```

Sem mudar backend, regras Firebase, Functions, deploy, pagamentos, Play Store,
Android fisico ou M2.6.
