# M2.18.3 - Dashboard e Metricas Essenciais do Admin

Data: 2026-05-30

## Estado

M2.18.3 concluida.

```text
M2.18 - ativa
M2.18.1 - FECHADA
M2.18.2 - FECHADA
M2.18.3 - FECHADA
M2.18.4 - PROXIMO passo
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

A secao `Visao geral` do Admin ficou mais clara e mais util para leitura
operacional. A M2.18.3 nao reorganizou a navegacao criada na M2.18.2 e nao
criou analytics avancado.

## Melhorias Criadas

Foram criados widgets de dashboard:

```text
admin_health_summary_card.dart
admin_metric_group_card.dart
admin_dashboard_explainer.dart
```

Foram atualizados:

```text
admin_overview_section.dart
admin_metric_tile.dart
admin_formatters.dart
admin_panel_content.dart
```

## Grupos de Metricas

A `Visao geral` agora agrupa:

```text
Pendencias operacionais
Pedidos
Financeiro operacional
Crescimento e retencao
```

Pendencias operacionais mostram:

```text
tickets abertos;
denuncias pendentes;
no-show pendente;
anomalias de ledger.
```

Pedidos mostram:

```text
pedidos criados nos ultimos 30 dias;
pedidos concluidos nos ultimos 30 dias;
taxa simples de conclusao;
cancelamentos.
```

Financeiro operacional mostra:

```text
receita liquida;
receita bruta;
comissao/plataforma.
```

Crescimento e retencao mostram:

```text
novos utilizadores;
utilizadores ativos;
churn estimado;
LTV estimado.
```

## Saude Operacional

Foi criado um resumo simples:

```text
Ha pendencias para rever
Operacao sem pendencias criticas
```

O texto nao promete sistema perfeito. Ele apenas resume as filas carregadas no
admin naquele momento.

## Dados Ausentes

Quando um dado nao existe, a UI mostra fallback honesto:

```text
-
Sem dados suficientes para esta metrica.
```

Nao foram inventados valores para lucro real, faturacao real, pagamento real,
ranking, KYC ou qualquer metrica ainda sem fonte confiavel.

## Callables e AdminService

Foram mantidos sem alteracao:

```text
AdminService
Cloud Functions admin
Firestore Rules
Storage Rules
```

A M2.18.3 usa os dados ja carregados pelo admin:

```text
dashboard
ops
cost
tickets
reports
noShowCases
ledgerAnomalies
```

Quando necessario, a contagem de reports pendentes e anomalias usa a lista
carregada no painel. Isso continua sendo uma leitura operacional simples, nao
um sistema de BI definitivo.

## Testes

Foram criados/atualizados:

```text
test/features/admin/admin_dashboard_metrics_test.dart
test/features/admin/admin_overview_section_test.dart
test/features/admin/admin_panel_navigation_test.dart
test/features/admin/admin_operational_sections_test.dart
test/features/admin/admin_reports_section_test.dart
```

O ciclo TDD foi respeitado: os testes novos foram executados em RED antes da
implementacao e falharam por widgets/parametros ainda inexistentes.

## Validacoes Executadas

```text
git diff --check - passou
npm.cmd run test:scripts - passou
flutter test --no-pub test/features/admin/admin_overview_section_test.dart - passou
flutter test --no-pub test/features/admin/admin_dashboard_metrics_test.dart - passou
flutter test --no-pub test/features/admin/admin_panel_navigation_test.dart - passou
flutter test --no-pub test/features/admin/admin_operational_sections_test.dart - passou
flutter test --no-pub test/features/admin/admin_reports_section_test.dart - passou
flutter test --no-pub - passou, 305/305
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

O build Web manteve apenas avisos conhecidos do dry run Wasm em `dart_webrtc`.

## QA Visual

Foi tentada verificacao via browser local, mas o conector do browser falhou no
runtime antes de abrir a pagina. Como nao ha rota admin autenticada simples e
isolada para validar a tela sem dependencias de auth/callables, a verificacao
visual especifica do admin ficou limitada a testes de widget e build Web.

## Fora do Escopo Mantido

```text
novas Cloud Functions grandes
alteracao Firestore Rules
alteracao Storage Rules
deploy
KYC
pagamentos
graficos complexos
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
metricas continuam dependentes de snapshots simples;
algumas contagens sao baseadas nas listas carregadas;
nao ha paginacao/cursor real nas filas;
nao ha DTOs especificos para todos os dados admin;
AdminService continua acoplado a FirebaseFunctions real.
```

## Decisao Final

M2.18.3 fica fechada. A `Visao geral` agora ajuda o dono/equipa a perceber
pendencias, pedidos, financeiro operacional e crescimento sem criar metricas
falsas nem analytics avancado.

Proximo passo:

```text
M2.18.4 - Melhorar filas operacionais: reports, suporte, no-show, stories
```
