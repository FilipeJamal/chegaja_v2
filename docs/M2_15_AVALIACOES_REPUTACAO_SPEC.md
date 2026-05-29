# M2.15 - Avaliacoes e Reputacao Leve Pos-Servico

Data: 2026-05-28

## Estado

```text
M2.15: iniciada
M2.15.1: concluida - spec e auditoria da base atual
M2.15.2: concluida - Rules, Function autoritativa e consistencia das avaliacoes
M2.15.3: proximo passo - UI de avaliacao pos-servico
Bloco H: ativo
Bloco F: parcial
Bloco R: pausado por falta de tester humano real
Bloco M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Objetivo

Permitir reputacao leve pos-servico sem criar confianca falsa.

A M2.15 deve consolidar um fluxo em que:

```text
Cliente avalia o Prestador depois de pedido concluido.
Avaliação usa 1 a 5 estrelas.
Comentario e opcional.
Nao existe avaliacao duplicada para o mesmo pedido/cliente.
Agregados do prestador sao consistentes.
Perfil publico pode mostrar reputacao leve apenas quando houver dados reais.
```

Esta fase nao cria KYC, certificacao, garantia, moderacao pesada ou pagamento
seguro.

## Base Atual Confirmada

### AvaliacaoService

Ficheiro:

```text
lib/core/services/avaliacao_service.dart
```

Estado atual:

```text
Existe AvaliacaoService.instance.enviarAvaliacao.
Grava em avaliacoes/{pedidoId}_{clienteId}.
Campos gravados: pedidoId, clienteId, prestadorId, estrelas, comentario opcional, createdAt.
Cria apenas o documento de avaliacao.
Se a avaliacao ja existe, retorna sem duplicar no mesmo docId.
Nao atualiza agregados do prestador pelo cliente.
A atualizacao de ratingCount/ratingSum/ratingAvg ficou autoritativa em Cloud Function.
```

Riscos:

```text
O service depende das Rules para garantir que o pedido esta concluido.
O service depende da Function onCreate para atualizar agregados.
O retorno silencioso quando a avaliacao ja existe evita duplicacao no docId esperado, mas nao informa a UI.
```

### AvaliacaoPedidoCard

Ficheiro:

```text
lib/features/cliente/widgets/avaliacao_pedido_card.dart
```

Estado atual:

```text
Existe widget de formulario/resumo.
Le avaliacoes/{pedidoId}_{clienteId} por StreamBuilder.
Mostra resumo quando a avaliacao ja existe.
Mostra formulario quando nao existe.
Exige selecionar pelo menos 1 estrela antes de enviar.
Permite comentario opcional.
Mostra loading no botao durante envio.
Mostra SnackBar de sucesso/erro.
Usa l10n rating*.
```

Integracao atual:

```text
lib/features/cliente/pedido_detalhe_screen.dart importa AvaliacaoPedidoCard.
Aparece quando isCliente, pedido.estado == 'concluido', prestadorId != null e clienteId != null.
```

Riscos:

```text
O widget nao valida estado do pedido por si; depende do parent e das Rules.
O parent deveria ser mais explicito e exigir clienteId == pedido.clienteId.
Nao ha teste dedicado para AvaliacaoPedidoCard.
O StreamBuilder nao tem estado visual especifico de loading/erro.
Ainda existem cores diretas no widget; dark mode deve ser revisto em M2.15.3.
```

Nota tecnica:

```text
Existe uma classe privada _AvaliacaoPedidoCard antiga dentro de
lib/features/cliente/pedido_detalhe_screen.dart. O detalhe usa o widget
importado publico, mas a classe privada duplicada aumenta ruido e deve ser
removida/refatorada numa fase de UI/testes, nao nesta auditoria.
```

### AvaliacaoRepo

Ficheiro:

```text
lib/core/repositories/avaliacao_repo.dart
```

Estado atual:

```text
Busca avaliacoes por prestadorId.
Ordena por createdAt descendente.
Limita resultados.
Mapeia documentos para Avaliacao.
Tenta enriquecer avaliacoes com dados de users/{clienteId}.
```

Riscos:

```text
As Firestore Rules atuais nao permitem leitura publica de avaliacoes.
Logo, AvaliacaoRepo nao deve ser usado diretamente no perfil publico anonimo sem nova decisao de Rules.
Enriquecer com displayName/photoUrl do cliente cria risco de privacidade.
Para reputacao publica leve, preferir "Cliente ChegaJa" ou mostrar apenas agregados enquanto nao houver moderacao/consentimento.
```

### Modelo Avaliacao

Ficheiro:

```text
lib/core/models/avaliacao.dart
```

Campos atuais:

```text
id
pedidoId
clienteId
prestadorId
estrelas
comentario
createdAt
clienteNome
clienteFoto
```

Riscos:

```text
createdAt usa DateTime.now() como fallback se o timestamp estiver ausente.
clienteNome/clienteFoto sao campos locais de enriquecimento; nao devem virar exibicao publica sem decisao de privacidade.
```

## Firestore Rules

### Colecao avaliacoes

Ficheiro:

```text
firestore.rules
```

Regra atual apos M2.15.2:

```text
read: participante do pedido ou admin
create: signedIn, docId == {pedidoId}_{clienteId}, clienteId == auth.uid,
        pedido existente, cliente dono do pedido, pedido concluido,
        prestadorId igual ao pedido, estrelas int 1..5,
        comentario opcional string <= 500, createdAt == request.time,
        campos extras bloqueados
update/delete: admin ou devMode
```

Pontos fortes:

```text
Somente cliente autenticado como clienteId pode criar.
Pedido precisa estar concluido.
Prestador avaliado precisa ser o prestador do pedido.
Prestador nao pode editar/deletar avaliacao.
Rating fora de 1..5 e bloqueado.
DocId errado e campos extras sao bloqueados.
Comentario e createdAt sao validados.
```

Riscos corrigidos em M2.15.2:

```text
hasOnly/whitelist de campos adicionada.
Comentario validado.
createdAt validado como server timestamp/request.time.
avaliacaoId ligado ao formato {pedidoId}_{clienteId}.
Tentativa de duplicar avaliacao por docId diferente bloqueada.
Testes de Rules adicionados.
```

### Agregados em prestadores

Ficheiro:

```text
firestore.rules
```

Regra atual apos M2.15.2:

```text
O proprio prestador nao pode alterar ratingCount/ratingSum/ratingAvg.
Clientes, prestadores e outros utilizadores comuns nao podem alterar
ratingCount, ratingSum ou ratingAvg.
Admin SDK/Cloud Function atualiza os agregados de forma autoritativa.
```

Risco corrigido:

```text
Foi removida a superficie que permitia a qualquer utilizador autenticado
nao-prestador manipular agregados de rating.
```

Decisao:

```text
M2.15.2 escolheu Cloud Function autoritativa para agregados.
```

Opcoes consideradas em M2.15.2:

```text
A. Manter transacao cliente-side, mas endurecer Rules com docId esperado,
   whitelist de campos, getAfter() e validacao de incremento.
B. Mover agregacao para fluxo autoritativo em Cloud Function e impedir cliente
   de escrever ratingCount/ratingSum/ratingAvg.
C. Como passo intermedio, permitir create de avaliacao e manter apenas leitura
   de agregados existentes, sem expor comentarios publicos ate a seguranca estar fechada.
```

Resultado:

```text
Apos testes RED, a opcao B foi implementada: cliente cria avaliacao,
Function onCreate atualiza agregados e Rules bloqueiam escrita direta.
```

### firestore.rules.local

Estado atual:

```text
firestore.rules.local foi alinhado para bloquear escrita direta dos agregados
ratingCount/ratingSum/ratingAvg por owner/prestador comum.
```

Risco:

```text
Permanece como ficheiro local/dev, mas a regra de avaliacoes e agregados foi
sincronizada com a decisao de M2.15.2.
```

## Reputacao no Perfil Publico

M2.15 pode mostrar apenas reputacao leve:

```text
ratingAvg se ratingCount > 0
ratingCount
Texto: "Avaliacao media de clientes"
Texto: "Baseado em pedidos concluidos avaliados"
```

Nao mostrar:

```text
Prestador verificado
Prestador certificado
Garantido pelo ChegaJa
100% confiavel
Pagamento seguro
Identidade confirmada
```

Sem avaliacoes:

```text
Nao inventar nota.
Mostrar estado neutro: "Ainda sem avaliacoes publicas".
```

## Comentarios Publicos

Decisao para esta spec:

```text
Nao expor comentarios publicos na primeira passagem sem resolver privacidade,
moderacao e Rules.
```

Se comentarios forem expostos numa fase futura:

```text
Limitar quantidade.
Mostrar apenas comentarios recentes e permitidos.
Considerar nome generico "Cliente ChegaJa".
Evitar foto/nome real do cliente sem consentimento claro.
Preparar moderationStatus/hiddenByAdmin antes de virar publico.
```

## Estados de Produto

```text
Pedido nao concluido: nao pode avaliar.
Pedido concluido sem avaliacao: Cliente ve formulario.
Pedido concluido ja avaliado: Cliente ve resumo.
Prestador sem avaliacoes: perfil publico mostra estado neutro.
Prestador com avaliacoes: perfil publico pode mostrar media e contagem apenas em M2.15.4.
Erro de envio: mensagem clara.
Sem estrelas selecionadas: pedir selecao.
Prestador/outsider: nao avalia como Cliente.
```

## Testes Necessarios

### Rules

```text
cliente dono do pedido concluido consegue criar avaliacao no docId esperado
cliente nao consegue avaliar pedido nao concluido
outro cliente nao consegue avaliar
prestador nao consegue avaliar como cliente
nao autenticado nao consegue avaliar
rating 0/6 falha
comentario nao-string falha
comentario longo falha
createdAt controlado pelo cliente falha
campos extras falham
docId errado falha
cliente nao consegue duplicar avaliacao em outro docId
prestador nao consegue alterar rating aggregates
outsider nao consegue alterar rating aggregates
agregado so muda no fluxo permitido ou por Function/admin
```

### Widget/UI

```text
AvaliacaoPedidoCard mostra formulario sem avaliacao.
AvaliacaoPedidoCard mostra resumo com avaliacao existente.
Enviar sem estrela mostra erro.
Enviar com estrela chama service.
Erro de envio mostra SnackBar.
Dark mode sem texto hardcoded problemático.
PedidoDetalheScreen mostra card apenas para cliente dono e pedido concluido.
Pedido nao concluido nao mostra formulario.
```

### E2E

```text
Depois de concluir pedido, Cliente envia avaliacao.
Firestore contem avaliacao esperada.
Prestador recebe ratingCount/ratingAvg consistente.
Perfil publico mostra reputacao leve quando permitido.
```

## Subfases

```text
M2.15.1 - Spec e auditoria da base atual de avaliacoes
M2.15.2 - Rules, seguranca e consistencia de avaliacao - concluida
M2.15.3 - UI de avaliacao pos-servico - proximo passo
M2.15.4 - Reputacao leve no perfil publico do prestador
M2.15.5 - Testes, E2E, QA visual e documentacao final
```

## Fora do Escopo

```text
KYC
certificacao
pagamento seguro
moderacao completa
denuncias
ranking global
resposta do prestador
avaliacao do cliente pelo prestador
edicao/delecao avancada de avaliacao
admin completo
deploy
Android fisico
tester externo
Play Store
```
