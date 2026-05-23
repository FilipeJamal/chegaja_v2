# M2.12 Pacote de Entrega Beta Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preparar um pacote de entrega beta Web/Windows que uma pessoa real consiga abrir, testar e reportar feedback sem depender do ambiente mental de desenvolvimento.

**Architecture:** A M2.12 deve ser executada como fase de entrega, nao como fase de produto. Os outputs versionados sao documentos, checklists, manifestos e status; os artefactos pesados de build devem ficar em `build/` ou numa pasta local fora do commit, salvo decisao explicita em contrario.

**Tech Stack:** Flutter Web, Flutter Windows, Firebase Emulator Suite, PowerShell, Markdown, documentos em `docs/`, roadmap A-T em `docs/ROADMAP_A_T_CHEGAJA.md`.

---

## File Structure

**Create**

- `docs/BETA_TESTER_GUIA_RAPIDO.md` - guia curto para o tester abrir a app, entender o escopo e saber como alternar Cliente/Prestador.
- `docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md` - roteiro de teste Cliente/Prestador em linguagem operacional.
- `docs/BETA_TESTER_FEEDBACK_FORM.md` - formulario de feedback geral de experiencia.
- `docs/BETA_TESTER_BUG_REPORT.md` - template de bug reproduzivel com severidade e evidencia.
- `docs/BETA_TESTER_CHECKLIST_ENTREGA.md` - checklist de entrega Web/Windows e criterios de aprovacao.
- `docs/BETA_TESTER_BUILD_INSTRUCTIONS.md` - instrucoes para gerar/abrir build Web e Windows.

**Modify**

- `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md` - registar plano, execucao, resultados de build, limitacoes e decisao final.
- `docs/ROADMAP_A_T_CHEGAJA.md` - atualizar Q2-Q8 conforme forem concluidos.

**Local outputs, not staged by default**

- `build/web/` - saida do `flutter build web`.
- `build/windows/x64/runner/Debug/` - saida do `flutter build windows --debug`.
- `C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\` - pasta local opcional para montar o pacote final do tester. Nao commitar sem decisao explicita.

**Do Not Touch**

- `functions/**`
- `firestore.rules`
- `storage.rules`
- `lib/core/services/**`
- `lib/core/repositories/**`
- `android/key.properties`
- qualquer keystore
- `.superpowers/`
- `artifacts/presentation_chegaja/~$*.pptx`

---

### Task 1: Consolidar estrutura da entrega beta

**Files:**
- Modify: `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`
- Modify: `docs/ROADMAP_A_T_CHEGAJA.md`

- [ ] **Step 1: Confirmar estado inicial**

Run:

```powershell
git branch --show-current
git status --short
git log -1 --oneline
```

Expected:

```text
main
somente .superpowers/ e os dois ~$...pptx fora do escopo, se ainda existirem
366b538 Registar roadmap A-T ChegaJa
```

- [ ] **Step 2: Atualizar status com plano de execucao**

Adicionar em `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`:

````markdown
## Plano de Execucao

```text
Q1: FECHADO - spec do pacote de entrega beta
Q2: em execucao - build Web beta preparado
Q3: em execucao - build Windows beta preparado
Q4: em execucao - guia rapido para tester
Q5: em execucao - roteiro simplificado
Q6: em execucao - template de feedback externo
Q7: em execucao - checklist de entrega
Q8: em execucao - pasta/pacote final para tester
```

Ordem:

```text
1. Criar documentos do tester.
2. Criar instrucoes de build Web/Windows.
3. Rodar validacoes tecnicas.
4. Gerar builds Web e Windows.
5. Montar manifest local do pacote.
6. Atualizar roadmap/status.
```
````

- [ ] **Step 3: Manter roadmap sem fechar tarefas cedo demais**

Em `docs/ROADMAP_A_T_CHEGAJA.md`, manter:

```text
Q1: FECHADO
Q2-Q8: FUTURO
```

So atualizar Q2-Q8 para `FECHADO` depois da execucao e evidencia de cada item.

- [ ] **Step 4: Validar diff**

Run:

```powershell
git diff --check
```

Expected:

```text
exit code 0
```

---

### Task 2: Criar guia rapido para tester

**Files:**
- Create: `docs/BETA_TESTER_GUIA_RAPIDO.md`

- [ ] **Step 1: Criar documento com orientacao inicial**

Criar `docs/BETA_TESTER_GUIA_RAPIDO.md`:

````markdown
# ChegaJa Beta - Guia Rapido do Tester

## Objetivo da Beta

Testar o ChegaJa como produto Web/Windows em fluxo Cliente e Prestador.

## O Que Testar

```text
abrir a app
mudar entre Cliente e Prestador pela UI
criar pedido
aceitar/iniciar/concluir pedido
testar orcamento/valor final
testar mensagens
testar conta/perfil
reportar bugs com passos claros
```

## O Que Nao Esta Nesta Beta

```text
pagamentos reais
Play Store
Android fisico real
package id final
HTTPS App Links
release publico
```

## Como Mudar Cliente/Prestador

```text
1. Abrir Conta/Perfil.
2. Usar "Mudar para modo prestador" ou "Mudar para modo cliente".
3. Confirmar que a Home mudou para o papel escolhido.
```

## Como Reportar Problemas

Para cada problema, enviar:

```text
plataforma: Web ou Windows
papel: Cliente ou Prestador
passos executados
resultado esperado
resultado obtido
screenshot ou video
severidade
frequencia
```
````

- [ ] **Step 2: Verificar linguagem de tester**

Run:

```powershell
Select-String -Path docs\BETA_TESTER_GUIA_RAPIDO.md -Pattern "Firestore|Rules|Functions|emulator|queryParameters"
```

Expected:

```text
sem resultados, exceto se estiver numa secao de limitacoes tecnicas claramente explicada
```

---

### Task 3: Criar roteiro simplificado Cliente/Prestador

**Files:**
- Create: `docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md`

- [ ] **Step 1: Criar roteiro com IDs de teste**

Criar `docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md`:

````markdown
# ChegaJa Beta - Roteiro Simplificado

## T01 - Abrir App

```text
Papel: Cliente
Plataforma: Web/Windows
Passos:
1. Abrir a app.
2. Confirmar que a Home aparece sem erro bloqueador.
Resultado esperado:
Home abre e permite escolher servico ou navegar.
```

## T02 - Criar Pedido como Cliente

```text
Papel: Cliente
Passos:
1. Escolher um servico.
2. Preencher o pedido.
3. Criar o pedido.
4. Abrir a lista/detalhe.
Resultado esperado:
Pedido aparece na lista e no detalhe com estado compreensivel.
```

## T03 - Trocar para Prestador

```text
Papel: Cliente -> Prestador
Passos:
1. Abrir Conta/Perfil.
2. Tocar em mudar para modo prestador.
Resultado esperado:
App mostra Home Prestador.
```

## T04 - Aceitar e Iniciar Pedido

```text
Papel: Prestador
Passos:
1. Ver pedido disponivel.
2. Aceitar pedido.
3. Abrir detalhe.
4. Iniciar servico quando disponivel.
Resultado esperado:
Pedido muda de estado e mostra proxima acao correta.
```

## T05 - Orcamento e Valor Final

```text
Papel: Cliente/Prestador
Passos:
1. Prestador envia estimativa/orcamento quando aplicavel.
2. Cliente aceita ou rejeita proposta.
3. Prestador envia valor final.
4. Cliente confirma ou questiona valor final.
Resultado esperado:
Fluxo chega ao estado final correto sem erro bloqueador.
```

## T06 - Mensagens

```text
Papel: Cliente/Prestador
Passos:
1. Abrir Mensagens.
2. Enviar mensagem como Cliente.
3. Trocar para Prestador.
4. Responder mensagem.
Resultado esperado:
Mensagens aparecem nos dois lados.
```

## T07 - Conta e Perfil

```text
Papel: Cliente/Prestador
Passos:
1. Abrir Conta/Perfil.
2. Confirmar nome, papel e opcoes principais.
3. Testar navegacao sem guardar dados sensiveis reais.
Resultado esperado:
Conta abre sem bloquear a navegacao.
```
````

- [ ] **Step 2: Conferir cobertura minima**

Run:

```powershell
Select-String -Path docs\BETA_TESTER_ROTEIRO_SIMPLIFICADO.md -Pattern "T01|T02|T03|T04|T05|T06|T07"
```

Expected:

```text
um resultado para cada ID T01-T07
```

---

### Task 4: Criar templates de feedback e bug report

**Files:**
- Create: `docs/BETA_TESTER_FEEDBACK_FORM.md`
- Create: `docs/BETA_TESTER_BUG_REPORT.md`

- [ ] **Step 1: Criar formulario de feedback**

Criar `docs/BETA_TESTER_FEEDBACK_FORM.md`:

````markdown
# ChegaJa Beta - Feedback Geral

## Identificacao

```text
Tester:
Data:
Plataforma: Web / Windows
Papel mais usado: Cliente / Prestador / Ambos
```

## Experiencia

```text
O que foi facil de entender?
O que foi confuso?
Em que momento teve duvida?
O visual parece produto real?
Que tela pareceu mais fraca?
Que tela pareceu melhor?
```

## Fluxos

```text
Conseguiu criar pedido? Sim / Nao
Conseguiu trocar Cliente/Prestador? Sim / Nao
Conseguiu testar mensagens? Sim / Nao
Conseguiu testar orcamento/valor final? Sim / Nao
Conseguiu abrir Conta/Perfil? Sim / Nao
```

## Nota Final

```text
Nota de 1 a 5:
Usaria novamente? Sim / Nao / Talvez
Principal melhoria recomendada:
```
````

- [ ] **Step 2: Criar bug report**

Criar `docs/BETA_TESTER_BUG_REPORT.md`:

````markdown
# ChegaJa Beta - Reporte de Bug

## Identificacao

```text
ID do bug:
Data:
Tester:
Plataforma: Web / Windows
Papel: Cliente / Prestador
```

## Reproducao

```text
Passos executados:
1.
2.
3.

Resultado esperado:

Resultado obtido:

Screenshot/video:
```

## Classificacao

```text
Severidade: bloqueador / alto / medio / baixo
Frequencia: sempre / as vezes / uma vez
Estado: aberto / em analise / corrigido / adiado
```

## Observacoes

```text
Notas adicionais:
```
````

- [ ] **Step 3: Validar campos obrigatorios**

Run:

```powershell
Select-String -Path docs\BETA_TESTER_BUG_REPORT.md -Pattern "Passos executados|Resultado esperado|Resultado obtido|Severidade|Frequencia"
Select-String -Path docs\BETA_TESTER_FEEDBACK_FORM.md -Pattern "Nota de 1 a 5|Principal melhoria recomendada"
```

Expected:

```text
todos os campos aparecem nos documentos
```

---

### Task 5: Criar checklist e instrucoes de build

**Files:**
- Create: `docs/BETA_TESTER_CHECKLIST_ENTREGA.md`
- Create: `docs/BETA_TESTER_BUILD_INSTRUCTIONS.md`

- [ ] **Step 1: Criar checklist de entrega**

Criar `docs/BETA_TESTER_CHECKLIST_ENTREGA.md`:

````markdown
# ChegaJa Beta - Checklist de Entrega

## Antes de Entregar

```text
flutter test passou
npm.cmd run test:scripts passou
Firebase emulator tests passaram
build Web gerado
build Windows gerado
guia rapido incluido
roteiro simplificado incluido
feedback form incluido
bug report incluido
limitacoes conhecidas comunicadas
```

## Conteudo do Pacote

```text
build Web ou link de acesso
build Windows ou caminho do executavel
docs/BETA_TESTER_GUIA_RAPIDO.md
docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
docs/BETA_TESTER_FEEDBACK_FORM.md
docs/BETA_TESTER_BUG_REPORT.md
```

## Criterio de Aprovacao

```text
tester abre a app
tester alterna Cliente/Prestador
tester cria pedido
tester testa mensagens
tester testa orcamento/valor final
nao ha bug bloqueador
bugs medios/baixos ficam documentados
```
````

- [ ] **Step 2: Criar instrucoes de build**

Criar `docs/BETA_TESTER_BUILD_INSTRUCTIONS.md`:

````markdown
# ChegaJa Beta - Instrucoes de Build

## Web

```powershell
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Saida esperada:

```text
build/web
```

## Windows

```powershell
flutter build windows --debug
```

Saida esperada:

```text
build/windows/x64/runner/Debug
```

## Validacoes Antes da Entrega

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

## Limitacoes

```text
Android fisico real continua pendente da M2.6.
Pagamentos reais nao fazem parte desta beta.
Play Store nao faz parte desta beta.
Deploy real so deve ocorrer com decisao explicita.
```
````

- [ ] **Step 3: Validar comandos documentados**

Run:

```powershell
Select-String -Path docs\BETA_TESTER_BUILD_INSTRUCTIONS.md -Pattern "flutter build web|flutter build windows|flutter test|firebase emulators:exec"
```

Expected:

```text
todos os comandos aparecem no documento
```

---

### Task 6: Rodar validacoes tecnicas antes dos builds

**Files:**
- Modify: `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`

- [ ] **Step 1: Rodar testes Flutter**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed
```

- [ ] **Step 2: Rodar scripts**

Run:

```powershell
npm.cmd run test:scripts
```

Expected:

```text
script exited with code 0
```

- [ ] **Step 3: Rodar testes Firebase**

Run:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```text
68 passing
Script exited successfully
```

- [ ] **Step 4: Documentar resultados**

Adicionar em `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`:

````markdown
## Validacoes Tecnicas

```text
flutter test: resultado documentado
npm.cmd run test:scripts: resultado documentado
Firestore/Storage/Functions emulator: resultado documentado
```
````

---

### Task 7: Gerar build Web beta

**Files:**
- Modify: `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`

- [ ] **Step 1: Gerar build Web**

Run:

```powershell
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Expected:

```text
Built build\web
```

- [ ] **Step 2: Confirmar pasta de saida**

Run:

```powershell
Test-Path build\web\index.html
```

Expected:

```text
True
```

- [ ] **Step 3: Documentar resultado**

Adicionar em `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`:

````markdown
## Build Web Beta

```text
Comando: flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
Resultado: passou
Saida: build/web
```
````

---

### Task 8: Gerar build Windows beta

**Files:**
- Modify: `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`

- [ ] **Step 1: Gerar build Windows**

Run:

```powershell
flutter build windows --debug
```

Expected:

```text
Built build\windows\x64\runner\Debug
```

- [ ] **Step 2: Confirmar executavel**

Run:

```powershell
Get-ChildItem build\windows\x64\runner\Debug -Filter *.exe
```

Expected:

```text
um executavel da app aparece na pasta
```

- [ ] **Step 3: Documentar resultado**

Adicionar em `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`:

````markdown
## Build Windows Beta

```text
Comando: flutter build windows --debug
Resultado: passou ou bloqueio ambiental documentado
Saida esperada: build/windows/x64/runner/Debug
```
````

---

### Task 9: Montar manifest do pacote final para tester

**Files:**
- Modify: `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`
- Modify: `docs/ROADMAP_A_T_CHEGAJA.md`

- [ ] **Step 1: Criar secao de pacote final**

Adicionar em `docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md`:

````markdown
## Pacote Final para Tester

```text
Build Web: build/web
Build Windows: build/windows/x64/runner/Debug
Guia rapido: docs/BETA_TESTER_GUIA_RAPIDO.md
Roteiro: docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
Feedback: docs/BETA_TESTER_FEEDBACK_FORM.md
Bug report: docs/BETA_TESTER_BUG_REPORT.md
Checklist: docs/BETA_TESTER_CHECKLIST_ENTREGA.md
Instrucoes de build: docs/BETA_TESTER_BUILD_INSTRUCTIONS.md
```
````

- [ ] **Step 2: Atualizar roadmap Q2-Q8**

Em `docs/ROADMAP_A_T_CHEGAJA.md`, atualizar o Bloco Q:

```text
Q1 FECHADO - Spec do pacote de entrega beta
Q2 FECHADO - Build Web beta preparado
Q3 FECHADO - Build Windows beta preparado, se build passou; PARCIAL se bloqueio ambiental
Q4 FECHADO - Guia rapido para tester
Q5 FECHADO - Roteiro simplificado
Q6 FECHADO - Template de feedback externo
Q7 FECHADO - Checklist de entrega
Q8 FECHADO - Pasta/pacote final para tester, se manifest e caminhos finais estiverem documentados
```

- [ ] **Step 3: Validar docs**

Run:

```powershell
git diff --check
Select-String -Path docs\BETA_TESTER_*.md,docs\M2_12_PACOTE_ENTREGA_BETA_STATUS.md -Pattern "Android fisico|pagamentos reais|Play Store|M2.6"
```

Expected:

```text
git diff --check com exit code 0
limitacoes conhecidas aparecem nos documentos relevantes
```

---

### Task 10: Commit final da execucao M2.12

**Files:**
- All files from Tasks 1-9

- [ ] **Step 1: Confirmar staging seguro**

Run:

```powershell
git status --short
```

Expected:

```text
Somente docs da M2.12 e roadmap aparecem como modificados/adicionados.
.superpowers/ fica fora.
artifacts/presentation_chegaja/~$*.pptx fica fora.
build/ nao aparece porque esta no .gitignore.
```

- [ ] **Step 2: Stagear apenas docs**

Run:

```powershell
git add -- docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md docs/ROADMAP_A_T_CHEGAJA.md docs/BETA_TESTER_GUIA_RAPIDO.md docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md docs/BETA_TESTER_FEEDBACK_FORM.md docs/BETA_TESTER_BUG_REPORT.md docs/BETA_TESTER_CHECKLIST_ENTREGA.md docs/BETA_TESTER_BUILD_INSTRUCTIONS.md
```

- [ ] **Step 3: Commit**

Run:

```powershell
git commit -m "Avancar M2.12 pacote entrega beta"
```

- [ ] **Step 4: Push**

Run:

```powershell
git push origin main
```

---

## Self-Review Checklist

```text
Spec M2.12 coberta: sim
Q2 Build Web: Task 7
Q3 Build Windows: Task 8
Q4 Guia rapido: Task 2
Q5 Roteiro simplificado: Task 3
Q6 Template feedback: Task 4
Q7 Checklist entrega: Task 5
Q8 Pacote final: Task 9
Limitacoes conhecidas: Tasks 2, 5, 9
Validacoes tecnicas: Task 6
Sem backend/Rules/Functions/deploy real: Do Not Touch e Fora do Escopo
Sem marcadores pendentes: documento nao usa placeholders de trabalho futuro
```
