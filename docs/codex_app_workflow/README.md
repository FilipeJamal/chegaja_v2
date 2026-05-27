# ChegaJá — Workflow Codex App inspirado no vídeo GPT-5.5 + Codex

Este pacote transforma o método do vídeo num processo prático para desenvolver o ChegaJá v2 com Codex App.

A ideia principal não é “pedir ao Codex para corrigir tudo”.
A ideia é trabalhar por ciclos curtos:

1. Definir uma intenção clara.
2. Fazer protótipo ou alteração pequena.
3. Correr a app.
4. Tirar screenshot/observar o comportamento.
5. Dar feedback específico ao Codex.
6. Testar vários cenários.
7. Fazer commit antes de continuar.

Este pacote foi integrado no projeto `chegaja_v2` sem substituir o `AGENTS.md` original.

Ficheiros principais:

- `AGENTS.md`: regras permanentes do projeto, agora com referência a este método.
- `docs/codex_app_workflow/AGENTS_VIDEO_METHOD.md`: regras originais do pacote do vídeo preservadas como referência.
- `docs/codex_app_workflow/CODEX_APP_WORKFLOW_FROM_VIDEO.md`: método principal extraído do vídeo.
- `docs/codex_app_workflow/CHEGAJA_FEATURE_CYCLE.md`: ciclo de trabalho para cada funcionalidade.
- `docs/codex_app_workflow/VISUAL_QA_SCREENSHOT_PLAYBOOK.md`: como usar screenshots para guiar correções de UI.
- `docs/codex_app_workflow/PROTOTYPE_FIRST_METHOD.md`: como prototipar antes de mexer em partes frágeis.
- `docs/codex_app_workflow/COMMIT_AND_TEST_RULES.md`: quando testar e quando fazer commit.
- `docs/codex_app_workflow/prompts/*.md`: prompts prontos para usar no Codex.
- `docs/codex_app_workflow/checklists/*.md`: checklists para UI e fluxos.
- `scripts/chegaja_preflight_windows.ps1`: script de pré-validação local no Windows.
