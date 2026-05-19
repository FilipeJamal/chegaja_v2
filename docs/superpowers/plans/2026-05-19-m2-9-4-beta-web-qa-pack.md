# M2.9.4 Beta Web QA Pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validar a beta Web Cliente/Prestador como conjunto, corrigir apenas regressões pequenas de UX encontradas no QA e fechar a M2.9 se os critérios passarem.

**Architecture:** Esta fase é um QA pack, não uma feature nova. A execução usa testes locais, Firebase Emulator Suite e E2E Web existentes para provar consistência entre criação, lista, detalhe, ações, orçamento, valor final e estados finais. Correções só entram se forem pequenas, de UI/UX, e diretamente ligadas às alterações da M2.9.

**Tech Stack:** Flutter/Dart, Flutter test, Node.js scripts, Firebase Emulator Suite, Playwright E2E, Firebase Functions tests, documentação Markdown.

---

## File Structure

**Criar se houver evidência nova fora do status principal:**

- Nenhum ficheiro novo é obrigatório. A evidência deve ficar em `docs/M2_9_BETA_WEB_STATUS.md`.

**Modificar obrigatoriamente:**

- `docs/M2_9_BETA_WEB_STATUS.md`
  - Registrar comandos executados, resultados, bloqueios ambientais se existirem, correções pequenas se existirem e decisão final sobre fechar M2.9.

**Modificar apenas se QA encontrar bug pequeno de UX/regressão:**

- `lib/features/cliente/novo_pedido_screen.dart`
- `lib/features/cliente/aguardando_prestador_screen.dart`
- `lib/features/cliente/cliente_home_screen.dart`
- `lib/features/cliente/pedido_detalhe_screen.dart`
- `lib/features/cliente/widgets/cliente_pedido_acoes.dart`
- `lib/features/cliente/widgets/pedido_flow_presenter.dart`
- `lib/features/cliente/widgets/pedido_list_presenter.dart`
- `lib/features/cliente/widgets/pedido_status_presenter.dart`
- `lib/features/prestador/prestador_home_screen.dart`
- `lib/features/prestador/widgets/prestador_pedido_acoes.dart`
- Testes correspondentes em `test/features/cliente/widgets/` ou `test/features/cliente/`.

**Nao modificar nesta fase:**

- `functions/`
- `firestore.rules`
- `storage.rules`
- `firebase.json`
- `.github/workflows/`
- `.env`
- `android/key.properties`
- keystore
- ficheiros `artifacts/presentation_chegaja/~$*.pptx`

---

### Task 1: Pré-check e baseline do workspace

**Files:**
- Read: `docs/M2_9_BETA_WEB_STATUS.md`
- Read: `docs/superpowers/specs/2026-05-19-m2-9-4-beta-web-qa-pack-design.md`
- Read: `package.json`

- [ ] **Step 1: Confirmar branch e working tree**

Run:

```powershell
git branch --show-current
git status --short
git log -1 --oneline
```

Expected:

```text
main
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
caecb9b Iniciar M2.9.4 beta web QA pack
```

Se aparecerem alterações adicionais não relacionadas, parar e inspecionar antes
de continuar. As duas deleções `~$...pptx` devem continuar fora de qualquer
commit desta fase.

- [ ] **Step 2: Confirmar scripts disponíveis**

Run:

```powershell
npm.cmd run
```

Expected: a lista deve conter pelo menos:

```text
e2e:ui:dual
e2e:ui:orcamento
test:scripts
smoke:firebase:production
health:firebase:production
```

Nao executar `smoke:firebase:production`, `health:firebase:production` ou
cleanup nesta fase.

- [ ] **Step 3: Registar baseline no bloco de trabalho local**

Não editar docs ainda. Manter notas temporárias fora do repositório, por
exemplo no terminal ou no bloco de notas da sessão:

```text
M2.9.4 baseline:
- branch:
- head:
- working tree:
- scripts presentes:
```

Estas notas serão consolidadas em `docs/M2_9_BETA_WEB_STATUS.md` no Task 6.

---

### Task 2: Validações locais obrigatórias

**Files:**
- No file changes expected.

- [ ] **Step 1: Rodar Flutter tests**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed!
```

O contador esperado atual é próximo de:

```text
69/69
```

Se falhar, usar a falha como evidência de QA. Só corrigir nesta fase se a falha
for regressão pequena de UX da M2.9.

- [ ] **Step 2: Rodar testes de scripts**

Run:

```powershell
npm.cmd run test:scripts
```

Expected:

```text
passou sem exit code diferente de 0
```

Estes testes validam runner Android, cleanup auditável e health check parser. A
execução não deve tocar produção real.

- [ ] **Step 3: Rodar testes Firebase no Emulator Suite**

Run:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```text
37/37 passou
```

Se os testes falharem por emulador/porta presa, documentar o erro e repetir
apenas depois de limpar processos locais. Nao alterar Rules ou Functions nesta
fase.

- [ ] **Step 4: Confirmar que não houve alteração gerada**

Run:

```powershell
git status --short
```

Expected:

```text
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
```

Se `flutter test` ou scripts gerarem ficheiros temporários, remover apenas
artefatos temporários claramente gerados e nunca tocar nos dois `~$...pptx`.

---

### Task 3: Preparar ambiente Web local para E2E

**Files:**
- No file changes expected.

- [ ] **Step 1: Confirmar dependências Node e Functions**

Run:

```powershell
npm.cmd ci
cd functions
npm.cmd ci
cd ..
```

Expected:

```text
dependencies installed successfully
```

Se `npm ci` indicar lockfile incompatível, parar e reportar. Não fazer upgrade
de dependências nesta fase.

- [ ] **Step 2: Confirmar que o alvo Web do E2E é local**

Run:

```powershell
$env:TARGET_URL
```

Expected:

```text
vazio
```

Quando vazio, o script usa:

```text
http://localhost:5173
```

Se `TARGET_URL` estiver definido para produção ou outro domínio externo,
limpar a variável antes de E2E:

```powershell
Remove-Item Env:TARGET_URL
```

- [ ] **Step 3: Subir app Web local em janela separada**

Run em outro PowerShell dentro do repo:

```powershell
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173 --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Expected:

```text
Listening on http://127.0.0.1:5173
```

Manter este processo aberto enquanto os E2E rodam.

- [ ] **Step 4: Validar que o servidor responde**

Run no PowerShell principal:

```powershell
Invoke-WebRequest http://127.0.0.1:5173 -UseBasicParsing | Select-Object -ExpandProperty StatusCode
```

Expected:

```text
200
```

Se não responder, corrigir apenas ambiente local: porta, processo Flutter ou
firewall local.

---

### Task 4: Rodar E2E Web dual-role

**Files:**
- No file changes expected unless QA finds a small UX regression.

- [ ] **Step 1: Rodar E2E dual-role com emuladores**

Run:

```powershell
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run e2e:ui:dual"
```

Expected:

```text
E2E completed successfully
exit code 0
```

O script pode criar screenshots temporários fora do repo, em pasta temporária
do Windows. Não commitar artefatos de screenshot.

- [ ] **Step 2: Se falhar por ambiente, classificar bloqueio**

Ambiente bloqueado se o erro for um destes:

```text
Target app not reachable at http://localhost:5173
browser install missing
Firebase emulator port already in use
functions/node_modules/firebase-admin missing
```

Correções ambientais permitidas:

```powershell
npx.cmd playwright install chromium
cd functions; npm.cmd ci; cd ..
```

Se for porta ocupada, encerrar processo local que usa a porta e repetir. Não
alterar código de produto por falha ambiental.

- [ ] **Step 3: Se falhar por UX/regressão, recolher evidência**

Guardar no resumo da sessão:

```text
comando:
erro:
tela/ação:
expected:
actual:
ficheiro provável:
```

Só avançar para Task 7 se a falha for pequena e dentro do escopo:

```text
texto contraditorio
loading/erro bruto
proxima acao errada
card divergente do detalhe
key quebrada
```

---

### Task 5: Rodar E2E Web orçamento

**Files:**
- No file changes expected unless QA finds a small UX regression.

- [ ] **Step 1: Rodar E2E orçamento com emuladores**

Run:

```powershell
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run e2e:ui:orcamento"
```

Expected:

```text
E2E completed successfully
exit code 0
```

Este cenário deve validar o caminho de orçamento/valor final no Web local sem
produção real.

- [ ] **Step 2: Confirmar que orçamento e valor final continuam coerentes**

No output do E2E, confirmar que não há falhas nos pontos:

```text
proposta pendente
proposta aceita
valor final pendente
pedido concluido
commissionPlatform 15%
earningsProvider 85%
```

Se o E2E falhar antes de chegar a esses pontos, classificar como ambiente ou
regressão seguindo Task 4.

- [ ] **Step 3: Revalidar working tree**

Run:

```powershell
git status --short
```

Expected:

```text
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
```

Se houver artefatos gerados por E2E dentro do repo, inspecionar e remover
apenas se forem claramente temporários e não versionados.

---

### Task 6: Corrigir apenas regressões pequenas de UX, se existirem

**Files:**
- Modify only the minimal UI/test files related to the failing QA point.

- [ ] **Step 1: Decidir se esta task é necessária**

Esta task só deve ser executada se Task 4 ou Task 5 encontrar regressão pequena
de UX. Se os E2E passarem, marcar esta task como não necessária no status final
e seguir para Task 8.

- [ ] **Step 2: Escrever teste antes da correção**

Escolher o teste mais próximo do problema:

```text
test/features/cliente/widgets/pedido_status_presenter_test.dart
test/features/cliente/widgets/pedido_list_presenter_test.dart
test/features/cliente/widgets/pedido_flow_presenter_test.dart
test/features/cliente/widgets/pedido_list_card_test.dart
test/features/cliente/widgets/pedido_final_state_panel_test.dart
test/features/cliente/novo_pedido_screen_test.dart
```

Exemplo para texto de próxima ação divergente entre lista e detalhe:

```dart
test('cliente ve a mesma proxima acao para valor final pendente', () {
  final pedido = buildPedido(
    estado: 'aguarda_confirmacao_valor',
    statusConfirmacaoValor: 'pendente_cliente',
    precoPropostoPrestador: 120,
  );

  final status = PedidoStatusPresenter.forPedido(
    pedido,
    viewerRole: PedidoViewerRole.cliente,
  );
  final list = PedidoListPresenter.forPedido(
    pedido,
    viewerRole: PedidoViewerRole.cliente,
  );

  expect(list.nextAction, status.nextAction);
});
```

Adaptar o builder e nomes reais ao teste existente antes de executar.

- [ ] **Step 3: Confirmar que o teste falha pelo motivo certo**

Run o ficheiro de teste alterado:

```powershell
flutter test test/features/cliente/widgets/pedido_list_presenter_test.dart
```

Expected:

```text
FAIL no texto/estado que reproduz a regressao
```

Se falhar por assinatura ou import errado, corrigir o teste antes de tocar no
código de produção.

- [ ] **Step 4: Aplicar correção mínima**

Correções permitidas:

```text
ajustar texto no presenter
usar presenter existente em vez de string duplicada
preservar key existente
trocar mensagem bruta de erro por mensagem humana
alinhar status/nextAction entre card e detalhe
```

Correções não permitidas nesta fase:

```text
criar campo novo
mudar regra de negócio
alterar Firestore Rules
alterar Cloud Functions
alterar serviço autoritativo
fazer deploy
```

- [ ] **Step 5: Rodar teste específico e Flutter completo**

Run:

```powershell
flutter test test/features/cliente/widgets/pedido_list_presenter_test.dart
flutter test
```

Expected:

```text
teste especifico passou
All tests passed!
```

- [ ] **Step 6: Repetir E2E que encontrou a falha**

Run apenas o cenário que falhou:

```powershell
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run e2e:ui:dual"
```

ou:

```powershell
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run e2e:ui:orcamento"
```

Expected:

```text
exit code 0
```

---

### Task 7: Documentar evidência da M2.9.4

**Files:**
- Modify: `docs/M2_9_BETA_WEB_STATUS.md`

- [ ] **Step 1: Atualizar status para M2.9.4 avançada ou bloqueada**

Se tudo passou, alterar o bloco `Estado` para:

```text
M2.9: pronto para fechar
M2.9.4: avancado em beta web QA pack
```

Se algum E2E ficou bloqueado por ambiente, usar:

```text
M2.9: avancado, QA Web parcialmente validado
M2.9.4: avancado com bloqueio ambiental documentado
```

Não marcar M2.9 como fechada se houver regressão real pendente.

- [ ] **Step 2: Registrar comandos e resultados**

Adicionar em `docs/M2_9_BETA_WEB_STATUS.md` dentro de M2.9.4:

```markdown
Evidencia M2.9.4:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, X/X |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run e2e:ui:dual"` | passou ou bloqueio documentado |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run e2e:ui:orcamento"` | passou ou bloqueio documentado |
```

Substituir `X/X` pelo contador real do `flutter test`.

- [ ] **Step 3: Registrar correções ou ausência de correções**

Se não houve correção:

```markdown
Correcoes durante QA:

```text
nenhuma correcao de codigo foi necessaria
```
```

Se houve correção pequena, listar:

```markdown
Correcoes durante QA:

```text
arquivo alterado:
problema:
correcao:
teste que cobre:
```
```

- [ ] **Step 4: Registrar fora do escopo mantido**

Confirmar no status:

```text
Nao houve backend, Firestore Rules, Storage Rules, Cloud Functions, deploy,
smoke real, cleanup real, health real, Android fisico, pagamentos, Play Store,
package id final, HTTPS App Links ou fecho da M2.6.
```

---

### Task 8: Fechar M2.9 se critérios passarem

**Files:**
- Modify: `docs/M2_9_BETA_WEB_STATUS.md`

- [ ] **Step 1: Aplicar decisão final**

Se todos os critérios passaram, alterar o bloco `Estado` para:

```text
M2.9: fechado
M2.9.1: avancado em detalhe do pedido UX
M2.9.2: avancado em lista de pedidos UX
M2.9.3: avancado em beta web flow pack
M2.9.4: fechado com beta web QA pack
```

Manter:

```text
M2.6: avancado tecnicamente, pendente de Android fisico
```

- [ ] **Step 2: Adicionar resumo de fecho**

Adicionar ao final de `docs/M2_9_BETA_WEB_STATUS.md`:

```markdown
## Fecho M2.9

A M2.9 fica fechada como beta Web funcional Cliente/Prestador.

Entregas:

```text
detalhe do pedido UX
lista de pedidos UX
flow pack Cliente/Prestador
QA pack Web/local
consistencia lista <-> detalhe <-> fluxo
```

Limite importante:

```text
M2.9 fecha apenas a beta Web. A M2.6 continua pendente de Android fisico para
push real, upload nativo de anexos e permissoes nativas negadas.
```
```

- [ ] **Step 3: Revisar docs**

Run:

```powershell
rg -n "(TB[D])|(FIXM[E])|(\\?\\?\\?)|(placeholde[r])|(em abert[o])" docs\M2_9_BETA_WEB_STATUS.md docs\superpowers\plans\2026-05-19-m2-9-4-beta-web-qa-pack.md
git diff --check
```

Expected:

```text
sem resultados do rg
sem erros do git diff --check
```

---

### Task 9: Validação final e commit

**Files:**
- Modify: `docs/M2_9_BETA_WEB_STATUS.md`
- Optional code/test files only if Task 6 was necessary.

- [ ] **Step 1: Rodar validações finais**

Run:

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```text
flutter test: All tests passed
test:scripts: exit code 0
Firebase emulator tests: 37/37 passou
```

Se E2E Web passou em Task 4 e Task 5, não precisa repetir. Se houve correção em
Task 6, repetir o E2E afetado antes de fechar.

- [ ] **Step 2: Confirmar escopo Git**

Run:

```powershell
git status --short
```

Expected se não houve correção de código:

```text
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
 M docs/M2_9_BETA_WEB_STATUS.md
```

Expected se houve correção pequena:

```text
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
 M docs/M2_9_BETA_WEB_STATUS.md
 M lib/...
 M test/...
```

Nunca stagear os dois ficheiros `~$...pptx`.

- [ ] **Step 3: Stage controlado**

Sem correção de código:

```powershell
git add -- docs\M2_9_BETA_WEB_STATUS.md
```

Com correção pequena:

```powershell
git add -- docs\M2_9_BETA_WEB_STATUS.md lib\features\cliente\... test\features\cliente\...
```

Substituir os caminhos `...` apenas pelos ficheiros realmente alterados durante
Task 6.

- [ ] **Step 4: Commit de fecho**

Se M2.9 fechou:

```powershell
git commit -m "Fechar M2.9 beta web"
```

Se houve bloqueio ambiental ou regressão pendente:

```powershell
git commit -m "Avancar M2.9.4 beta web QA pack"
```

- [ ] **Step 5: Push**

Run:

```powershell
git push origin main
```

Expected:

```text
main -> main
```

---

## Final Handoff

No final da execução, reportar em português:

```text
commit final
validações executadas
E2E Web dual/orcamento: passou ou bloqueio documentado
correções aplicadas, se houver
estado final da M2.9
confirmação de que M2.6 continua pendente de Android físico
confirmação de que os ~$...pptx não entraram no commit
```
