# M2.10.4 - Home Prestador redesign

## Contexto

A M2.10 esta a transformar o ChegaJa de uma app funcional com aspeto de prototipo para um produto visualmente mais profissional, organizado e responsivo.

Estado recente:

```txt
M2.10.1: spec visual audit e design direction
M2.10.2: avancado com design system foundation
M2.10.3: avancado com Home Cliente redesign
```

Commit de referencia da fase anterior:

```txt
2c62f15696020d00ba61643a8ce04d470c406c91
Avancar M2.10.3 home cliente redesign
```

A M2.10.4 aplica a mesma filosofia visual na Home Prestador, que e a tela operacional mais importante para quem recebe, aceita e gere trabalhos.

## Problema

A Home Prestador atual funciona, mas ainda comunica produto inacabado:

- o estado online/offline existe, mas parece um bloco utilitario simples;
- os KPIs de ganhos e servicos usam containers locais, sem a foundation visual da M2.10.2;
- pedidos disponiveis aparecem em lista vertical, mesmo em Web/Windows;
- a tela mistura disponibilidade, categorias, mensagens, trabalho em destaque e pedidos perto de ti sem arquitetura clara;
- desktop ainda nao usa composicao de dashboard com coluna principal e lateral;
- mobile precisa continuar direto, mas com acoes mais claras;
- cards de pedidos disponiveis ainda podem parecer pouco premium para a acao critica "Aceitar";
- empty/loading/error existem, mas podem ficar mais orientados a operacao real;
- ha keys criticas de testes Android/Windows/E2E que nao podem ser quebradas.

Como o prestador e quem executa o servico, esta Home precisa passar confianca operacional: "estou disponivel?", "que trabalho exige acao?", "que pedidos posso aceitar agora?", "como estou hoje?".

## Objetivo

Transformar a Home Prestador num painel operacional profissional, mantendo as funcionalidades existentes.

A tela deve responder rapidamente:

```txt
1. Estou online ou offline?
2. Ha trabalho meu a exigir acao?
3. Ha pedidos compativeis para aceitar agora?
4. Como esta a minha atividade hoje/este mes?
5. Preciso ajustar categorias, raio ou disponibilidade?
```

## Principios visuais

- **Disponibilidade como comando principal:** online/offline deve ser o primeiro sinal operacional.
- **Aceitar pedido com peso visual:** aceitar/ignorar devem continuar funcionais, mas com hierarquia mais clara.
- **Dashboard real em desktop:** Web/Windows deve usar colunas, grids e paineis, nao uma lista mobile esticada.
- **Mobile rapido:** em Android/mobile, manter uma coluna clara com estado, proxima acao e pedidos.
- **Metricas sem poluicao:** ganhos e servicos devem informar sem virar dashboard financeiro complexo.
- **Categorias como configuracao operacional:** quando faltarem categorias, a tela deve orientar a configuracao.
- **Foundation antes de estilos locais:** usar `AppPageScaffold`, `AppContentShell`, `AppActionPanel`, `AppMetricTile`, `AppStatusPill` e `AppResponsiveGrid`.
- **Preservar contrato de testes:** keys e fluxos existentes continuam.

## Alternativas consideradas

### A1 - Apenas refinar os containers atuais

Trocar `Container` por `AppCard`, ajustar espacamento e manter a estrutura vertical atual.

**Rejeitada.** Melhoraria a estetica local, mas manteria a arquitetura de prototipo, especialmente em desktop.

### A2 - Redesign operacional da Home Prestador com foundation

Recompor a Home Prestador como dashboard responsivo:

```txt
hero/availability operacional
metric tiles
painel de proxima acao/trabalho ativo
categorias e mensagens em coluna lateral
pedidos disponiveis em cards responsivos
```

**Escolhida.** Ataca o problema real de arquitetura visual sem mexer em backend.

### A3 - Redesenhar todo o fluxo Prestador

Mudar tambem abas, detalhe, acoes do pedido, pagamentos, settings e navegacao.

**Adiada.** E grande demais para M2.10.4 e aumentaria risco. Esta fase foca a Home.

## Escopo

### Entra

- Redesign da aba Inicio da Home Prestador em `lib/features/prestador/prestador_home_screen.dart`.
- Criar componentes visuais pequenos para a Home Prestador, se necessario:
  - disponibilidade online/offline;
  - metricas;
  - painel de proxima acao;
  - painel de categorias;
  - card/painel de pedidos disponiveis.
- Usar foundation M2.10.2:
  - `AppPageScaffold`
  - `AppContentShell`
  - `AppActionPanel`
  - `AppMetricTile`
  - `AppStatusPill`
  - `AppResponsiveGrid`
  - `AppSectionHeader`
- Melhorar estado online/offline com hierarquia visual forte.
- Melhorar cards de pedidos disponiveis.
- Preservar acoes:
  - Aceitar
  - Ignorar
  - Enviar orcamento quando aplicavel
  - Abrir detalhe
- Preservar keys:
  - `prestador_pedido_card_<pedidoId>`
  - `prestador_aceitar_pedido_<pedidoId>`
  - `prestador_ignorar_pedido_<pedidoId>`
  - `prestador_orcamento_dialog_later_button`
  - `prestador_orcamento_dialog_now_button`
  - `orcamento_min_field`
  - `orcamento_max_field`
  - `orcamento_msg_field`
  - `orcamento_enviar_button`
- Melhorar loading/empty/error.
- Desktop com layout em colunas.
- Tablet com grid intermediario.
- Mobile com uma coluna limpa.
- Adicionar testes Flutter dos componentes visuais/presenters novos.
- Atualizar docs/status M2.10.

### Nao entra

- Redesign completo da Home Cliente.
- Redesign completo da lista de trabalhos.
- Redesign completo do detalhe do pedido.
- Mudanca de regras de matching.
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

Manter a logica operacional existente no modulo Prestador, mas extrair componentes visuais para reduzir complexidade.

Arquivos provaveis:

```txt
lib/features/prestador/prestador_home_screen.dart
lib/features/prestador/widgets/prestador_home_components.dart
test/features/prestador/widgets/prestador_home_components_test.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Componentes possiveis:

```txt
PrestadorAvailabilityPanel
PrestadorMetricStrip
PrestadorNextWorkPanel
PrestadorCategoriesPanel
PrestadorAvailableOrdersSection
PrestadorAvailableOrderCard
```

Regras:

- componentes visuais nao decidem permissao, matching ou regras financeiras;
- filtros existentes de categorias, raio, estado online e ignorados devem continuar no fluxo atual;
- componentes recebem dados ja derivados e callbacks;
- nao duplicar logica de `PedidoService`;
- manter `PedidoListPresenter` quando fizer sentido;
- manter `PrestadorPedidoAcoes` fora desta fase, salvo ajuste visual pequeno inevitavel.

## Layout desejado

### Mobile

Uma coluna direta:

```txt
Disponibilidade online/offline
Metricas compactas
Trabalho que exige acao, se existir
Mensagens, se houver
Categorias/configuracao
Pedidos compativeis
```

Caracteristicas:

- switch de online/offline facil de tocar;
- CTA claro quando offline;
- pedido disponivel com aceitar/ignorar visiveis;
- sem cards gigantes;
- sem overflow horizontal.

### Tablet

Composicao intermediaria:

```txt
Disponibilidade em largura total
Metricas em 2 colunas
Pedidos compativeis em grid
Categorias/mensagens abaixo ou ao lado
```

### Desktop/Web/Windows

Dashboard operacional:

```txt
Topo: disponibilidade + metricas principais
Coluna principal: pedidos compativeis e trabalho ativo
Coluna lateral: categorias, mensagens, resumo operacional
```

Caracteristicas:

- melhor uso da largura;
- pedidos disponiveis em cards com boa densidade;
- coluna lateral sem parecer lixo visual;
- disponibilidade sempre visivel no topo;
- sem mobile esticado.

## UX por area

### Disponibilidade online/offline

O estado deve ser visualmente forte:

```txt
Online
Pronto para receber pedidos compativeis.
```

```txt
Offline
Ativa para receber novos pedidos.
```

O switch atual continua, mas deve parecer comando principal, nao detalhe secundario.

### Metricas

Usar metricas simples que ja existem:

```txt
Ganhos hoje liquido
Servicos este mes
Bruto/Taxa como suporte discreto
```

Nao adicionar pagamentos reais nem nova logica financeira.

### Trabalho em destaque

Se houver pedido com acao pendente para o prestador, mostrar como painel forte:

```txt
Tens um trabalho para gerir
Enviar orcamento / iniciar servico / enviar valor final
Abrir trabalho
```

O painel abre o detalhe do pedido.

### Categorias

Categorias devem aparecer como estado operacional:

```txt
Categorias de atuacao
3 selecionadas
Editar categorias
```

Se nao houver categorias:

```txt
Seleciona categorias para receber pedidos compativeis.
```

### Pedidos disponiveis

Os pedidos disponiveis devem ter:

- titulo/categoria;
- estado/valor resumido via presenter;
- tipo de preco;
- tipo de pagamento;
- agendamento/imediato;
- descricao curta quando existir;
- botao `Aceitar` com maior prioridade;
- botao `Ignorar` secundario;
- keys atuais preservadas.

### Mensagens

Mensagens nao lidas devem aparecer como sinal operacional, sem dominar a tela:

```txt
Tens mensagens novas
No trabalho: <titulo>
Abrir conversa
```

## Compatibilidade funcional

Preservar:

- stream de pedidos do prestador;
- stream de pedidos disponiveis;
- sincronizacao `prestadores/{uid}.isOnline`;
- tracking de localizacao quando online;
- filtros por categorias e raio;
- lista de ignorados local;
- dialog de orcamento;
- chat meta apos aceitar pedido;
- navegacao para detalhe;
- navegacao para settings;
- keys de integracao.

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

- painel online mostra estado e chama callback ao alternar;
- painel offline mostra copy correta;
- metric tiles mostram ganhos/servicos;
- card de pedido disponivel preserva keys `prestador_aceitar_pedido_*` e `prestador_ignorar_pedido_*`;
- card de pedido disponivel chama callback de aceitar/ignorar;
- estado vazio offline orienta ativar disponibilidade;
- componente de categorias mostra categorias e CTA de edicao;
- layout nao quebra em largura mobile.

Validações finais:

```txt
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

## Criterios de aceitacao

- Home Prestador deixa de parecer lista vertical de prototipo em Web/Windows.
- Online/offline fica visualmente claro e acionavel.
- Pedidos disponiveis ficam mais fortes e operacionais.
- Acoes Aceitar/Ignorar continuam funcionais e com keys preservadas.
- Trabalho pendente fica facil de encontrar.
- Categorias e mensagens ficam integradas como operacao, nao blocos soltos.
- Mobile continua limpo e direto.
- Desktop usa composicao de dashboard.
- Testes principais continuam verdes.
- Nenhum backend, regra Firebase, Function ou deploy e alterado.

## Commit recomendado

```txt
Iniciar M2.10.4 home prestador redesign
```
