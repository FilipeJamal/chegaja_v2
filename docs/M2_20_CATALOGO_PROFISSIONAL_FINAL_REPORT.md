# M2.20 - Relatorio Final do Catalogo Profissional

Data: 2026-06-05

## Estado final

O trilho de catalogo profissional fica fechado no escopo atual.

```text
M2.20.7  - FECHADA - Spec/auditoria de catalogo profissional
M2.20.8  - FECHADA - Modelo/taxonomia de catalogo profissional
M2.20.9  - FECHADA - UI profissional de escolha de servico
M2.20.9.1 - FECHADA - Outro servico custom e bloqueio robusto de proibidos
M2.20.10 - FECHADA - QA final do catalogo profissional
```

Commit de referencia antes do QA final:

```text
b1c72ba6e57c8835beb83973aa0933c006c5d94e
Corrigir bloqueio robusto de servicos proibidos
```

## Problema original

O catalogo anterior tinha boa cobertura, mas misturava servicos canonicos,
microtarefas e modos de pedido numa lista extensa. A opcao "Outro servico"
tambem podia ficar generica demais, enfraquecendo pesquisa/matching e abrindo
risco para texto proibido.

O objetivo foi transformar o catalogo em uma experiencia profissional:

- categorias principais claras;
- subcategorias canonicas;
- aliases e frases comuns para pesquisa por linguagem natural;
- intencao de pedido separada do servico;
- "Outro servico" com nome, descricao e termos pesquisaveis;
- bloqueio Trust & Safety antes de gravar servico proibido;
- filtragem defensiva de dados proibidos antigos.

## Implementado

### Taxonomia

Foram criados:

```text
lib/core/catalog/service_intent.dart
lib/core/catalog/service_taxonomy.dart
lib/core/catalog/service_taxonomy_catalog.dart
lib/core/catalog/service_taxonomy_normalizer.dart
lib/core/catalog/service_taxonomy_matcher.dart
```

A taxonomia inclui categorias como Casa e reparacoes, Limpeza e manutencao,
Beleza e bem-estar, Alimentacao, Eventos, Tecnologia, Educacao, Transporte,
Cuidados, Animais, Negocios e criativos e Outros.

O matcher deterministico cobre aliases e frases populares como:

```text
arranjar luz -> Eletricidade
cano rebentou -> Canalizacao
bolo aniversario -> Bolos e confeitaria
pc lento -> Reparacao de computadores
senhora limpar casa -> Limpeza domestica
```

### Cliente

`NovoPedidoScreen` passou a organizar a criacao de pedido em:

```text
Servico
Quando e como?
Detalhes
```

O pedido continua compativel com campos antigos:

```text
servicoId
servicoNome
categoria
modo
tipoPreco
```

Quando o Cliente usa um servico fora do catalogo, o pedido custom grava campos
proprios:

```text
isCustomService
customServiceName
customServiceDescription
customServiceSearchTerms
```

### Prestador

`PrestadorSettingsScreen` passou a selecionar servicos por categoria e
subcategoria profissional. "Outro servico" nao pode ficar vazio: o prestador
precisa adicionar nome, descricao e aliases.

Servicos personalizados permitidos entram em:

```text
servicos
servicosNomes
customServices
customServiceNames
customServiceSearchTerms
customServiceUpdatedAt
```

Esses servicos ficam associados ao perfil do prestador, mas nao viram categoria
oficial global automaticamente.

### Trust & Safety

Foram adicionadas/validadas as camadas:

```text
lib/core/trust_safety/prohibited_terms.dart
lib/core/trust_safety/service_safety_guard.dart
lib/core/trust_safety/custom_service_safety_validator.dart
lib/core/trust_safety/trust_safety_classifier.dart
```

O app bloqueia servicos proibidos antes de guardar e filtra dados antigos antes
de renderizar/search/matching.

O matching nao usa substring simples para termos obscenos. A protecao usa
normalizacao, tokenizacao, frases proibidas, stem seguro e obfuscacoes simples,
mantendo falsos positivos legitimos permitidos.

Exemplos bloqueados:

```text
puta
p.u.t.a
p-u-t-a
p u t a
prostituta
prostituicao
garota de programa
programa sexual
servicos sexuais
vadia
drogas
trafico
armas ilegais
falsificacao de documentos
```

Exemplos permitidos:

```text
computador
reparacao de computadores
reputacao online
disputa contratual
consultoria de imagem
```

### Search e matching

`ProviderSearchProfile` e `ProviderSearchMatcher` consideram custom services
permitidos e ignoram dados proibidos persistidos.

Um pedido custom nao faz match amplo com `other_service` generico. O match usa
termos custom normalizados quando existirem.

## Validacao final

A M2.20.10 executou:

```text
git status --short --branch
git diff --check
npm.cmd run test:scripts
flutter test --no-pub test/core/service_intent_test.dart test/core/service_taxonomy_test.dart test/core/service_taxonomy_normalizer_test.dart test/core/service_taxonomy_matcher_test.dart
flutter test --no-pub test/core/service_safety_guard_test.dart test/core/trust_safety_classifier_test.dart test/core/provider_custom_service_test.dart test/core/custom_service_safety_validator_test.dart
flutter test --no-pub test/features/cliente/novo_pedido_screen_test.dart test/features/cliente/novo_pedido_taxonomy_test.dart
flutter test --no-pub test/features/prestador/prestador_settings_taxonomy_test.dart test/features/prestador/prestador_settings_sensitive_categories_test.dart test/features/prestador/widgets/prestador_home_components_test.dart
flutter test --no-pub test/features/common/perfil_publico_screen_test.dart test/features/cliente/discovery/provider_search_profile_test.dart test/features/cliente/discovery/provider_search_matcher_test.dart test/features/cliente/discovery/provider_search_screen_test.dart test/core/pedido_service_test.dart
flutter test --no-pub
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual
TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m22010-visual-qa --wait-ms=12000
```

Resultados:

- testes focados passaram;
- `flutter test --no-pub` passou com 475/475;
- build Web release passou, com aviso wasm conhecido em `dart_webrtc`;
- E2E dual passou com `FULL MULTI-SCENARIO FLOW OK`;
- E2E orcamento passou com `ORCAMENTO MIN-MAX FLOW OK`;
- QA visual passou e gerou 8 screenshots;
- Browser QA com dados contaminados confirmou `forbiddenVisible = []` e
  `consoleErrors = 0`.

## Rules, Functions e deploy

Nao foram alterados:

```text
firestore.rules
storage.rules
functions/index.js
```

Nao houve deploy.

## Fora do escopo mantido

```text
IA externa
motor externo de search
migracao Firestore
transformar custom services em categoria oficial automatica
validacao server-side/callable definitiva para texto livre
KYC
pagamentos
upload real
ranking avancado
deploy
Android fisico
tester externo
R/R1/M/M2.6
M2.21
```

## Riscos remanescentes

- A defesa de texto livre ainda depende de client-side guard e filtragem
  defensiva no app; antes de producao publica ampla, e recomendado adicionar
  validacao server-side/callable para bloquear escrita direta fora da UI.
- Custom services permitidos ainda nao entram em fila admin para virar catalogo
  oficial; isso deve ser decisao futura de produto/admin.
- Regras juridicas por categoria sensivel continuam a precisar revisao antes de
  escala publica.
- R e M continuam pausados por dependencias externas: tester humano e Android
  fisico real.

## Proximo passo

```text
M2.21 - Conta, definicoes e suporte premium
```

M2.21 nao foi iniciada neste fecho.
