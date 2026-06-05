# M2.20.10 - QA final do catalogo profissional

Data: 2026-06-05

Estado: FECHADA no escopo atual.

Commit de referencia da fase anterior:

```text
b1c72ba6e57c8835beb83973aa0933c006c5d94e
Corrigir bloqueio robusto de servicos proibidos
```

## Objetivo

A M2.20.10 fechou o trilho do catalogo profissional depois da M2.20.7,
M2.20.8, M2.20.9 e M2.20.9.1. Esta fase foi QA/documentacao: nao criou feature
nova, nao alterou Dart, nao alterou Rules, nao alterou Functions, nao fez
deploy e nao iniciou M2.21.

O foco foi confirmar que:

- a taxonomia profissional continua funcional;
- Cliente e Prestador usam Servico -> Intencao -> Detalhes sem regressao;
- "Outro servico" exige descricao real quando usado como servico personalizado;
- servicos personalizados permitidos entram em search/matching;
- servicos proibidos sao bloqueados antes de guardar;
- dados proibidos antigos sao filtrados antes de renderizar, pesquisar ou fazer
  matching;
- categorias sensiveis da M2.20 continuam separadas de servicos proibidos;
- o catalogo legado continua compativel.

## Resultado funcional validado

- M2.20.7 ficou como spec/auditoria de catalogo profissional.
- M2.20.8 criou modelos, catalogo canonico, normalizador e matcher
  deterministico.
- M2.20.9 aplicou a UI profissional no Cliente e no Prestador.
- M2.20.9.1 tornou "Outro servico" profissional, pesquisavel e protegido por
  Trust & Safety.
- O hotfix critico bloqueou e filtrou termos obscenos/proibidos persistidos.
- A M2.20.9.2 ampliou o bloqueio para servicos ilicitos globais, incluindo
  violencia criminal, exploracao de menores, trafico humano, drogas, armas,
  fraude, falsificacao, terrorismo, procedimentos medicos ilegais e outros
  servicos criminosos.
- M2.20.10 confirmou o fecho do trilho por testes, build, E2E e QA visual.

## Hotfix critico revalidado

Foram revalidadas as regras principais:

```text
Servico novo permitido: guardar como servico personalizado.
Servico sensivel: avisar/analisar conforme M2.20.
Servico proibido: bloquear imediatamente e nao guardar nada.
Servico proibido persistido: filtrar antes de aparecer, pesquisar ou fazer matching.
```

Cobertura confirmada:

- `puta`, `prostituta`, `vadia` e obfuscacoes simples bloqueiam.
- `assassino`, `pedofilia`, `vender droga`, `documento falso`,
  `hackear conta`, `lavagem de dinheiro` e equivalentes ilicitos bloqueiam.
- `computador`, `reparacao de computadores`, `reputacao online` e
  `disputa contratual`, `trafego pago`, `fisioterapia` e `bolo de aniversario`
  continuam permitidos.
- `ServiceSafetyGuard` filtra `servicosNomes`, `customServiceNames`,
  `customServiceSearchTerms` e `customServices`.
- `ProviderSearchMatcher` retorna zero para query proibida.
- Home Prestador, Perfil Publico e Discovery nao renderizam dados contaminados.
- Pedido personalizado do Cliente continua protegido por
  `CustomServiceSafetyValidator`.
- A mensagem segura nao expoe termo interno:

```text
Este tipo de servico nao e permitido no ChegaJa.
```

## Ficheiros de teste equivalentes

O prompt de QA citava alguns ficheiros provaveis com nomes separados para
custom service. No estado real do repo, essa cobertura esta consolidada em
testes existentes:

```text
test/core/service_safety_guard_test.dart
test/core/custom_service_safety_validator_test.dart
test/core/provider_custom_service_test.dart
test/features/prestador/prestador_settings_taxonomy_test.dart
test/features/prestador/widgets/prestador_home_components_test.dart
test/features/cliente/novo_pedido_taxonomy_test.dart
test/features/common/perfil_publico_screen_test.dart
test/features/cliente/discovery/provider_search_profile_test.dart
test/features/cliente/discovery/provider_search_matcher_test.dart
test/features/cliente/discovery/provider_search_screen_test.dart
```

Ficheiros solicitados mas inexistentes no repo atual:

```text
test/features/prestador/custom_service_form_test.dart
test/features/prestador/prestador_settings_custom_service_test.dart
test/features/cliente/custom_service_request_form_test.dart
test/features/cliente/novo_pedido_custom_service_test.dart
test/features/prestador/home_prestador_screen_test.dart
```

A cobertura funcional equivalente foi validada pelos testes acima, sem criar
ficheiros artificiais apenas para satisfazer nomes.

## Validacoes executadas

| Comando | Resultado |
| --- | --- |
| `git status --short --branch` | Executado no inicio. Mostrou apenas alteracoes fora de escopo ja existentes: dois temporarios `~$...pptx` apagados e `.superpowers/` nao versionado. |
| `git diff --check` | Passou sem saida. |
| `npm.cmd run test:scripts` | Passou. |
| `flutter test --no-pub test/core/service_intent_test.dart test/core/service_taxonomy_test.dart test/core/service_taxonomy_normalizer_test.dart test/core/service_taxonomy_matcher_test.dart` | Passou, 16 testes. |
| `flutter test --no-pub test/core/service_safety_guard_test.dart test/core/trust_safety_classifier_test.dart test/core/provider_custom_service_test.dart test/core/custom_service_safety_validator_test.dart` | Passou, 30 testes apos hotfix M2.20.9.2. |
| `flutter test --no-pub test/features/cliente/novo_pedido_screen_test.dart test/features/cliente/novo_pedido_taxonomy_test.dart` | Passou, 8 testes. |
| `flutter test --no-pub test/features/prestador/prestador_settings_taxonomy_test.dart test/features/prestador/prestador_settings_sensitive_categories_test.dart test/features/prestador/widgets/prestador_home_components_test.dart` | Passou, 23 testes. |
| `flutter test --no-pub test/features/prestador/widgets/prestador_home_components_test.dart test/features/prestador/prestador_settings_taxonomy_test.dart test/features/common/perfil_publico_screen_test.dart test/features/cliente/novo_pedido_taxonomy_test.dart test/features/cliente/discovery/provider_search_profile_test.dart test/features/cliente/discovery/provider_search_matcher_test.dart test/features/cliente/discovery/provider_search_screen_test.dart test/core/pedido_service_test.dart` | Passou, 98 testes apos hotfix M2.20.9.2. |
| `flutter test --no-pub` | Passou, 481/481 testes. |
| `flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release` | Passou. Apenas avisos wasm conhecidos de `dart_webrtc`. |
| `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual` | Primeiras tentativas falharam por ambiente: app nao servida e depois emuladores desligados. A execucao valida com servidor estatico + Auth/Firestore/Storage Emulators passou com `FULL MULTI-SCENARIO FLOW OK`. |
| `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento` | Passou com `ORCAMENTO MIN-MAX FLOW OK`. |
| `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m22092-illicit-services-visual-qa --wait-ms=12000` | Passou, 8 screenshots gerados. |
| Browser QA com dados contaminados no emulador | 13 documentos `prestadores` contaminados localmente com `assassino`, `prostituta`, `puta`, `vadia`, `pedofilia`, `vender droga`, `documento falso`, `s i c a r i o` e `d0cumento falso`; Home Prestador abriu em `http://127.0.0.1:5174/?role=prestador`; `forbiddenVisible = []`; `consoleErrors = 0`; estado seguro exibido. |

## Rules, Storage Rules e Functions

Nao foram alteradas nesta fase.

Motivo: a M2.20.10 foi QA/documentacao. O hotfix anterior ja tinha confirmado
que a protecao atual e client-side + filtragem defensiva nas superficies do app.
Validacao server-side/callable para escrita direta maliciosa continua como risco
remanescente antes de producao publica ampla.

## Decisao final

A M2.20.10 fica fechada no escopo atual. O trilho de catalogo profissional
M2.20.7 -> M2.20.10 fica estabilizado para a fase atual.

Proximo passo recomendado:

```text
M2.21 - Conta, definicoes e suporte premium
```

M2.21 nao foi iniciada nesta tarefa.

Dependencias pausadas continuam:

```text
R - Beta externa/tester real: pausado por falta de tester humano.
M - Android release/dispositivo fisico: pausado por falta de Android fisico real.
R1 - pendente.
M2.6 - pendente.
```
