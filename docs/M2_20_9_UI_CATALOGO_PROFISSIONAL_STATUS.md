# M2.20.9 - UI profissional de escolha de servico

Data: 2026-06-01

Estado: CONCLUIDA no escopo atual.

## Resultado

A M2.20.9 aplicou a taxonomia profissional criada na M2.20.8 nas telas
principais de escolha de servico, sem alterar Rules, Functions, deploy, KYC,
pagamentos ou upload.

## Alteracoes

- `NovoPedidoScreen` passou a usar uma secao de taxonomia profissional.
- O Cliente pode pesquisar em linguagem simples, como "arranjar luz", "cano
  rebentou" ou "bolo aniversario".
- Categorias principais aparecem como escolha visivel antes das subcategorias.
- Subcategorias canonicas substituem a sensacao de lista de microtarefas.
- `ServiceIntent` organiza "Preciso agora", "Quero agendar" e "Quero receber
  orcamento".
- A criacao de pedido continua a gravar campos compativeis:
  - `servicoId`;
  - `servicoNome`;
  - `categoria`;
  - `modo`;
  - `tipoPreco`.
- Categorias sensiveis continuam a mostrar aviso e a preencher campos de
  approval da M2.20 quando aplicavel.
- `PrestadorSettingsScreen` passou a organizar a selecao de servicos por
  categorias e subcategorias profissionais.
- A selecao do Prestador continua a guardar `servicos` e `servicosNomes`,
  agora usando IDs/nomes canonicos da taxonomia quando escolhidos.

## Widgets criados

- `lib/features/cliente/widgets/service_taxonomy_picker_section.dart`
- `lib/features/prestador/widgets/prestador_service_taxonomy_selector.dart`

## Exemplos de pesquisa

- "arranjar luz" sugere Eletricidade.
- "bolo aniversario" sugere Bolos e confeitaria.
- "cano rebentou" sugere Canalizacao.

## Categorias sensiveis

Subcategorias com `requiresApproval` continuam a usar linguagem segura:

- "Este servico exige prestador com aprovacao na categoria."
- "Exige prestador com aprovacao na categoria."

Nao foram usados termos como:

- certificado;
- verificado;
- garantido;
- aprovado oficialmente;
- pagamento seguro.

## Validacoes

- `git diff --check` - passou, apenas avisos CRLF.
- `npm.cmd run test:scripts` - passou.
- `flutter test --no-pub test/core/service_intent_test.dart` - passou.
- `flutter test --no-pub test/core/service_taxonomy_test.dart` - passou.
- `flutter test --no-pub test/core/service_taxonomy_normalizer_test.dart` - passou.
- `flutter test --no-pub test/core/service_taxonomy_matcher_test.dart` - passou.
- `flutter test --no-pub test/features/cliente/novo_pedido_screen_test.dart` - passou.
- `flutter test --no-pub test/features/cliente/novo_pedido_taxonomy_test.dart` - passou.
- `flutter test --no-pub test/features/prestador/prestador_settings_taxonomy_test.dart` - passou.
- `flutter test --no-pub test/features/prestador/prestador_settings_sensitive_categories_test.dart` - passou.
- `flutter test --no-pub test/core/pedido_service_test.dart` - passou.
- `flutter test --no-pub` - passou, 435/435.
- `flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release` - passou.
- `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual` via Firebase Emulators - passou, `FULL MULTI-SCENARIO FLOW OK`.
- `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento` via Firebase Emulators - passou, `ORCAMENTO MIN-MAX FLOW OK`.
- `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m2209-visual-qa-emulators --wait-ms=12000` via Firebase Emulators - passou, 8 screenshots sem `consoleErrors`.

Observacao: uma primeira execucao do QA visual sem emuladores registou erros de
consola por ligacao aos emuladores ausentes. A execucao valida desta fase foi
repetida com Auth/Firestore/Storage Emulators ativos.

## Fora do escopo

- IA externa;
- motor externo de search;
- migracao Firestore;
- remocao do catalogo antigo;
- alteracao de Firestore Rules;
- alteracao de Cloud Functions;
- KYC;
- pagamentos;
- upload;
- ranking avancado;
- deploy;
- Android fisico;
- R/R1/M/M2.6.

## Proximo passo

M2.20.10 - QA final do catalogo profissional.
