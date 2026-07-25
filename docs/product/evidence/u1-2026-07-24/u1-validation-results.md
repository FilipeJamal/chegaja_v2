# U1 — resultados de validação

Data de início: 2026-07-24
Data de fecho: 2026-07-25
Branch: `agent/u1-design-system-2`
Base: `9fcae74`
Commit da aplicação e dos builds: `770ef41927a00375388a9a4cc8a4f06085fb0fe7`
Commit de hardening das Rules e da CI: `58890890d6f2fed7f10dc7786e7596120d6b4ef7`

## Estado

**APROVADO para integração técnica.**

Isto não autoriza lançamento público nem piloto externo. Os gates externos
continuam descritos no fim deste documento.

## Design e regressões visuais

- referência e implementação: `390 × 844`, escala `1x`, estado carregado;
- comparação: `u1-home-side-by-side.png`;
- componentes finais: `u1-client-home-widget-final.png`;
- decisão: `design-qa.md`;
- resultado: aprovado, sem P0/P1/P2 visual aberto no escopo comparado.

## Validações obrigatórias

| Área | Comando | Resultado |
| --- | --- | --- |
| Scripts | `npm.cmd run test:scripts` | **PASS** — 14 validadores, 43,695 s |
| Análise Flutter | `flutter analyze --no-pub --no-fatal-warnings --no-fatal-infos` | **PASS** — exit 0, 310 avisos/info não fatais já existentes, 276,964 s |
| Discovery/trigger Functions | `npx.cmd firebase emulators:exec --only firestore,functions "cd functions && node scripts/ci_smoke_emulators.js"` | **PASS** — trigger real criou projeção sanitizada, callable respondeu com erro controlado, exit 0, 74 s |
| Rules e cores Functions | `npx.cmd firebase emulators:exec --only firestore,storage "cd functions && npm.cmd test"` | **PASS** — 179/179, exit 0, 182,2 s |
| Testes Flutter | `flutter test --no-pub` | **PASS** — 666/666, exit 0, 503,522 s |
| Sintaxe Functions | `node --check functions/index.js` e reconciler | **PASS** |
| Whitespace | `git diff --check` | **PASS** — apenas avisos locais LF/CRLF |

O primeiro comando combinado com Firestore, Storage e Functions passou
localmente, mas revelou no runner Linux uma corrida entre os triggers do
processo do emulador e as fixtures que exercitam os cores diretamente. A CI
passou a validar separadamente um trigger e uma callable reais em
`pt-coimbra/EUR`, mantendo os 179 testes determinísticos de Rules, Storage e
cores Functions. Nenhuma asserção ou regra de autorização foi relaxada.

## Builds de validação

| Plataforma | Comando | Resultado |
| --- | --- | --- |
| Android | `flutter build apk --profile --no-pub --dart-define=U1_PREVIEW=true --dart-define=FAST_DEV_MODE=false` | **PASS** — 478,498 s |
| Web | `flutter build web --profile --no-pub --dart-define=U1_PREVIEW=true --dart-define=FAST_DEV_MODE=false` | **PASS** — 414,425 s |
| Windows | `flutter build windows --profile --no-pub --dart-define=U1_PREVIEW=true --dart-define=FAST_DEV_MODE=false` | **PASS** — 104,545 s no build incremental final |

O primeiro build Windows detetou que o CMake ligava bibliotecas Firebase C++
Debug ao runner Profile com CRT Release. A correção versionada define
`CMAKE_MAP_IMPORTED_CONFIG_PROFILE=Release`; o build final passou. Web e
Windows verificam consistência técnica e não ativam essas plataformas no
piloto. O Android é uma compilação privada de validação, não uma publicação.

Os caminhos, tamanhos e SHA-256 dos artefactos estão em
`u1-build-manifest.json`.

## Integridade

- scan do diff adicionado: zero NUIT/NIF pessoal e zero padrão de segredo real;
- `.env`, `functions/.env` e `functions/.env.local` permaneceram ignorados e
  fora dos commits;
- artefactos pessoais, temporários e do pacote de investidores ficaram fora do
  staging;
- `U1_PREVIEW=true` só força a experiência em `debug`/`profile` e é ignorado
  em `release`;
- o identificador Android permanece `com.chegaja.app` até o cliente
  `com.pontosegaja.app` ser registado no Firebase/App Check e migrado de forma
  controlada;
- nenhum deploy de produção faz parte do U1.

## Gates externos que permanecem

- Android físico API 33+ e permissões reais;
- App Check produtivo e cutover;
- identidade/contacto jurídico revistos;
- documentos legais do mercado aprovados;
- recrutamento e execução de uma coorte real.

## GitHub

Este relatório é versionado na própria branch. Pull request, checks e merge
são estados externos e ficam registados no histórico do PR no GitHub, que é a
fonte de verdade para esses estados.
