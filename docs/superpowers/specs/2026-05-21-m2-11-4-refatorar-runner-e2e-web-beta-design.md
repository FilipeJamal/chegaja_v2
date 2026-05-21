# M2.11.4 - Refatorar Runner E2E Web da Beta

Data: 2026-05-21

## Contexto

A M2.11.1 executou a beta interna Web/Windows sobre o commit:

```text
2a43fc645230d32ab08b812e7b07fdb723f19150
Avancar M2.11.1 execucao beta interna
```

O resultado foi deliberadamente honesto:

```text
base tecnica aprovada
Windows aprovado
Web build aprovado
Web E2E automatizado bloqueado no runner
beta interna completa ainda nao aprovada
```

Os comandos principais passaram:

```text
flutter test: 149/149
npm.cmd run test:scripts: passou
Firestore/Storage/Functions emulator: 37/37
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true: passou
flutter build windows --debug: passou
Windows cross-role: 5/5
```

O bloqueio ficou concentrado no runner `scripts/e2e/full_ui_dual_role_e2e.js`.
Nos cenarios `e2e:ui:dual` e `e2e:ui:orcamento`, o runner cria e aceita o
pedido, mas perde contexto na etapa do Prestador e cai na conversa antes de
enviar estimativa/orcamento.

## Problema

O runner E2E Web ainda depende demasiado de heuristicas visuais frageis:

```text
cliques por coordenada
texto visivel ambiguo
tentativas genericas de abrir detalhe
detecao insuficiente da tela atual
mistura entre detalhe do pedido e conversa/chat
validacao de estado tarde demais
```

Isto causa falso bloqueio de beta: a automacao nao consegue concluir o roteiro,
mesmo depois de o pedido ter avancado em Firestore.

O problema deve ser tratado como bloqueio de QA automatizado, nao como prova de
que o produto falhou. A M2.11.4 existe para tornar a validacao Web confiavel.

## Objetivo

Refatorar o runner E2E Web da beta para ser orientado por estado, por seletores
estaveis e por checkpoints Firestore apos cada acao importante.

O objetivo final e conseguir executar:

```cmd
npm.cmd run e2e:ui:dual
npm.cmd run e2e:ui:orcamento
```

com o app Web local em modo emulador, sem depender de cliques frageis e sem
confundir chat com detalhe do pedido.

## Principios

### Estado antes de proxima acao

Depois de cada acao relevante, o runner deve esperar o estado correto no
Firestore antes de continuar:

```text
pedido criado
prestador aceite
proposta enviada
proposta aceite
servico iniciado
valor final proposto
valor final confirmado
pedido concluido
```

### Navegacao explicita

O runner deve saber que tela espera abrir:

```text
Home Cliente
Home Prestador
Lista de pedidos
Detalhe do pedido
Chat
Dialog de orcamento
Dialog de valor final
```

Se abrir a tela errada, deve registar o contexto e falhar com mensagem clara.

### Keys e semantica em vez de coordenadas

Sempre que uma acao critica depender de UI, usar:

```text
keys existentes
labels estaveis
aria/semantics quando disponivel
titulo unico do pedido
pedidoId quando visivel ou disponivel
```

Coordenadas devem ser fallback temporario apenas quando documentado no codigo e
com uma falha clara se nao funcionar.

### Sem backend novo

A M2.11.4 nao altera backend, Firestore Rules, Storage Rules ou Cloud Functions.
Se forem necessarias keys minimas na UI para estabilizar automacao, elas devem
ser pequenas, sem impacto visual e sem mudar regra de negocio.

## Escopo

### 1. Auditoria do runner atual

Auditar:

```text
scripts/e2e/full_ui_dual_role_e2e.js
scripts/test/full_ui_dual_role_e2e.test.js
package.json
```

Mapear os pontos frageis:

```text
isOnOrderForm
ensureOrderForm
providerOpenDetail
providerAcceptAndQuote
clientAcceptProvider
providerStartAndFinish
clientConfirmFinalValue
runHappyPathScenario
runOrcamentoScenario
```

### 2. Helpers orientados por fluxo

Separar helpers claros dentro do runner ou em modulo auxiliar local:

```text
criarPedidoCliente
abrirDetalhePedidoCliente
abrirDetalhePedidoPrestador
aceitarPedidoPrestador
enviarOrcamentoPrestador
aceitarPropostaCliente
iniciarServicoPrestador
enviarValorFinalPrestador
confirmarValorFinalCliente
assertNotChatScreen
assertPedidoState
```

Os nomes no codigo podem continuar em ingles se esse for o padrao do ficheiro,
mas as responsabilidades precisam ficar separadas.

### 3. Checkpoints Firestore

Adicionar ou reforcar esperas por estado:

```text
created/open: pedido existe e clienteId correto
accepted: prestadorId correto e estado aceito
quotePending: statusProposta pendente_cliente
quoteAccepted: statusProposta aceita_cliente
serviceStarted: estado em_andamento
finalPending: statusConfirmacaoValor pendente_cliente
completed: estado/status concluido e split correto
```

### 4. Protecao contra chat/detalhe errado

O runner deve falhar cedo se estiver numa conversa quando a proxima acao exige
detalhe do pedido.

Mensagem de erro esperada:

```text
Expected pedido detail for pedido abc123 "Pedido teste", but current screen looks like chat.
```

### 5. Logs operacionais

Cada etapa deve logar:

```text
scenario
pedidoId
title
role atual
tela esperada
estado Firestore atual
acao seguinte
```

Isto deve facilitar diagnostico sem abrir screenshots primeiro.

### 6. Testes do runner

Expandir `scripts/test/full_ui_dual_role_e2e.test.js` para cobrir helpers puros
ou semi-puros:

```text
nao tratar perfil como formulario de pedido
detectar tela de chat como tela errada para detalhe
formatar erro de contexto com pedidoId/title
validar transicoes esperadas de Firestore
montar plano de proxima acao por estado
```

### 7. Execucao E2E

Rodar com emuladores e seed de servicos:

```cmd
npx.cmd firebase emulators:exec --only auth,firestore,storage "node scripts/seed_servicos.js --emulator-host=127.0.0.1 && npm.cmd run e2e:ui:dual"
npx.cmd firebase emulators:exec --only auth,firestore,storage "node scripts/seed_servicos.js --emulator-host=127.0.0.1 && npm.cmd run e2e:ui:orcamento"
```

Se o comando npm sem seed continuar a ser usado no futuro, a falta de catalogo
de servicos deve ser detectada com erro claro.

### 8. Documentacao

Atualizar:

```text
docs/M2_11_BETA_INTERNA_STATUS.md
docs/BETA_INTERNA_CHECKLIST_WEB_WINDOWS.md
```

Documentar:

```text
runner refatorado
validacoes executadas
resultado do dual
resultado do orcamento
bugs corrigidos
bugs pendentes
decisao da beta Web
```

## Fora do Escopo

```text
backend novo
Firestore Rules novas
Storage Rules novas
Cloud Functions novas
deploy real
smoke real
cleanup real
health real
Android fisico real
pagamentos reais
Play Store
package id final
HTTPS App Links
fechar M2.6
novas funcionalidades de produto
redesign visual
```

## Criterios de Aceitacao

A M2.11.4 fica aceite quando:

```text
runner E2E Web esta menos dependente de coordenadas
runner falha com contexto claro quando abre tela errada
detalhe do pedido e chat deixam de ser confundidos
npm.cmd run test:scripts passa
flutter test passa
Firestore/Storage/Functions emulator tests passam
e2e:ui:dual passa com app Web local e emuladores
e2e:ui:orcamento passa com app Web local e emuladores
docs de M2.11 registam a nova decisao da beta Web
M2.6 continua pendente de Android fisico real
```

Se `e2e:ui:dual` ou `e2e:ui:orcamento` ainda falhar, a fase pode ser avancada
apenas se:

```text
a falha estiver isolada
o erro for mais claro do que antes
o estado Firestore ate ao ponto da falha estiver documentado
houver bug aberto com proxima acao objetiva
```

## Resultado Esperado

Ao final da M2.11.4, a equipa deve conseguir confiar no runner Web para validar
a beta interna ou, no minimo, diagnosticar uma falha real com evidencia concreta
e sem ambiguidades entre detalhe, chat e perfil.
