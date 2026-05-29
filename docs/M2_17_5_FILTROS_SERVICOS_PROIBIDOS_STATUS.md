# M2.17.5 - Filtros de Servicos Proibidos e Categorias Sensiveis

Data: 2026-05-29

## Estado

```text
M2.17.5 - concluida
M2.17 - ativa
M2.17.6 - proximo passo
Bloco F - parcial
Bloco H - parcial
R - pausado por falta de tester humano real
M - pausado por falta de Android fisico real
R1 - pendente
M2.6 - pendente
```

## Resultado

A M2.17.5 criou a primeira camada simples e auditavel de filtros de Trust &
Safety para texto de servicos, perfis e pedidos. A fase nao usa IA, nao faz KYC,
nao bane utilizadores automaticamente e nao oculta conteudo existente.

## Implementacao

Ficheiros criados:

```text
lib/core/models/trust_safety_classification.dart
lib/core/trust_safety/trust_safety_text_normalizer.dart
lib/core/trust_safety/prohibited_terms.dart
lib/core/trust_safety/sensitive_categories.dart
lib/core/trust_safety/trust_safety_classifier.dart
```

Testes criados:

```text
test/core/trust_safety_text_normalizer_test.dart
test/core/trust_safety_classifier_test.dart
test/core/sensitive_categories_test.dart
```

## Normalizador

`TrustSafetyTextNormalizer` faz:

```text
lowercase;
remocao de acentos;
normalizacao de espacos;
troca de pontuacao irrelevante por espaco;
preservacao de palavras relevantes para classificacao.
```

Exemplos cobertos:

```text
Prostituicao -> prostituicao
TRAFICO de Drogas -> trafico de drogas
Armas ilegais!!! -> armas ilegais
servicos-sexuais / adultos -> servicos sexuais adultos
```

## Termos Proibidos

`ProhibitedTerms` cobre uma lista inicial conservadora de alto risco:

```text
prostituicao / servicos sexuais;
pornografia / conteudo sexual explicito;
trafico humano;
drogas ilegais;
armas ilegais;
falsificacao de documentos;
fraude/golpe/burla/phishing;
exploracao de menores;
violencia criminosa/extorsao;
contexto adulto ambiguo para analise.
```

Termos claros produzem `block`. Termos ambiguos produzem `needsReview` para
evitar falso bloqueio automatico quando o contexto nao e suficiente.

## Categorias Sensiveis

`SensitiveCategories` cobre:

```text
saude;
cuidados infantis;
cuidados a idosos/pessoas vulneraveis;
eletricidade;
gas;
seguranca privada;
alimentacao profissional/catering;
treino/nutricao;
transporte;
servicos em casa do cliente.
```

Categorias sensiveis geram `needsReview`, nao `block`.

## Classificacao

`TrustSafetyClassifier` retorna:

```text
TrustSafetyDecision.allow
TrustSafetyDecision.warn
TrustSafetyDecision.needsReview
TrustSafetyDecision.block
```

O resultado inclui:

```text
decision;
matchedTerms;
matchedCategories;
reasonCodes;
severity;
messageForUser;
internalReason.
```

Mensagens ao utilizador sao seguras e nao expõem a lista completa de termos
internos nem ensinam como contornar o filtro.

## Integracao Leve

A fase integrou o classifier em dois pontos de entrada:

```text
PrestadorPerfilScreen - classifica nome e bio antes de guardar perfil.
NovoPedidoScreen - classifica titulo, descricao e categoria antes de submeter pedido.
```

Comportamento:

```text
allow - segue normalmente;
warn/needsReview - mostra SnackBar e permite continuar;
block - mostra SnackBar e bloqueia o envio/guardar.
```

Esta decisao evita quebrar categorias legitimas sensiveis, como eletricidade,
gas, saude ou cuidados infantis, antes de existir fluxo formal de comprovativos
e aprovacao.

## Limite de Seguranca

Este filtro e uma camada de UX/preventiva client-side. Nao substitui validacao
server-side.

Antes de producao publica em escala, os casos criticos precisam ser reforcados
em camada autoritativa:

```text
Cloud Functions;
Rules quando aplicavel;
providerSearchIndex/publicProfiles;
fila de moderacao;
admin/backoffice;
audit logs.
```

## Fora do Escopo Mantido

```text
IA de moderacao;
moderacao automatica pesada;
ocultar conteudo existente automaticamente;
banimento automatico;
admin/backoffice completo;
KYC;
documentos/selfie;
videos;
pagamentos;
ranking;
patrocinados;
Play Store;
Android fisico;
tester externo;
deploy;
fechar R;
fechar R1;
fechar M;
fechar M2.6.
```

## Riscos Remanescentes

```text
Client-side pode ser contornado e precisa enforcement server-side futuro.
NeedsReview ainda nao cria moderationCase automatico.
Categorias sensiveis ainda nao tem fluxo de comprovativo/aprovacao.
Discovery ainda precisa filtrar isSearchable/moderationStatus em fase futura.
Conteudo existente nao foi reclassificado.
```

## Validacoes

Executadas:

```text
git status
git diff --check
npm.cmd run test:scripts
flutter test --no-pub test/core/trust_safety_text_normalizer_test.dart
flutter test --no-pub test/core/trust_safety_classifier_test.dart
flutter test --no-pub test/core/sensitive_categories_test.dart
flutter test --no-pub test/features/cliente/novo_pedido_screen_test.dart
flutter test --no-pub test/features/prestador/prestador_perfil_portfolio_test.dart
flutter test --no-pub
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento
```

Resultados:

```text
test:scripts passou;
testes focados de Trust & Safety passaram;
testes focados de NovoPedidoScreen/PrestadorPerfil passaram;
flutter test completo passou: 289/289;
build Web release passou;
e2e:ui:dual passou em repeticao isolada com FULL MULTI-SCENARIO FLOW OK;
e2e:ui:orcamento passou com ORCAMENTO MIN-MAX FLOW OK.
```

Observacao:

```text
A primeira tentativa conjunta de e2e:ui:dual falhou no runner de cancelamento
apos o happy-path, mesmo com o botao "Cancelar pedido" visivel no screenshot.
A repeticao isolada passou completa, portanto o evento foi tratado como flake
de runner/ambiente e nao como regressao do filtro.
```

## Decisao

M2.17.5 fica concluida no escopo de filtros simples e auditaveis de servicos
proibidos e categorias sensiveis.

Proximo passo recomendado:

```text
M2.17.6 - Testes, E2E, QA visual e documentacao final da M2.17
```
