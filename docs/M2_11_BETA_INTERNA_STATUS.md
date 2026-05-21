# M2.11 - Beta Interna Controlada

Data: 2026-05-21

## Estado

```text
M2.11: em execucao de beta interna controlada
M2.11.1: avancado com troca de modo Cliente/Prestador pela UI
M2.11.2: avancado com roteiro, template de bugs e checklist Web/Windows
M2.11.3: avancado com execucao tecnica Web/Windows e bloqueio E2E Web documentado
M2.11.4: avancada com runner E2E Web mais robusto; orcamento passou; dual bloqueado por cancelamento nas Rules
M2.11.5: avancada com permissao de cancelamento Cliente corrigida nas Firestore Rules; dual ainda bloqueado por navegacao/lista no cancelamento
M2.6: continua pendente de Android fisico real
```

## M2.11.1 - Troca de modo Cliente/Prestador pela UI

Problema corrigido:

```text
Antes, o app dependia de ?role=cliente ou ?role=prestador na URL para abrir o
modo inicial. Isso era aceitavel para desenvolvimento, mas inadequado para beta
interna, porque o tester nao deve precisar editar a URL.
```

Implementacao:

```text
RoleModeService criado para resolver e persistir o modo local.
Ordem de resolucao mantida:
1. role da URL, para desenvolvimento e automacao;
2. role persistido localmente;
3. DEFAULT_ROLE;
4. RoleSelectorScreen.

Conta Cliente ganhou acao "Mudar para modo prestador".
Conta Prestador ganhou acao "Mudar para modo cliente".
RoleSelectorScreen agora grava o modo escolhido localmente.
ChegaJaApp escuta RoleModeService e troca a home renderizada sem exigir nova
sessao.
```

Ficheiros principais:

```text
lib/core/services/role_mode_service.dart
lib/features/common/widgets/role_mode_switch_tile.dart
lib/app.dart
lib/features/auth/role_selector_screen.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
```

Testes adicionados:

```text
test/core/services/role_mode_service_test.dart
test/features/common/widgets/role_mode_switch_tile_test.dart
test/app_role_mode_test.dart
```

Validação executada:

```text
flutter test: 149/149 passou
```

## Fora do escopo mantido

```text
backend novo
Firestore Rules
Storage Rules
Cloud Functions
deploy real
smoke real
cleanup real
health real
Android fisico real
pagamentos reais
Play Store
package id final
HTTPS App Links
fecho da M2.6
```

## M2.11.2 - Pacote de beta interna

Documentos criados:

```text
docs/BETA_INTERNA_ROTEIRO_TESTE.md
docs/BETA_INTERNA_TEMPLATE_BUGS.md
docs/BETA_INTERNA_CHECKLIST_WEB_WINDOWS.md
```

Cobertura:

```text
roteiro Cliente/Prestador
Mensagens/chat
Conta/Perfil
troca Cliente/Prestador pela UI
template de bugs com severidade, frequencia e estado
criterios de aprovacao/reprovacao
checklist Web/Windows
validacoes tecnicas e E2E previstas
M2.6 explicitamente pendente de Android fisico real
```

## Plano de execucao

Plano criado:

```text
docs/superpowers/plans/2026-05-21-m2-11-beta-interna-controlada.md
```

Ordem recomendada:

```text
1. Consolidar status M2.11.
2. Criar roteiro executavel da beta interna.
3. Criar template de feedback e bugs.
4. Criar checklist tecnico de build e validacao.
5. Rodar validacoes tecnicas Web/Windows.
6. Atualizar resultados e decidir aprovacao, bloqueio ou ajustes.
```

Validacoes finais previstas:

```cmd
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter build windows --debug
npm.cmd run e2e:ui:dual
npm.cmd run e2e:ui:orcamento
```

## M2.11.3 - Execucao beta interna Web/Windows

Objetivo:

```text
Executar a beta interna controlada em Web/Windows, validar builds e roteiro
tecnico Cliente/Prestador, documentar bugs e decidir se a beta pode ser
aprovada.
```

Commit base testado:

```text
42841ff Avancar M2.11 pacote beta interna
```

Comandos executados:

```cmd
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173 --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
npx.cmd firebase emulators:exec --only auth,firestore,storage "node scripts/seed_servicos.js --emulator-host=127.0.0.1 && npm.cmd run e2e:ui:dual"
npx.cmd firebase emulators:exec --only auth,firestore,storage "node scripts/seed_servicos.js --emulator-host=127.0.0.1 && npm.cmd run e2e:ui:orcamento"
flutter build windows --debug
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:windows:cross"
```

Resultados:

```text
flutter test: 149/149 passou
npm.cmd run test:scripts: passou
Firestore/Storage/Functions emulator: 37/37 passou
flutter build web com RUN_FIREBASE_EMULATOR_TESTS=true: passou
servidor Web local em 127.0.0.1:5173: respondeu HTTP 200
flutter build windows --debug: passou
test:windows:cross: passou, 5/5 fluxos Windows
e2e:ui:dual Web: bloqueado no runner E2E apos pedido criado/aceite
e2e:ui:orcamento Web: bloqueado no runner E2E apos pedido criado/aceite
```

Correcoes aplicadas durante a execucao:

```text
scripts/e2e/full_ui_dual_role_e2e.js deixou de tratar formulario de perfil como
formulario de pedido.

scripts/e2e/full_ui_dual_role_e2e.js deixou de depender de um clique por
coordenada fixa para abrir o formulario de pedido.

scripts/e2e/full_ui_dual_role_e2e.js passou a tentar abrir detalhe por titulo e
por CTA visivel antes de acionar envio de estimativa.

scripts/test/full_ui_dual_role_e2e.test.js foi criado para proteger a deteccao
do formulario de pedido contra regressao.

integration_test/windows_cross_role_flow_test.dart deixou de escrever
prestadorId diretamente com auth de cliente no teste de chat e passou a aceitar
o pedido pelo PedidoService, respeitando as Rules.
```

Bugs registados:

```text
ID: M2.11-BUG-001
Titulo: E2E Web dual/orcamento perde contexto no fluxo do prestador
Papel: ambos
Plataforma: Web
Fluxo: pedido por orcamento / prestador envia estimativa
Frequencia: sempre nos runs desta execucao
Severidade: alto para QA automatizado
Estado: aberto
Resultado obtido: o runner cria e aceita o pedido, mas perde a tela de detalhe e
termina na conversa antes de enviar a estimativa.
Impacto: bloqueia aprovacao automatizada da beta Web. Precisa refatorar o
runner E2E para navegar por keys/semantica estavel em vez de heuristicas visuais
e coordenadas.

ID: M2.11-BUG-002
Titulo: Teste Windows de chat tentava simular participante com escrita negada
Papel: ambos
Plataforma: Windows
Fluxo: chat entre cliente e prestador
Frequencia: sempre antes da correcao
Severidade: medio
Estado: corrigido
Resultado obtido: permission-denied ao tentar gravar prestadorId diretamente com
auth de cliente.
Correcao: o teste passou a usar PedidoService.aceitarPedidoAberto pelo auth do
prestador antes de enviar mensagens.
```

Decisao da beta interna:

```text
Aprovada parcialmente para base tecnica e Windows.
Reprovada/bloqueada para aprovacao completa da beta Web automatizada.

Motivo:
- testes unitarios/widgets/scripts/Functions passaram;
- build Web e build Windows passaram;
- Windows validou pedido normal, orcamento e chat;
- mas os E2E Web dual/orcamento ainda nao concluem o fluxo Cliente/Prestador.

Proxima acao recomendada:
M2.11.4 - Refatorar runner E2E Web da beta para usar seletores/keys estaveis,
rodar novamente dual/orcamento e so entao decidir aprovacao final da beta Web.
```

## M2.11.4 - Planeamento runner E2E Web beta

Artefactos criados:

```text
docs/superpowers/specs/2026-05-21-m2-11-4-refatorar-runner-e2e-web-beta-design.md
docs/superpowers/plans/2026-05-21-m2-11-4-refatorar-runner-e2e-web-beta.md
```

Direcao tecnica:

```text
refatorar scripts/e2e/full_ui_dual_role_e2e.js para ser orientado por estado
separar helpers puros/testaveis para tela, estado e proxima acao
validar Firestore apos cada acao importante
evitar confundir chat/perfil/detalhe
reduzir cliques por coordenada
adicionar logs com pedidoId, role, tela esperada e estado atual
rodar novamente e2e:ui:dual e e2e:ui:orcamento
```

Limites mantidos:

```text
sem backend novo
sem Firestore Rules novas
sem Storage Rules novas
sem Cloud Functions novas
sem deploy real
sem smoke real
sem cleanup real
sem health real
sem Android fisico real
sem pagamentos reais
sem Play Store
sem fechar M2.6
```

## M2.11.4 - Execucao runner E2E Web beta

Objetivo:

```text
Refatorar o runner E2E Web para deixar de depender de cliques frageis e
classificar corretamente detalhe do pedido, chat, perfil e lista de pedidos.
```

Implementacao:

```text
scripts/e2e/full_ui_dual_role_e2e_helpers.js criado com helpers puros:
- detectScreenKind
- assertExpectedScreen
- describePedidoState
- nextProviderAction

scripts/e2e/full_ui_dual_role_e2e.js passou a:
- usar 127.0.0.1:5173 como TARGET_URL padrao;
- abrir Chromium headless por padrao;
- logar pedidoId, role, tela esperada e estado Firestore;
- evitar tratar lista de pedidos como detalhe so por conter "Enviar estimativa";
- evitar clicar no banner de trabalho do prestador, porque ele abre chat por design;
- clicar no CTA "Abrir/Ver detalhes" perto do titulo do pedido antes de acionar fluxos de detalhe;
- abrir o detalhe do Cliente antes de aceitar proposta;
- garantir Home Cliente antes de criar novos pedidos entre cenarios;
- sair do formulario "Novo pedido" antes de procurar um pedido por titulo.

scripts/test/full_ui_dual_role_e2e.test.js cobre regressao dos helpers e garante
que formulario de perfil nao e confundido com formulario de pedido.
```

Ambiente Web usado:

```text
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
servidor estatico local em http://127.0.0.1:5173
Firebase emulators auth/firestore/storage em background
seed de servicos executado com scripts/seed_servicos.js --emulator-host=127.0.0.1
```

Resultado E2E:

```text
npm.cmd run e2e:ui:orcamento: passou
- pedido por orcamento criado
- prestador enviou faixa 20-35
- cliente aceitou proposta
- prestador iniciou servico
- prestador enviou valor final 30
- cliente confirmou valor final
- pedido concluiu com commissionPlatform=4.5 e earningsProvider=25.5

npm.cmd run e2e:ui:dual: avancou alem do bloqueio antigo
- happy-path passou ate pedido concluido
- runner deixou de cair no chat antes de enviar estimativa
- runner abriu detalhe pelo CTA "Abrir"
- bloqueou no cenario de cancelamento Cliente
```

Novo bloqueio encontrado:

```text
ID: M2.11-BUG-003
Titulo: Cliente nao consegue cancelar pedido criado no E2E Web por permission-denied nas Rules
Papel: Cliente
Plataforma: Web
Fluxo: cancelamento enquanto "A encontrar prestador"
Frequencia: reproduzido no e2e:ui:dual apos refator do runner
Severidade: alta para aprovacao completa da beta Web
Estado: aberto
Resultado obtido:
  Firestore Emulator devolveu permission-denied ao tentar atualizar pedidos/{id}
  com status/estado=cancelado, canceladoPor=cliente e historico cancelado.
Impacto:
  O runner ja passou o antigo problema de navegacao/contexto, mas a beta Web
  dual continua bloqueada por permissao/regras no cancelamento Cliente.
Fora do escopo desta subfase:
  alterar Firestore Rules. A M2.11.4 focou runner E2E.
```

Decisao:

```text
M2.11.4 avancada parcialmente.
O runner E2E Web ficou mais robusto e o fluxo de orcamento passou.
A aprovacao completa da beta Web continua bloqueada pelo BUG-003 de
cancelamento Cliente nas Rules/emulador.
```

## M2.11.5 - Correcao de permissao/fluxo de cancelamento Cliente

Objetivo:

```text
Corrigir o BUG-003 sem mascarar o problema no runner.
O cliente dono do pedido deve conseguir cancelar um pedido permitido, com
canceladoPor=cliente e evento de historico, mas sem poder alterar campos
economicos, prestadorId ou pedidos finais.
```

Reproducao em teste:

```text
Foi adicionado um teste de Firestore Rules que reproduziu o mesmo bloqueio do
E2E Web:
- cliente dono tenta cancelar pedido em estado criado;
- update inclui status/estado=cancelado;
- canceladoPor=cliente;
- motivoCancelamento="";
- tipoReembolso=total;
- updatedAt serverTimestamp;
- historico com arrayUnion(evento=cancelado).

Antes da correcao, esse teste falhou com permission-denied e limite de
1000 expressoes, igual ao E2E Web.
```

Correcao aplicada:

```text
firestore.rules ganhou um caminho especifico para cancelamento pelo cliente:
- validPedidoClientCancellation();
- hasOnlyPedidoClientCancelFields();

Esse caminho evita passar pelo update generico quando o cliente esta a cancelar
o proprio pedido. A regra permite apenas os campos necessarios para cancelamento:
status, estado, updatedAt, canceladoPor, motivoCancelamento, tipoReembolso e
historico.

Tambem exige:
- cliente dono do pedido;
- transicao permitida para cancelado;
- canceladoPor exatamente "cliente";
- motivoCancelamento string quando existir;
- tipoReembolso limitado a total/parcial/nenhum/analise.
```

Testes de Rules adicionados:

```text
Positivo:
- cliente dono consegue cancelar o proprio pedido aberto com historico.

Negativos:
- outro cliente nao consegue cancelar pedido alheio;
- prestador nao consegue cancelar pedido aberto como cliente;
- cliente nao consegue cancelar pedido concluido;
- cliente nao consegue alterar campos economicos durante cancelamento;
- cliente nao consegue trocar prestadorId durante cancelamento.
```

Validações executadas:

```text
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test": 43/43 passou
flutter test: 149/149 passou
npm.cmd run test:scripts: passou
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true: passou
npm.cmd run e2e:ui:orcamento: passou
npm.cmd run e2e:ui:dual: ainda bloqueado, mas nao por permission-denied
```

Resultado do BUG-003:

```text
M2.11-BUG-003: corrigido no nivel Firestore Rules.
O teste que reproduzia o permission-denied agora passa.
No E2E dual, nao apareceu novo permission-denied no cancelamento Cliente.
```

Novo bloqueio encontrado:

```text
ID: M2.11-BUG-004
Titulo: E2E dual nao consegue chegar ao cancelamento porque a lista Cliente
mostra 0 pedidos ativos apos criar o pedido de cancelamento.
Papel: Cliente
Plataforma: Web/emulador
Fluxo: cancelamento Cliente apos criar pedido automatico
Frequencia: reproduzido no e2e:ui:dual apos correcao das Rules
Severidade: alta para aprovacao automatizada da beta Web
Estado: aberto

Evidencia:
- Firestore tinha o pedido criado com clienteId correto e estado=criado.
- A tela "Meus pedidos" mostrava Pendentes 0 e empty state.
- O runner nao conseguiu abrir o detalhe nem clicar em "Cancelar pedido".

Decisao:
Nao mascarar no runner nesta subfase. O BUG-003 foi corrigido; o dual continua
bloqueado por um novo problema de navegacao/lista/estado visual que deve ser
tratado numa subfase propria.
```

Decisao da M2.11.5:

```text
M2.11.5 avancada.
Permissao/Rules de cancelamento Cliente corrigidas com teste positivo e testes
negativos.
Beta interna Web completa ainda nao aprovada porque o e2e:ui:dual continua
bloqueado pelo novo M2.11-BUG-004.
```

## Proximo passo recomendado

```text
M2.11.5 - Corrigir permissao de cancelamento Cliente nas Rules ou ajustar o
fluxo autoritativo correspondente, com testes de regras antes de repetir
e2e:ui:dual.
```
