# Relatorio Final M2.15 - Avaliacoes e Reputacao Leve

Data: 2026-05-29

## Objetivo

Fechar a primeira camada de avaliacoes e reputacao leve do ChegaJa sem criar
confianca falsa. A M2.15 permite avaliacao pos-servico, protege a reputacao
contra manipulacao direta e mostra uma media publica simples apenas quando ha
agregados validos.

## Fases

| Fase | Estado | Resultado |
| --- | --- | --- |
| M2.15.1 | FECHADO | Spec e auditoria da base existente de avaliacoes |
| M2.15.2 | FECHADO | Rules endurecidas e Cloud Function autoritativa para agregados |
| M2.15.3 | FECHADO | UI de avaliacao pos-servico melhorada |
| M2.15.4 | FECHADO | Reputacao leve no perfil publico com ratingAvg/ratingCount |
| M2.15.5 | FECHADO | Testes, E2E, QA visual e documentacao final |

## Commits Principais

```text
191c044f62495f5149f83be4e546e2fcce5e7ae2
Iniciar M2.15 avaliacoes reputacao leve

3bdcc3052443e2b4557253275d1d9b8e8850621b
Registar visao mestre e preparar M2.15.3

026992b07e31131263e0ceb5ede438ff95a8a01d
Melhorar M2.15.3 UI avaliacao pos-servico

76da6e526c9c7f049e90bbf013010fbb53b45e33
Mostrar M2.15.4 reputacao leve perfil publico
```

## Implementado

```text
AvaliacaoService cria apenas avaliacoes/{pedidoId}_{clienteId}.
Firestore Rules validam cliente, pedido concluido, docId, estrelas, comentario e campos permitidos.
Cloud Function onAvaliacaoCreated atualiza ratingCount/ratingSum/ratingAvg.
Utilizadores comuns nao podem escrever agregados de reputacao diretamente.
AvaliacaoPedidoCard mostra formulario, loading, erro, resumo e contador 0/500.
PedidoDetalheScreen mostra avaliacao apenas ao Cliente dono do pedido concluido.
PublicProfileScreen mostra reputacao leve quando ratingAvg/ratingCount sao validos.
Prestador sem rating valido ve estado neutro, sem nota inventada.
```

## Testado

```text
Rules de avaliacao e bloqueio de agregados.
Cloud Function de agregacao de ratings.
UI do AvaliacaoPedidoCard.
PublicProfileScreen com e sem reputacao.
Flutter test completo.
Build Web release.
E2E dual Cliente/Prestador.
E2E orcamento min-max.
Matriz visual Home Cliente/Prestador em quatro viewports.
```

## Decisoes Tecnicas

```text
Agregados de rating sao autoritativos via Cloud Function.
Cliente nao atualiza ratingCount/ratingSum/ratingAvg.
Perfil publico usa apenas ratingAvg/ratingCount.
Comentarios publicos nao sao exibidos nesta fase.
AvaliacaoRepo nao e usado no perfil publico.
Leitura publica da colecao avaliacoes continua fora.
Reputacao leve e estatistica, nao certificacao.
```

## Fora do Escopo

```text
comentarios publicos
reviews publicas completas
moderacao de avaliacoes
denuncias
ranking de reputacao
resposta do prestador
avaliacao do cliente pelo prestador
KYC
certificacao
pagamento seguro
pagamentos reais
admin completo
deploy
Android fisico
tester externo
Play Store
```

## Riscos Remanescentes

```text
Comentarios publicos precisam de privacidade, consentimento e moderacao antes de serem exibidos.
Ranking futuro so deve usar reputacao depois de manter agregados protegidos e antifraude.
Matriz visual atual nao captura diretamente perfil publico/reputacao; a cobertura nesta fase ficou em testes e E2E.
Bloco H continua parcial porque reviews completas, denuncias e moderacao ainda faltam.
R e M continuam bloqueados por dependencias externas.
```

## Proximo Passo Recomendado

```text
M2.16 - Pesquisa manual e descoberta de prestadores estilo Instagram
```

Antes de ranking ou descoberta baseada em reputacao avancada, manter a regra de
produto: nao prometer verificacao, certificacao ou garantia sem processo real.

