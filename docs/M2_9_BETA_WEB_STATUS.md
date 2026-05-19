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
M2.9.2: planeado em lista de pedidos UX
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

Objetivo:

```text
melhorar a forma como Cliente e Prestador encontram, entendem e abrem pedidos
```

Escopo previsto:

```text
cards de pedidos com estado claro
proxima acao resumida no card
separacao visual entre ativos, concluidos e cancelados
empty states mais humanos
loading e erro mais claros
reuso do PedidoStatusPresenter quando fizer sentido
```

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
