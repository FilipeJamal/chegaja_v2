# M2.14.6 - Integracao do Perfil Publico no Fluxo Cliente

Data: 2026-05-28

## Estado

```text
M2.14.6: concluida
Bloco F: ativo
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: continua pendente
M2.6: continua pendente
```

## Objetivo

Integrar o `PublicProfileScreen` nos pontos principais do fluxo Cliente para
que o Cliente consiga abrir o perfil publico do prestador quando o pedido ja
tem `prestadorId`, sem criar tela duplicada e sem alterar dados, Rules,
Functions ou deploy.

## Integracao Implementada

| Ponto | Estado | Decisao |
| --- | --- | --- |
| Detalhe do pedido Cliente | FEITO | `ContatoSection` passa a mostrar `Ver perfil` quando existe `prestadorId`. |
| PedidoDetalheAutoScreen | FEITO INDIRETO | Continua a delegar para `PedidoDetalheScreen`; a integracao entra pela secao de contacto. |
| Aguardando prestador | NAO APLICAVEL | Quando ha prestador encontrado, o fluxo navega para o detalhe do pedido; sem prestador nao deve mostrar perfil. |
| Cards/listas de pedidos | PARCIAL | Mantidos sem novo botao para evitar poluicao visual; o card abre o detalhe e o detalhe mostra `Ver perfil`. |
| Chat | PRESERVADO | `ChatThreadScreen` continua a abrir perfil do outro participante. |
| Selecao de prestador | PRESERVADO | Card de prestador continua com `Ver perfil`. |
| Favoritos | PRESERVADO | Favoritos continuam a abrir `PublicProfileScreen`. |
| Stories | PRESERVADO | Stories continuam a abrir perfil publico do prestador. |

## Implementacao

Foi criado o helper:

```text
lib/features/common/utils/open_public_profile.dart
```

O helper centraliza a abertura do `PublicProfileScreen` e normaliza valores
vazios antes de passar `initialName` e `initialPhotoUrl`.

Foi atualizado:

```text
lib/features/cliente/widgets/pedido_contato_section.dart
```

Alteracoes principais:

```text
- ContatoSection aceita injecao opcional de FirebaseFirestore para testes.
- Cliente ve o botao "Ver perfil" quando o pedido tem prestadorId.
- O botao nao aparece quando nao ha prestador associado.
- Nome e foto do prestador sao passados como initialName/initialPhotoUrl quando ja existem no documento.
- O fluxo de telefone/contacto foi preservado.
```

## Testes

Foi criado:

```text
test/features/cliente/widgets/pedido_provider_profile_action_test.dart
```

Casos cobertos:

```text
- PedidoProviderProfileAction mostra "Ver perfil" quando existe prestador.
- PedidoProviderProfileAction nao aparece sem prestador.
- ContatoSection mostra "Ver perfil" no detalhe Cliente com prestador associado.
- ContatoSection nao mostra "Ver perfil" quando o pedido nao tem prestador.
```

## Fora do Escopo Mantido

```text
PublicProfileScreen nao foi redesenhado.
Badges nao foram alterados.
Portfolio publico nao foi alterado.
Gestao de portfolio do prestador nao foi alterada.
Firestore Rules nao foram alteradas.
Storage Rules nao foram alteradas.
Cloud Functions nao foram alteradas.
Deploy nao foi feito.
KYC, reviews, pagamentos e moderacao continuam fora.
R e R1 continuam pendentes.
M e M2.6 continuam pendentes.
```

## Proximo Passo

```text
M2.14.7 - Testes, QA visual e documentacao final da M2.14
```
