# M2.18.1 - Auditoria Admin/backoffice Leve

Data: 2026-05-29

## Estado

M2.18.1 concluida.

```text
M2.18 - iniciada
M2.18.1 - FECHADA
M2.18.2 - PROXIMO passo
M2.17 - FECHADA no escopo atual
Bloco F - PARCIAL
Bloco H - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo

Auditar o estado atual do admin/backoffice antes de implementar mudancas
visuais ou funcionais grandes.

Esta fase foi documental/auditoria.

Nao foram alterados:

```text
Dart;
Firestore Rules;
Storage Rules;
Cloud Functions;
deploy;
KYC;
pagamentos;
Android fisico;
R/R1/M/M2.6.
```

## Ficheiros Auditados

```text
docs/ROADMAP_A_T_CHEGAJA.md
docs/CHEGAJA_PRODUCT_MASTER_VISION.md
docs/M2_17_FINAL_REPORT.md
docs/M2_17_6_QA_FINAL_TRUST_SAFETY_STATUS.md
docs/M2_17_4_FILA_MODERACAO_ADMIN_STATUS.md
lib/features/admin/admin_panel_screen.dart
lib/features/admin/widgets/admin_reports_section.dart
lib/core/services/admin_service.dart
functions/index.js
functions/test/adminModeration.test.js
functions/test/firestore.test.js
test/features/admin/admin_reports_section_test.dart
firestore.rules
```

## Estado Atual do AdminPanel

O admin atual ja existe e e funcional.

Secoes renderizadas:

```text
Resumo operacional (7d/30d);
Moderacao e denuncias;
Custos e retencao;
Suporte interno;
Moderacao no-show;
Moderacao de Historias;
Saude do Ledger (Anomalias).
```

Dados carregados:

```text
dashboard;
ops;
cost/retention;
support tickets;
reports;
no-show cases;
stories;
ledger anomalies.
```

Callables usadas pelo painel:

```text
admin_getDashboardSnapshot;
admin_getOpsMetrics;
admin_getCostRetentionSnapshot;
admin_listSupportTickets;
admin_updateSupportTicketStatus;
admin_listReports;
admin_updateReportStatus;
admin_listNoShowCases;
admin_setNoShowDecision;
admin_listStories;
admin_deleteStory;
admin_getLedgerAnomalies.
```

Estados existentes:

```text
loading inicial global;
refresh geral;
erro global;
erros por secao via guarded loader;
estado vazio em filas/listas;
SnackBar para sucesso/erro em acoes.
```

Problemas estruturais:

```text
AdminPanelScreen concentra muita responsabilidade;
os widgets das secoes ainda nao estao todos isolados;
ha muitos mapas dinamicos em vez de modelos especificos;
todas as secoes carregam no mesmo ciclo;
nao ha navegacao/tabs para reduzir densidade;
algumas strings exibem dados crus de status/callables;
testes de AdminPanel completo ainda nao existem.
```

## Estado Atual do AdminService

`AdminService` centraliza chamadas para Firebase Functions.

Pontos positivos:

```text
interface unica para admin;
parse defensivo de mapas/listas;
metodos claros para reports, suporte, no-show, stories e ledger;
usa regiao configurada em AppConfig.
```

Limites:

```text
sem injecao de FirebaseFunctions para testes;
sem modelos Dart especificos por fila;
retorna Map<String, dynamic> em quase tudo;
contrato de resposta vive implicitamente nas Functions;
erros ficam para a UI tratar de forma generica.
```

## Estado Atual das Functions Admin

As Functions admin usam `ensureAdmin`.

Modelo de permissao:

```text
em emulador, ensureAdmin permite chamadas;
fora de emulador, exige token admin;
nao ha roles granulares de moderador/suporte nesta fase.
```

Callables auditadas:

```text
admin_getDashboardSnapshot;
admin_getOpsMetrics;
admin_getCostRetentionSnapshot;
admin_listSupportTickets;
admin_updateSupportTicketStatus;
admin_listReports;
admin_updateReportStatus;
admin_listNoShowCases;
admin_setNoShowDecision;
admin_listStories;
admin_deleteStory;
admin_getLedgerAnomalies.
```

Cobertura atual:

```text
admin_listReports e admin_updateReportStatus tem testes dedicados;
Rules de reports e blockedUsers tem testes;
outras callables admin ainda precisam de testes focados em fases futuras.
```

Riscos:

```text
listas sem paginacao real;
filtros aplicados em memoria apos rawLimit;
respostas sem DTO Dart;
algumas operacoes destrutivas simples, como deleteStory;
metricas podem ser interpretadas como definitivas quando sao snapshot simples;
sem auditoria completa de acoes admin.
```

## Operacao Necessaria

O dono/equipa precisa de uma area interna para:

```text
ver pendencias e risco operacional rapidamente;
ver reports de Trust & Safety;
triagem de suporte;
decidir no-show;
remover stories problematicos;
acompanhar anomalias de ledger;
entender funil e receita de forma basica;
acompanhar futuramente prestadores, clientes, categorias e KYC.
```

## Decisao de Arquitetura Recomendada

M2.18 deve evoluir o admin atual, nao criar um segundo painel paralelo.

Recomendacao:

```text
manter AdminService como porta de entrada;
extrair secoes do AdminPanel para widgets testaveis;
usar tabs ou navegacao segmentada;
manter callables atuais na M2.18.2;
adiar modelos Dart especificos para quando houver necessidade real;
priorizar estados vazios/erro/loading por secao;
melhorar testes antes de aumentar funcionalidade.
```

## Subfases Recomendadas

```text
M2.18.1 - Spec e auditoria Admin/backoffice leve
M2.18.2 - Reorganizar navegacao/secoes do AdminPanel
M2.18.3 - Melhorar dashboard e metricas essenciais
M2.18.4 - Melhorar filas operacionais: reports, suporte, no-show, stories
M2.18.5 - Logs/auditoria leve e estados operacionais
M2.18.6 - Testes, E2E, QA visual e documentacao final
```

## Riscos Encontrados

```text
AdminPanelScreen pode continuar crescendo como ficheiro gigante;
reports/suporte/no-show/stories/ledger estao visualmente misturados;
algumas callables admin ainda nao tem testes dedicados;
nao existe paginacao/cursor real;
nao existem roles granulares de equipa;
sem auditoria completa para todas as acoes admin;
sem QA visual especifico do AdminPanel;
dados sensiveis podem exigir redacao/mascara futura;
dark mode e responsividade precisam ser preservados.
```

## Testes Necessarios para Proximas Fases

```text
AdminPanel com dados mockados;
secoes extraidas com estados loading/erro/vazio;
AdminService com callable fake, se houver injecao futura;
Functions admin de suporte/no-show/stories/ledger;
acoes bloqueadas para user comum/anonimo;
build Web;
QA visual do AdminPanel.
```

## Validacoes da M2.18.1

```text
git status - executado;
git diff --check - passou;
npm.cmd run test:scripts - passou.
```

## Decisao Final

M2.18.1 fica concluida como spec/auditoria documental.

Proximo passo:

```text
M2.18.2 - Reorganizar navegacao/secoes do AdminPanel
```
