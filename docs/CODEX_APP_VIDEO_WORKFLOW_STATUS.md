# Codex App Video Workflow - Status

Data: 2026-05-27

## Estado

```text
Workflow do video importado para o ChegaJa v2
Pacote base: C:\Users\Jamal\Downloads\chegaja_codex_video_workflow_pack.zip
Integracao: documentacao + script de preflight + referencia no AGENTS.md
```

## Objetivo

Trazer para o ChegaJa v2 o metodo de trabalho mostrado no video GPT-5.5 + Codex App:

```text
ciclos pequenos
prototipo antes de mexer em areas incertas
screenshots como ferramenta de QA visual
testes de fluxo real Cliente/Prestador
commits apos mudancas estaveis
sem vibe coding
sem declarar validacoes sem prova real
```

## Ficheiros Integrados

```text
AGENTS.md
docs/codex_app_workflow/README.md
docs/codex_app_workflow/AGENTS_VIDEO_METHOD.md
docs/codex_app_workflow/CODEX_APP_WORKFLOW_FROM_VIDEO.md
docs/codex_app_workflow/CHEGAJA_FEATURE_CYCLE.md
docs/codex_app_workflow/VISUAL_QA_SCREENSHOT_PLAYBOOK.md
docs/codex_app_workflow/PROTOTYPE_FIRST_METHOD.md
docs/codex_app_workflow/COMMIT_AND_TEST_RULES.md
docs/codex_app_workflow/checklists/UI_FEATURE_CHECKLIST.md
docs/codex_app_workflow/checklists/FLOW_TEST_CHECKLIST.md
docs/codex_app_workflow/prompts/CODEX_MASTER_PROMPT_VIDEO_METHOD.md
docs/codex_app_workflow/prompts/PROTOTYPE_FIRST_PROMPT.md
docs/codex_app_workflow/prompts/UI_FEATURE_PROMPT_TEMPLATE.md
docs/codex_app_workflow/prompts/SCREENSHOT_BUGFIX_PROMPT.md
docs/codex_app_workflow/prompts/BUG_REPRODUCTION_PROMPT.md
docs/codex_app_workflow/prompts/CUSTOMER_FEEDBACK_TO_FEATURE_PROMPT.md
docs/codex_app_workflow/prompts/M2_NEXT_SAFE_PROMPT.md
docs/codex_app_workflow/chegaja_codex_session_notes_template.md
scripts/chegaja_preflight_windows.ps1
```

## Decisao de Integracao

O `AGENTS.md` original nao foi substituido.

Foi reforcado com referencias ao novo metodo, preservando as regras existentes do projeto:

```text
Flutter/Firebase continuam como base tecnica.
Nao alterar Rules/Functions sem necessidade explicita.
Nao apagar ficheiros temporarios ~$...pptx.
Nao guardar secrets.
Nao declarar teste/build/commit/push sem prova real.
Preservar fluxos Cliente/Prestador.
```

## Uso Recomendado

No inicio de uma sessao importante com Codex:

```text
1. Ler AGENTS.md.
2. Ler docs/codex_app_workflow/CODEX_APP_WORKFLOW_FROM_VIDEO.md.
3. Se for UI incerta, usar docs/codex_app_workflow/PROTOTYPE_FIRST_METHOD.md.
4. Se houver screenshot, usar docs/codex_app_workflow/VISUAL_QA_SCREENSHOT_PLAYBOOK.md.
5. Antes de fechar, seguir docs/codex_app_workflow/COMMIT_AND_TEST_RULES.md.
```

## Validacao

Como esta fase integra documentacao e script auxiliar, a validacao minima esperada e:

```text
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\chegaja_preflight_windows.ps1
```

O preflight completo pode demorar porque executa testes Flutter, Functions e scripts.

Resultado nesta integracao:

```text
git diff --check: passou
scripts/chegaja_preflight_windows.ps1: passou
flutter test --no-pub: 152/152 passou
npm.cmd run test:scripts: passou
Firebase emulator tests: 68/68 passou
```

Observacao:

```text
Os logs PERMISSION_DENIED no fim dos emulator tests pertencem a testes negativos esperados de Firestore Rules.
```

## Ajuste Local ao Script de Preflight

O script original do pacote executava `cd functions && npm.cmd test` diretamente. No ChegaJa v2, os testes de Rules/Functions esperam os emuladores Firebase, por isso o script integrado foi adaptado para usar:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Tambem foi adicionado controlo explicito de exit code para comandos nativos, evitando que uma falha de `npm.cmd`, `flutter`, `npx.cmd` ou `git` seja ignorada pelo PowerShell.
