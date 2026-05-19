# M2.10.1 Visual Audit e Direcao de Design

Data: 2026-05-19

## Estado

M2.9 esta fechada como beta Web funcional.

```text
M0: fechado
M2.5: parcial
M2.6: avancado tecnicamente, pendente de Android fisico
M2.7: fechado
M2.8: fechado
M2.9: fechado
M2.10: proxima fase visual/produto
M2.10.1: spec de auditoria visual e direcao de design
```

## Problema

O ChegaJa ja esta mais forte em testes, regras, Functions, operacoes e fluxo
Web Cliente/Prestador. O problema atual e outro: a experiencia visual ainda
parece prototipo.

Sintomas observados:

```text
muito espaco vazio sem funcao em Web/Windows
conteudo principal demasiado estreito em desktop
hierarquia visual fraca entre titulo, status, pedido, timeline e acoes
cards com pouco peso visual ou repetidos sem uma arquitetura clara
botoes longos, pouco premium e nem sempre bem agrupados por importancia
alertas/banners com aparencia funcional, mas pouco refinada
timeline e estado do pedido ocupam largura sem criar uma composicao rica
home Cliente e home Prestador ainda parecem telas de MVP
desktop parece mobile esticado ou canvas vazio
Android precisa continuar simples, mas com mais acabamento
```

A imagem fornecida pelo utilizador evidencia bem o problema no detalhe do
pedido: ha uma faixa larga vazia no lado direito, os blocos nao formam uma
composicao de produto, e a pagina nao usa bem a largura disponivel.

## Objetivo da M2.10

Transformar o ChegaJa de uma beta funcional para uma experiencia visual mais
profissional, organizada e prazerosa, com principios de apps on-demand como
Uber, Bolt e servicos de mercado local.

O objetivo nao e copiar marcas, cores ou layout de terceiros. O objetivo e
adaptar principios:

```text
acao principal evidente
estado do servico sempre compreensivel
preco/valor/status visiveis sem procurar
cards densos, legiveis e com boa hierarquia
navegacao direta
responsividade real para Web, Windows e Android
visual limpo, confiante e consistente
```

## Referencias consultadas

### Uber/Base

Uber descreve o Base Web como um sistema com componentes reutilizaveis, tokens
de design, consistencia, acessibilidade e base personalizavel para varios
produtos internos. Tambem descreve design como trabalho de clareza, craft e
colaboracao entre Produto e Engenharia.

Licoes para o ChegaJa:

```text
criar fundacao visual reutilizavel antes de redesenhar tela por tela
usar tokens de cor, spacing, tipografia, radius e layout
tratar acessibilidade como parte do acabamento, nao como extra
evitar componentes soltos com estilos locais divergentes
```

Fonte:

```text
https://www.uber.com/au/en/blog/introducing-base-web/
https://jobs.uber.com/en/teams/design/
```

### Bolt

Bolt comunica no app acoes curtas e essenciais: pedir em segundos, preco
transparente, escolher tipo de servico, acompanhar em tempo real e chegar com
confianca. A marca tambem reforca escala e acessibilidade no seu sistema visual.

Licoes para o ChegaJa:

```text
reduzir atrito no inicio do fluxo
dar visibilidade imediata ao estado do pedido
mostrar valor/preco com linguagem clara
usar CTAs fortes e especificos
organizar servicos e pedidos por relevancia operacional
```

Fonte:

```text
https://apps.apple.com/us/app/bolt-request-a-ride/id675033630
https://bolt.eu/en-ch/company/brand/
```

## Principios de design para o ChegaJa

### 1. Utilitario premium

ChegaJa deve parecer uma ferramenta de servicos reais, nao uma landing page nem
um prototipo. A UI deve ser limpa, direta, com poucos enfeites e boa densidade.

Decisoes:

```text
sem herois decorativos gigantes nas telas operacionais
sem cards dentro de cards
sem gradientes decorativos sem funcao
sem listas soltas em canvas vazio
priorizar paineis, listas densas, filtros e CTAs claros
```

### 2. Estado antes de detalhe

Em servicos on-demand, o utilizador precisa de entender primeiro:

```text
o que esta a acontecer
quem deve agir
qual e o proximo passo
quanto custa ou pode custar
se esta seguro continuar
```

Cada tela importante deve responder a essas perguntas antes de mostrar detalhes
secundarios.

### 3. Desktop nao e mobile esticado

Web/Windows devem ter layout proprio:

```text
largura util maior
conteudo em duas colunas quando fizer sentido
painel principal + painel lateral de resumo/acompanhamento
listas com densidade mais alta
acoes fixas ou agrupadas em zona previsivel
```

Android deve continuar:

```text
uma coluna
CTA primario visivel
menos densidade
cards respiraveis
sem depender de hover
```

### 4. Densidade com ordem

O problema atual nao e apenas "espaco vazio"; e falta de composicao. A M2.10
deve trocar espaco ocioso por informacao util, sem poluir.

Exemplos:

```text
desktop detalhe pedido: coluna esquerda com progresso e dados principais,
coluna direita com proxima acao, valor, contacto, chat/anexos

home prestador: painel operacional com online/offline, pedidos disponiveis,
trabalhos ativos, ganhos/atividade e alertas

home cliente: entrada para novo pedido, servicos frequentes, pedidos ativos,
historico recente e mensagens relevantes
```

### 5. Componentes antes de telas

A M2.10 nao deve aplicar estilos locais em cada tela. Primeiro devem existir
componentes suficientes para refazer telas com consistencia.

Componentes candidatos:

```text
AppPageScaffold
AppContentShell
AppSectionHeader
AppHeroActionPanel
AppMetricTile
AppActionPanel
AppStatusPill
AppTimelineStep
AppResponsiveGrid
AppBottomActionBar
AppDesktopSidePanel
AppServiceTile
```

Os nomes finais podem mudar no plano, mas a responsabilidade deve ficar clara.

## Auditoria visual por area

### Home Cliente

Problemas atuais:

```text
entrada principal para criar pedido ainda pode ter pouco destaque
servicos/categorias parecem lista funcional, nao marketplace de servicos
pedidos ativos nao competem visualmente bem com a acao principal
desktop usa largura limitada demais para uma home operacional
```

Direcao:

```text
topo com acao forte: "Que servico precisas agora?"
campo/CTA de criacao com presenca visual clara
categorias em tiles com icone, titulo e subtitulo curto
pedidos ativos numa faixa ou coluna visivel
desktop com layout em grid: servicos + atividade/pedidos recentes
```

### Home Prestador

Problemas atuais:

```text
estado online/offline deve parecer comando operacional central
pedidos disponiveis precisam maior destaque e melhor hierarquia
cards de pedidos ainda podem parecer repetitivos
desktop nao aproveita bem painel lateral/metricas
```

Direcao:

```text
painel de trabalho com estado online/offline e proxima recomendacao
pedidos disponiveis em cards densos, com valor, distancia/servico/status
acoes "Aceitar" e "Ignorar" fortes, mas bem diferenciadas
metricas simples: ativos, concluidos recentes, ganhos estimados se ja existirem
```

### Lista de pedidos

Problemas atuais:

```text
M2.9 melhorou texto e estado, mas a composicao ainda e basica
desktop pode ter filtros, grupos e resumo lateral
ativos/concluidos/cancelados devem ser reconheciveis de longe
```

Direcao:

```text
tabs ou segmented control para Ativos / Historico
chips de status mais fortes e padronizados
cards com grid interno consistente
proxima acao em zona fixa do card
empty states com acao primaria real
```

### Detalhe do pedido

Problemas atuais:

```text
conteudo ocupa uma faixa estreita e deixa muito branco em desktop
banners, timeline e acoes aparecem empilhados sem composicao forte
timeline larga demais para pouco conteudo
acoes principais ficam isoladas e perdem contexto
```

Direcao:

```text
desktop em duas colunas
cabecalho com estado, titulo, servico, valor e chip
coluna principal com timeline, descricao, anexos, chat/resumo
coluna lateral com proxima acao, acoes, contacto e valor
mobile mantem uma coluna e acoes no fim ou bottom action bar
```

### Criacao de pedido

Problemas atuais:

```text
fluxo pode parecer formulario longo
prioridade visual entre servico, local, preco, anexos e modo deve melhorar
feedback pos-criacao ja existe, mas pode ficar visualmente mais confiante
```

Direcao:

```text
wizard leve ou secoes com progresso
resumo persistente do pedido em desktop
CTA final forte e sempre claro
erros em contexto, nao apenas snackbars
```

### Estados loading/erro/vazio

Problemas atuais:

```text
variam entre telas
alguns estados ainda parecem fallback tecnico
vazio sem acao pode parecer app quebrada
```

Direcao:

```text
estado vazio sempre tem titulo, descricao curta e acao quando aplicavel
loading usa skeletons em listas/cards importantes
erro explica o que falhou e oferece retry/voltar quando fizer sentido
```

## Arquitetura visual proposta

### Foundation

Primeiro consolidar tokens e componentes base:

```text
spacing responsivo
larguras maximas por tipo de tela
page scaffold responsivo
cards com variantes de produto
botoes com hierarquia forte
chips/status pills
section headers
metric tiles
```

### Layout responsivo

Breakpoints propostos:

```text
mobile: ate 599
tablet: 600 a 1023
desktop: 1024+
wide desktop: 1280+
```

Regras:

```text
mobile usa uma coluna e CTA direto
tablet pode usar grid de 2 colunas em cards
desktop deve usar largura util maior e layout em duas colunas
wide desktop nao deve espalhar conteudo sem limite
```

### Estilo visual

Direcao de cor:

```text
manter identidade ChegaJa com verde/teal como acao primaria
usar neutros mais refinados para fundo e superficies
usar azul escuro apenas para estrutura/contraste, nao dominar tudo
usar warning/error/success com consistencia sem excesso de saturacao
```

Direcao de tipografia:

```text
titulos fortes, mas proporcionais ao contexto
menos textos grandes dentro de cards pequenos
labels consistentes para status, metrica e acao
numero/preco com peso visual apropriado
```

Direcao de formas:

```text
radius controlado
cards de 8 a 12 px quando possivel
botoes sem excesso de arredondamento
chips arredondados apenas para status/filtros
```

## Plano macro da M2.10

### M2.10.1 - Visual audit e direcao de design

Entrega:

```text
spec visual
problemas atuais identificados
referencias documentadas
macroplano M2.10
criterios de aceite
```

Sem codigo.

### M2.10.2 - Design system foundation

Entrega esperada:

```text
tokens refinados
AppPageScaffold/AppContentShell responsivo
section headers
status pills
metric tiles
action panels
testes de componentes
```

### M2.10.3 - Home Cliente redesign

Entrega esperada:

```text
home cliente com hero operacional compacto
servicos em tiles melhores
pedidos ativos com presenca
desktop com grid real
mobile limpo e direto
```

### M2.10.4 - Home Prestador redesign

Entrega esperada:

```text
painel operacional do prestador
online/offline visualmente forte
pedidos disponiveis com hierarquia
acoes preservadas e mais claras
desktop com painel/metricas
```

### M2.10.5 - Pedido/listas/detalhe polish

Entrega esperada:

```text
detalhe em duas colunas no desktop
acoes agrupadas em painel claro
lista e detalhe visualmente consistentes
timeline mais compacta e premium
```

### M2.10.6 - Responsividade Web/Windows/Android

Entrega esperada:

```text
auditoria em larguras desktop, tablet e mobile
ajustes de overflow
sem texto cortado em botoes/cards
Windows sem canvas vazio
Android sem densidade excessiva
```

### M2.10.7 - QA visual e fecho M2.10

Entrega esperada:

```text
flutter test
test:scripts
Firebase emulator tests
screenshots/playwright ou browser local quando aplicavel
documentacao final
fecho da M2.10 se criterios passarem
```

## Fora do escopo da M2.10.1

```text
alterar codigo de producao
alterar backend
alterar Firestore Rules
alterar Storage Rules
alterar Cloud Functions
fazer deploy
rodar smoke real
rodar cleanup real
rodar health real
pagamentos reais
Play Store
Android fisico
package id final
HTTPS App Links
fechar M2.6
```

## Guardrails para implementacao futura

```text
nao fazer "skin" superficial por tela
nao criar estilos locais duplicados
nao quebrar keys existentes dos testes Web/Android
nao remover funcionalidades ja validadas
nao mudar regra de negocio em componentes visuais
nao usar marcas, logos, cores ou assets de Uber/Bolt
nao transformar telas operacionais em landing pages
```

## Criterios de aceite da M2.10.1

```text
spec visual criada e commitada
problemas visuais atuais identificados
direcao visual definida
referencias documentadas
macroplano M2.10 organizado
escopo e fora de escopo claros
sem alteracao de codigo de producao
```

## Decisao

A M2.10 deve ser tratada como fase grande de produto visual. A prioridade nao
e mais adicionar texto ou pequenos cards isolados. A prioridade e criar uma
arquitetura visual consistente que permita ao ChegaJa parecer app real em Web,
Windows e Android.

