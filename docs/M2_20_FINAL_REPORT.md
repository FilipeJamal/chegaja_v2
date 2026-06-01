# M2.20 - Relatorio Final Categorias Sensiveis e Comprovativos

Data: 2026-06-01

## Estado Final

M2.20 fechada no escopo atual de categorias sensiveis e comprovativos
profissionais.

```text
M2.20.1 - FECHADA - Spec e auditoria de categorias sensiveis/comprovativos
M2.20.2 - FECHADA - Modelo de categoria sensivel e pedido de aprovacao
M2.20.3 - FECHADA - UI do prestador para pedir aprovacao
M2.20.4 - FECHADA - Admin leve para analisar comprovativos
M2.20.5 - FECHADA - Integracao com perfil/discovery/pedido
M2.20.6 - FECHADA - Testes, E2E, QA visual e documentacao final
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

## Objetivo da M2.20

Criar a base de categorias sensiveis e comprovativos profissionais para que
certos servicos nao sejam tratados como categorias comuns quando exigem analise,
comprovativo, experiencia, licenca ou restricao operacional.

A M2.20 separa tres conceitos:

```text
categoria proibida - nao permitida;
categoria sensivel - permitida com analise/aprovacao quando aplicavel;
categoria normal - permitida sem analise especial.
```

M2.20 nao e KYC. Identidade civil, documento pessoal, selfie/liveness e
validacao formal de pessoa continuam fora.

## Commits Principais

```text
760e02b7de4c75d915a78ea5f2ea484e7aaa809a
Iniciar M2.20 categorias sensiveis comprovativos

907dceef66952aa94bb8713164556f89a2819fcc
Criar M2.20.2 modelo categorias sensiveis

56da7cf97b669b578d87fee629e15d7f2108e9e8
Criar M2.20.3 UI aprovacao categoria

55fa678a38876161a72260136b3554ad308ff62b
Criar M2.20.4 admin comprovativos

c1cde18b6832b37caea46f1ae9786d6846544f3d
Integrar M2.20.5 categorias aprovadas
```

## Fases

### M2.20.1

Criou a spec e auditoria de categorias sensiveis e comprovativos. A fase mapeou
catalogo, `SensitiveCategories`, Trust & Safety, perfil do prestador, portfolio,
discovery, pedidos, AdminPanel, Rules, Storage e KYC legado/futuro.

Decisao principal: comprovativo profissional por categoria nao deve ser
misturado com KYC.

### M2.20.2

Criou a base tecnica:

```text
CategoryRequirement;
SensitiveCategoryRequest;
ProviderCategoryApproval;
CategoryApprovalService;
categoryRequirements/{categoryId};
sensitiveCategoryRequests/{requestId};
prestadores/{uid}/categoryApprovals/{categoryId};
Rules para ownership/admin.
```

O prestador nao consegue criar approval para si proprio nem escrever campos de
review.

### M2.20.3

Criou a UI do prestador:

```text
PrestadorSensitiveCategoriesSection;
SensitiveCategoryRequestSheet;
CategoryApprovalStatusChip;
integracao em PrestadorSettingsScreen.
```

O prestador consegue ver categorias sensiveis, abrir pedido, enviar evidencia
textual, referenciar portfolio publico e reenviar informacao quando o pedido
esta em `needs_more_info`.

### M2.20.4

Criou o lado admin:

```text
admin_listSensitiveCategoryRequests;
admin_reviewSensitiveCategoryRequest;
AdminSensitiveCategoryRequestsSection;
AdminSensitiveCategoryDecisionSheet;
secao Comprovativos no AdminPanel.
```

O admin pode aprovar, rejeitar ou pedir mais informacao. Quando aprova, cria ou
atualiza `prestadores/{providerId}/categoryApprovals/{categoryId}`. As decisoes
geram `adminAuditLogs` leves sem copiar evidencia completa.

### M2.20.5

Integrou aprovacoes reais no produto:

```text
resumo publico seguro no prestador;
approvedSensitiveCategoryIds;
approvedSensitiveCategoryNames;
categoryApprovalsUpdatedAt;
perfil publico mostra categorias com aprovacao;
discovery/card mostra aprovacao com linguagem segura;
pedido sensivel grava categoryApprovalRequired e metadados auxiliares;
aceite direto e protegido por Rules;
propostas/orcamentos sao protegidos pelo PedidoService.
```

### M2.20.6

Fechou o bloco com documentacao final, testes focados, Functions/Rules, Flutter
completo, build Web, E2E e QA visual.

## Implementado no Escopo

```text
modelo de requisito de categoria;
modelo de pedido de aprovacao;
modelo de aprovacao por prestador/categoria;
service Dart para requests/approvals;
Rules de ownership/admin para categorias sensiveis;
UI privada do prestador para pedidos;
admin leve para analisar comprovativos;
audit log de decisoes admin;
resumo publico seguro de aprovacoes;
perfil publico com categorias aprovadas;
discovery/card com aprovacao segura;
pedido sensivel com aviso e metadados;
matching/aceite respeitando aprovacao onde implementado;
documentacao final.
```

## Validado

```text
test:scripts;
node --check functions/index.js;
Functions/Rules tests;
testes focados de modelos/services;
testes focados de UI do prestador;
testes focados de admin;
testes focados de perfil/discovery/pedido;
flutter test --no-pub;
build Web release;
E2E dual;
E2E orcamento;
QA visual.
```

Os resultados finais de comandos estao documentados em:

```text
docs/M2_20_6_QA_FINAL_CATEGORIAS_STATUS.md
```

## Decisoes Tecnicas Importantes

```text
M2.20 nao e KYC;
portfolio publico pode ser evidencia informal, nao documento privado;
upload real fica fora ate existir politica de Storage/privacidade;
approval vive em prestadores/{uid}/categoryApprovals/{categoryId};
resumo publico fica em prestadores/{uid} apenas com dados minimos;
evidenceText/documentRefs nao entram no resumo publico;
prestador nao escreve campos de approval diretamente;
audit log nao guarda payload sensivel completo;
perfil/discovery usam linguagem segura, sem certificado/verificado;
Rules protegem aceite direto de pedido sensivel;
PedidoService protege propostas/orcamentos por limite de expressoes das Rules.
```

## Fora do Escopo Mantido

```text
upload real;
Storage path novo para comprovativos;
documentos privados;
KYC;
selfie/liveness;
badges "certificado" ou "verificado";
ranking avancado;
monetizacao;
pagamentos;
deploy;
Android fisico;
tester externo;
fechar R/R1/M/M2.6.
```

## Riscos Remanescentes

```text
categoryRequirements ainda precisa de seed/configuracao operacional real;
expiracao/revogacao de aprovacoes ainda precisa de politica final;
upload privado de comprovativos continua fora;
KYC continua separado;
SEO/metadados publicos continuam fora;
ranking por aprovacao continua fora;
server-side enforcement cobre apenas pedidos marcados como categoryApprovalRequired;
Rules protegem aceite direto e PedidoService protege propostas/orcamentos;
politica juridica por categoria sensivel ainda precisa revisao antes de escala.
```

## Proximo Bloco Recomendado

```text
M2.21 - Conta, definicoes e suporte premium
```

M2.21 nao foi iniciada nesta tarefa.
