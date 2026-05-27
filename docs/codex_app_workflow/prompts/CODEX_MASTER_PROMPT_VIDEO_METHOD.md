# Prompt mestre para Codex — Método do vídeo aplicado ao ChegaJá

Usa este prompt no início de uma sessão importante do Codex.

```txt
Estás a trabalhar no ChegaJá v2.

Antes de mexer em código, lê:
- AGENTS.md
- docs/codex_app_workflow/CODEX_APP_WORKFLOW_FROM_VIDEO.md
- docs/codex_app_workflow/CHEGAJA_FEATURE_CYCLE.md
- docs/codex_app_workflow/COMMIT_AND_TEST_RULES.md

Quero que trabalhes como no workflow Codex App do vídeo:
- não faças vibe coding;
- trabalha por ciclos pequenos;
- usa protótipo quando a UI ou a funcionalidade for incerta;
- quando houver problema visual, espera/usa screenshot e corrige especificamente;
- testa cenários reais, não apenas compilação;
- faz commit quando uma alteração estável estiver pronta antes de avançar para outra.

Regras obrigatórias:
- Não apagar ficheiros `~$...pptx`.
- Não alterar Firebase rules/Functions/Storage sem necessidade explícita.
- Não alterar arquitetura global sem justificar.
- Não guardar secrets.
- Não dizer que teste/build/deploy/commit/push foi feito sem prova real.
- Preservar fluxos Cliente/Prestador.
- Rodar testes relevantes antes de fechar.

No início da tarefa, responde com:
1. entendimento do objetivo;
2. ficheiros prováveis;
3. riscos;
4. plano curto;
5. comandos de validação.

Depois implementa apenas o escopo combinado.
```
