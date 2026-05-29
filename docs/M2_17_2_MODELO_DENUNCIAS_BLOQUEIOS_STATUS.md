# M2.17.2 - Modelo de Denuncias, Bloqueios e Moderacao

Data: 2026-05-29

## Estado

```text
M2.17.2 - CONCLUIDA
M2.17.3 - PROXIMO PASSO
```

Estado global mantido:

```text
M2.14 - fechada no escopo atual
M2.15 - fechada no escopo atual
M2.16 - fechada no escopo atual
M2.17 - ativa
Bloco F - parcial
Bloco H - parcial
R - pausado por falta de tester humano real
M - pausado por falta de Android fisico real
R1 - pendente
M2.6 - pendente
```

## Objetivo

Transformar a spec/auditoria da M2.17.1 em base tecnica minima de Trust &
Safety, sem criar UI grande e sem admin/backoffice completo.

## Alteracoes Criadas

Modelos/enums:

```text
lib/core/models/moderation_types.dart
lib/core/models/trust_safety_report.dart
lib/core/models/user_block.dart
lib/core/models/moderation_case.dart
```

Service:

```text
lib/core/services/trust_safety_service.dart
```

Rules:

```text
firestore.rules
firestore.rules.local
```

Testes:

```text
functions/test/firestore.test.js
test/core/trust_safety_models_test.dart
test/core/trust_safety_service_test.dart
```

Documentacao:

```text
docs/M2_17_2_MODELO_DENUNCIAS_BLOQUEIOS_STATUS.md
docs/M2_17_TRUST_SAFETY_SPEC.md
docs/ROADMAP_A_T_CHEGAJA.md
```

## Reports

Colecao criada nas Rules:

```text
reports/{reportId}
```

Campos permitidos na criacao:

```text
reporterId
targetType
targetId
targetOwnerId
reasonCode
severity
details
status
createdAt
updatedAt
sourceContext
pedidoId
chatId
messageId
mediaUrl
mediaPath
```

Regras aplicadas:

```text
apenas utilizador autenticado cria report;
reporterId precisa ser request.auth.uid;
targetType precisa estar na whitelist;
reasonCode precisa estar na whitelist;
severity precisa estar na whitelist;
status inicial precisa ser pending_review;
createdAt e updatedAt precisam ser request.time;
details opcional limitado a 1000 caracteres;
campos extras falham;
reporter pode ler o proprio report;
outro utilizador comum nao le report alheio;
utilizador comum nao atualiza nem apaga report;
admin/moderador/dev podem gerir reports.
```

## Blocked Users

Colecao criada nas Rules:

```text
users/{uid}/blockedUsers/{blockedUid}
```

Campos permitidos:

```text
blockedUid
createdAt
reason
source
```

Regras aplicadas:

```text
apenas utilizador autenticado bloqueia;
uid do caminho precisa ser request.auth.uid;
blockedUid precisa bater com o documentId;
utilizador nao pode bloquear a si proprio;
createdAt precisa ser request.time;
reason/source opcionais tem limites;
campos extras falham;
utilizador le os proprios blockedUsers;
outro utilizador comum nao le blockedUsers alheio;
utilizador remove o proprio bloqueio;
update direto fica bloqueado.
```

## Moderation Cases

`ModerationCase` foi criado como modelo Dart/contrato para a fase admin/fila,
mas a colecao `moderationCases/{caseId}` e a criacao automatica de casos foram
adiadas.

Motivo:

```text
M2.17.2 precisava fechar modelo minimo + Rules + testes.
Fila visual/admin e abertura automatica de caso pertencem a M2.17.4/M2.18.
```

## Service

`TrustSafetyService` foi criado com injecao opcional de `FirebaseFirestore` e
`currentUserIdProvider` para testes.

Metodos:

```text
createReport(...)
blockUser(...)
unblockUser(...)
blockedUsersStream()
getBlockedUsers()
```

O service cria reports com `pending_review` e escreve bloqueios em
`users/{uid}/blockedUsers/{blockedUid}`.

## Testes Criados

Dart:

```text
trust_safety_models_test
- codecs de targetType/reasonCode/severity/status
- TrustSafetyReport create/fromFirestoreMap
- UserBlock create/fromFirestoreMap
- rejeicao defensiva de enum invalido/self-block/docId inconsistente

trust_safety_service_test
- createReport escreve payload pending_review
- createReport exige autenticacao
- blockUser escreve bloqueio
- unblockUser remove bloqueio
- blockUser rejeita self-block
```

Rules:

```text
Reports:
- authenticated create valido
- unauthenticated create falha
- reporterId falso falha
- targetType invalido falha
- reasonCode invalido falha
- severity invalida falha
- status inicial diferente de pending_review falha
- details acima do limite falha
- campo extra falha
- timestamp controlado pelo cliente falha
- user comum nao atualiza status
- user comum nao apaga report
- reporter le proprio report
- outro user nao le report alheio

Blocked users:
- user autenticado bloqueia outro user
- unauthenticated falha
- path uid diferente de auth.uid falha
- blockedUid diferente do docId falha
- self-block falha
- campo extra falha
- createdAt invalido falha
- user le propria lista
- outro user nao le lista alheia
- user remove proprio bloqueio
```

## Validacoes

Executadas:

```text
git status
git diff --check
npm.cmd run test:scripts
cd functions && FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=chegaja-ac88d npm.cmd test
flutter test --no-pub test/core/trust_safety_models_test.dart
flutter test --no-pub test/core/trust_safety_service_test.dart
flutter test --no-pub
```

## Fora do Escopo Mantido

```text
UI de denuncia;
UI de bloqueio;
botoes no perfil/chat/portfolio;
fila admin visual;
admin/backoffice completo;
moderacao automatica;
filtros automaticos de texto/conteudo;
esconder perfis na discovery;
KYC;
validacao documental;
videos;
pagamentos;
ranking;
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
a UI ainda nao liga denuncia/bloqueio a perfil, chat ou portfolio;
blockedUsers ainda nao impede mensagens no chat;
discovery ainda nao filtra moderationStatus/isPublic/isSearchable;
portfolio/stories ainda nao tem hide por item;
moderationCases ainda nao sao criados automaticamente;
admin/backoffice para fila de moderacao ainda nao existe;
filtros de servicos proibidos/categorias sensiveis ficam para M2.17.5.
```

## Decisao Final

A M2.17.2 fecha a base tecnica minima de Trust & Safety:

```text
modelo;
service;
Rules;
testes de Rules;
testes Dart.
```

O proximo passo correto e:

```text
M2.17.3 - UI de denuncia/bloqueio em perfil, chat e portfolio
```
