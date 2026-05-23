# ChegaJa Beta - Roteiro Simplificado

## T01 - Abrir App

```text
Papel: Cliente
Plataforma: Web/Windows
Passos:
1. Abrir a app.
2. Confirmar que a Home aparece sem erro bloqueador.
3. Navegar entre Inicio, Pedidos, Mensagens e Conta.
Resultado esperado:
Home abre e permite escolher servico ou navegar.
```

## T02 - Criar Pedido como Cliente

```text
Papel: Cliente
Passos:
1. Escolher um servico.
2. Preencher o pedido.
3. Criar o pedido.
4. Abrir a lista de pedidos.
5. Abrir o detalhe do pedido.
Resultado esperado:
Pedido aparece na lista e no detalhe com estado compreensivel.
```

## T03 - Trocar para Prestador

```text
Papel: Cliente -> Prestador
Passos:
1. Abrir Conta/Perfil.
2. Tocar em mudar para modo prestador.
3. Confirmar que a Home Prestador aparece.
Resultado esperado:
App mostra Home Prestador sem obrigar a editar URL.
```

## T04 - Aceitar e Iniciar Pedido

```text
Papel: Prestador
Passos:
1. Ver pedido disponivel.
2. Aceitar pedido.
3. Abrir detalhe.
4. Iniciar servico quando disponivel.
Resultado esperado:
Pedido muda de estado e mostra proxima acao correta.
```

## T05 - Orcamento e Valor Final

```text
Papel: Cliente/Prestador
Passos:
1. Prestador envia estimativa/orcamento quando aplicavel.
2. Cliente aceita ou rejeita proposta.
3. Prestador envia valor final.
4. Cliente confirma ou questiona valor final.
Resultado esperado:
Fluxo chega ao estado final correto sem erro bloqueador.
```

## T06 - Mensagens

```text
Papel: Cliente/Prestador
Passos:
1. Abrir Mensagens.
2. Enviar mensagem como Cliente.
3. Trocar para Prestador.
4. Responder mensagem.
Resultado esperado:
Mensagens aparecem nos dois lados.
```

## T07 - Conta e Perfil

```text
Papel: Cliente/Prestador
Passos:
1. Abrir Conta/Perfil.
2. Confirmar nome, papel e opcoes principais.
3. Testar navegacao sem guardar dados sensiveis reais.
Resultado esperado:
Conta abre sem bloquear a navegacao.
```

## T08 - Cancelamento ou No-show

```text
Papel: Cliente/Prestador
Passos:
1. Criar ou abrir pedido de teste.
2. Testar cancelamento quando a app mostrar essa opcao.
3. Testar no-show quando a app mostrar essa opcao.
Resultado esperado:
O pedido mostra estado final ou aviso claro, sem crash e sem bloquear navegacao.
```

## Como Finalizar o Roteiro

```text
1. Preencher feedback geral.
2. Preencher um bug report para cada problema reproduzivel.
3. Anexar screenshot ou video quando o bug for visual ou dificil de explicar.
```
