# M2.20.9.2 - Politica global de admissao de servicos

Data: 2026-06-05

Estado: FECHADA no escopo atual.

## Problema observado

Depois do bloqueio global de servicos ilicitos, foi identificado no browser que
termos como `burlas` e `burlador` ainda podiam passar como servico
personalizado. Isso mostrou que a protecao nao podia depender apenas de ir
acrescentando palavras isoladas.

O problema de fundo e admissibilidade de servico:

```text
Isto e um servico legitimo?
Isto e sensivel e precisa de aprovacao?
Isto e ilicito e deve bloquear?
Isto e vago/desconhecido e deve ir para revisao antes de ficar publico?
```

## Politica aplicada

Foi criada a camada `ServiceAdmissionGuard` com quatro decisoes:

```text
allow
sensitiveReview
block
unknownReview
```

Significado:

- `allow`: servico legitimo, claro e pesquisavel.
- `sensitiveReview`: servico legitimo, mas sensivel/regulado conforme M2.20.
- `block`: servico ilicito, criminoso, sexual proibido, exploratorio,
  fraudulento ou perigoso.
- `unknownReview`: servico vago/desconhecido que nao deve ser guardado como
  servico publico ativo, indexado ou usado em matching ate revisao.

## Exemplos bloqueados

```text
burlas
burlador
burlao
fraudador
golpista
scammer
cartao clonado
hackear conta
assassino
documento falso
pedofilia
vender droga
arma ilegal
recrutamento terrorista
```

Obfuscacoes cobertas:

```text
b.u.r.l.a
b-u-r-l-a
b u r l a
bur1a
assass1no
ped0filia
d0cumento falso
s i c a r i o
```

## Falsos positivos protegidos

Continuam admissiveis:

```text
computador
reparacao de computadores
reputacao online
disputa contratual
consultoria de imagem
trafego pago
matematica
exterminador de pragas
matar baratas
bolo de aniversario
fotografia de eventos
seguranca informatica
```

Servicos legitimos de saude/cuidados continuam sem bloqueio. Quando a camada
sensivel existente os reconhece, entram como `sensitiveReview`; caso contrario,
podem continuar como `allow` ate haver politica sensivel mais especifica.

## UnknownReview

Textos vagos passam a ser tratados como `unknownReview`:

```text
servico especial
trabalho secreto
faco de tudo
qualquer coisa
servico privado
coisa discreta
contactos especiais
ajuda confidencial
```

Regra:

```text
unknownReview nao guarda como servico publico ativo,
nao aparece no perfil,
nao entra em searchTerms,
nao faz matching.
```

Mensagem segura:

```text
Este servico precisa de analise antes de ficar disponivel.
```

## Superficies protegidas

- PrestadorServiceTaxonomySelector;
- ServiceTaxonomyPickerSection;
- NovoPedidoScreen antes de criar pedido custom;
- ServiceSafetyGuard na sanitizacao defensiva;
- Home Prestador;
- Perfil Publico;
- ProviderSearchProfile;
- ProviderSearchMatcher;
- dados antigos persistidos em `servicosNomes`, `customServices`,
  `customServiceNames` e `customServiceSearchTerms`.

## Rules, Functions e deploy

Nao foram alteradas Firestore Rules, Storage Rules ou Cloud Functions.
Nao houve deploy.

Risco remanescente: antes de producao publica ampla, continua recomendado criar
validacao server-side/callable ou trigger idempotente para impedir escrita
maliciosa direta fora da UI.

## Validacoes

| Comando/QA | Resultado |
| --- | --- |
| `git status --short --branch` | Confirmou apenas alteracoes do hotfix e dirty state antigo fora de escopo: dois temporarios `~$...pptx` apagados e `.superpowers/` nao versionado. |
| `git diff --check` | Passou. Apenas avisos normais de conversao LF/CRLF. |
| `npm.cmd run test:scripts` | Passou. |
| `flutter test --no-pub test/core/service_admission_guard_test.dart test/core/service_safety_guard_test.dart test/core/custom_service_safety_validator_test.dart test/features/prestador/prestador_settings_taxonomy_test.dart test/features/cliente/novo_pedido_taxonomy_test.dart test/features/cliente/discovery/provider_search_profile_test.dart test/features/cliente/discovery/provider_search_matcher_test.dart` | Passou, 59 testes focados. |
| `flutter test --no-pub test/core/service_admission_guard_test.dart test/core/service_safety_guard_test.dart test/core/custom_service_safety_validator_test.dart test/core/trust_safety_classifier_test.dart test/core/provider_custom_service_test.dart test/features/prestador/prestador_settings_taxonomy_test.dart test/features/prestador/widgets/prestador_home_components_test.dart test/features/common/perfil_publico_screen_test.dart test/features/cliente/novo_pedido_taxonomy_test.dart test/features/cliente/discovery/provider_search_profile_test.dart test/features/cliente/discovery/provider_search_matcher_test.dart test/features/cliente/discovery/provider_search_screen_test.dart test/core/pedido_service_test.dart` | Passou, 138 testes focados alargados. |
| `flutter test --no-pub` | Passou, 491/491 testes. |
| `flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release` | Passou. Apenas avisos wasm conhecidos em `dart_webrtc`. |
| `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:dual` | Passou com `FULL MULTI-SCENARIO FLOW OK`. |
| `TARGET_URL=http://127.0.0.1:5174 npm.cmd run e2e:ui:orcamento` | Passou com `ORCAMENTO MIN-MAX FLOW OK`. |
| `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:5174 --out-dir=%TEMP%\chegaja-m22092-service-admission-qa --wait-ms=12000` | Passou, 8 screenshots gerados. |
| Browser QA com dados contaminados no emulador | 19 documentos `prestadores` contaminados localmente com `burlador`, `burlas`, `servico especial`, `trabalho secreto`, `assassino`, `prostituta`, `puta`, `vadia`, `pedofilia`, `vender droga`, `documento falso` e obfuscacoes; Home Prestador em `http://127.0.0.1:5174/?role=prestador`; `forbiddenVisible = []`; `consoleErrors = 0`; estado seguro exibido. |

## Resultado final

A M2.20.9.2 passa a estar fechada como politica global de admissao:

```text
Servico legitimo: allow.
Servico sensivel/regulado: sensitiveReview.
Servico proibido/ilicito/fraudulento/sexual proibido: block.
Servico vago/desconhecido: unknownReview.
```

O proximo passo do trilho continua a ser manter M2.20.10 como QA final ja
fechado no escopo atual, sem iniciar M2.21 nesta correcao.
