# M2.18.2 - Reorganizacao do AdminPanel em Secoes

Data: 2026-05-29

## Estado

M2.18.2 concluida.

```text
M2.18 - ativa
M2.18.1 - FECHADA
M2.18.2 - FECHADA
M2.18.3 - PROXIMO passo
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

O `AdminPanelScreen` foi reorganizado para reduzir a densidade da tela unica e
separar a responsabilidade visual em secoes testaveis.

A navegacao interna passou a usar segmentos:

```text
Visao geral
Moderacao
Suporte
No-show
Conteudo
Financeiro
```

O painel existente foi evoluido. Nao foi criado um segundo admin paralelo.

## Estrutura Criada

Foram criados widgets de apoio em `lib/features/admin/widgets/`:

```text
admin_panel_content.dart
admin_overview_section.dart
admin_support_tickets_section.dart
admin_no_show_section.dart
admin_stories_section.dart
admin_finance_ledger_section.dart
admin_section_state.dart
admin_metric_tile.dart
admin_formatters.dart
```

O `AdminPanelScreen` ficou responsavel por carregar dados, manter estados,
executar callbacks e renderizar `AdminPanelContent`.

## Callables e AdminService

As callables admin foram mantidas sem alteracao:

```text
admin_getDashboardSnapshot
admin_getOpsMetrics
admin_getCostRetentionSnapshot
admin_listSupportTickets
admin_updateSupportTicketStatus
admin_listReports
admin_updateReportStatus
admin_listNoShowCases
admin_setNoShowDecision
admin_listStories
admin_deleteStory
admin_getLedgerAnomalies
```

O `AdminService` tambem foi mantido sem alteracao de contrato.

## Estados

Foram preservados ou isolados:

```text
loading inicial
refresh geral
erro global
erro por secao
estado vazio por secao
feedback via SnackBar para acoes
```

A `AdminReportsSection` continua integrada na secao `Moderacao`.

## Testes

Foram criados testes dedicados:

```text
test/features/admin/admin_panel_navigation_test.dart
test/features/admin/admin_overview_section_test.dart
test/features/admin/admin_operational_sections_test.dart
```

Tambem foi preservada a cobertura existente:

```text
test/features/admin/admin_reports_section_test.dart
```

## Validacoes Executadas

```text
git diff --check - passou
npm.cmd run test:scripts - passou
flutter test --no-pub test/features/admin/admin_reports_section_test.dart test/features/admin/admin_panel_navigation_test.dart test/features/admin/admin_overview_section_test.dart test/features/admin/admin_operational_sections_test.dart - passou
flutter test --no-pub - passou, 299/299
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

Antes da implementacao, os novos testes foram executados em RED e falharam por
widgets ainda inexistentes, como esperado no ciclo TDD.

## QA Visual

O build Web release passou. Nao foi feita verificacao visual especifica do
admin no browser porque nao ha uma rota admin autenticada simples e isolada no
ambiente local para abrir a secao sem depender de auth/callables. A organizacao
visual do admin ficou coberta por testes de widget das secoes e da navegacao.

## Fora do Escopo Mantido

```text
novas Cloud Functions
alteracoes em Firestore Rules
alteracoes em Storage Rules
deploy
KYC
pagamentos
graficos avancados
analytics avancado
export CSV/PDF
roles granulares
custom claims novos
auditoria completa
admin enterprise completo
Android fisico
tester externo
fechar R
fechar R1
fechar M
fechar M2.6
```

## Riscos Remanescentes

```text
AdminService ainda usa mapas dinamicos e FirebaseFunctions diretamente.
Algumas callables admin continuam sem testes dedicados isolados.
Nao ha paginacao/cursor real nas filas.
O admin ainda nao e backoffice completo nem tem roles granulares.
```

## Decisao Final

M2.18.2 fica fechada. O AdminPanel esta mais navegavel e testavel, mantendo as
funcionalidades e contratos existentes.

Proximo passo:

```text
M2.18.3 - Melhorar dashboard e metricas essenciais
```
