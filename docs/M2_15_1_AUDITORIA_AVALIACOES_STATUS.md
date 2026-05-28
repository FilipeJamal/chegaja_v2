# M2.15.1 - Auditoria Avaliacoes e Reputacao Leve

Data: 2026-05-28

## Estado

```text
M2.15.1: concluida
M2.15: iniciada
Bloco H: ativo
Bloco R: pausado por falta de tester humano real
Bloco M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Ficheiros Analisados

| Ficheiro | Responsabilidade | Estado | Risco | Acao recomendada |
| --- | --- | --- | --- | --- |
| `lib/core/services/avaliacao_service.dart` | Criar avaliacao e atualizar agregados do prestador | Funcional | Cliente escreve agregados diretamente | Endurecer Rules ou mover agregacao para Function |
| `lib/core/repositories/avaliacao_repo.dart` | Buscar avaliacoes de prestador | Parcial | Rules nao permitem leitura publica; privacidade do cliente | Nao usar em perfil publico ate M2.15.4 decidir Rules/moderacao |
| `lib/core/models/avaliacao.dart` | Modelo de avaliacao | Simples | `createdAt` fallback pode mascarar dado ausente | Revisar em testes/UI |
| `lib/features/cliente/widgets/avaliacao_pedido_card.dart` | Formulario/resumo de avaliacao | Funcional | Sem testes dedicados; StreamBuilder sem estado de erro especifico | Cobrir em M2.15.3 |
| `lib/features/cliente/pedido_detalhe_screen.dart` | Integra avaliacao no pedido concluido | Funcional/parcial | Condicao UI pode exigir explicitamente cliente dono; classe privada duplicada | Ajustar em M2.15.3 |
| `lib/features/common/perfil_publico_screen.dart` | Perfil publico do prestador | Nao mostra reputacao ainda | Nao deve exibir reviews antes da seguranca | Integrar agregados apenas apos M2.15.2 |
| `firestore.rules` | Regras principais | Parcial | Agregados de rating abertos a qualquer signedIn nao-prestador | Prioridade M2.15.2 |
| `firestore.rules.local` | Regras locais | Parcial/divergente | Nao replica regra principal de agregados | Decidir alinhamento em M2.15.2 |
| `functions/test/firestore.test.js` | Testes de Rules | Parcial | Nao ha cobertura de avaliacoes | Adicionar testes RED em M2.15.2 |
| `scripts/e2e/full_ui_dual_role_e2e.js` | E2E Web principal | Parcial | Semeia rating, mas nao testa envio de avaliacao | Expandir em M2.15.5 |

## Conclusoes Principais

```text
1. A base de avaliacoes ja existe e nao precisa ser criada do zero.
2. O fluxo Cliente pos-conclusao ja mostra AvaliacaoPedidoCard.
3. O service ja grava avaliacao e atualiza agregados em transacao.
4. As Rules de create de avaliacoes ja exigem pedido concluido e prestador correto.
5. A seguranca dos agregados ratingCount/ratingSum/ratingAvg ainda e fraca.
6. Nao ha testes de Rules para avaliacoes.
7. Comentarios publicos ainda nao devem ser expostos.
8. Perfil publico pode mostrar media/contagem depois de M2.15.2.
```

## Risco Critico Encontrado

Em `firestore.rules`, qualquer utilizador autenticado com `uid() != prestadorId`
pode atualizar apenas:

```text
ratingCount
ratingSum
ratingAvg
updatedAt
```

Isto protege contra o proprio prestador inflar a reputacao, mas nao protege
contra outro utilizador autenticado manipular agregados. Antes de mostrar
reputacao publica no perfil, M2.15.2 deve corrigir esta superficie.

## Riscos Secundarios

```text
avaliacoes/{avaliacaoId} nao exige avaliacaoId == {pedidoId}_{clienteId}
create de avaliacao nao tem whitelist de campos
comentario nao tem tipo/tamanho validado nas Rules
createdAt nao e validado nas Rules
firestore.rules.local diverge de firestore.rules
AvaliacaoPedidoCard ainda nao tem testes dedicados
PedidoDetalheScreen contem classe privada duplicada _AvaliacaoPedidoCard
AvaliacaoRepo pode expor nome/foto de cliente se usado publicamente
E2E ainda nao cobre avaliacao pos-servico
```

## Decisao da M2.15.1

Nao implementar feature nesta fase.

M2.15 deve avancar primeiro para seguranca:

```text
M2.15.2 - Rules, seguranca e consistencia de avaliacao
```

So depois:

```text
M2.15.3 - UI de avaliacao pos-servico
M2.15.4 - Reputacao leve no perfil publico do prestador
M2.15.5 - Testes, E2E, QA visual e documentacao final
```

## Fora do Escopo Mantido

```text
KYC
certificacao
pagamento seguro
moderacao completa
denuncias
ranking global
resposta do prestador
avaliacao do cliente pelo prestador
admin completo
deploy
Android fisico
tester externo
Play Store
```

## Validacoes

Por ser uma fase documental/auditoria:

```text
git status
git diff --check
npm.cmd run test:scripts
```

Nenhum ficheiro Dart, Rules ou Functions foi alterado nesta fase.
