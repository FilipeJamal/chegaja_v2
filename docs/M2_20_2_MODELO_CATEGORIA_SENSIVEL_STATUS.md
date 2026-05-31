# M2.20.2 - Modelo de Categoria Sensivel e Pedido de Aprovacao

Data: 2026-05-31

## Estado

M2.20.2 concluida.

```text
M2.20 - ativa
M2.20.1 - FECHADA
M2.20.2 - FECHADA
M2.20.3 - PROXIMO passo
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

A M2.20.2 criou a base tecnica de dados para categorias sensiveis e pedidos de
aprovacao profissional, sem criar UI, upload real, admin visual, badges publicos,
matching/discovery ou KYC.

Foram criados os modelos Dart:

```text
lib/core/models/category_approval_types.dart
lib/core/models/category_requirement.dart
lib/core/models/sensitive_category_request.dart
lib/core/models/provider_category_approval.dart
```

Foi criado o service minimo:

```text
lib/core/services/category_approval_service.dart
```

## Enums e Status

Foram definidos:

```text
CategoryRiskLevel:
- normal
- sensitive
- prohibited

SensitiveCategoryRequestStatus:
- draft
- submitted
- pending_review
- approved
- rejected
- needs_more_info
- expired
- revoked

EvidenceType:
- certificate
- license
- work_experience
- portfolio_reference
- external_profile
- declaration
- other

ProviderCategoryApprovalStatus:
- approved
- rejected
- suspended
- expired
- revoked
```

Importante: `certificate` e `license` sao tipos internos de evidencia. A fase
nao cria promessa publica de prestador "certificado".

## Modelo de Dados

Colecao de requisitos:

```text
categoryRequirements/{categoryId}
```

Objetivo:

```text
definir risco da categoria;
indicar se exige aprovacao;
listar tipos de evidencia aceites;
fornecer mensagem segura para o prestador.
```

Colecao de pedidos:

```text
sensitiveCategoryRequests/{requestId}
```

Campos principais:

```text
providerId
categoryId
categoryName
status
evidenceTypes
evidenceText
portfolioUrls
documentRefs
createdAt
updatedAt
submittedAt
reviewedBy
reviewedAt
decisionReason
expiresAt
```

Subcolecao de aprovacao por prestador:

```text
prestadores/{uid}/categoryApprovals/{categoryId}
```

Decisao inicial:

```text
approval de categoria vive junto ao prestador;
read e publico porque deve alimentar perfil/discovery no futuro;
write e apenas admin/dev;
prestador nao pode aprovar a si proprio.
```

## Service

`CategoryApprovalService` prepara a UI futura com operacoes minimas:

```text
buildRequestDraft(...)
createSensitiveCategoryRequest(...)
getProviderCategoryRequests(providerId)
streamProviderCategoryRequests(providerId)
getCategoryRequirement(categoryId)
isCategoryApprovedForProvider(providerId, categoryId)
```

O service aceita injecao de `FirebaseFirestore`, o que permitiu testes com
`fake_cloud_firestore` sem Firebase real.

## Rules

As Firestore Rules foram ajustadas porque a fase criou colecoes reais.

Decisoes:

```text
categoryRequirements:
- read publico;
- write apenas admin/dev.

sensitiveCategoryRequests:
- create apenas pelo proprio providerId;
- provider nao define reviewedBy/reviewedAt/decisionReason/expiresAt;
- evidenceText limitado;
- listas de evidencias/referencias com limites;
- provider le seus pedidos;
- admin/dev le todos;
- provider so edita enquanto draft ou needs_more_info;
- provider nao aprova/rejeita o proprio pedido;
- admin/dev pode rever.

prestadores/{uid}/categoryApprovals/{categoryId}:
- read publico;
- write apenas admin/dev;
- provider nao cria approval para si.
```

Storage Rules nao foram alteradas. Upload real continua fora.

## Testes

Foram adicionados testes Dart:

```text
test/core/category_requirement_test.dart
test/core/sensitive_category_request_test.dart
test/core/provider_category_approval_test.dart
test/core/category_approval_service_test.dart
```

Foram adicionados testes de Rules em:

```text
functions/test/firestore.test.js
```

Cobertura principal:

```text
parse/serializacao dos modelos;
fallbacks seguros;
isCurrentlyApproved;
criacao/listagem de requests;
leitura de requirements;
aprovacao por provider/category;
cliente nao fabrica approval;
provider nao escreve campos de review;
admin/dev pode gerir requirements e approvals.
```

## Fora do Escopo Mantido

```text
UI do prestador;
upload real de documentos;
admin visual;
integracao com discovery;
integracao com pedido/matching;
badges publicos de aprovacao;
KYC;
selfie/liveness;
pagamentos;
deploy;
Android fisico;
tester externo;
R/R1/M/M2.6.
```

## Riscos Remanescentes

```text
M2.20 ainda nao impede matching em categoria sensivel;
nao ha upload privado de comprovativos;
nao ha fila admin visual para revisao;
aprovacoes ainda nao criam audit log operacional;
perfil/discovery ainda nao mostram estado de aprovacao;
expiracao/revisao periodica ainda precisa de decisao operacional.
```

## Proximo Passo

```text
M2.20.3 - UI do prestador para pedir aprovacao em categoria sensivel
```
