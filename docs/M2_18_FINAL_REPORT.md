# M2.18 - Relatorio Final Admin/backoffice Leve

Data: 2026-05-30

## Estado Final

M2.18 fechada no escopo atual de Admin/backoffice leve.

```text
M2.18.1 - FECHADA - Spec e auditoria Admin/backoffice leve
M2.18.2 - FECHADA - Reorganizar navegacao/secoes do AdminPanel
M2.18.3 - FECHADA - Melhorar dashboard e metricas essenciais
M2.18.4 - FECHADA - Melhorar filas operacionais: reports, suporte, no-show, stories
M2.18.5 - FECHADA - Logs/auditoria leve e estados operacionais
M2.18.6 - FECHADA - Testes, E2E, QA visual e documentacao final
```

Blocos relacionados continuam assim:

```text
Bloco F - PARCIAL
Bloco H - PARCIAL
Bloco J - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo da M2.18

Criar um Admin/backoffice leve mais organizado para acompanhar operacao, suporte,
denuncias, no-show, stories, anomalias financeiras e metricas principais, sem
transformar o ChegaJa num backoffice enterprise nesta fase.

## Commits Principais

```text
0856ea0f5aa874350b8a25c95840dceacb6e45b8
Iniciar M2.18 admin backoffice leve

faa2e7461a5f9786a125482ddb56e202dd4c033b
Reorganizar M2.18.2 AdminPanel secoes

de1bb07617493bd5de777cfdda4117dcfb597fa1
Melhorar M2.18.3 dashboard admin

86b4a213408a3eea90f61c65a3f7781a00ec27f4
Melhorar M2.18.4 filas operacionais admin

a0f173315d9864a5931b7df89044c87995a8d6c7
Criar M2.18.5 auditoria admin leve
```

## Fases

### M2.18.1

A fase criou spec e auditoria do Admin/backoffice leve. Confirmou que o admin ja
existia, mas concentrava demasiada responsabilidade no `AdminPanelScreen`, usava
muitos `Map<String, dynamic>` e carregava muitas secoes no mesmo ciclo.

Decisao: evoluir o AdminPanel existente, nao criar um painel paralelo.

### M2.18.2

Reorganizou o AdminPanel em secoes navegaveis:

```text
Visao geral
Moderacao
Suporte
No-show
Conteudo
Financeiro
```

Foram extraidos widgets testaveis e preservadas as callables existentes.

### M2.18.3

Melhorou a Visao geral com grupos de metricas:

```text
Pendencias operacionais
Pedidos
Financeiro operacional
Crescimento e retencao
```

A fase manteve fallbacks honestos para dados ausentes e nao inventou metricas
sem fonte confiavel.

### M2.18.4

Melhorou as filas operacionais:

```text
reports/moderacao
suporte
no-show
stories/conteudo
```

Criou padroes visuais para cards, chips, filtros e acoes, mantendo as acoes
existentes e sem adicionar novas acoes destrutivas.

### M2.18.5

Criou auditoria leve para acoes admin principais:

```text
admin_updateReportStatus
admin_updateSupportTicketStatus
admin_setNoShowDecision
admin_deleteStory
```

Foi criada a colecao `adminAuditLogs/{logId}`, a callable
`admin_listAuditLogs`, o metodo `AdminService.listAuditLogs(...)` e a secao
`Auditoria` no AdminPanel.

### M2.18.6

Fechou o bloco com documentacao final, testes focados, Functions, Flutter
completo, build Web, E2E e QA visual.

Durante o QA final, o E2E dual expôs um bloqueador no runner de cancelamento:
o script tentava procurar o pedido por titulo enquanto a app ja estava no ecra
`A encontrar prestador`. A correcao ficou limitada ao runner e ao feedback de
sessao no cancelamento em espera, sem criar feature nova e sem alterar Rules,
Functions ou deploy.

## Implementado no Escopo

```text
AdminPanel organizado por secoes;
dashboard com metricas essenciais e explicacoes;
filas operacionais mais legiveis;
reports/moderacao integrados;
suporte, no-show, stories e ledger organizados;
auditoria leve por adminAuditLogs;
AdminService atualizado para reports e audit logs;
widgets admin testaveis;
documentacao operacional da M2.18.
```

## Validado

```text
testes focados admin - 29 testes;
Functions tests - 123 passing;
Flutter test completo - 314/314;
build Web release - passou;
E2E dual - FULL MULTI-SCENARIO FLOW OK;
E2E orcamento - ORCAMENTO MIN-MAX FLOW OK;
QA visual - 8 screenshots.
```

## Decisoes Tecnicas Importantes

```text
evoluir o AdminPanel existente, sem criar outro painel paralelo;
manter AdminService como ponto de integracao das callables;
usar widgets pequenos e testaveis por secao;
nao inventar metricas sem fonte;
usar reports como fila inicial de moderacao;
gravar audit logs leves, sem payloads sensiveis completos;
corrigir apenas bloqueadores encontrados no QA final;
nao criar roles granulares nem custom claims novos nesta fase;
nao transformar M2.18 em admin enterprise.
```

## Fora do Escopo Mantido

```text
KYC
pagamentos reais
roles granulares
custom claims novos
export CSV/PDF
paginacao/cursor real
auditoria enterprise
admin enterprise completo
graficos avancados
analytics avancado
ocultacao automatica
banimento automatico
deploy
Android fisico
tester externo
fechar R
fechar R1
fechar M
fechar M2.6
```

## Riscos Remanescentes

```text
AdminService ainda trabalha com Map<String, dynamic>;
algumas callables admin ainda nao tem paginacao/cursor real;
audit logs sao leves, nao trilha enterprise completa;
sem roles granulares de equipa/moderador;
QA visual especifico do Admin depende de rota/auth local simples;
Bloco J continua parcial.
```

## Proximo Passo Recomendado

```text
M2.19 - Link publico, @handle e partilha social
```

Nao iniciar M2.19 neste fecho.
