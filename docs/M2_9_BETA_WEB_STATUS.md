# M2.9 Beta Web Status

Data: 2026-05-19

## Estado

```text
M0: fechado
M2.5: parcial
M2.6: avancado tecnicamente, pendente de Android fisico
M2.7: fechado
M2.8: fechado
M2.9: iniciado
M2.9.1: avancado em detalhe do pedido UX
M2.9.2: avancado em lista de pedidos UX
M2.9.3: avancado em beta web flow pack
M2.9.4: iniciado em beta web QA pack e fecho M2.9
```

## M2.9.1 - Detalhe do Pedido UX

Escopo implementado:

```text
banner principal de estado
proxima acao por Cliente/Prestador
timeline com mapping centralizado
textos mais claros de orcamento e valor final
fallbacks mais humanos no detalhe do pedido
helper puro testavel para status/proxima acao
```

Arquivos principais:

```text
lib/features/cliente/widgets/pedido_status_presenter.dart
lib/features/cliente/widgets/pedido_status_summary.dart
lib/features/cliente/widgets/pedido_next_action_card.dart
lib/features/cliente/widgets/pedido_timeline.dart
lib/features/cliente/widgets/cliente_pedido_acoes.dart
lib/features/prestador/widgets/prestador_pedido_acoes.dart
lib/features/cliente/pedido_detalhe_screen.dart
test/features/cliente/widgets/pedido_status_presenter_test.dart
```

Fora do escopo:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
pagamentos reais
Play Store
package id final
HTTPS App Links
Android fisico
fecho da M2.6
```

## Evidencia

Validacoes locais:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 54/54 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

## Observacoes

- A UI deriva textos a partir de `Pedido + role + estado`.
- Nao foram alteradas regras de seguranca, Functions ou schema.
- Mensagens de erro de valor final deixaram de expor excecoes brutas ao
  utilizador final; detalhes ficam em `debugPrint`.
- Texto de pedido concluido evita prometer avaliacao quando essa acao nao esta
  garantida no contexto.

## M2.9.2 - Lista de Pedidos UX

Spec criada:

```text
docs/superpowers/specs/2026-05-19-m2-9-2-lista-pedidos-ux-design.md
```

Plano criado:

```text
docs/superpowers/plans/2026-05-19-m2-9-2-lista-pedidos-ux.md
```

Objetivo:

```text
melhorar a forma como Cliente e Prestador encontram, entendem e abrem pedidos
```

Escopo implementado:

```text
cards de pedidos com estado claro
proxima acao resumida por Cliente/Prestador
distincao entre pedidos ativos, concluidos e cancelados
empty states estruturados
loading e erros mais humanos
preservacao das keys e acoes do Prestador
reuso do PedidoStatusPresenter via presenter de lista
texto claro para faixa estimada, valor proposto e valor final
```

Arquivos principais:

```text
lib/features/cliente/widgets/pedido_list_presenter.dart
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/cliente/widgets/pedido_empty_state.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
test/features/cliente/widgets/pedido_list_presenter_test.dart
test/features/cliente/widgets/pedido_list_card_test.dart
```

Evidencia M2.9.2:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 61/61 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

Fora do escopo continua:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
pagamentos reais
Play Store
package id final
HTTPS App Links
Android fisico
fecho da M2.6
```

## M2.9.3 - Beta Web Flow Pack

Spec criada:

```text
docs/superpowers/specs/2026-05-19-m2-9-3-beta-web-flow-pack-design.md
```

Plano criado:

```text
docs/superpowers/plans/2026-05-19-m2-9-3-beta-web-flow-pack.md
```

Objetivo:

```text
melhorar o fluxo completo Cliente <-> Prestador no Web, do pedido criado ate
conclusao ou cancelamento
```

Escopo implementado:

```text
feedback pos-criacao de pedido
aguardando prestador com loading/erro humano
UX Cliente para proposta e valor final
UX Prestador para convite, estimativa, inicio e valor final
painel de estados finais no detalhe
mensagens de erro sem excecao bruta nos fluxos alterados
keys de fluxo preservadas
consistencia entre lista e detalhe via presenters de pedido
```

Arquivos principais:

```text
lib/features/cliente/widgets/pedido_flow_presenter.dart
lib/features/cliente/widgets/pedido_final_state_panel.dart
lib/features/cliente/novo_pedido_screen.dart
lib/features/cliente/aguardando_prestador_screen.dart
lib/features/cliente/pedido_detalhe_screen.dart
lib/features/cliente/widgets/cliente_pedido_acoes.dart
lib/features/prestador/widgets/prestador_pedido_acoes.dart
test/features/cliente/widgets/pedido_flow_presenter_test.dart
test/features/cliente/widgets/pedido_final_state_panel_test.dart
```

Evidencia M2.9.3:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 69/69 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

Fora do escopo continua:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
pagamentos reais
Play Store
package id final
HTTPS App Links
Android fisico
fecho da M2.6
```

## M2.9.4 - Beta Web QA Pack e Fecho M2.9

Spec criada:

```text
docs/superpowers/specs/2026-05-19-m2-9-4-beta-web-qa-pack-design.md
```

Objetivo:

```text
validar a experiencia Web completa Cliente/Prestador depois das melhorias de
UX da M2.9.1, M2.9.2 e M2.9.3
```

Escopo previsto:

```text
revisar fluxo completo no Web
rodar E2E/local existente quando o ambiente estiver disponivel
corrigir pequenos bugs de UX encontrados durante QA
confirmar consistencia lista <-> detalhe <-> fluxo
documentar evidencias
fechar M2.9 se tudo estiver consistente
```

Validacoes previstas:

| Comando | Objetivo |
| --- | --- |
| `flutter test` | regressao Flutter/widgets |
| `npm.cmd run test:scripts` | scripts operacionais locais |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | regras/Functions no Emulator Suite |
| `npm.cmd run e2e:ui:dual` | fluxo Web dual-role existente |
| `npm.cmd run e2e:ui:orcamento` | fluxo Web de orcamento/valor existente |

Fora do escopo continua:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
pagamentos reais
Play Store
package id final
HTTPS App Links
Android fisico
fecho da M2.6
```
