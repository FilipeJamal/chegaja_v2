# M2.20.9.2 - Bloqueio global de servicos ilicitos

Data: 2026-06-05

Estado: FECHADA no escopo atual.

## Problema

O hotfix anterior de M2.20.9.1 bloqueava prostituicao, servicos sexuais,
obscenidade e alguns servicos proibidos, mas o risco de produto era mais amplo:
o ChegaJa nao pode aceitar nenhum servico ilicito, criminoso, exploratorio,
violento, fraudulento ou perigoso como servico personalizado, pedido, termo de
pesquisa, chip de perfil, resultado de discovery ou criterio de matching.

Exemplos que motivaram o hotfix:

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

## Politica aplicada

```text
Servico novo legitimo -> aceita.
Servico sensivel -> analise/aprovacao conforme M2.20.
Servico ilicito -> bloqueia imediatamente.
Servico ilicito persistido -> filtra antes de aparecer, pesquisar ou fazer matching.
```

Mensagem segura:

```text
Este tipo de servico nao e permitido no ChegaJa.
```

O app continua sem mostrar termo detectado, reasonCode, lista interna ou
instrucao de contorno.

## Grupos proibidos ampliados

`ProhibitedTerms` passou a cobrir de forma mais explicita:

- servicos sexuais, prostituicao, pornografia e obscenidades usadas como
  servico;
- violencia criminal e servico sob encomenda;
- exploracao de menores e abuso infantil;
- trafico humano;
- drogas e narcoticos ilegais;
- armas, municoes e explosivos;
- fraude, golpe, burla e cybercrime;
- falsificacao de documentos;
- terrorismo e extremismo violento;
- procedimentos medicos ilegais ou clandestinos;
- outros servicos ilicitos, como lavagem de dinheiro, contrabando, extorsao,
  sequestro, suborno e corrupcao.

## Matching seguro

O matcher continua sem substring burra. A deteccao usa:

- normalizacao textual;
- tokens exatos;
- frases multi-token;
- stems seguros para raizes inequivocas, como `prostitu`, `pedofil`,
  `assass`, `sicari`, `terror`, `falsific`, `trafic` e `explosiv`;
- leet simples;
- obfuscacoes como `p.u.t.a`, `s i c a r i o`, `d.r.o.g.a`,
  `d0cumento falso` e `a.r.m.a ilegal`;
- regra anti-falso-positivo para nao bloquear substring solta.

Falsos positivos protegidos:

```text
computador
reparacao de computadores
reputacao online
disputa contratual
consultoria de imagem
trafego pago
matematica
matar baratas
exterminador de pragas
farmacia
fisioterapia
enfermagem ao domicilio
apoio psicologico
bolo de aniversario
fotografia de eventos
```

## Superficies protegidas

Foram reforcados testes e cobertura nas superficies que ja usam a camada
central:

- `ProviderCustomService`;
- `CustomServiceSafetyValidator`;
- `PrestadorServiceTaxonomySelector`;
- Home Prestador;
- `PublicProfileScreen`;
- `ServiceTaxonomyPickerSection`;
- `ProviderSearchProfile`;
- `ProviderSearchMatcher`;
- `ProviderSearchScreen`;
- `PedidoService`.

Dados antigos contaminados em `servicosNomes`, `customServices`,
`customServiceNames` e `customServiceSearchTerms` sao filtrados antes de
renderizar ou entrar em search/matching.

## Rules, Functions e deploy

Firestore Rules, Storage Rules e Cloud Functions nao foram alteradas neste
hotfix.

Motivo: Firestore Rules nao sao o lugar adequado para dicionario lexical grande.
A protecao desta fase e client-side + sanitizacao defensiva nas leituras e
fluxos normais do app.

Risco remanescente documentado: antes de producao publica ampla, criar
validacao server-side/callable ou trigger idempotente para impedir escrita
maliciosa direta fora da UI.

## Validacoes

| Comando | Resultado |
| --- | --- |
| `git status --short --branch` | Executado antes do fecho. Mostrou alteracoes deste hotfix e alteracoes antigas fora de escopo: temporarios `~$...pptx` apagados e `.superpowers/` nao versionado. |
| `git diff --check` | Passou sem erros. |
| `npm.cmd run test:scripts` | Passou. |
| `flutter test --no-pub test/core/service_safety_guard_test.dart test/core/trust_safety_classifier_test.dart test/core/provider_custom_service_test.dart test/core/custom_service_safety_validator_test.dart` | Passou, 30/30 testes. |
| `flutter test --no-pub test/features/prestador/widgets/prestador_home_components_test.dart test/features/prestador/prestador_settings_taxonomy_test.dart test/features/common/perfil_publico_screen_test.dart test/features/cliente/novo_pedido_taxonomy_test.dart test/features/cliente/discovery/provider_search_profile_test.dart test/features/cliente/discovery/provider_search_matcher_test.dart test/features/cliente/discovery/provider_search_screen_test.dart test/core/pedido_service_test.dart` | Passou, 98/98 testes. |
| `flutter test --no-pub` | Passou, 481/481 testes. |
| `flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release` | Passou. Apenas avisos wasm conhecidos de `dart_webrtc`. |
| `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual` | Passou com `FULL MULTI-SCENARIO FLOW OK`. |
| `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento` | Passou com `ORCAMENTO MIN-MAX FLOW OK`. |
| `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m22092-illicit-services-visual-qa --wait-ms=12000` | Passou, 8 screenshots gerados. |
| Browser QA com dados contaminados no emulador | 13 documentos `prestadores` contaminados localmente com `assassino`, `prostituta`, `puta`, `vadia`, `pedofilia`, `vender droga`, `documento falso`, `s i c a r i o` e `d0cumento falso`; Home Prestador abriu em `http://127.0.0.1:5174/?role=prestador`; `forbiddenVisible = []`; `consoleErrors = 0`; estado seguro exibido. |

Ficheiros pedidos no prompt mas inexistentes no repo atual:

```text
test/features/prestador/prestador_settings_custom_service_test.dart
test/features/cliente/novo_pedido_custom_service_test.dart
test/features/prestador/home_prestador_screen_test.dart
```

A cobertura equivalente esta consolidada nos testes de taxonomy, Home
Prestador, Perfil Publico, Discovery e `PedidoService` listados acima.

## Fora do escopo

- IA externa;
- motor externo de search;
- migracao Firestore;
- validacao server-side/callable definitiva;
- KYC;
- pagamentos;
- upload;
- ranking avancado;
- deploy;
- Android fisico;
- R/R1/M/M2.6;
- M2.21.
