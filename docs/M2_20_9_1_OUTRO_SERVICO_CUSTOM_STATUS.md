# M2.20.9.1 - Outro servico custom profissional e seguro

Data: 2026-06-01

Estado: CONCLUIDA no escopo atual.

## Problema resolvido

"Outro servico" deixou de ser uma categoria generica vazia. Antes, Cliente e
Prestador podiam cair em "Outro" sem explicar qual trabalho estava em causa,
enfraquecendo pesquisa, matching e apresentacao profissional.

Tambem foi adicionada uma barreira obrigatoria para impedir que "Outro servico"
vire porta aberta para servicos proibidos.

## Prestador

- O Prestador pode adicionar um servico personalizado com nome, descricao curta
  e aliases/palavras de pesquisa.
- O app nao permite guardar apenas `other_service` como servico generico vazio.
- Servicos personalizados permitidos entram em:
  - `servicos`;
  - `servicosNomes`;
  - `customServices`;
  - `customServiceNames`;
  - `customServiceSearchTerms`;
  - `customServiceUpdatedAt`.
- O servico personalizado continua associado ao perfil do prestador e nao vira
  categoria oficial global.

## Cliente

- Quando a pesquisa nao encontra uma categoria clara, o Cliente descreve o
  servico que precisa antes de criar o pedido.
- A selecao custom grava `ServiceTaxonomySelection.customService`.
- Pedidos custom permitidos passam a gravar:
  - `isCustomService`;
  - `customServiceName`;
  - `customServiceDescription`;
  - `customServiceSearchTerms`;
  - `servicoId` com o id custom;
  - `servicoNome` com o nome custom;
  - `categoria` compativel.
- A UI do `NovoPedidoScreen` ficou organizada em:
  1. Servico;
  2. Quando e como?;
  3. Detalhes.

## Trust & Safety

Foi criado `CustomServiceSafetyValidator` para validar:

- nome do servico;
- descricao;
- aliases/palavras de pesquisa;
- query original.

Se qualquer campo gerar `TrustSafetyDecision.block`, o app bloqueia e nao
guarda nada. A mensagem ao utilizador e sempre segura:

```text
Este tipo de serviço não é permitido no ChegaJá.
```

O app nao mostra termo encontrado, `reasonCode`, lista interna ou instrucoes de
contorno. Em bloqueio, os campos com o texto proibido sao limpos da UI.

`needsReview` e `warn` continuam a ser avisos: nao bloqueiam automaticamente e
mantem a separacao da M2.20 entre servico sensivel e servico proibido.

## Hotfix critico - bloqueio robusto de termos obscenos/proibidos

Problema observado no browser: termos obscenos/proibidos persistidos, como
`prostituta`, `puta` e `vadia`, ainda podiam aparecer como chip na Home do
Prestador em "Categorias de atuacao".

Causa provavel: a defesa anterior bloqueava alguns fluxos novos, mas ainda
havia dados antigos em `servicosNomes`/`customServices` e superficies de
renderizacao/search que confiavam nesses campos sem sanitizacao central.

Correcao aplicada:

- `ProhibitedTerms` foi ampliado em grupos estruturados:
  `sexualServicesTerms`, `prostitutionTerms`, `obsceneServiceTerms`,
  `illegalDrugTerms`, `weaponsTerms`, `fraudTerms`,
  `documentForgeryTerms`, `violenceCriminalTerms`, `childSafetyTerms` e
  `platformAbuseTerms`.
- Foi criado `ServiceSafetyGuard` para classificar, filtrar e sanitizar nomes,
  termos de pesquisa e `ProviderCustomService`.
- O matching deixou de ser substring simples: usa normalizacao, tokens exatos,
  frases por sequencia de tokens, stem seguro `prostitu...`, leet simples e
  obfuscacoes como `p.u.t.a`, `p-u-t-a`, `p u t a` e `p*uta`.
- Falsos positivos como `computador`, `reputacao online` e
  `disputa contratual` continuam permitidos.
- `PrestadorSettingsScreen` sanitiza dados ao carregar e antes de guardar.
- Home Prestador, Perfil Publico e Discovery filtram defensivamente antes de
  renderizar ou pesquisar dados persistidos.
- `ProviderSearchMatcher` retorna zero para query proibida.
- Pedido personalizado do Cliente continua protegido pelo
  `TrustSafetyClassifier`/`CustomServiceSafetyValidator`.

Risco remanescente: este hotfix e client-side com filtragem defensiva. Antes de
abrir producao publica ampla, continua recomendado adicionar validacao
server-side/callable para impedir escrita maliciosa direta fora do app.

## Hotfix M2.20.9.2 - Bloqueio global de servicos ilicitos

Depois do bloqueio de prostituicao/obscenidade, foi identificado que a politica
precisava ser mais ampla: "Outro servico" tambem nao pode aceitar servicos
ilicitos/criminosos de outros grupos.

Politica final:

```text
Servico novo legitimo -> aceita.
Servico sensivel -> analise/aprovacao conforme M2.20.
Servico ilicito -> bloqueia imediatamente.
```

`ProhibitedTerms` foi ampliado para cobrir violencia criminal, exploracao de
menores, trafico humano, drogas ilegais, armas/explosivos, fraude/cybercrime,
falsificacao de documentos, terrorismo, procedimentos medicos ilegais e outros
servicos ilicitos.

Exemplos bloqueados:

```text
assassino
assassino de aluguel
pedofilia
venda de criancas
trafico humano
vender droga
arma ilegal
documento falso
cartao clonado
hackear conta
terrorismo
lavagem de dinheiro
contrabando
```

Falsos positivos protegidos:

```text
computador
reputacao online
disputa contratual
consultoria de imagem
trafego pago
matematica
matar baratas
farmacia
fisioterapia
bolo de aniversario
fotografia de eventos
```

O matching continua sem substring simples: usa tokens, frases, stems seguros,
leet simples e obfuscacoes comuns. Home Prestador, Perfil Publico, Discovery,
ProviderSearchProfile, ProviderSearchMatcher e pedidos custom continuam a
filtrar dados antigos antes de renderizar, pesquisar ou fazer matching.

Documento detalhado:

```text
docs/M2_20_9_2_BLOQUEIO_GLOBAL_SERVICOS_ILICITOS_STATUS.md
```

## Discovery e matching

- `ProviderSearchProfile` inclui `customServiceNames`,
  `customServiceSearchTerms`, `customServices.title`,
  `customServices.description`, `customServices.aliases` e
  `customServices.normalizedSearchTerms`.
- A pesquisa manual encontra prestadores por nome custom, descricao e alias.
- `PedidoService` deixou de tratar `other_service` generico como match amplo.
- Pedido custom pode bater por id/nome custom ou termos normalizados
  compativeis, sem criar motor externo de search.

## Rules e Functions

Firestore Rules nao foram alteradas nesta fase.

Motivo: as Rules atuais nao usam whitelist fechada para `prestadores` e
`pedidos` nestes campos; os novos campos sao dados publicos/pesquisaveis e nao
incluem documentos, contacto, KYC, pagamento ou segredos.

Cloud Functions nao foram alteradas.

## Ficheiros principais

- `lib/core/models/provider_custom_service.dart`
- `lib/core/trust_safety/prohibited_terms.dart`
- `lib/core/trust_safety/service_safety_guard.dart`
- `lib/core/trust_safety/custom_service_safety_validator.dart`
- `lib/features/prestador/widgets/prestador_service_taxonomy_selector.dart`
- `lib/features/prestador/prestador_settings_screen.dart`
- `lib/features/cliente/widgets/service_taxonomy_picker_section.dart`
- `lib/features/cliente/novo_pedido_screen.dart`
- `lib/features/cliente/discovery/provider_search_profile.dart`
- `lib/core/services/pedido_service.dart`
- `lib/core/repositories/pedido_repo.dart`
- `lib/core/models/pedido.dart`
- `scripts/e2e/full_ui_dual_role_e2e.js`
- `docs/M2_20_9_2_BLOQUEIO_GLOBAL_SERVICOS_ILICITOS_STATUS.md`

## Validacoes executadas

- `git status --short --branch` - executado no inicio.
- `git diff --check` - passou; apenas avisos CRLF.
- `npm.cmd run test:scripts` - passou.
- `flutter test --no-pub test/core/service_safety_guard_test.dart test/core/trust_safety_classifier_test.dart test/core/provider_custom_service_test.dart test/features/prestador/widgets/prestador_home_components_test.dart test/features/common/perfil_publico_screen_test.dart` - passou.
- `flutter test --no-pub test/features/cliente/discovery/provider_search_profile_test.dart test/features/cliente/discovery/provider_search_matcher_test.dart test/features/prestador/prestador_settings_taxonomy_test.dart test/features/cliente/novo_pedido_taxonomy_test.dart` - passou.
- `flutter test --no-pub` - passou, 475/475.
- `flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release` - passou. O build avisou apenas sobre incompatibilidades wasm em `dart_webrtc`.
- `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual` - passou, `FULL MULTI-SCENARIO FLOW OK`. O selector do E2E foi ajustado para reconhecer a tela real de pedido pendente com `Cancelar pedido`.
- `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento` - passou, `ORCAMENTO MIN-MAX FLOW OK`.
- `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m22091-safety-hotfix-visual-qa --wait-ms=12000` - passou, 8 screenshots.
- Browser do Codex abriu `http://127.0.0.1:5174/?role=prestador`, contaminou dados no emulador com `puta`, `prostituta` e `vadia`, e confirmou que a Home Prestador nao mostra esses termos, mostra estado seguro e tem `consoleErrors = 0`.

## Fora do escopo

- IA externa;
- motor externo de search;
- migracao Firestore;
- transformacao automatica em categoria oficial;
- KYC;
- pagamentos;
- upload;
- ranking avancado;
- deploy;
- Android fisico;
- R/R1/M/M2.6;
- M2.21.

## Proximo passo

M2.20.9.2 entrou depois como hotfix critico de bloqueio global de servicos
ilicitos. A M2.20.10 permanece fechada como QA final do catalogo profissional no
escopo atual.
