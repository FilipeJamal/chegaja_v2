# Pedido State Machine - M2.7.1 / M2.7.2

Data: 2026-05-17

## Objetivo

Este documento regista a state machine operacional de `pedidos` usada no app e
nas regras Firestore.

M2.7.1 nao fecha M2.6 nem M2.7. O foco foi reduzir risco de manipulacao direta
de estados, `prestadorId` e valores economicos enquanto a validacao Android
fisica continua bloqueada.

## Estados validos

```text
criado
aguarda_resposta_prestador
aguarda_resposta_cliente
aceito
em_andamento
aguarda_confirmacao_valor
concluido
cancelado
```

Quando `status` e `estado` existem no mesmo documento, as regras exigem que
ambos tenham o mesmo valor.

## Transicoes por cliente

| De | Para |
| --- | --- |
| `criado` | `aguarda_resposta_prestador`, `cancelado` |
| `aguarda_resposta_prestador` | `cancelado` |
| `aguarda_resposta_cliente` | `aceito`, `criado`, `cancelado` |
| `aceito` | `cancelado` |
| `em_andamento` | `cancelado` |
| `aguarda_confirmacao_valor` | `concluido`, `em_andamento`, `cancelado` |

## Transicoes por prestador

| De | Para |
| --- | --- |
| `criado` | `aceito`, `aguarda_resposta_cliente` |
| `aguarda_resposta_prestador` | `aceito`, `criado` |
| `aguarda_resposta_cliente` | `criado` |
| `aceito` | `em_andamento`, `aguarda_resposta_cliente`, `criado` |
| `em_andamento` | `aguarda_confirmacao_valor`, `cancelado` |
| `aguarda_confirmacao_valor` | `cancelado` |

`concluido` e `cancelado` sao finais nas regras: nao podem regressar para
estados operacionais.

## `prestadorId`

Regras aplicadas:

- pedido aberto pode continuar sem prestador;
- prestador compativel pode aceitar/propor apenas para o proprio UID;
- cliente pode convidar manualmente um prestador a partir de `criado`;
- pedido ja atribuido nao pode trocar `prestadorId` para outro UID;
- `prestadorId` so pode voltar a `null` nos fluxos previstos de rejeicao ou
  desistencia que regressam a `criado`.

## Campos economicos protegidos

Campos finais persistidos protegidos nas regras:

```text
precoFinal
preco
commissionPlatform
earningsProvider
earningsTotal
```

Os nomes de negocio equivalentes sao:

```text
valorFinal -> precoFinal/preco
comissaoPlataforma -> commissionPlatform
ganhosPrestador -> earningsProvider
```

Campos de proposta final protegidos:

```text
precoPropostoPrestador
statusConfirmacaoValor
```

## Regra de confirmacao final

A confirmacao final so e permitida quando:

- ator autenticado e o cliente do pedido;
- estado atual e `aguarda_confirmacao_valor`;
- proximo estado e `concluido`;
- `statusConfirmacaoValor` passa para `confirmado_cliente`;
- `precoFinal` bate com `precoPropostoPrestador` com tolerancia de 0.01;
- `preco` e `earningsTotal` batem com `precoFinal`;
- `commissionPlatform` bate com 15% do valor final;
- `earningsProvider` bate com 85% do valor final.

M2.7.2 iniciou a migracao desse calculo para Cloud Functions/Admin SDK. O
caminho de producao da app chama `confirmarValorFinalPedido`, que le
`precoPropostoPrestador`, calcula a divisao 15%/85% no backend e escreve os
campos finais como admin.

As regras Firestore ainda mantem a confirmacao direta validada para preservar
os testes e fluxos de emulador que nao sobem Functions. Mesmo nesse caminho, a
divisao tem de bater exatamente com a regra 15%/85%. O marcador
`lastAuthoritativeFunction` e protegido: cliente/prestador nao podem falsificar
que uma escrita veio do backend.

Documento complementar:

```text
docs/FUNCTIONS_PEDIDOS.md
```

## Testes de seguranca

Cobertura em `functions/test/firestore.test.js`:

- cliente consegue criar pedido valido;
- prestador compativel consegue aceitar pedido aberto para si;
- prestador nao consegue aceitar pedido aberto para outro UID;
- cliente consegue convidar prestador manualmente;
- prestador atribuido consegue iniciar servico;
- prestador atribuido consegue enviar faixa de orcamento;
- prestador atribuido consegue propor valor final;
- cliente nao consegue manipular ganhos do prestador;
- prestador nao consegue manipular preco final/comissao;
- pedido `concluido` nao volta para `em_andamento`;
- pedido `cancelado` nao volta para `aceito`;
- confirmacao final com comissao adulterada e negada;
- confirmacao final com divisao esperada e permitida;
- cliente nao consegue falsificar `lastAuthoritativeFunction`;
- Functions cobrem proposta final, confirmacao final, calculo 15%/85%, ator
  errado e estado invalido.
