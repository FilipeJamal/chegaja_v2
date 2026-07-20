# Politica de pagamentos do piloto (P1.7)

## Decisao atual

- Moeda autoritativa: `MZN` (apresentada como `MT`).
- Meio ativo por defeito: dinheiro.
- M-Pesa, e-Mola e Stripe ficam desativados por feature flag ate a integracao respetiva ser validada.
- A percentagem de comissao e uma hipotese de piloto, nao uma decisao comercial definitiva.

O cliente Flutter e as Cloud Functions usam os mesmos identificadores estaveis:
`dinheiro`, `mpesa`, `emola` e `stripe`. Pedidos com um prestador desativado sao
rejeitados pelo backend, mesmo que um cliente alterado tente envia-los.

## Abstracao

`PaymentProvider` separa a experiencia do pedido da empresa de pagamentos:

- `CashPaymentProvider`: ativo, sem confirmacao externa;
- `MPesaPaymentProvider`: reservado, inativo ate validacao;
- `EmolaPaymentProvider`: reservado, inativo ate validacao;
- `StripePaymentProvider`: inativo no piloto e condicionado a suporte de plataforma.

Ativar uma flag sem implementar o adaptador nao inicia uma cobranca: o adaptador
falha de forma explicita. No backend, Stripe exige simultaneamente
`ENABLE_STRIPE=true` e `STRIPE_MZN_VALIDATED=true`.

## Comissao em dinheiro

Configuracao inicial, alteravel sem mudar o modelo de dados:

- primeiros 2 trabalhos confirmados: 0%;
- trabalhos seguintes em dinheiro: 10%;
- prazo: 7 dias;
- limite de saldo: 100 MT;
- teto por trabalho: opcional.

Ao confirmar o valor final, uma transacao Firestore atomica:

1. conclui o pedido com os valores calculados pelo servidor;
2. cria `payments/cash_{pedidoId}`;
3. cria uma linha privada em
   `provider_private/{uid}/financialTransactions/{transactionId}`;
4. atualiza `commissionBalanceDue`, `financialBalance`, `commissionDueAt` e
   `financialStatus` em `provider_private/{uid}`.

O saldo financeiro nunca escreve em classificacoes, avaliacoes ou campos de
ranking publicos.

## Incumprimento e regularizacao

O agendador `scheduled_enforceCommissionDebt` aplica a unica restricao:

- `provider_private.financialStatus = suspended_new_jobs`;
- `provider_dispatch_private.acceptingNewJobs = false`.

O prestador continua a poder concluir trabalhos existentes, conversar, consultar
o historico, pagar, contestar e contactar suporte. A aceitacao de novos pedidos
passa obrigatoriamente por `pedidos_acceptDispatch`, que verifica esta restricao.
As Rules rejeitam aceitacoes e confirmacoes financeiras diretas.

O backoffice regista uma liquidacao confirmada através de
`admin_recordCommissionPayment`. Quando o saldo chega a zero, a transacao repoe
`financialStatus = active` e `acceptingNewJobs = true`. Cada liquidacao fica em
`commission_payments` e no livro privado do prestador.

## Validacao obrigatoria antes de M-Pesa/e-Mola

- entidade contratante e condicoes comerciais;
- acesso a API e ambiente de testes;
- custos, limites e prazos de liquidacao;
- autenticacao, idempotencia e rotacao de segredos;
- webhooks assinados;
- reversoes e estornos;
- reconciliacao diaria e referencias de pagamento;
- requisitos regulatorios e de retencao;
- suporte operacional e processo de disputa.

Nenhuma flag deve ser ativada em producao antes de estes pontos terem evidencia
documentada e testes de ponta a ponta.
