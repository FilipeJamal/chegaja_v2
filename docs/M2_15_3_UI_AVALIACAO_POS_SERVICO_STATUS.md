# M2.15.3 - UI de Avaliacao Pos-Servico

Data: 2026-05-29

## Estado

```text
M2.15.3: concluida
M2.15.4: proximo passo - reputacao leve no perfil publico do prestador
Bloco H: ativo
Bloco F: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Resultado

A UI de avaliacao pos-servico foi melhorada no widget existente:

```text
lib/features/cliente/widgets/avaliacao_pedido_card.dart
```

O widget continua a ler `avaliacoes/{pedidoId}_{clienteId}`, mostra formulario
quando ainda nao existe avaliacao, mostra resumo quando a avaliacao ja foi
enviada e usa `AvaliacaoService` para criar apenas o documento de avaliacao.
Os agregados `ratingCount`, `ratingSum` e `ratingAvg` continuam sob
responsabilidade da Cloud Function criada na M2.15.2.

## Alteracoes

```text
Redesign leve do card de avaliacao.
Estado de loading do StreamBuilder.
Estado de erro do StreamBuilder.
Resumo de avaliacao enviada mais claro.
Estrelas maiores e com tooltip.
Comentario opcional com contador 0/500.
Comentario acima de 500 caracteres bloqueia o envio.
Envio sem estrela mostra erro claro.
Botao fica desativado durante envio.
Injecao opcional de Firestore/stream/callback para testes.
Condicao do detalhe do pedido exige Cliente dono do pedido concluido.
Classe privada duplicada de avaliacao no detalhe foi removida.
```

## Testes

Foi criado:

```text
test/features/cliente/widgets/avaliacao_pedido_card_test.dart
```

Cobertura principal:

```text
formulario sem avaliacao
resumo com avaliacao existente
selecao de estrela
erro sem estrela
comentario acima de 500 caracteres
contador de comentario
botao desativado durante envio
loading do stream
erro do stream
dark mode sem excecao
```

## Fora do Escopo Mantido

```text
reputacao publica no perfil
comentarios publicos
reviews publicas completas
moderacao
denuncias
resposta do prestador
avaliacao do cliente pelo prestador
Firestore Rules
Storage Rules
Cloud Functions
deploy
Android fisico
tester externo
pagamentos
KYC
ranking
pesquisa estilo Instagram
Trust & Safety implementation
admin/backoffice
```

## Decisao

A M2.15.3 fica fechada no escopo de UI de avaliacao pos-servico.

A reputacao publica continua fora desta fase e so deve entrar na M2.15.4,
aproveitando os agregados protegidos pela M2.15.2.

## Proximo Passo

```text
M2.15.4 - Reputacao leve no perfil publico do prestador
```
