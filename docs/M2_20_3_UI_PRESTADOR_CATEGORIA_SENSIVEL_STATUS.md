# M2.20.3 - UI do Prestador para Categoria Sensivel

Data: 2026-05-31

## Estado

M2.20.3 concluida.

```text
M2.20 - ativa
M2.20.1 - FECHADA
M2.20.2 - FECHADA
M2.20.3 - FECHADA
M2.20.4 - PROXIMO passo
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

A M2.20.3 criou a primeira UI do prestador para categorias sensiveis e
comprovativos profissionais, usando a base tecnica criada na M2.20.2.

Foram criados:

```text
lib/features/prestador/widgets/prestador_sensitive_categories_section.dart
lib/features/prestador/widgets/sensitive_category_request_sheet.dart
lib/features/prestador/widgets/category_approval_status_chip.dart
```

Foram atualizados:

```text
lib/features/prestador/prestador_settings_screen.dart
lib/core/services/category_approval_service.dart
```

## UI Criada

O `PrestadorSettingsScreen` passou a mostrar a secao:

```text
Categorias sensiveis e comprovativos
```

A secao permite ao prestador:

```text
ver categorias sensiveis relevantes;
ver requisitos basicos;
ver status de pedido/aprovacao;
abrir formulario de pedido;
enviar evidencia textual;
referenciar URLs publicas do portfolio;
reenviar informacao quando o pedido estiver em needs_more_info.
```

Quando ainda nao houver documentos em `categoryRequirements`, a UI usa fallback
local baseado nos servicos selecionados e no `SensitiveCategories`, sem inventar
aprovacoes.

## Formulario de Pedido

O `SensitiveCategoryRequestSheet` permite:

```text
selecionar tipo de comprovativo;
descrever experiencia ou contexto profissional;
referenciar portfolio publico;
enviar pedido via CategoryApprovalService;
ver erro seguro em caso de falha;
bloquear duplo clique durante envio.
```

O texto informa claramente que o envio de ficheiros fica para uma fase futura e
que o prestador nao deve enviar documentos pessoais no campo livre.

## Service

O `CategoryApprovalService` foi ampliado apenas no lado Dart para suportar a UI:

```text
getActiveCategoryRequirements()
getProviderCategoryApprovals(providerId)
resubmitSensitiveCategoryRequest(...)
```

Nao foram alteradas Cloud Functions.

## Textos Seguros

A UI usa linguagem conservadora:

```text
pedido em analise;
categoria aprovada;
aprovacao ativa;
precisa de mais informacao;
comprovativo em analise.
```

Nao foram adicionadas promessas publicas como:

```text
Prestador certificado
verificado
garantido
pagamento seguro
aprovado oficialmente
```

## Fora do Escopo Mantido

```text
upload real de documentos;
Storage path novo;
admin visual;
aprovar/rejeitar no Admin;
integracao com discovery;
integracao com pedido/matching;
badges publicos;
KYC;
selfie/liveness;
pagamentos;
deploy;
Android fisico;
tester externo;
R/R1/M/M2.6.
```

## Testes Criados/Atualizados

```text
test/features/prestador/prestador_sensitive_categories_section_test.dart
test/features/prestador/sensitive_category_request_sheet_test.dart
test/features/prestador/prestador_settings_sensitive_categories_test.dart
test/core/category_approval_service_test.dart
```

Cobertura principal:

```text
secao renderiza categorias sensiveis;
status em analise aparece;
aprovacao ativa aparece;
estado vazio/erro aparece;
botao de pedido chama callback;
needs_more_info permite atualizar informacao;
sheet valida dados;
sheet envia payload correto;
portfolio publico pode ser referenciado;
upload real nao aparece;
texto de privacidade aparece;
loading bloqueia duplo clique;
erro de envio mostra feedback seguro;
fallback de servicos selecionados detecta categoria sensivel;
service lista requirements/approvals e reenvia pedido.
```

## Riscos Remanescentes

```text
nao ha upload privado de comprovativos;
nao ha fila admin visual para revisao;
nao ha enforcement em discovery/matching;
nao ha badge publico de categoria aprovada;
categoryRequirements ainda precisa de seed/configuracao operacional;
decisoes de admin ainda nao geram audit log de M2.20.
```

## Proximo Passo

```text
M2.20.4 - Admin leve para analisar comprovativos
```
