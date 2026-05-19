# M2.9.4 Beta Web QA Pack e Fecho M2.9 Design

Data: 2026-05-19

## Estado

M2.9 melhora a beta Web funcional para Cliente e Prestador enquanto a M2.6
continua pendente de Android fisico.

M2.9.1 avancou o detalhe do pedido. M2.9.2 avancou listas e cards de pedidos.
M2.9.3 avancou o fluxo Web Cliente <-> Prestador. M2.9.4 deve validar o
conjunto inteiro e fechar a M2.9 apenas se a experiencia Web estiver coerente.

## Objetivo

Validar a experiencia Web completa Cliente/Prestador depois das melhorias de
UX da M2.9.1, M2.9.2 e M2.9.3.

A M2.9.4 deve responder:

```text
1. O fluxo Web faz sentido de ponta a ponta?
2. Lista, detalhe e acoes usam a mesma linguagem?
3. Os estados finais deixam claro que nao ha acao indevida?
4. Os testes locais e E2E existentes continuam verdes?
5. A M2.9 pode ser fechada sem fingir que a M2.6 foi resolvida?
```

## Escopo aprovado

Abordagem A2:

```text
QA Pack local/Web com correcao pequena de UX se encontrada, evidencias
documentadas e fecho da M2.9 se tudo passar.
```

Esta subfase e um pacote de validacao e acabamento. O foco nao e criar uma
feature nova, mas provar que o que foi construido na M2.9 funciona em conjunto.

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
usar Android fisico
adicionar pagamentos reais
mexer em Play Store
alterar package id final
alterar HTTPS App Links
fechar M2.6
criar funcionalidades grandes novas
refazer visualmente a app inteira
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
PedidoFlowPresenter
PedidoFinalStatePanel
```

Fluxos e telas principais para QA:

```text
lib/features/cliente/novo_pedido_screen.dart
lib/features/cliente/aguardando_prestador_screen.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/cliente/pedido_detalhe_screen.dart
lib/features/cliente/widgets/cliente_pedido_acoes.dart
lib/features/prestador/prestador_home_screen.dart
lib/features/prestador/widgets/prestador_pedido_acoes.dart
```

Scripts e testes relevantes:

```text
npm.cmd run e2e:ui:dual
npm.cmd run e2e:ui:orcamento
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Os E2E Web dependem de app Web local e emuladores. A M2.9.4 deve documentar
como foram executados ou, se houver bloqueio ambiental, qual foi o bloqueio.

## Abordagens consideradas

### A1 - Fechar M2.9 apenas com testes unitarios

Rapido, mas insuficiente. A M2.9 alterou fluxo e UX entre telas; os testes de
widgets nao provam sozinhos a continuidade Cliente/Prestador.

### A2 - QA Pack Web/local com E2E existente

Recomendado. Usa a bateria local ja existente, roda E2E Web onde aplicavel,
corrige apenas bugs pequenos encontrados e documenta evidencia antes de fechar.

### A3 - Criar suite E2E nova e ampla

Mais completo, mas grande demais para o fecho da M2.9. Pode virar fase futura
se os E2E atuais nao cobrirem pontos suficientes.

## Principios de QA

- Provar o conjunto, nao apenas cada tela isolada.
- Preferir testes existentes e evidencia reproduzivel.
- Corrigir apenas problemas pequenos de UX/regressao encontrados durante QA.
- Se surgir bug de regra, backend ou schema, documentar e abrir fase propria.
- Nao criar dados reais em producao.
- Nao esconder bloqueios: se um E2E local depender de ambiente que nao esta
  disponivel, documentar claramente.
- Preservar keys existentes que protegem testes Android/Web.

## Fluxos de QA esperados

### 1. Cliente cria pedido

Validar:

```text
feedback pos-criacao claro
navegacao para aguardando/detalhe/lista sem tela morta
estado inicial compreensivel
loading e erro humanos
```

### 2. Prestador aceita e inicia

Validar:

```text
card/lista mostra estado e proxima acao coerentes
detalhe mostra banner e proxima acao coerentes
aceitar convite/pedido preserva comportamento atual
iniciar trabalho da feedback claro
```

### 3. Orcamento, proposta e valor final

Validar:

```text
faixa estimada nao parece valor final
proposta pendente e clara para Cliente e Prestador
valor final pendente explica confirmacao do cliente
conclusao mostra estado final sem acao indevida
split financeiro continua vindo das Functions/backend nos testes existentes
```

### 4. Cancelamento

Validar:

```text
cancelamento por Cliente/Prestador mostra linguagem humana
lista e detalhe nao sugerem seguir fluxo cancelado
motivo/responsavel aparece quando ja existir no modelo
```

### 5. Consistencia lista <-> detalhe <-> fluxo

Validar:

```text
status com mesmo nome
proxima acao compativel
tom consistente para aguardar, aceitar, iniciar, confirmar e finalizar
sem excecao bruta para utilizador final nos pontos alterados da M2.9
```

## Plano de validacao

Validacao obrigatoria local:

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Validacao Web/E2E esperada:

```powershell
npm.cmd run e2e:ui:dual
npm.cmd run e2e:ui:orcamento
```

Se os E2E exigirem app Web local, usar o padrao documentado pelo proprio script:

```powershell
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173
```

Quando necessario, executar E2E com emuladores Firebase locais. Nao usar
producao real para fechar esta subfase.

## Correcao de bugs durante QA

Se a validacao encontrar problemas pequenos e diretamente relacionados a M2.9,
podem entrar nesta subfase:

```text
texto contraditorio
loading/erro bruto
proxima acao errada
estado final com acao indevida
card/lista divergente do detalhe
key perdida ou comportamento de botao quebrado
```

Se aparecer problema maior, deve ser documentado como pendencia e nao empurrado
para dentro do fecho:

```text
mudanca de backend
mudanca de Rules
mudanca de Functions
schema novo
pagamento real
Android fisico
deploy real
```

## Documentacao esperada

Atualizar:

```text
docs/M2_9_BETA_WEB_STATUS.md
```

Registrar:

```text
M2.9.4 iniciada
comandos executados
resultado dos E2E Web
correcoes pequenas aplicadas, se houver
pendencias fora do escopo
decisao final sobre fechar M2.9
```

Se a M2.9 for fechada, o status deve manter claro:

```text
M2.6 continua pendente de Android fisico
M2.9 fecha apenas a beta Web
```

## Criterios de aceitacao

M2.9.4 pode fechar a M2.9 quando:

```text
flutter test passa
npm.cmd run test:scripts passa
Functions/Firestore/Storage emulator tests passam
E2E Web dual passa ou bloqueio ambiental e documentado
E2E Web orcamento passa ou bloqueio ambiental e documentado
lista, detalhe e fluxo ficam coerentes
nao ha regressao conhecida nos pontos de UX da M2.9
docs/status M2.9 atualizados
nao houve backend, rules, Functions, deploy, smoke real, cleanup real ou Android fisico
```

## Riscos

- E2E Web pode depender de servidor local, browser e emuladores ativos. O plano
  de implementacao deve tratar isso explicitamente.
- Bugs pequenos de UX podem aparecer durante QA. Corrigir apenas se estiverem
  dentro do escopo e forem de baixo risco.
- Fechar M2.9 nao fecha M2.6. O status final deve evitar essa ambiguidade.
- Nao misturar as delecoes antigas dos ficheiros `~$...pptx`.

## Decisao

Avancar com M2.9.4 usando a abordagem A2:

```text
Beta Web QA Pack local/Web, com E2E existente, documentacao de evidencia e
fecho da M2.9 se os criterios passarem.
```

Sem backend, regras Firebase, Functions, deploy, smoke real, cleanup real,
health real, pagamentos, Play Store, Android fisico ou fecho da M2.6.
