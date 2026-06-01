# M2.20.8 - Modelo/taxonomia de catalogo profissional

Data: 2026-06-01

Estado: CONCLUIDA no escopo atual.

## Resultado

A M2.20.8 criou a base tecnica do catalogo profissional sem redesenhar as telas
principais. A fase adicionou modelos puros, catalogo canonico inicial,
normalizador textual, matcher deterministico e testes focados para preparar a
M2.20.9.

## Ficheiros criados

- `lib/core/catalog/service_intent.dart`
- `lib/core/catalog/service_taxonomy.dart`
- `lib/core/catalog/service_taxonomy_catalog.dart`
- `lib/core/catalog/service_taxonomy_normalizer.dart`
- `lib/core/catalog/service_taxonomy_matcher.dart`
- `test/core/service_intent_test.dart`
- `test/core/service_taxonomy_test.dart`
- `test/core/service_taxonomy_normalizer_test.dart`
- `test/core/service_taxonomy_matcher_test.dart`

## Modelos criados

### ServiceIntent

Foram criadas as intencoes novas:

- `now` -> "Preciso agora";
- `scheduled` -> "Quero agendar";
- `quote` -> "Quero receber orcamento".

Tambem foi criada compatibilidade com modos antigos:

- `IMEDIATO` -> `now`;
- `AGENDADO` -> `scheduled`;
- `POR_PROPOSTA`, `POR_ORCAMENTO` e `ORCAMENTO` -> `quote`.

### ServiceTaxonomyCategory

Modelo de categoria principal com:

- `id`;
- `label`;
- `description`;
- `iconKey`;
- `sortOrder`;
- `isActive`;
- `subcategories`.

### ServiceTaxonomySubcategory

Modelo de subcategoria canonica com:

- `id`;
- `parentCategoryId`;
- `label`;
- `description`;
- `aliases`;
- `commonPhrases`;
- `examples`;
- `allowedIntents`;
- `defaultIntent`;
- `legacyServicoIds`;
- `legacyNames`;
- `sensitiveRequirementId`;
- `riskLevel`;
- `requiresApproval`;
- `isActive`;
- `sortOrder`.

## Catalogo canonico inicial

Foram criadas categorias principais para:

- Casa e reparacoes;
- Limpeza e manutencao;
- Beleza e bem-estar;
- Alimentacao;
- Eventos;
- Tecnologia;
- Educacao;
- Transporte e entregas;
- Cuidados;
- Animais;
- Negocios e criativos;
- Outros.

Subcategorias iniciais incluem, entre outras:

- Canalizacao;
- Eletricidade;
- Gas;
- Reparacoes gerais;
- Pintura;
- Montagem de moveis;
- Limpeza domestica;
- Jardinagem;
- Bolos e confeitaria;
- Catering;
- Comida para atletas;
- Reparacao de computadores;
- Internet e routers;
- Explicacoes;
- Aulas de musica;
- Entregas;
- Mudancas;
- Cuidados infantis;
- Cuidados a idosos;
- Passeio de caes.

## Normalizador textual

O `ServiceTaxonomyNormalizer` faz:

- lowercase;
- trim;
- remocao de acentos;
- remocao de pontuacao irrelevante;
- normalizacao de espacos;
- tokenizacao simples com stopwords basicas.

Exemplos validados:

- "Agua a Pingar" -> `agua a pingar`;
- "Arranjar luz!!!" -> `arranjar luz`;
- "Bolo de aniversario" -> `bolo de aniversario`;
- "PC lento" -> `pc lento`.

## Matcher deterministico

O `ServiceTaxonomyMatcher` procura matches por:

- label;
- aliases;
- common phrases;
- examples;
- legacy names;
- fallback parcial por tokens.

O retorno inclui:

- `bestMatch`;
- `suggestions`;
- `confidence`;
- `matchedBy`;
- `normalizedQuery`.

Exemplos validados:

- "arranjar luz" -> `electricity`;
- "cano rebentou" -> `plumbing`;
- "bolo aniversario" -> `cakes_confectionery`;
- "pc lento" -> `computer_repair`;
- "senhora limpar casa" -> `home_cleaning`;
- "montar chuveiro" -> `plumbing`;
- "comida fitness" -> `athlete_meals`;
- "buscar crianca na escola" -> `child_care`;
- "aulas matematica" -> `school_tutoring`.

Queries ambiguas, como "aulas", retornam sugestoes sem forcar um unico match.

## Compatibilidade com catalogo antigo

A M2.20.8 nao removeu nem alterou:

- `Servico`;
- `ServicosRepo`;
- `servicos_catalogo_generator.dart`;
- colecao `servicos`;
- dados de Firestore.

A compatibilidade foi preparada com:

- `legacyServicoIds`;
- `legacyNames`;
- `ServiceTaxonomyCatalog.mapLegacyServicoToSubcategory(...)`;
- conversao de legacy mode via `ServiceIntentX.fromLegacyMode(...)`.

Exemplos:

- `canalizador` -> `plumbing`;
- `bolos_personalizados` -> `cakes_confectionery`;
- `POR_PROPOSTA` -> `quote`.

## Categorias sensiveis preservadas

A taxonomia preserva os IDs de requisitos da M2.20:

- `electricity`;
- `gas`;
- `child_care`;
- `elder_care`;
- `professional_food`;
- `training_nutrition`;
- `transport`;
- `in_home_service`.

Subcategorias sensiveis usam:

- `requiresApproval = true`;
- `riskLevel = sensitive`;
- `sensitiveRequirementId` preenchido.

## Fora do escopo mantido

- redesenhar `NovoPedidoScreen`;
- redesenhar `PrestadorSettingsScreen`;
- alterar Firestore Rules;
- alterar Storage Rules;
- alterar Cloud Functions;
- migrar dados de `servicos`;
- apagar catalogo antigo;
- IA externa;
- motor externo de search;
- KYC;
- pagamentos;
- upload;
- deploy;
- Android fisico;
- tester externo;
- fechar R/R1/M/M2.6.

## Validacoes

Executadas no fecho da fase:

- `git diff --check`;
- `npm.cmd run test:scripts`;
- `flutter test --no-pub test/core/service_intent_test.dart`;
- `flutter test --no-pub test/core/service_taxonomy_test.dart`;
- `flutter test --no-pub test/core/service_taxonomy_normalizer_test.dart`;
- `flutter test --no-pub test/core/service_taxonomy_matcher_test.dart`;
- `flutter test --no-pub`;
- `flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release`.

## Proximo passo

```text
M2.20.9 - UI profissional de escolha de servico
```

A M2.20.9 deve usar esta base para redesenhar a escolha de servico no Cliente e
organizar a selecao de servicos do Prestador por categoria/subcategoria.
