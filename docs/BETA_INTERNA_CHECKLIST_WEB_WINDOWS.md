# Beta Interna - Checklist Web/Windows

Data base: 2026-05-21

## Pre-check

```cmd
git branch --show-current
git status --short
git log -1 --oneline
```

Esperado:

```text
branch main
sem alteracoes inesperadas alem de temporarios conhecidos fora do commit
commit correto da beta no topo
```

## Validacoes Tecnicas

```cmd
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter build windows --debug
```

Se `flutter build windows --debug` nao for o comando correto para o ambiente,
usar o equivalente atual e documentar o comando executado.

## Web

Validar:

```text
Web local/emulador abre
Web build estatico abre
login/Auth anonimo funciona
Firestore emulador funciona
Storage emulador funciona quando aplicavel
navegacao por tabs funciona
sidebar desktop funciona
bottom navigation em viewport estreito funciona
responsividade basica sem overflow critico
nenhum botao principal fica escondido
troca Cliente/Prestador pela UI funciona
Mensagens funciona
Pedidos funciona
Conta/Perfil funciona
```

## Windows

Validar:

```text
Windows debug/build abre
layout desktop continua utilizavel
sidebar nao fica estreita ou vazia demais
scroll funciona
inputs recebem foco
SVGs e icones renderizam
pedidos/listas/detalhe abrem
mensagens abrem
conta/perfil abre
troca Cliente/Prestador pela UI funciona
```

## Proibido Nesta Fase

```text
deploy Firebase real
smoke real em producao
cleanup real
health real
pagamentos reais
Play Store
Android fisico real
fechar M2.6
backend novo
Firestore Rules novas
Storage Rules novas
Cloud Functions novas
```

## Evidencia a Registar

```text
data/hora
commit testado
plataforma
comandos executados
resultado de cada comando
prints ou videos quando houver bug visual
bloqueios ambientais
bugs encontrados
decisao final: aprovado / reprovado / aprovado com pendencias
```

## Execucao 2026-05-21 - M2.11.1

Commit base:

```text
42841ff Avancar M2.11 pacote beta interna
```

Resultado do checklist:

```text
Pre-check: passou, com alteracoes antigas fora do escopo mantidas fora do commit
flutter test: passou, 149/149
npm.cmd run test:scripts: passou
Firestore/Storage/Functions emulator: passou, 37/37
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true: passou
Web local em 127.0.0.1:5173: respondeu HTTP 200
flutter build windows --debug: passou
Windows cross-role integration: passou, 5/5 fluxos
e2e:ui:dual Web: bloqueado no runner E2E
e2e:ui:orcamento Web: bloqueado no runner E2E
```

Checklist Web:

```text
Web abre: passou
Auth/Firestore emulador: passou parcialmente; houve timeouts de bootstrap em runs longos do runner
Build Web estatico: passou
Troca Cliente/Prestador pela UI: coberta por flutter test
Fluxo Cliente/Prestador por E2E Web: bloqueado no runner
Mensagens Web: nao aprovado por E2E nesta execucao
Pedidos Web: criado/aceite no runner, mas fluxo nao concluiu
```

Checklist Windows:

```text
Windows debug/build abre no teste: passou
Fluxo Cliente pedido normal: passou
Fluxo Prestador pedido normal: passou
Fluxo Cliente orcamento: passou
Fluxo Prestador orcamento: passou
Chat cliente/prestador: passou apos correcao do seed do teste
```

Decisao:

```text
aprovado parcialmente com pendencia alta no E2E Web.
nao aprovado como beta interna completa ate refatorar e passar os runners Web.
```

## Execucao 2026-05-21 - M2.11.4

Commit base:

```text
6d9de30 Planear M2.11.4 runner E2E Web beta
```

Resultado do checklist E2E Web:

```text
Runner E2E Web refatorado com helpers puros e logs de estado.
Build Web debug com RUN_FIREBASE_EMULATOR_TESTS=true: passou.
Servidor estatico local em 127.0.0.1:5173: passou.
Emuladores auth/firestore/storage em background: passaram.
Seed de servicos no emulador: passou.
npm.cmd run e2e:ui:orcamento: passou.
npm.cmd run e2e:ui:dual: bloqueado no cancelamento Cliente.
```

Melhorias confirmadas:

```text
O runner deixou de confundir chat com detalhe do pedido no fluxo do prestador.
O runner passou a abrir detalhe pelo CTA "Abrir/Ver detalhes" perto do pedido.
O fluxo de orcamento concluiu ponta a ponta.
O happy-path do dual concluiu antes de chegar ao cenario de cancelamento.
```

Bloqueio aberto:

```text
M2.11-BUG-003
Cliente nao consegue cancelar pedido criado no E2E Web.
Firestore Emulator devolve permission-denied ao update do pedido para cancelado
com canceladoPor=cliente.

Classificacao: alto para beta Web automatizada.
Estado: aberto.
Proximo passo: corrigir Rules/fluxo autoritativo em subfase propria e repetir
npm.cmd run e2e:ui:dual.
```

## Execucao 2026-05-21 - M2.11.5

Objetivo:

```text
Corrigir M2.11-BUG-003: Cliente nao conseguia cancelar pedido proprio no E2E
Web por permission-denied nas Firestore Rules.
```

Checklist tecnico executado:

```text
flutter test: passou, 149/149
npm.cmd run test:scripts: passou
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test": passou, 43/43
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true: passou
seed de servicos no emulador: passou
npm.cmd run e2e:ui:orcamento: passou
npm.cmd run e2e:ui:dual: falhou em novo bloqueio de navegacao/lista no cancelamento
```

Resultado:

```text
M2.11-BUG-003: corrigido.
O cliente dono agora consegue cancelar pedido permitido nas Rules, incluindo
historico auditavel.

M2.11-BUG-004: aberto.
Depois da correcao de permissao, o e2e:ui:dual deixou de bloquear por
permission-denied, mas ainda nao consegue chegar ao botao de cancelamento
porque a UI Cliente mostra "Pendentes 0" apos criar o pedido de cancelamento,
mesmo com pedido criado em Firestore.
```

Decisao:

```text
Beta interna Web automatizada ainda nao aprovada.
A correcao de Rules esta validada, mas o dual completo precisa de nova subfase
para investigar a lista/navegacao do Cliente apos criar pedido.
```

## Execucao 2026-05-22 - M2.11.6

Objetivo:

```text
Corrigir M2.11-BUG-004: a UI Cliente nao mostrava o pedido recem-criado no
e2e:ui:dual, apesar de o pedido existir no Firestore com clienteId correto e
estado=criado.
```

Checklist tecnico executado:

```text
npm.cmd run test:scripts: passou
flutter test test/features/cliente/widgets/pedido_list_presenter_test.dart: passou
flutter test: passou, 150/150
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test": passou, 43/43
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true: passou
seed de servicos no emulador: passou
npm.cmd run e2e:ui:orcamento: passou
npm.cmd run e2e:ui:dual: avancou para alem do cancelamento Cliente e bloqueou no convite manual Prestador
```

Resultado:

```text
M2.11-BUG-004: corrigido.
O e2e:ui:dual agora consegue localizar o pedido de cancelamento na UI Cliente,
abrir o detalhe, clicar em cancelar e confirmar estado=cancelado /
canceladoPor=cliente no Firestore.

M2.11-BUG-005: aberto.
Depois de corrigir a lista/navegacao Cliente, o e2e:ui:dual chegou ao fluxo
manual-provider + chat + no-show. Nesse ponto, o Prestador nao conseguiu
aceitar o convite manual porque Firestore Emulator devolveu permission-denied
por limite de avaliacao de Rules no update.
```

Decisao:

```text
Beta interna Web automatizada ainda nao aprovada.
O bloqueio de lista Cliente foi corrigido, mas o dual completo precisa de nova
subfase para corrigir a permissao/Rules do aceite de convite manual pelo
Prestador.
```

## Execucao 2026-05-22 - M2.11.7

Objetivo:

```text
Corrigir M2.11-BUG-005: Prestador convidado manualmente recebia
permission-denied ao aceitar convite no e2e:ui:dual.
```

Checklist tecnico executado:

```text
Teste RED de Firestore Rules: falhou antes da correcao, reproduzindo o BUG-005.
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test": passou, 51/51
flutter test: passou, 150/150
npm.cmd run test:scripts: passou
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true: passou
seed de servicos no emulador: passou
npm.cmd run e2e:ui:orcamento: passou
npm.cmd run e2e:ui:dual: falhou por novo bloqueio de stream/list de chat antes de confirmar novamente o convite manual
```

Resultado:

```text
M2.11-BUG-005: corrigido no nivel Firestore Rules.
O prestador convidado agora consegue aceitar convite manual em teste de Rules.
Foram adicionados negativos para impedir:
- outro prestador aceitar convite alheio;
- troca de prestadorId;
- troca de clienteId;
- alteracao de campos economicos;
- aceite de pedido cancelado/concluido;
- cliente aceitar como prestador.

M2.11-BUG-006: aberto.
O e2e:ui:dual deixou de evidenciar o BUG-005, mas ficou bloqueado antes de
chegar novamente ao cenario manual por erro em stream/list de mensagens:
PrestadorHome/PrestadorHomeBanner tentam ouvir /chats/{pedidoId}/messages e
recebem permission-denied. Depois disso, o Firestore Web SDK entra em erro
interno "Unexpected state" e o runner falha ao criar o pedido do cenario de
cancelamento.
```

Decisao:

```text
Beta interna Web automatizada ainda nao aprovada.
A correcao de Rules do aceite manual esta validada, e o fluxo de orcamento
continua aprovado, mas o dual completo precisa de nova subfase para corrigir o
M2.11-BUG-006 sem mascarar o runner.
```
