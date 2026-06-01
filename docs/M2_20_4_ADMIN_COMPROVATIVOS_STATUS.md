# M2.20.4 - Admin Leve para Analisar Comprovativos

Data: 2026-06-01

## Estado

M2.20.4 concluida.

```text
M2.20 - ativa
M2.20.1 - FECHADA
M2.20.2 - FECHADA
M2.20.3 - FECHADA
M2.20.4 - FECHADA
M2.20.5 - PROXIMO passo
M2.19 - FECHADA no escopo atual
Bloco F - PARCIAL
Bloco H - PARCIAL
Bloco J - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Resultado

A M2.20.4 criou o lado admin leve para analisar pedidos de categorias
sensiveis e comprovativos profissionais.

Foram criadas as callables:

```text
admin_listSensitiveCategoryRequests
admin_reviewSensitiveCategoryRequest
```

Foram criados os widgets:

```text
lib/features/admin/widgets/admin_sensitive_category_requests_section.dart
lib/features/admin/widgets/admin_sensitive_category_decision_sheet.dart
```

Foram atualizados:

```text
functions/index.js
lib/core/services/admin_service.dart
lib/features/admin/admin_panel_screen.dart
lib/features/admin/widgets/admin_panel_content.dart
lib/features/admin/widgets/admin_queue_status_chip.dart
```

## Callables

`admin_listSensitiveCategoryRequests` permite ao admin/dev listar pedidos por:

```text
status
providerId
categoryId
limit
```

Retorna pedidos recentes com dados operacionais seguros:

```text
id
providerId
categoryId
categoryName
status
evidenceTypes
evidenceText
portfolioUrls
documentRefs
createdAt
submittedAt
updatedAt
reviewedBy
reviewedAt
decisionReason
```

`admin_reviewSensitiveCategoryRequest` permite:

```text
approved
rejected
needs_more_info
```

Quando a decisao e `approved`, a callable cria/atualiza:

```text
prestadores/{providerId}/categoryApprovals/{categoryId}
```

com status `approved`, `sourceRequestId`, `approvedBy`, `approvedAt`,
`decisionReason` e `expiresAt` opcional.

## Audit Logs

As decisoes admin criam audit log leve em `adminAuditLogs`:

```text
sensitive_category_request.approve
sensitive_category_request.reject
sensitive_category_request.needs_more_info
```

O log guarda apenas metadados pequenos:

```text
providerId
categoryId
categoryName
```

Nao grava `evidenceText` completo, documentos privados ou payloads sensiveis.

## UI Admin

O AdminPanel ganhou a secao:

```text
Comprovativos
```

A secao mostra:

```text
categoria;
providerId;
status;
tipos de evidencia;
evidencia textual;
URLs publicas de portfolio;
motivo anterior, quando existir;
filtros por status;
estado vazio;
estado de erro;
acoes de decisao.
```

As acoes disponiveis sao:

```text
Aprovar
Rejeitar
Pedir mais informacao
```

Rejeicao e pedido de mais informacao exigem motivo. Aprovacao aceita motivo
opcional, mas a UI recomenda motivo para rastreabilidade.

## Fora do Escopo Mantido

```text
upload real de documentos;
Storage path novo;
visualizacao de documentos privados;
KYC;
selfie/liveness;
badges publicos;
integracao com discovery;
integracao com pedido/matching;
ranking;
pagamentos;
deploy;
Android fisico;
tester externo;
R/R1/M/M2.6.
```

## Validacoes

```text
git status - executado
git diff --check - passou
node --check functions/index.js - passou
npm.cmd run test:scripts - passou
npm.cmd --prefix functions test - passou dentro do Firestore/Storage Emulator, 147 passing
flutter test --no-pub test/features/admin/admin_sensitive_category_requests_section_test.dart - passou
flutter test --no-pub test/features/admin/admin_sensitive_category_decision_sheet_test.dart - passou
flutter test --no-pub test/features/admin/admin_panel_navigation_test.dart - passou
flutter test --no-pub - passou, 407/407
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
```

Nota tecnica: os testes Functions foram executados com o Emulator Suite ativo e
com `FUNCTIONS_EMULATOR`/`FIREBASE_EMULATOR_HUB` limpos no processo de teste
para preservar a validacao de `ensureAdmin` contra utilizador comum e anonimo.

## Riscos Remanescentes

```text
nao ha upload privado de documentos;
nao ha enforcement em discovery/matching;
nao ha badge publico de categoria aprovada;
categoryRequirements ainda precisa de configuracao operacional/seed real;
expiracao/revisao periodica de aprovacoes ainda precisa de politica final;
KYC continua fase separada.
```

## Proximo Passo

```text
M2.20.5 - Integracao com perfil/discovery/pedido
```
