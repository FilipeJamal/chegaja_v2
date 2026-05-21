# M2.11 - Beta Interna Controlada

Data: 2026-05-21

## Estado

```text
M2.11: em execucao de beta interna controlada
M2.11.1: avancado com troca de modo Cliente/Prestador pela UI
M2.11.2: avancado com roteiro, template de bugs e checklist Web/Windows
M2.11.3: avancado com execucao tecnica Web/Windows e bloqueio E2E Web documentado
M2.11.4: planeada para refatorar runner E2E Web da beta
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

## Proximo passo recomendado

```text
Executar validacoes tecnicas da beta:
- flutter test
- npm.cmd run test:scripts
- Firebase emulator tests
- flutter build web
- flutter build windows --debug
- e2e:ui:dual, se ambiente local permitir
- e2e:ui:orcamento, se ambiente local permitir
```
