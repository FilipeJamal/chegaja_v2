# M2.17.4 - Fila Basica de Moderacao/Admin Leve

Data: 2026-05-29

## Estado

```text
M2.17.4 - concluida
M2.17 - ativa
M2.17.5 - proximo passo
Bloco F - parcial
Bloco H - parcial
R - pausado por falta de tester humano real
M - pausado por falta de Android fisico real
R1 - pendente
M2.6 - pendente
```

## Resultado

A M2.17.4 transformou `reports/{reportId}` na primeira fila operacional de
moderacao do ChegaJa. O admin/dev agora consegue listar denuncias e atualizar o
status de triagem sem criar backoffice completo, sem ocultar conteudo
automaticamente e sem banir utilizadores.

## Cloud Functions

Callables criadas:

```text
admin_listReports
admin_updateReportStatus
```

`admin_listReports`:

```text
exige admin;
lista reports por status;
default: pending_review;
limite default: 50;
retorna fields publicaveis para admin;
retorna contagens simples por status a partir da janela carregada.
```

`admin_updateReportStatus`:

```text
exige admin;
valida reportId;
valida status;
atualiza status;
grava updatedAt;
grava reviewedAt;
grava reviewedBy;
grava decisionReason quando informado.
```

Statuses aceitos nesta fase:

```text
pending_review
reviewed
resolved
hidden
rejected
dismissed
escalated
```

## Flutter/Admin

`AdminService` foi atualizado com:

```text
listReports({status, limit})
updateReportStatus({reportId, status, decisionReason})
```

O `AdminPanelScreen` ganhou a secao:

```text
Moderacao e denuncias
```

A secao permite:

```text
filtrar denuncias;
ver targetType;
ver reasonCode;
ver severity;
ver status;
ver reporterId;
ver targetId;
ver targetOwnerId;
ver detalhes;
marcar como analisada;
descartar;
escalar.
```

## Widget Isolado

Criado:

```text
lib/features/admin/widgets/admin_reports_section.dart
```

O widget trata:

```text
lista;
estado vazio;
erro isolado por secao;
dark mode;
acoes reviewed/dismissed/escalated.
```

## Testes

Criados/atualizados:

```text
functions/test/adminModeration.test.js
test/features/admin/admin_reports_section_test.dart
test/core/trust_safety_models_test.dart
```

Cobertura principal:

```text
admin lista reports pendentes;
admin lista reports por status;
admin atualiza status;
reviewedAt/reviewedBy/updatedAt sao gravados;
status invalido falha;
report inexistente falha de forma controlada;
utilizador comum nao lista nem atualiza reports;
utilizador anonimo nao lista nem atualiza reports;
secao admin mostra reports;
secao admin mostra erro/estado vazio;
acoes reviewed/dismissed/escalated chamam callback;
dark mode renderiza.
```

## ModerationCases

`ModerationCase` continua como modelo/contrato. A M2.17.4 usa `reports` como
fila inicial para manter o escopo pequeno e testavel. Criacao automatica de
`moderationCases` fica para uma fase posterior de admin/moderacao mais completa.

## Fora do Escopo Mantido

```text
admin/backoffice completo;
roles de moderador granulares;
custom claims novos;
ocultar conteudo automaticamente;
suspender utilizador;
banir utilizador;
apagar portfolio;
apagar mensagens;
moderacao automatica com IA;
filtros de servicos proibidos;
categorias sensiveis;
KYC;
pagamentos;
deploy;
Android fisico;
tester externo;
fechar R;
fechar R1;
fechar M;
fechar M2.6.
```

## Riscos Remanescentes

```text
Conteudo denunciado ainda nao e ocultado automaticamente.
Bloqueio ainda e sinal gravado, sem enforcement completo no chat.
Nao ha fila avancada com atribuicao, SLA ou historico de decisoes separado.
ModerationCases automaticos continuam futuros.
Discovery ainda precisa filtrar moderationStatus/isSearchable em fase futura.
```

## Decisao

M2.17.4 fica concluida no escopo de fila basica de moderacao/admin leve.

Proximo passo recomendado:

```text
M2.17.5 - Filtros de servicos proibidos e categorias sensiveis
```
