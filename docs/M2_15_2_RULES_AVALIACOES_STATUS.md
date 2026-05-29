# M2.15.2 - Rules, Seguranca e Consistencia de Avaliacoes

Data: 2026-05-29

## Estado

```text
M2.15.2: concluida
M2.15: em andamento
Bloco H: ativo
Bloco F: parcial
Bloco R: pausado por falta de tester humano real
Bloco M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Decisao Tecnica

Foi escolhida a opcao B da spec:

```text
Cliente cria apenas a avaliacao.
Cloud Function onCreate atualiza ratingCount/ratingSum/ratingAvg.
Firestore Rules bloqueiam utilizadores comuns de escrever agregados diretamente.
```

Motivo: agregados de reputacao sao dados derivados. Validar esses calculos
apenas em Rules deixaria o fluxo fragil, porque a regra de
`prestadores/{prestadorId}` teria de confiar em writes vindos do cliente. A
Function passa a ser a fonte autoritativa para calcular a media.

## Alteracoes de Seguranca

### Avaliacoes

As Rules de `avaliacoes/{avaliacaoId}` agora exigem:

```text
avaliacaoId == {pedidoId}_{clienteId}
clienteId == request.auth.uid
pedido existente
pedido concluido
cliente autenticado e dono do pedido
prestadorId igual ao prestador do pedido
estrelas int entre 1 e 5
comentario opcional string ate 500 caracteres
createdAt como server timestamp/request.time
campos extras bloqueados
```

`update` e `delete` continuam reservados para admin/dev.

### Agregados do Prestador

Utilizadores comuns ja nao podem escrever diretamente:

```text
ratingCount
ratingSum
ratingAvg
```

O prestador continua impedido de editar os proprios agregados. Clientes e
outros utilizadores autenticados tambem ficam bloqueados. A atualizacao passa
pela Function `onAvaliacaoCreated`, que usa Admin SDK.

## Cloud Function

Foi adicionada `onAvaliacaoCreated` em `functions/index.js`.

A Function valida defensivamente:

```text
pedidoId, clienteId, prestadorId e estrelas
docId esperado
pedido existente
pedido concluido
clienteId do pedido
prestadorId do pedido
```

Depois atualiza `prestadores/{prestadorId}` em transacao:

```text
ratingCount
ratingSum
ratingAvg
updatedAt
```

Avaliacoes invalidas sao ignoradas sem inflar agregados.

## Cliente Flutter

`AvaliacaoService.enviarAvaliacao` deixou de atualizar
`prestadores/{prestadorId}`. Agora cria apenas o documento de avaliacao em:

```text
avaliacoes/{pedidoId}_{clienteId}
```

Isto remove a escrita client-side dos agregados.

## Testes

Foram adicionados testes para:

```text
cliente dono do pedido concluido cria avaliacao no docId correto
pedido nao concluido falha
outro cliente falha
prestador avaliando o proprio pedido como cliente falha
nao autenticado falha
rating 0 falha
rating 6 falha
comentario nao-string falha
comentario maior que 500 falha
campo extra falha
createdAt controlado pelo cliente falha
docId errado falha
duplicacao por outro docId falha
prestador diferente do pedido falha
cliente nao altera agregados diretamente
outro utilizador autenticado nao altera agregados diretamente
Function atualiza agregados validos
Function recalcula media em segunda avaliacao
Function ignora rating invalido
Function ignora docId invalido
```

## Fora do Escopo Mantido

```text
mostrar reputacao no perfil publico
comentarios publicos
reviews publicas completas
moderacao
denuncias
ranking
KYC
certificacao
pagamento seguro
avaliacao do cliente pelo prestador
resposta do prestador
admin completo
deploy
Android fisico
tester externo
Play Store
fechar R
fechar R1
fechar M
fechar M2.6
```

## Riscos Remanescentes

```text
A UI de avaliacao ainda precisa de testes/polish em M2.15.3.
Comentarios publicos continuam bloqueados por decisao de privacidade/moderacao.
Reputacao no perfil publico so deve entrar em M2.15.4.
Leitura publica de avaliacoes ainda nao foi aberta.
```

## Proximo Passo

```text
M2.15.3 - UI de avaliacao pos-servico
```
