# M2.20.5 - Integracao com Perfil, Discovery e Pedido

Data: 2026-06-01

## Estado

M2.20.5 concluida.

```text
M2.20 - ativa
M2.20.1 - FECHADA
M2.20.2 - FECHADA
M2.20.3 - FECHADA
M2.20.4 - FECHADA
M2.20.5 - FECHADA
M2.20.6 - PROXIMO passo
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

A M2.20.5 integrou as aprovacoes reais de categorias sensiveis no produto sem
criar KYC, upload real, badges fortes ou ranking avancado.

## Integracao Feita

Quando o admin aprova um pedido em `admin_reviewSensitiveCategoryRequest`, a
Function continua a criar/atualizar:

```text
prestadores/{providerId}/categoryApprovals/{categoryId}
```

E agora tambem atualiza um resumo publico minimo no documento do prestador:

```text
approvedSensitiveCategoryIds
approvedSensitiveCategoryNames
categoryApprovalsUpdatedAt
```

Esse resumo nao inclui:

```text
evidenceText
documentRefs
documentos privados
dados KYC
telefone/email
payloads sensiveis
```

## Rules

As Firestore Rules protegem os campos de resumo contra escrita client-side:

```text
approvedSensitiveCategoryIds
approvedSensitiveCategoryNames
categoryApprovalsUpdatedAt
```

O prestador continua a poder atualizar campos normais permitidos do perfil, mas
nao consegue fingir aprovacao para si proprio.

As Rules passam a exigir aprovacao no aceite direto de pedidos quando o pedido
tem:

```text
categoryApprovalRequired == true
```

Nesse caso, o prestador precisa ter o `servicoId` em
`approvedSensitiveCategoryIds`. Para propostas/orcamentos, o `PedidoService`
aplica a mesma regra no fluxo de negocio para evitar ultrapassar o limite de
expressoes das Firestore Rules.

## Perfil e Discovery

`PublicProfileScreen` mostra a secao:

```text
Categorias com aprovacao
```

apenas quando existem categorias aprovadas. O texto usado e conservador:

```text
Aprovacao ativa
Estas categorias foram analisadas pelo ChegaJa com base nas informacoes enviadas pelo prestador.
```

`ProviderSearchProfile` mapeia `approvedSensitiveCategoryIds` e
`approvedSensitiveCategoryNames`, e o `ProviderSearchCard` mostra uma indicacao
discreta de categoria aprovada quando existe resumo real.

## Pedido e Matching

`NovoPedidoScreen` identifica categorias sensiveis pela base local
`SensitiveCategories` e mostra:

```text
Este servico exige prestador com aprovacao na categoria.
```

Pedidos sensiveis criados pela tela gravam campos auxiliares:

```text
categoryApprovalRequired
categoryRequirementId
categoryRequirementName
categoryRiskLevel
```

A selecao manual de prestador filtra por `approvedSensitiveCategoryIds` quando a
categoria exige aprovacao. O `PedidoService` tambem impede proposta de prestador
sem aprovacao para pedido sensivel. Pedidos normais continuam com o fluxo
existente.

## Linguagem Segura

Foram evitados textos como:

```text
Prestador certificado
verificado
garantido
aprovado oficialmente
pagamento seguro
identidade confirmada
```

## Fora do Escopo Mantido

```text
upload real;
Storage path novo;
documentos privados;
KYC;
selfie/liveness;
badge "certificado";
badge "verificado";
ranking avancado;
monetizacao;
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
npm.cmd run test:scripts - passou
node --check functions/index.js - passou
npm.cmd --prefix functions test - passou, 151 passing
flutter test --no-pub test/features/common/perfil_publico_screen_test.dart - passou
flutter test --no-pub test/features/cliente/discovery/provider_search_profile_test.dart - passou
flutter test --no-pub test/features/cliente/discovery/provider_search_card_test.dart - passou
flutter test --no-pub test/features/cliente/widgets/provider_suggestions_section_test.dart - passou
flutter test --no-pub test/features/cliente/novo_pedido_screen_test.dart - passou
flutter test --no-pub test/core/pedido_service_test.dart - passou
flutter test --no-pub - passou, 414/414
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release - passou
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual - passou, FULL MULTI-SCENARIO FLOW OK
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento - passou, ORCAMENTO MIN-MAX FLOW OK
```

Observacao: os E2E foram executados com emuladores Auth/Firestore/Storage. A
primeira tentativa sem Auth Emulator falhou antes do fluxo por falta de
`127.0.0.1:9099`; a repeticao com Auth passou. No E2E de orcamento apareceu um
erro interno do SDK Firestore no console do browser/emulator apos o envio do
orcamento, mas o fluxo terminou com pedido concluido e o script passou.

## Riscos Remanescentes

```text
categoryRequirements ainda precisa de seed/configuracao operacional real;
expiracao/revogacao de aprovacoes ainda precisa de politica final;
upload privado de comprovativos continua fora;
KYC continua separado;
SEO/metadados publicos continuam fora;
ranking por aprovacao continua fora.
```

## Proximo Passo

```text
M2.20.6 - Testes, E2E, QA visual e documentacao final
```
