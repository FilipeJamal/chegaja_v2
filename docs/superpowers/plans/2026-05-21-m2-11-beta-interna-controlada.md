# M2.11 Beta Interna Controlada Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar o pacote executavel da beta interna controlada do ChegaJa, com roteiro Cliente/Prestador, feedback, checklist de builds e criterios claros de decisao.

**Architecture:** Esta fase e documental/operacional. Ela nao altera backend, regras Firebase, Cloud Functions, pagamentos, Play Store, Android fisico ou fluxos de negocio; organiza a validacao real da app em Web e Windows com artefactos auditaveis.

**Tech Stack:** Flutter/Dart, Firebase Emulator Suite, scripts npm existentes, documentos Markdown em `docs/`.

---

## File Structure

**Create**

- `docs/BETA_INTERNAL_TEST_SCRIPT.md` - roteiro passo a passo que o tester vai seguir para Cliente, Prestador, Mensagens, Conta/Perfil, Web e Windows.
- `docs/BETA_FEEDBACK_TEMPLATE.md` - modelo padrao para bugs, feedback geral, decisao de aprovacao/reprovacao e triagem P0/P1/P2/P3.
- `docs/BETA_BUILD_AND_TEST_CHECKLIST.md` - checklist tecnico para gerar/validar build Web, build Windows e comandos de pre-check sem tocar em producao.

**Modify**

- `docs/M2_11_BETA_INTERNA_STATUS.md` - atualizar M2.11 de iniciada para planeada/avancada conforme os documentos forem criados e as validacoes executadas.
- `docs/superpowers/specs/2026-05-21-m2-11-beta-interna-controlada-design.md` - manter referencia de que a troca Cliente/Prestador pela UI ja foi cumprida.

**Do Not Touch**

- `functions/**`
- `firestore.rules`
- `storage.rules`
- `lib/core/services/pedido_service.dart`
- `lib/core/repositories/pedido_repo.dart`
- `lib/core/services/location_service.dart`
- `lib/core/services/chat_service.dart`
- `android/key.properties`
- qualquer keystore
- `.superpowers/`
- `artifacts/presentation_chegaja/~$*.pptx`

---

### Task 1: Consolidar estado da M2.11

**Files:**
- Modify: `docs/M2_11_BETA_INTERNA_STATUS.md`

- [ ] **Step 1: Atualizar o bloco de estado**

Trocar o bloco inicial por:

~~~markdown
## Estado

```text
M2.11: planeada para beta interna controlada
M2.11.1: avancado com troca de modo Cliente/Prestador pela UI
M2.6: continua pendente de Android fisico real
```
~~~

- [ ] **Step 2: Adicionar secao de plano aprovado**

Inserir depois da secao `M2.11.1`:

~~~markdown
## Plano de execucao M2.11

Artefactos a criar nesta fase:

```text
docs/BETA_INTERNAL_TEST_SCRIPT.md
docs/BETA_FEEDBACK_TEMPLATE.md
docs/BETA_BUILD_AND_TEST_CHECKLIST.md
```

Validacao tecnica esperada antes de entregar a beta:

```cmd
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter build windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Sem deploy, sem smoke real, sem cleanup real, sem health real e sem fechar M2.6.
~~~

- [ ] **Step 3: Rever diff**

Run:

```powershell
git diff -- docs/M2_11_BETA_INTERNA_STATUS.md
```

Expected:

```text
Mostra apenas atualizacao documental do estado e plano da M2.11.
```

---

### Task 2: Criar roteiro executavel da beta interna

**Files:**
- Create: `docs/BETA_INTERNAL_TEST_SCRIPT.md`

- [ ] **Step 1: Criar documento com este conteudo**

~~~markdown
# Beta Interna - Roteiro de Teste

Data base: 2026-05-21

## Objetivo

Validar o ChegaJa como produto real em Web e Windows, com tester interno,
percorrendo Cliente e Prestador sem pagamentos reais, sem Play Store, sem deploy
novo e sem Android fisico.

## Preparacao

Antes de iniciar:

```text
Confirmar que a build entregue corresponde ao commit informado.
Confirmar se o ambiente usa emuladores Firebase ou ambiente controlado.
Confirmar que nao serao usados cartoes, pagamentos reais ou dados sensiveis.
Confirmar que a troca Cliente/Prestador esta disponivel em Conta/Perfil.
```

## Fluxo 1 - Cliente

1. Abrir a app como Cliente.
2. Confirmar que Home, categorias e catalogo visual sao compreensiveis.
3. Selecionar um servico.
4. Criar um pedido com dados de teste identificaveis.
5. Confirmar que o pedido aparece na lista.
6. Abrir o detalhe do pedido.
7. Confirmar que o estado do pedido e a proxima acao sao claros.
8. Usar Mensagens quando houver conversa disponivel.
9. Aceitar proposta/orcamento quando o fluxo apresentar essa acao.
10. Confirmar valor final quando o fluxo apresentar essa acao.
11. Cancelar apenas quando o fluxo permitir.
12. Consultar pedidos concluidos/cancelados.
13. Abrir Conta/Perfil.
14. Usar "Mudar para modo prestador" e confirmar que a app troca de modo sem editar URL.

## Fluxo 2 - Prestador

1. Abrir a app como Prestador.
2. Confirmar que estado online/offline e categorias sao compreensiveis.
3. Ver pedidos disponiveis.
4. Aceitar um pedido quando disponivel.
5. Ignorar um pedido quando aplicavel.
6. Abrir o detalhe do pedido.
7. Iniciar servico quando a acao estiver disponivel.
8. Enviar orcamento/faixa quando aplicavel.
9. Enviar valor final quando aplicavel.
10. Usar Mensagens com o cliente.
11. Consultar pedidos em curso, concluidos e cancelados.
12. Abrir Conta/Perfil.
13. Usar "Mudar para modo cliente" e confirmar que a app troca de modo sem editar URL.

## Fluxo 3 - Mensagens

1. Abrir Mensagens como Cliente.
2. Verificar lista de conversas, pesquisa e filtros.
3. Abrir uma conversa.
4. Enviar uma mensagem de texto.
5. Confirmar que a mensagem aparece sem quebrar layout.
6. Repetir como Prestador.

## Fluxo 4 - Conta/Perfil

1. Abrir Conta como Cliente.
2. Verificar cartao de perfil, definicoes, ajuda e troca de modo.
3. Abrir Perfil editavel quando disponivel.
4. Repetir como Prestador.
5. Confirmar que a app nao promete KYC, documentos reais ou pagamentos reais sem suporte.

## Plataformas

Testar no minimo:

```text
Web/Chrome desktop
Web/Chrome viewport estreito
Windows build quando disponivel
```

Windows nao substitui Android fisico. A M2.6 continua pendente.

## Resultado esperado

```text
Fluxos Cliente e Prestador podem ser percorridos sem P0/P1.
Mensagens funcionam no fluxo testado.
Pedidos aparecem em lista e detalhe.
Estados e proximas acoes sao compreensiveis.
Troca de modo funciona pela UI.
Bugs restantes ficam classificados e documentados.
```
~~~

- [ ] **Step 2: Validar conteudo**

Run:

```powershell
Select-String -Path docs/BETA_INTERNAL_TEST_SCRIPT.md -Pattern "TB[D]|TO[D]O|placehol[d]er|Android fisico continua|Mudar para modo"
```

Expected:

```text
Nao encontra marcadores pendentes.
Encontra as referencias explicitas a Android fisico e troca de modo.
```

---

### Task 3: Criar template de feedback e bugs

**Files:**
- Create: `docs/BETA_FEEDBACK_TEMPLATE.md`

- [ ] **Step 1: Criar documento com este conteudo**

~~~markdown
# Beta Interna - Template de Feedback

Data do teste:
Tester:
Commit/build testado:
Plataforma: Web / Windows
Role: Cliente / Prestador / ambos

## Resumo da sessao

```text
Fluxo Cliente: passou / bloqueado / nao testado
Fluxo Prestador: passou / bloqueado / nao testado
Mensagens: passou / bloqueado / nao testado
Conta/Perfil: passou / bloqueado / nao testado
Troca Cliente/Prestador pela UI: passou / bloqueado / nao testado
```

## Bug

```text
ID:
Titulo:
Plataforma:
Role:
Fluxo:
Severidade: P0 / P1 / P2 / P3
Tipo: funcional / visual / texto / performance / dados / ambiente
Status: novo / confirmado / corrigido / nao reproduzido / futuro
```

### Passos para reproduzir

1.
2.
3.

### Resultado esperado

```text
Descrever o que deveria acontecer.
```

### Resultado observado

```text
Descrever exatamente o que aconteceu.
```

### Evidencia

```text
Screenshot, video, log ou nota visual.
```

## Severidade

```text
P0 bloqueador: impede concluir fluxo Cliente/Prestador.
P1 alto: quebra acao importante, dados errados ou estado incoerente.
P2 medio: confusao de UX, visual quebrado, mensagem ruim, workaround existe.
P3 baixo: polish, copy, ajuste visual sem impacto forte.
```

## Decisao da beta

```text
Aprovada: sem P0/P1 abertos.
Bloqueada: existe P0/P1 aberto.
Aprovada com pendencias: P2/P3 documentados e aceites para backlog.
```
~~~

- [ ] **Step 2: Validar conteudo**

Run:

```powershell
Select-String -Path docs/BETA_FEEDBACK_TEMPLATE.md -Pattern "P0|P1|P2|P3|Troca Cliente/Prestador|TB[D]|TO[D]O|placehol[d]er"
```

Expected:

```text
Encontra P0/P1/P2/P3 e Troca Cliente/Prestador.
Nao encontra marcadores pendentes.
```

---

### Task 4: Criar checklist tecnico de builds e validacoes

**Files:**
- Create: `docs/BETA_BUILD_AND_TEST_CHECKLIST.md`

- [ ] **Step 1: Criar documento com este conteudo**

~~~markdown
# Beta Interna - Checklist de Build e Validacao

Data base: 2026-05-21

## Pre-check

```cmd
git branch --show-current
git status --short
git log -1 --oneline
```

Expected:

```text
branch main
sem alteracoes inesperadas alem dos temporarios ja conhecidos quando existirem
commit correto da beta no topo
```

## Testes obrigatorios

```cmd
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```text
flutter test passa
test:scripts passa
Functions/Rules emulator tests passam com 37/37
```

## Build Web

```cmd
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Expected:

```text
Build Web concluido sem erro.
Artefactos gerados em build/web.
```

## Build Windows

```cmd
flutter build windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Expected:

```text
Build Windows concluido sem erro.
Artefactos gerados em build/windows.
```

Se falhar por configuracao local, registar como bloqueio ambiental com output
curto e nao maquilhar como validado.

## Proibido nesta fase

```text
deploy Firebase real
smoke real em producao
cleanup real
health real
pagamentos reais
Play Store
Android fisico real
fechar M2.6
```

## Evidencia a registar

```text
data/hora
commit testado
plataforma
comandos executados
resultado de cada comando
bloqueios ambientais
bugs encontrados
decisao final
```
~~~

- [ ] **Step 2: Validar conteudo**

Run:

```powershell
Select-String -Path docs/BETA_BUILD_AND_TEST_CHECKLIST.md -Pattern "flutter test|flutter build web|flutter build windows|deploy Firebase real|TB[D]|TO[D]O|placehol[d]er"
```

Expected:

```text
Encontra os comandos de teste/build e proibicoes.
Nao encontra marcadores pendentes.
```

---

### Task 5: Executar validacoes tecnicas da beta

**Files:**
- Modify: `docs/M2_11_BETA_INTERNA_STATUS.md`

- [ ] **Step 1: Rodar pre-check**

Run:

```powershell
git branch --show-current
git status --short
git log -1 --oneline
```

Expected:

```text
main
somente alteracoes esperadas da M2.11 e temporarios conhecidos fora do commit
commit mais recente correto
```

- [ ] **Step 2: Rodar Flutter tests**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed.
```

- [ ] **Step 3: Rodar scripts**

Run:

```powershell
npm.cmd run test:scripts
```

Expected:

```text
run_android_integration_test args ok
cleanup_smoke_data safeguards ok
firebase_production_health parsing ok
capture_visual_matrix planning ok
```

- [ ] **Step 4: Rodar Firebase emulator tests**

Run:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```text
37 passing
Script exited successfully
```

- [ ] **Step 5: Validar build Web**

Run:

```powershell
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Expected:

```text
Build Web concluido sem erro.
```

- [ ] **Step 6: Validar build Windows**

Run:

```powershell
flutter build windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Expected:

```text
Build Windows concluido sem erro ou bloqueio ambiental documentado.
```

- [ ] **Step 7: Atualizar status com resultados**

Adicionar a `docs/M2_11_BETA_INTERNA_STATUS.md`:

~~~markdown
## Validacoes tecnicas da beta

```text
flutter test: resultado registado
npm.cmd run test:scripts: resultado registado
Firebase emulator tests: resultado registado
flutter build web: resultado registado
flutter build windows: resultado registado ou bloqueio ambiental documentado
```
~~~

---

### Task 6: Revisao final e commit

**Files:**
- Modify: all M2.11 docs changed in this plan

- [ ] **Step 1: Procurar marcadores pendentes**

Run:

```powershell
Select-String -Path docs/BETA_INTERNAL_TEST_SCRIPT.md,docs/BETA_FEEDBACK_TEMPLATE.md,docs/BETA_BUILD_AND_TEST_CHECKLIST.md,docs/M2_11_BETA_INTERNA_STATUS.md -Pattern "TB[D]|TO[D]O|placehol[d]er"
```

Expected:

```text
Sem resultados.
```

- [ ] **Step 2: Confirmar que arquivos proibidos ficam fora**

Run:

```powershell
git status --short
```

Expected:

```text
Arquivos .superpowers/ e ~$*.pptx, se aparecerem, continuam fora do commit.
Nao ha mudancas em backend, rules, functions, services ou repositories.
```

- [ ] **Step 3: Commit**

Run:

```powershell
git add -- docs/M2_11_BETA_INTERNA_STATUS.md docs/BETA_INTERNAL_TEST_SCRIPT.md docs/BETA_FEEDBACK_TEMPLATE.md docs/BETA_BUILD_AND_TEST_CHECKLIST.md
git commit -m "Planear M2.11 beta interna controlada"
git push origin main
```

Expected:

```text
Commit criado e enviado para main.
```

---

## Self-Review

Spec coverage:

```text
Roteiro Cliente/Prestador: Task 2.
Contas/roles e troca pela UI: Task 2 e status existente.
Build Web/Windows: Task 4 e Task 5.
Checklist de bugs e feedback: Task 3.
Criterios de aprovacao/reprovacao: Task 3.
Triagem: Task 3.
M2.6 pendente: Task 2, Task 4 e status.
```

Scope check:

```text
O plano e documental/operacional. Nao adiciona funcionalidades, nao altera
backend e nao faz deploy real.
```
