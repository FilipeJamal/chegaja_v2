# M2.18.4 - Filas Operacionais do Admin

Data: 2026-05-30

## Estado

M2.18.4 concluida.

```text
M2.18 - ativa
M2.18.1 - FECHADA
M2.18.2 - FECHADA
M2.18.3 - FECHADA
M2.18.4 - FECHADA
M2.18.5 - PROXIMO passo
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

As filas operacionais do Admin ficaram mais consistentes e mais legiveis:

```text
reports/moderacao;
suporte;
no-show;
stories/conteudo.
```

A fase melhorou apresentacao, filtros, chips, cards, fallbacks e acoes
existentes. Nao criou novas acoes destrutivas.

## Padroes Visuais Criados

Foram criados widgets comuns:

```text
admin_queue_status_chip.dart
admin_queue_card.dart
admin_queue_action_row.dart
admin_queue_filter_bar.dart
```

Tambem foi reforcado:

```text
admin_formatters.dart
```

Os widgets comuns cobrem:

```text
labels legiveis para status/severidade/motivo/tipo;
cards com titulo, subtitulo, metadados e acoes;
filtros por status com labels amigaveis;
acoes em linha com suporte a estado bloqueado e acao destrutiva;
fallback "Sem dados" ou "-" quando falta informacao.
```

## Reports/moderacao

A `AdminReportsSection` foi mantida como fila de triagem de reports, mas ficou
mais clara:

```text
targetType, reasonCode, severity e status aparecem como chips legiveis;
acoes reviewed/dismissed/escalated foram preservadas;
details continuam truncados no card;
reporter, target e owner continuam visiveis quando existem.
```

Nao entrou:

```text
ocultacao automatica de conteudo;
banimento automatico;
moderationCases automaticos.
```

## Suporte

A fila de suporte agora mostra:

```text
ticketId com fallback;
assunto com fallback;
mensagem com fallback;
status em chip;
tipo de utilizador em chip;
data de criacao quando existe;
acoes existentes para reabrir/em andamento/resolver/fechar.
```

Nao entrou:

```text
chat de suporte;
SLA avancado;
novas callables.
```

## No-show

A fila de no-show agora mostra:

```text
pedidoId com fallback;
titulo com fallback;
decisao atual em chip;
reportado por;
motivo quando existe;
data de atualizacao quando existe;
acoes existentes aprovar/rejeitar para casos pendentes.
```

Nao houve mudanca de regra de negocio.

## Stories/conteudo

A fila de stories agora mostra:

```text
storyId com fallback;
prestador com fallback;
preview quando existe;
descricao com fallback;
expiracao quando existe;
aviso de acao destrutiva;
acao existente de remover story.
```

Nao entrou moderacao avancada de media.

## Callables e AdminService

Foram mantidos sem alteracao:

```text
AdminService
Cloud Functions admin
Firestore Rules
Storage Rules
```

A M2.18.4 foi uma melhoria de apresentacao e testabilidade das filas, usando os
dados ja retornados pelas callables existentes.

## Testes

Foram criados/atualizados:

```text
test/features/admin/admin_queue_widgets_test.dart
test/features/admin/admin_reports_section_test.dart
test/features/admin/admin_operational_sections_test.dart
test/features/admin/admin_panel_navigation_test.dart
```

Os testes cobrem:

```text
chips legiveis;
cards com fallback;
acoes chamando callbacks;
filtros;
erro isolado;
estado vazio;
dark mode;
reports;
suporte;
no-show;
stories.
```

## Validacoes Executadas

```text
git diff --check - passou
npm.cmd run test:scripts - passou
flutter test --no-pub test/features/admin/admin_queue_widgets_test.dart test/features/admin/admin_reports_section_test.dart test/features/admin/admin_operational_sections_test.dart test/features/admin/admin_panel_navigation_test.dart test/features/admin/admin_overview_section_test.dart - passou
flutter test --no-pub - 312/312 passou
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

Functions tests nao foram executados nesta fase porque nao houve alteracao em
Cloud Functions, Firestore Rules ou Storage Rules.

QA visual especifico do Admin nao foi executado por depender de rota/admin auth
local simples. A cobertura desta fase ficou em widget tests focados, Flutter test
completo e build Web release.

## Fora do Escopo Mantido

```text
novas Cloud Functions grandes
alteracao Firestore Rules
alteracao Storage Rules
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
acoes destrutivas novas
ocultacao automatica de conteudo
banimento automatico
Android fisico
tester externo
fechar R
fechar R1
fechar M
fechar M2.6
```

## Riscos Remanescentes

```text
as filas continuam sem paginacao/cursor real;
os dados continuam chegando como Map<String, dynamic>;
algumas callables admin ainda nao tem testes dedicados isolados;
acoes admin ainda nao geram audit log completo;
nao ha roles granulares de equipa.
```

## Decisao Final

M2.18.4 fica fechada. As filas operacionais estao mais consistentes, legiveis e
acionaveis, sem aumentar o risco operacional.

Proximo passo:

```text
M2.18.5 - Logs/auditoria leve e estados operacionais
```
