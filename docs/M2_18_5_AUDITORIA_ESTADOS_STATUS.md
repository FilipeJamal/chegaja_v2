# M2.18.5 - Auditoria Leve e Estados Operacionais

Data: 2026-05-30

## Estado

M2.18.5 concluida.

```text
M2.18 - ativa
M2.18.1 - FECHADA
M2.18.2 - FECHADA
M2.18.3 - FECHADA
M2.18.4 - FECHADA
M2.18.5 - FECHADA
M2.18.6 - PROXIMO passo
M2.17 - FECHADA no escopo atual
Bloco F - PARCIAL
Bloco H - PARCIAL
Bloco J - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Resultado

A M2.18.5 criou auditoria leve para as principais acoes admin. O objetivo foi
garantir rastreabilidade minima sem criar um sistema enterprise de auditoria.

Agora as acoes admin principais podem registar:

```text
quem executou a acao;
qual acao foi executada;
qual alvo foi alterado;
estado anterior;
estado novo;
motivo/nota, quando existir;
data da acao;
origem admin_callable.
```

## Colecao Criada

```text
adminAuditLogs/{logId}
```

Campos gravados:

```text
actorUid
actorRole
action
targetType
targetId
beforeStatus
afterStatus
reason
metadata, opcional e pequeno
source
createdAt
```

O log nao guarda payloads completos de denuncias, mensagens, documentos, dados
pessoais ou detalhes sensiveis. Apenas metadados pequenos de rastreabilidade.

## Helper Server-side

Foi criado helper interno em `functions/index.js` para escrever audit logs:

```text
writeAdminAuditLog(...)
adminAuditLogPayload(...)
serializeAdminAuditLog(...)
```

As acoes admin usam batch quando possivel, para que a alteracao operacional e o
log sejam gravados juntos.

## Acoes Auditadas

Foram auditadas:

```text
admin_updateReportStatus
action: report.update_status
targetType: report

admin_updateSupportTicketStatus
action: support_ticket.update_status
targetType: support_ticket

admin_setNoShowDecision
action: no_show.set_decision
targetType: no_show

admin_deleteStory
action: story.delete
targetType: story
```

Nao foram criadas acoes destrutivas novas. A fase apenas passou a registar as
acoes ja existentes.

## Listagem de Logs

Foi criada callable admin/dev:

```text
admin_listAuditLogs
```

Entrada:

```text
limit, default 50 e maximo 100
targetType opcional
action opcional
```

Saida:

```text
logs recentes ordenados por createdAt desc
```

Utilizador comum e anonimo nao conseguem listar logs.

## AdminService e UI

`AdminService` recebeu:

```text
listAuditLogs({limit, targetType, action})
```

O AdminPanel ganhou a secao:

```text
Auditoria
```

Widget criado:

```text
AdminAuditLogsSection
```

A UI mostra:

```text
acao;
actorUid;
targetType/targetId;
beforeStatus -> afterStatus;
data;
motivo, quando existir;
estado vazio;
erro isolado;
dark mode.
```

## Estados Operacionais

Os estados continuam usando os chips/labels criados na M2.18.4. Foram
reforcados labels para estados como:

```text
active
deleted
missing
```

Nao houve mudanca de regra de negocio.

## Testes

Foram criados/atualizados:

```text
functions/test/adminAuditLogs.test.js
test/features/admin/admin_audit_logs_section_test.dart
test/features/admin/admin_panel_navigation_test.dart
```

Os testes cobrem:

```text
admin_updateReportStatus cria audit log;
admin_updateSupportTicketStatus cria audit log;
admin_setNoShowDecision cria audit log;
admin_deleteStory cria audit log;
admin_listAuditLogs lista logs recentes;
admin_listAuditLogs filtra por targetType/action;
utilizador comum/anonimo nao lista logs;
secao Auditoria renderiza logs;
estado vazio/erro/fallback;
dark mode;
navegacao do AdminPanel inclui Auditoria.
```

## Validacoes Executadas

```text
git diff --check - passou
npm.cmd run test:scripts - passou
node --check functions/index.js - passou
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=chegaja-ac88d npm.cmd --prefix functions test - passou na repeticao completa, 123 passing
flutter test --no-pub test/features/admin/admin_audit_logs_section_test.dart test/features/admin/admin_panel_navigation_test.dart test/features/admin/admin_queue_widgets_test.dart test/features/admin/admin_reports_section_test.dart test/features/admin/admin_operational_sections_test.dart test/features/admin/admin_overview_section_test.dart - passou
flutter test --no-pub - 314/314 passou
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

Observacao: a primeira execucao completa de Functions teve `92 passing` e uma
falha isolada `Transaction lock timeout` no hook dos testes de chat do Firestore
Emulator, fora do escopo da M2.18.5. A repeticao completa passou com `123
passing`, por isso ficou classificada como flake/contencao do emulator.

QA visual especifico do Admin nao foi executado porque o painel depende de rota
admin/auth local simples. Para esta fase, a cobertura usada foi widget tests,
Functions tests, Flutter completo e build Web release.

## Fora do Escopo Mantido

```text
auditoria enterprise completa
export CSV/PDF
paginacao/cursor real
roles granulares
custom claims novos
KYC
pagamentos
analytics avancado
graficos complexos
ocultacao automatica
banimento automatico
novas acoes destrutivas
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
logs ainda nao tem paginacao/cursor real;
nao ha exportacao operacional;
roles granulares de moderador/equipa continuam fora;
audit log ainda e leve, nao trilha enterprise completa;
Rules client-side para adminAuditLogs continuam dependentes da estrategia de leitura via callable.
```

## Decisao Final

M2.18.5 fica fechada. O Admin agora tem rastreabilidade minima para acoes
operacionais criticas, com listagem leve no painel e sem expandir para admin
enterprise.

Proximo passo:

```text
M2.18.6 - Testes, E2E, QA visual e documentacao final da M2.18
```
