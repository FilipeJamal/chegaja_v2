# M2.10.5 - Pedido, listas e detalhe polish

## Contexto

A M2.10 esta a transformar o ChegaJa de uma app funcional com aspeto de prototipo para um produto visualmente mais profissional, organizado e responsivo.

Estado recente:

```txt
M2.10.1: spec visual audit e design direction
M2.10.2: avancado com design system foundation
M2.10.3: avancado com Home Cliente redesign
M2.10.4: avancado com Home Prestador redesign
```

Commits de referencia:

```txt
39aea08d1bcc6e2785cab8ce858e9100010ad30e
Avancar M2.10.2 design system foundation

2c62f15696020d00ba61643a8ce04d470c406c91
Avancar M2.10.3 home cliente redesign

95e8a6e
Avancar M2.10.4 home prestador redesign
```

A M2.10.5 aplica a mesma qualidade visual ao sistema de pedidos: listas, cards, detalhe, timeline, paineis de acao e estados finais. O detalhe do pedido deve ser a tela ancora desta fase, porque e onde Cliente e Prestador decidem, acompanham e concluem o trabalho.

## Problema

A M2.9 melhorou bastante a UX funcional de pedidos, mas as telas ainda podem comunicar prototipo quando comparadas com as Homes redesenhadas:

- o detalhe do pedido ainda e muito vertical em Web/Windows;
- desktop nao aproveita bem uma composicao de duas colunas;
- status, proxima acao, valor, timeline e botoes podem parecer blocos empilhados, sem arquitetura forte;
- a timeline ocupa largura total e pode ficar pesada para estados simples;
- acoes de Cliente e Prestador ficam funcionais, mas ainda podem parecer botoes soltos em vez de painel operacional;
- lista e detalhe podem parecer de sistemas visuais diferentes;
- cards de pedido precisam alinhar melhor com as Homes redesenhadas;
- estados finais concluido/cancelado precisam parecer encerramento claro, nao apenas ausencia de acao;
- mobile deve continuar simples, mas sem perder a nova qualidade visual;
- ha keys de testes Android/Web/Windows que nao podem ser quebradas.

O problema nao e so cor ou espacamento. E arquitetura visual: o pedido precisa parecer o centro operacional do produto.

## Objetivo

Fazer listas, cards e detalhe do pedido parecerem parte do mesmo produto visual das novas Homes, mantendo todos os fluxos existentes.

A experiencia deve responder rapidamente:

```txt
1. Em que estado esta este pedido?
2. Qual e a proxima acao para o meu papel?
3. Existe proposta, valor final ou decisao pendente?
4. O que ja aconteceu na timeline?
5. Que acao posso executar com seguranca agora?
```

## Direcao escolhida

### Detalhe premium como ancora, sistema de pedidos coerente

A fase deve dar prioridade ao detalhe do pedido com layout mais forte em desktop, mas sem deixar listas/cards desalinhados.

Direcao visual:

```txt
desktop: conteudo principal + rail lateral operacional
mobile: uma coluna limpa
listas/cards: mesma linguagem visual das Homes
acoes: agrupadas em AppActionPanel
status: AppStatusPill e paineis compactos
timeline: mais compacta, menos prototipo
```

Esta direcao evita dois erros:

- redesenhar so o detalhe e deixar a entrada da lista com outro aspeto;
- fazer uma mudanca superficial em cards sem resolver o uso ruim de largura no detalhe.

## Principios visuais

- **Pedido como centro operacional:** estado, acao e valor devem aparecer antes de detalhes secundarios.
- **Desktop real:** usar duas colunas em Web/Windows quando houver largura, sem mobile esticado.
- **Mobile direto:** manter uma coluna com status, proxima acao, detalhes e acoes na ordem natural.
- **Acoes agrupadas:** botoes importantes devem viver em paineis de acao, nao espalhados.
- **Timeline compacta:** estados devem ser legiveis sem consumir espaco excessivo.
- **Status sempre visivel:** usar `AppStatusPill` e cards compactos para orientar o utilizador.
- **Consistencia com Homes:** listas e detalhe devem herdar a mesma linguagem visual da M2.10.3/M2.10.4.
- **Sem regra de negocio na UI:** widgets visuais recebem dados e callbacks; seguranca e regras continuam nos services/backend existentes.
- **Preservar contrato de testes:** keys atuais continuam.

## Alternativas consideradas

### A1 - Apenas polir o detalhe do pedido

Criar layout em duas colunas e melhorar timeline/acoes apenas no detalhe.

**Parcialmente escolhida.** O detalhe e a prioridade, mas a fase tambem precisa alinhar listas/cards para nao deixar ruptura visual entre entrada e detalhe.

### A2 - Sistema de pedidos coerente

Tratar detalhe, listas/cards, paineis de acao e timeline como um conjunto visual:

```txt
PedidoDetailLayout
PedidoDetailSidePanel
PedidoListCard alinhado com foundation
PedidoTimeline compacta
Cliente/Prestador actions em AppActionPanel
```

**Escolhida.** Ataca a arquitetura visual real sem mexer em backend.

### A3 - Redesenhar todo o fluxo de pedidos e estados de negocio

Mudar schema, regras, Functions, estados, rotas e pagamentos.

**Rejeitada.** Isso pertence a fases futuras. A M2.10.5 e visual/produto, nao backend.

## Escopo

### Entra

- Redesenhar o detalhe do pedido em `lib/features/cliente/pedido_detalhe_screen.dart`.
- Criar ou ajustar widgets de pedido:
  - `PedidoStatusSummary`
  - `PedidoNextActionCard`
  - `PedidoTimeline`
  - `PedidoFinalStatePanel`
  - `PedidoListCard`
  - `ClientePedidoAcoes`
  - `PrestadorPedidoAcoes`
- Criar componentes visuais pequenos, se fizer sentido:
  - `PedidoDetailLayout`
  - `PedidoDetailSidePanel`
  - `PedidoActionRail`
  - `PedidoValueSummary`
- Usar foundation M2.10.2:
  - `AppPageScaffold`
  - `AppContentShell`
  - `AppActionPanel`
  - `AppStatusPill`
  - `AppMetricTile`
  - `AppResponsiveGrid`
  - `AppSectionHeader`
- Desktop/Web/Windows com duas colunas:
  - coluna principal para conteudo do pedido;
  - lateral para status, proxima acao, valor, resumo e acoes.
- Mobile em uma coluna limpa.
- Timeline mais compacta e premium.
- Acoes Cliente/Prestador agrupadas em paineis, preservando callbacks.
- Listas/cards de pedido alinhados visualmente com as novas Homes.
- Loading, empty e erro mais humanos.
- Estados finais concluido/cancelado com encerramento claro.
- Preservar fluxos Cliente/Prestador.
- Preservar keys existentes.
- Adicionar ou ajustar testes Flutter.
- Atualizar docs/status M2.10.

### Nao entra

- Backend.
- Firestore Rules.
- Storage Rules.
- Cloud Functions.
- Deploy.
- Smoke real.
- Cleanup real.
- Health real.
- Android fisico.
- Pagamentos reais.
- Play Store.
- Package id final.
- HTTPS App Links.
- Fechar M2.6.

## Arquitetura proposta

Manter a logica existente de pedidos, presenters e acoes. A M2.10.5 deve extrair ou ajustar widgets visuais para reduzir empilhamento e melhorar responsividade.

Arquivos provaveis:

```txt
lib/features/cliente/pedido_detalhe_screen.dart
lib/features/cliente/widgets/pedido_status_summary.dart
lib/features/cliente/widgets/pedido_next_action_card.dart
lib/features/cliente/widgets/pedido_timeline.dart
lib/features/cliente/widgets/pedido_final_state_panel.dart
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/cliente/widgets/cliente_pedido_acoes.dart
lib/features/prestador/widgets/prestador_pedido_acoes.dart
test/features/cliente/widgets/pedido_*_test.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Novos widgets possiveis:

```txt
PedidoDetailLayout
PedidoDetailSidePanel
PedidoActionPanelSection
PedidoValueSummary
PedidoCompactTimeline
```

Regras:

- nao alterar `PedidoService`;
- nao alterar repositorios;
- nao alterar schema Firestore;
- nao alterar Functions;
- nao alterar Rules;
- widgets recebem `Pedido`, presenter data e callbacks ja existentes;
- derivacoes visuais simples podem ficar em helpers testaveis;
- nao duplicar logica financeira ou de permissao;
- manter `PedidoStatusPresenter` e presenter de lista quando fizer sentido;
- nao criar estilos locais se a foundation resolver.

## Layout desejado

### Desktop/Web/Windows

Composicao em duas colunas:

```txt
AppPageScaffold
  AppContentShell
    topo compacto: titulo + categoria + status pill
    grid:
      coluna principal:
        resumo do pedido
        timeline compacta
        descricao/local/anexos/metadados
        estados finais, se houver
      lateral:
        proxima acao
        valor/orcamento/status financeiro
        acoes principais
        atalhos de chat/cancelamento quando existirem
```

Caracteristicas:

- lateral com largura estavel;
- status e proxima acao sempre faceis de encontrar;
- botoes principais agrupados;
- timeline nao domina a tela;
- conteudo usa largura maxima coerente;
- sem espacos vazios grandes sem funcao.

### Tablet

Composicao hibrida:

```txt
Status/proxima acao em largura total
Detalhes e timeline em coluna principal
Valor/acoes abaixo ou em segunda coluna quando houver largura
```

### Mobile/Android

Uma coluna:

```txt
Status
Proxima acao
Titulo/resumo
Valor/orcamento
Acoes principais
Timeline
Detalhes secundarios
Estados finais
```

Caracteristicas:

- botoes com area de toque adequada;
- sem rail lateral artificial;
- sem grid apertado;
- sem overflow horizontal;
- textos curtos e orientados a acao.

## UX por area

### Cabecalho do pedido

O cabecalho deve mostrar:

- titulo do pedido;
- servico/categoria;
- status em `AppStatusPill`;
- tipo de preco ou agendamento quando existir;
- identificador do pedido de forma discreta.

Exemplo:

```txt
Assentamento de anexos
Servico imediato
[Aceito]
```

### Painel lateral operacional

O painel lateral deve concentrar:

- proxima acao;
- estado atual;
- valor estimado/final quando existir;
- acao principal;
- acoes secundarias.

Exemplos:

```txt
Proxima acao
Enviar uma faixa estimada para o cliente decidir.

Orcamento
A faixa nao e valor final. O valor final vem depois do servico.
```

```txt
Valor final pendente
O cliente precisa confirmar antes de concluir o pedido.
```

### Timeline

A timeline deve ficar mais compacta:

- etapas com label curto;
- estado atual destacado;
- concluido/cancelado com tratamento visual final;
- menos altura ocupada em desktop;
- legivel em mobile.

Estados principais:

```txt
Criado
Aceito
Em andamento
Aguarda valor
Concluido
Cancelado
```

### Acoes Cliente

Preservar fluxo e keys, mas agrupar visualmente em `AppActionPanel` quando fizer sentido.

Keys conhecidas a preservar:

```txt
cliente_rejeitar_proposta_button
cliente_aceitar_proposta_button
cliente_duvida_valor_button
confirmar_valor_button
```

Acoes devem continuar:

- aceitar/rejeitar proposta;
- confirmar valor final;
- pedir duvida sobre valor;
- cancelar quando permitido;
- abrir chat/detalhe quando existir.

### Acoes Prestador

Preservar fluxo e keys, mas melhorar a presenca visual.

Keys conhecidas a preservar:

```txt
prestador_enviar_orcamento_button
prestador_iniciar_servico_button
valor_final_field
prestador_enviar_valor_final_button
prestador_lancar_valor_final_button
prestador_orcamento_dialog_later_button
prestador_orcamento_dialog_now_button
orcamento_min_field
orcamento_max_field
orcamento_msg_field
orcamento_enviar_button
```

Acoes devem continuar:

- enviar orcamento;
- iniciar servico;
- lancar/enviar valor final;
- cancelar/reportar quando permitido;
- manter dialog de orcamento funcional.

### Cards/listas

`PedidoListCard` deve alinhar com a nova linguagem visual:

- status pill clara;
- proxima acao resumida;
- titulo e servico com hierarquia melhor;
- valor/status financeiro de forma compacta;
- diferenca visual entre ativo, concluido e cancelado;
- keys existentes preservadas;
- area clicavel clara.

### Estados finais

Concluido e cancelado devem parecer encerramento claro:

```txt
Pedido concluido
Os detalhes deste servico ficam disponiveis no historico.
```

```txt
Pedido cancelado
Este pedido foi encerrado e nao precisa de novas acoes.
```

Nao prometer funcionalidades ainda inexistentes, como avaliacao, se nao houver feature real.

### Loading, empty e erro

- Loading deve usar mensagem humana.
- Pedido nao encontrado deve orientar voltar para lista.
- Erro deve evitar excecao bruta.
- Retry so aparece se houver callback real.

## Compatibilidade funcional

Preservar:

- rotas atuais para detalhe;
- navegacao de voltar;
- lista Cliente;
- lista Prestador;
- fluxo de convite/aceite;
- fluxo de orcamento;
- fluxo de valor final;
- chat/detalhe quando existente;
- estados finais;
- keys Android/Web/Windows;
- presenters existentes.

Nao alterar:

```txt
PedidoService
PedidosRepo
LocationService
ChatService
Firestore schema
Cloud Functions
Rules
```

## Testes

Adicionar ou ajustar testes Flutter para cobrir:

- detalhe renderiza layout responsivo sem overflow em mobile;
- em desktop, detalhe mostra painel lateral operacional;
- status aparece com `AppStatusPill` ou componente equivalente;
- proxima acao aparece no painel correto para Cliente;
- proxima acao aparece no painel correto para Prestador;
- acoes Cliente preservam keys principais;
- acoes Prestador preservam keys principais;
- timeline mapeia estados principais;
- pedido concluido nao mostra acao indevida;
- pedido cancelado mostra encerramento;
- card/lista preserva status e proxima acao resumida;
- loading/erro mostram textos humanos.

Validações finais:

```txt
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

## Criterios de aceitacao

- Detalhe do pedido deixa de parecer uma lista vertical de blocos em Web/Windows.
- Desktop usa duas colunas com rail lateral operacional.
- Mobile continua em uma coluna limpa.
- Status, proxima acao e valor ficam faceis de encontrar.
- Timeline fica mais compacta e premium.
- Acoes Cliente/Prestador ficam agrupadas sem quebrar callbacks.
- Listas/cards ficam alinhados visualmente as Homes redesenhadas.
- Estados finais ficam claros e sem acao indevida.
- Loading/empty/error ficam humanos.
- Keys e fluxos existentes continuam preservados.
- Testes principais continuam verdes.
- Nenhum backend, regra Firebase, Function ou deploy e alterado.

## Commit recomendado

```txt
Iniciar M2.10.5 pedido listas detalhe polish
```
