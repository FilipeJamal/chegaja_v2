# M2.18 - Admin/backoffice Leve

Data: 2026-05-29

## Estado

M2.18 fechada no escopo atual de Admin/backoffice leve.

```text
M2.14 - FECHADA no escopo atual de perfil, portfolio e confianca leve
M2.15 - FECHADA no escopo atual de avaliacoes e reputacao leve
M2.16 - FECHADA no escopo atual de pesquisa manual/discovery
M2.17 - FECHADA no escopo atual de Trust & Safety basico
M2.18.1 - FECHADA com spec e auditoria
M2.18.2 - FECHADA com reorganizacao de navegacao/secoes
M2.18.3 - FECHADA com dashboard e metricas essenciais
M2.18.4 - FECHADA com filas operacionais melhoradas
M2.18.5 - FECHADA com auditoria leve e estados operacionais
M2.18.6 - FECHADA com QA final e documentacao
```

Blocos relacionados:

```text
Bloco F - parcial
Bloco H - parcial
Bloco J - parcial
R - pausado por falta de tester humano real
M - pausado por falta de Android fisico real
R1 - pendente
M2.6 - pendente
```

## Objetivo da M2.18

Criar um Admin/backoffice leve, mais organizado e utilizavel, para o dono/equipa
acompanharem operacao sem transformar o produto num backoffice enterprise nesta
fase.

A M2.18 deve organizar:

```text
visao geral;
metricas principais;
suporte;
denuncias/moderacao;
no-show;
stories/conteudo;
anomalias financeiras/ledger;
estados operacionais;
documentacao de operacao.
```

## Principio de Escopo

M2.18 nao e admin completo. E uma camada operacional leve em cima das bases ja
existentes.

Entram:

```text
reorganizacao leve do AdminPanel;
navegacao por secoes/tabs;
resumo operacional mais claro;
melhor organizacao das filas existentes;
loading/erro/estado vazio por secao;
testes de widgets e services;
documentacao operacional.
```

Ficam fora:

```text
admin enterprise completo;
roles granulares de equipa;
KYC real;
pagamentos reais;
graficos complexos;
analytics avancado;
exportacao CSV/PDF;
auditoria completa;
custom claims novos;
deploy;
Android fisico;
tester externo.
```

## Estado Atual do Admin

### AdminPanelScreen

Arquivo:

```text
lib/features/admin/admin_panel_screen.dart
```

O painel atual e uma tela unica que:

```text
carrega todos os blocos no initState;
usa RefreshIndicator e botao de refresh;
tem loading global inicial;
tem erro global;
tem mapa de erros por secao;
renderiza tudo numa ListView unica;
concentra metricas, suporte, reports, no-show, stories e ledger.
```

Secoes atuais:

```text
Resumo operacional (7d/30d);
Moderacao e denuncias;
Custos e retencao;
Suporte interno;
Moderacao no-show;
Moderacao de Historias;
Saude do Ledger (Anomalias).
```

Acoes atuais:

```text
refresh geral;
alterar status de support ticket;
alterar status de report;
decidir no-show;
apagar story;
filtrar tickets;
filtrar reports;
filtrar no-show.
```

Estados atuais:

```text
loading inicial global;
refresh geral;
erro global;
erros por secao capturados por guarded loader;
estado vazio em tickets, reports, no-show, stories e ledger.
```

### AdminReportsSection

Arquivo:

```text
lib/features/admin/widgets/admin_reports_section.dart
```

O widget de reports ja esta isolado e testavel.

Ele trata:

```text
lista de reports;
filtro por status;
erro isolado;
estado vazio;
cards de report;
acoes reviewed, dismissed e escalated;
dark mode via ColorScheme.
```

Esta deve ser a referencia de padrao para as proximas secoes da M2.18.

## Estado Atual do AdminService

Arquivo:

```text
lib/core/services/admin_service.dart
```

Metodos existentes:

| Metodo | Callable | Funcao |
| --- | --- | --- |
| `getDashboardSnapshot()` | `admin_getDashboardSnapshot` | resumo operacional de tickets, no-show, pagamentos e pedidos recentes |
| `getOpsMetrics(days)` | `admin_getOpsMetrics` | funil, no-show, receita e assinaturas |
| `getCostRetentionSnapshot()` | `admin_getCostRetentionSnapshot` | CAC/LTV/churn/coortes basicas |
| `listSupportTickets(status, limit)` | `admin_listSupportTickets` | lista tickets de suporte |
| `updateSupportTicketStatus(ticketId, status)` | `admin_updateSupportTicketStatus` | atualiza status de ticket |
| `listReports(status, limit)` | `admin_listReports` | lista reports para moderacao |
| `updateReportStatus(reportId, status, decisionReason)` | `admin_updateReportStatus` | atualiza status de report |
| `listNoShowCases(decision, limit)` | `admin_listNoShowCases` | lista casos no-show |
| `setNoShowDecision(pedidoId, decision)` | `admin_setNoShowDecision` | decide caso no-show |
| `listStories(limit)` | `admin_listStories` | lista stories ativos |
| `deleteStory(storyId)` | `admin_deleteStory` | remove story |
| `getLedgerAnomalies(limit)` | `admin_getLedgerAnomalies` | lista pagamentos sem ledger correspondente |

Observacoes:

```text
o service usa FirebaseFunctions diretamente;
nao ha injecao de FirebaseFunctions para teste;
parseia mapas/listas de forma defensiva;
nao ha DTOs especificos para admin;
AdminPanel consome Map<String, dynamic> diretamente.
```

## Estado Atual das Cloud Functions Admin

Arquivo:

```text
functions/index.js
```

As callables admin existentes usam `ensureAdmin(req.auth)`.

`ensureAdmin`:

```text
em emuladores, permite chamadas;
fora de emuladores, exige auth.token.admin == true.
```

Callables atuais:

| Callable | Input principal | Output principal | Teste conhecido |
| --- | --- | --- | --- |
| `admin_getDashboardSnapshot` | nenhum | contagens 7d/30d, tickets, no-show, pagamentos, pedidos | sem teste dedicado isolado |
| `admin_getOpsMetrics` | `days` | funil, no-show, receita, assinaturas | sem teste dedicado isolado |
| `admin_getCostRetentionSnapshot` | nenhum | aquisicao, retencao, receita/coortes | sem teste dedicado isolado |
| `admin_listSupportTickets` | `status`, `limit` | `tickets` | sem teste dedicado isolado |
| `admin_updateSupportTicketStatus` | `ticketId`, `status` | `ok` | sem teste dedicado isolado |
| `admin_listReports` | `status`, `limit` | `reports`, `counts` | `functions/test/adminModeration.test.js` |
| `admin_updateReportStatus` | `reportId`, `status`, `decisionReason` | `ok`, `reportId`, `status` | `functions/test/adminModeration.test.js` |
| `admin_listNoShowCases` | `decision`, `limit` | `cases` | sem teste dedicado isolado |
| `admin_setNoShowDecision` | `pedidoId`, `decision` | `ok` | sem teste dedicado isolado |
| `admin_listStories` | `limit` | `stories` | sem teste dedicado isolado |
| `admin_deleteStory` | `storyId` | `ok` | sem teste dedicado isolado |
| `admin_getLedgerAnomalies` | `limit` | `anomalies` | sem teste dedicado isolado |

Riscos das Functions:

```text
algumas listas fazem leitura com rawLimit e filtro em memoria;
nao ha paginacao/cursor real;
ha limites defensivos, mas ainda simples;
algumas callables nao tem testes dedicados;
as respostas sao mapas soltos, sem contrato Dart forte;
em emulador ensureAdmin permite chamadas para facilitar testes locais.
```

## Areas Operacionais Necessarias

Com base na visao de produto, o admin/backoffice leve deve evoluir para:

```text
Visao geral - estado operacional, pendencias e riscos.
Metricas - pedidos, conversao, receita simulada/real quando existir.
Suporte - tickets e acompanhamento de problemas.
Denuncias/moderacao - reports, severidade, status e triagem.
No-show - casos reportados e decisao.
Stories/conteudo - conteudo efemero e remocao.
Ledger/anomalias - saude operacional de pagamentos/ledger.
Prestadores - visao futura de perfis, estados e qualidade.
Clientes - visao futura de utilizadores e suporte.
Categorias - gestao futura de catalogo e categorias sensiveis.
Seguranca - flags, reports e risco.
KYC futuro - documentos/selfie/certificados quando existir processo real.
```

## Escopo Recomendado da M2.18

M2.18 deve melhorar a operacao interna sem abrir escopo pesado.

Entram:

```text
separar o painel por secoes/tabs;
isolar widgets como AdminReportsSection;
criar estados vazios/erros consistentes;
reduzir densidade visual da ListView unica;
priorizar pendencias acionaveis;
documentar significado de metricas;
criar testes de AdminPanel com dados mockados quando a estrutura permitir;
melhorar cobertura de callables admin criticas.
```

Nao entram:

```text
custom claims novos;
roles granulares de moderador/suporte;
auditoria completa;
logs imutaveis completos;
exportacoes;
graficos avancados;
KYC real;
gestao financeira real;
deploy.
```

## Riscos

```text
AdminPanel virar ficheiro gigante e dificil de testar;
callables crescerem sem paginacao real;
reports, suporte, no-show e stories ficarem misturados;
dados sensiveis aparecerem em secoes erradas;
metricas parecerem definitivas quando ainda sao aproximacoes;
dark mode e responsividade ficarem secundarios;
erro numa callable afetar a percepcao do painel inteiro;
Functions sem testes dedicados regressarem silenciosamente;
AdminService continuar acoplado a FirebaseFunctions real e dificil de testar;
admin/backoffice ser confundido com KYC ou moderacao completa.
```

## Testes Necessarios

```text
AdminService parseia respostas das callables;
AdminPanel renderiza com dados mockados;
AdminPanel mostra loading, erro global e erros por secao;
secoes isoladas mostram estado vazio;
acoes de suporte chamam callbacks corretos;
acoes de no-show chamam callbacks corretos;
acoes de stories chamam callbacks corretos;
AdminReportsSection continua coberta;
Functions admin bloqueiam user comum/anonimo;
Functions admin validam inputs;
build Web;
QA visual admin.
```

## Subfases M2.18

```text
M2.18.1 - FECHADA - Spec e auditoria Admin/backoffice leve
M2.18.2 - FECHADA - Reorganizar navegacao/secoes do AdminPanel
M2.18.3 - FECHADA - Melhorar dashboard e metricas essenciais
M2.18.4 - FECHADA - Melhorar filas operacionais: reports, suporte, no-show, stories
M2.18.5 - FECHADA - Logs/auditoria leve e estados operacionais
M2.18.6 - FECHADA - Testes, E2E, QA visual e documentacao final
```

## Implementacao M2.18.2

A M2.18.2 reorganizou o `AdminPanelScreen` sem criar painel paralelo e sem
alterar callables admin.

Estrutura criada:

```text
AdminPanelScreen - carrega dados, callbacks e estados
AdminPanelContent - navegacao por secoes
AdminOverviewSection - visao geral
AdminReportsSection - moderacao e denuncias
AdminSupportTicketsSection - suporte
AdminNoShowSection - no-show
AdminStoriesSection - conteudo/stories
AdminFinanceLedgerSection - financeiro/ledger
AdminSectionError/AdminSectionEmptyState - estados comuns
AdminMetricTile - metricas compactas
```

Secoes atuais:

```text
Visao geral
Moderacao
Suporte
No-show
Conteudo
Financeiro
```

Foram mantidos:

```text
AdminService existente;
callables admin existentes;
AdminReportsSection;
erros e estados vazios por secao;
refresh geral;
acoes de suporte, no-show, stories e reports.
```

Nao entraram:

```text
novas Functions;
novas Rules;
KYC;
pagamentos;
roles granulares;
admin enterprise completo;
deploy.
```

## Implementacao M2.18.3

A M2.18.3 melhorou a secao `Visao geral` sem alterar navegacao, AdminService,
Functions ou Rules.

Widgets criados:

```text
AdminHealthSummaryCard - resumo de pendencias operacionais
AdminMetricGroupCard - grupos compactos de metricas
AdminDashboardExplainer - nota sobre estimativas operacionais
```

Grupos criados no dashboard:

```text
Pendencias operacionais - tickets, reports, no-show e ledger anomalies
Pedidos - criados, concluidos, taxa simples de conclusao e cancelamentos
Financeiro operacional - receita liquida, bruta e comissao/plataforma
Crescimento e retencao - novos utilizadores, ativos, churn e LTV estimados
```

Decisoes importantes:

```text
nao criar graficos complexos;
nao criar analytics avancado;
nao inventar metricas sem fonte;
mostrar fallback "-" quando faltam dados;
explicar que valores podem ser estimativas operacionais;
usar listas carregadas como aproximacao quando nao houver count dedicado.
```

Nao entraram:

```text
novas Functions;
alteracoes em Rules;
novos contratos do AdminService;
KYC;
pagamentos;
exportacoes;
admin enterprise completo.
```

## Implementacao M2.18.4

A M2.18.4 melhorou as filas operacionais existentes sem alterar AdminService,
Functions, Rules ou deploy.

Widgets comuns criados:

```text
AdminQueueStatusChip - labels legiveis para status/severidade/motivo/tipo
AdminQueueCard - card padrao para item de fila
AdminQueueActionRow - linha de acoes com suporte a acao destrutiva
AdminQueueFilterBar - titulo, descricao e filtro de status
```

Filas melhoradas:

```text
AdminReportsSection - reports com chips legiveis e acoes existentes
AdminSupportTicketsSection - tickets com status, user, data e fallbacks
AdminNoShowSection - pedidos no-show com decisao, reporter, motivo e acoes
AdminStoriesSection - stories com owner, descricao, expiracao e aviso destrutivo
```

Decisoes importantes:

```text
manter acoes existentes;
nao criar acoes destrutivas novas;
nao ocultar conteudo automaticamente;
nao banir utilizadores;
mostrar "Sem dados" ou "-" quando informacao estiver ausente;
traduzir status internos para labels legiveis.
```

Nao entraram:

```text
novas Functions;
alteracoes em Rules;
roles granulares;
audit logs completos;
KYC;
pagamentos;
exportacoes;
admin enterprise completo.
```

## Implementacao M2.18.5

A M2.18.5 criou rastreabilidade minima para acoes admin principais, sem criar
auditoria enterprise, roles granulares ou novas acoes destrutivas.

Backend criado/alterado:

```text
adminAuditLogs/{logId}
writeAdminAuditLog(...)
admin_listAuditLogs
```

Acoes auditadas:

```text
admin_updateReportStatus - report.update_status
admin_updateSupportTicketStatus - support_ticket.update_status
admin_setNoShowDecision - no_show.set_decision
admin_deleteStory - story.delete
```

Cada log guarda:

```text
actorUid;
actorRole;
action;
targetType;
targetId;
beforeStatus;
afterStatus;
reason, quando existir;
createdAt;
source = admin_callable.
```

UI/admin:

```text
AdminService.listAuditLogs(...)
AdminAuditLogsSection
secao Auditoria no AdminPanel
```

Decisoes importantes:

```text
logs sao leves e nao guardam payloads sensiveis completos;
listagem acontece por callable admin/dev;
utilizador comum e anonimo nao conseguem listar logs;
sem exportacao CSV/PDF;
sem paginacao/cursor real;
sem roles granulares;
sem KYC/pagamentos/deploy.
```

## Implementacao M2.18.6

A M2.18.6 fechou a M2.18 sem criar feature nova.

Foram criados:

```text
docs/M2_18_6_QA_FINAL_ADMIN_STATUS.md
docs/M2_18_FINAL_REPORT.md
```

O fecho validou:

```text
AdminPanel organizado;
dashboard/Visao geral;
filas operacionais;
reports/moderacao;
auditoria leve;
Functions admin;
Flutter completo;
build Web;
E2E principal;
QA visual geral.
```

Resultados finais:

```text
Functions tests - 123 passing;
Flutter test completo - 314/314;
E2E dual - FULL MULTI-SCENARIO FLOW OK;
E2E orcamento - ORCAMENTO MIN-MAX FLOW OK;
QA visual - 8 screenshots.
```

M2.18 fica fechada apenas no escopo atual de Admin/backoffice leve.

Continuam fora:

```text
admin enterprise completo;
roles granulares;
custom claims novos;
KYC;
pagamentos;
export CSV/PDF;
paginacao/cursor real;
auditoria enterprise;
deploy.
```

## Proximo Passo

```text
M2.19 - Link publico, @handle e partilha social
```

Objetivo recomendado:

```text
permitir que o prestador tenha handle/link publico partilhavel em redes sociais,
sem iniciar essa implementacao dentro da M2.18.
```
