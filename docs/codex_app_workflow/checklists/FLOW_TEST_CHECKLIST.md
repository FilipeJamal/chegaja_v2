# Checklist de fluxo Cliente/Prestador — ChegaJá

## Pedido imediato

- [ ] Cliente cria pedido.
- [ ] Prestador vê pedido.
- [ ] Prestador aceita.
- [ ] Cliente vê “Prestador encontrado”.
- [ ] Pedido muda para `aceito`.
- [ ] Prestador inicia.
- [ ] Pedido muda para `em_andamento`.
- [ ] Prestador conclui.
- [ ] Cliente confirma quando aplicável.
- [ ] Ganhos atualizam.
- [ ] Pedido concluído já não pode ser editado.

## Pedido agendado

- [ ] Cliente escolhe data/hora.
- [ ] Pedido aparece com informação de agendamento.
- [ ] Prestador vê corretamente.
- [ ] Estados funcionam como no imediato.
- [ ] Cancelamento antes de aceitar funciona.

## Pedido por orçamento/proposta

- [ ] Cliente cria pedido sem preço fechado.
- [ ] Prestador aceita interesse.
- [ ] Prestador envia proposta com valor.
- [ ] Cliente vê proposta.
- [ ] Cliente aceita.
- [ ] Pedido segue para estado correto.
- [ ] Cliente recusa.
- [ ] Pedido volta/fecha conforme regra definida.
- [ ] Prestador não consegue concluir sem aceitação quando necessário.

## Notificações

- [ ] Prestador recebe notificação de novo pedido.
- [ ] Cliente recebe notificação de pedido aceito/proposta.
- [ ] Clique na notificação abre pedido correto.
- [ ] Deep link `/pedido/{id}` funciona em refresh.
