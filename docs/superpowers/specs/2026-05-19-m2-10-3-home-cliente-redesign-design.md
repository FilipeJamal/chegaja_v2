# M2.10.3 - Home Cliente redesign

## Contexto

A M2.10 foi aberta para tirar o ChegaJa do aspeto de prototipo e aproximar a experiencia de um produto real de servicos on-demand. A M2.10.1 definiu a direcao visual e a M2.10.2 entregou a foundation reutilizavel:

- `AppPageScaffold`
- `AppContentShell`
- `AppSectionHeader`
- `AppActionPanel`
- `AppStatusPill`
- `AppMetricTile`
- `AppResponsiveGrid`
- tokens responsivos em `AppTokens`

Commit de referencia:

```txt
39aea08d1bcc6e2785cab8ce858e9100010ad30e
Avancar M2.10.2 design system foundation
```

Esta fase aplica a foundation na primeira tela de produto que o Cliente usa com frequencia: a Home Cliente.

## Problema

A Home Cliente atual funciona, mas ainda comunica prototipo:

- o desktop/Web parece uma versao mobile esticada;
- ha muito espaco vazio sem funcao clara;
- a hierarquia visual entre saudacao, procura, servicos e pedidos nao orienta bem a acao principal;
- a area de servicos depende de altura fixa derivada do viewport, o que fragiliza layouts maiores;
- cards e botoes ainda nao tem presenca visual de produto premium;
- banners de pendencia/mensagens aparecem como blocos soltos, sem arquitetura operacional;
- a lista de servicos nao explora bem grid responsivo em Web/Windows;
- estados vazios/loading/erro ainda podem parecer tecnicos ou pobres visualmente.

O resultado e uma tela que permite operar, mas nao cria a sensacao de confianca, fluidez e clareza esperada em apps como Uber, Bolt e outros servicos on-demand.

## Objetivo

Transformar a Home Cliente numa tela operacional bonita, clara e responsiva, mantendo as funcionalidades existentes.

A Home Cliente deve responder rapidamente a tres perguntas:

```txt
1. Que servico posso pedir agora?
2. Tenho alguma acao pendente?
3. O que esta a acontecer com os meus pedidos?
```

## Principios visuais

- **Acao principal evidente:** criar/pedir servico deve ser a primeira intencao visual.
- **Desktop real:** usar largura em Web/Windows com composicao em colunas e grids, sem parecer mobile esticado.
- **Mobile direto:** em Android/mobile, manter uma coluna limpa, com CTA forte e sem densidade exagerada.
- **Cards com funcao:** cada card deve representar uma acao, estado ou informacao util, nao decoracao.
- **Densidade organizada:** reduzir espaco vazio sem encher a tela de ruido.
- **Consistencia com M2.10.2:** usar componentes core antes de criar estilos locais.
- **Nao copiar marcas:** usar Uber/Bolt como referencia de clareza, foco e confianca, sem replicar identidade visual.

## Alternativas consideradas

### A1 - Apenas maquilhar a tela atual

Trocar cores, aumentar sombras e ajustar margens na Home atual.

**Rejeitada.** Isso preserva a arquitetura visual fraca e nao resolve o problema de desktop/mobile.

### A2 - Redesign da Home Cliente com foundation M2.10.2

Recompor a tela usando `AppPageScaffold`, `AppContentShell`, `AppResponsiveGrid`, paineis de acao, status pills e tiles de servico.

**Escolhida.** Resolve a arquitetura visual e cria base para Home Prestador e demais telas.

### A3 - Redesenhar toda a navegacao Cliente agora

Alterar tabs, rotas, estrutura da app e fluxos maiores.

**Adiada.** E maior do que a M2.10.3 e aumenta risco sem necessidade.

## Escopo

### Entra

- Redesenhar a Home Cliente em `lib/features/cliente/cliente_home_screen.dart`.
- Usar `AppPageScaffold` e `AppContentShell` como estrutura visual.
- Criar hero operacional compacto com foco em:
  - saudacao;
  - pergunta principal, por exemplo "Que servico precisas?";
  - CTA forte para criar pedido/escolher servico;
  - entrada de procura clara.
- Reorganizar servicos/categorias em tiles mais fortes.
- Usar `AppResponsiveGrid` para servicos em tablet/desktop.
- Manter mobile em uma coluna limpa.
- Melhorar presenca visual de pedidos ativos/recentes na Home.
- Integrar pendencias e mensagens como paineis operacionais, nao banners soltos.
- Melhorar loading, empty state e erro da Home Cliente.
- Preservar navegacao e comportamento funcional existente.
- Preservar keys existentes usadas por testes Web/Android.
- Adicionar ou ajustar testes Flutter para a nova estrutura visual.
- Atualizar docs/status da M2.10.

### Nao entra

- Redesign completo da Home Prestador.
- Redesign completo da lista de pedidos.
- Redesign completo do detalhe do pedido.
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

Manter a tela no modulo atual, extraindo widgets privados quando isso reduzir complexidade.

Arquivos provaveis:

```txt
lib/features/cliente/cliente_home_screen.dart
test/features/cliente/cliente_home_screen_test.dart ou teste equivalente existente
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Widgets/presenters possiveis:

```txt
_ClienteHomeHero
_ClienteHomeOperationsPanel
_ClienteServicesSection
_ClienteServiceTile
_ClienteActiveOrdersPanel
_ClienteMessagesPanel
```

Regras:

- widgets visuais nao devem conter regra de negocio pesada;
- derivacoes simples de texto/estado podem ficar em helpers pequenos e testaveis;
- streams, servicos e navegacao existentes devem ser preservados;
- se houver `PedidoStatusPresenter` ou presenter de lista util, reutilizar em vez de duplicar texto;
- nao criar estilos locais quando componente core da M2.10.2 resolver.

## Layout desejado

### Mobile

Uma coluna:

```txt
Hero operacional
Procura/CTA
Pendencias ou pedidos ativos
Servicos principais
Mensagens/recentes
```

Caracteristicas:

- CTA grande e facil de tocar;
- tiles com altura estavel;
- textos curtos;
- sem grid apertado quando uma coluna for melhor;
- sem excesso de espaco vazio entre secoes.

### Tablet

Composicao intermediaria:

```txt
Hero em largura total
Grid de servicos 2 colunas
Painel de pedidos/mensagens abaixo ou ao lado, conforme largura
```

### Desktop/Web/Windows

Dashboard operacional:

```txt
Topo: hero compacto + acao principal
Coluna principal: servicos/categorias em grid
Coluna lateral: pendencias, pedidos ativos, mensagens/recentes
```

Caracteristicas:

- conteudo com largura maxima controlada por `AppContentShell`;
- usar `AppResponsiveGrid` para evitar lista estreita em tela grande;
- sem alturas fixas baseadas em porcentagem do viewport;
- aproveitar largura sem criar cartoes gigantes.

## Componentes esperados

### Hero operacional

Deve comunicar:

```txt
Ola, [nome se disponivel]
Que servico precisas?
```

Com CTA claro:

```txt
Criar pedido
```

ou, se a experiencia atual partir da escolha de servico:

```txt
Escolher servico
```

O texto deve ser direto, sem tom de landing page.

### Servicos/categorias

Os servicos devem parecer opcoes de produto, nao linhas de prototipo.

Cada tile deve ter:

- icone ou marcador visual consistente;
- nome do servico;
- modo/preco em `AppStatusPill` ou equivalente;
- indicacao de acao;
- area clicavel clara;
- dimensoes estaveis.

### Pendencias e pedidos ativos

Pedidos que exigem acao do cliente devem ter presenca visual maior que uma lista secundaria.

Exemplos:

```txt
Tens uma proposta para decidir
Valor final pendente de confirmacao
Pedido em andamento
```

O painel deve orientar a proxima acao e apontar para detalhe do pedido.

### Mensagens

Mensagens nao lidas devem ser integradas como sinal operacional:

```txt
Tens novas mensagens
Abrir conversas
```

Sem ocupar uma faixa grande se nao houver conteudo relevante.

### Empty/loading/error

- Loading deve parecer parte da tela, nao um estado tecnico solto.
- Empty state deve orientar a primeira acao.
- Erro deve explicar o que aconteceu e oferecer retry quando houver acao real.

## Compatibilidade funcional

Preservar:

- navegacao para criacao/detalhe de pedido;
- escolha de servico por modo;
- procura de servicos;
- mensagens nao lidas;
- pendencias de pedido;
- tabs existentes da area Cliente, se continuarem fazendo parte da tela;
- keys usadas por E2E e testes Android.

Se alguma key precisar mudar por exigencia visual, adicionar alias/compatibilidade em vez de quebrar teste existente sem necessidade.

## Testes

Adicionar ou ajustar testes Flutter para cobrir:

- Home Cliente renderiza hero operacional;
- CTA principal existe e esta acessivel;
- servicos aparecem como tiles/lista responsiva;
- estado vazio orienta criacao de pedido;
- pendencia de pedido aparece com proxima acao;
- erro/loading usam mensagens humanas;
- keys criticas permanecem disponiveis.

Validações finais:

```txt
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

## Criterios de aceitacao

- Home Cliente deixa de parecer mobile esticado em Web/Windows.
- Desktop usa composicao responsiva com melhor densidade e hierarquia.
- Mobile continua simples e direto.
- CTA principal fica visualmente forte.
- Servicos/categorias ficam mais claros e clicaveis.
- Pedidos ativos/pendencias ficam mais faceis de entender.
- Empty/loading/error ficam mais humanos.
- Funcionalidades existentes continuam preservadas.
- Testes principais continuam verdes.
- Nenhum backend, regra Firebase, Function ou deploy e alterado.

## Commit recomendado

```txt
Iniciar M2.10.3 home cliente redesign
```
