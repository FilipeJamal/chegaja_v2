# M2.15.3 - UI de Avaliacao Pos-Servico

Data: 2026-05-29

## Estado

```text
M2.15.1: concluida
M2.15.2: concluida
M2.15.3: concluida
M2.15.4: proximo passo - reputacao leve no perfil publico do prestador
Bloco H: ativo
R: pausado
M: pausado
R1: pendente
M2.6: pendente
```

## Objetivo

Melhorar a experiencia visual e funcional do Cliente ao avaliar o Prestador
depois de um pedido concluido, sem expor ainda reputacao publica no perfil.

A M2.15.2 fechou a seguranca. A M2.15.3 deve melhorar a UI que ja existe:

```text
lib/features/cliente/widgets/avaliacao_pedido_card.dart
```

## Base Atual

O widget atual:

```text
le avaliacoes/{pedidoId}_{clienteId}
mostra formulario se ainda nao ha avaliacao
mostra resumo se ja existe avaliacao
permite estrelas 1..5
permite comentario opcional
mostra loading no botao
usa AvaliacaoService para enviar
```

Limitacoes:

```text
visual simples
cores diretas em vez de ColorScheme completo
sem estado de loading/erro do StreamBuilder refinado
sem contador/limite visual de comentario
sem teste dedicado do widget
classe privada duplicada em pedido_detalhe_screen.dart
condicao de exibicao no parent pode exigir cliente dono explicitamente
```

## Escopo

Pode entrar:

```text
redesign leve do AvaliacaoPedidoCard
usar ColorScheme e componentes visuais existentes
estado de loading do StreamBuilder
estado de erro do StreamBuilder
estado "avaliacao enviada" mais claro
estrelas maiores e acessiveis
comentario opcional com limite visual de 500 caracteres
mensagens PT-PT mais naturais
validacao local de comentario vazio/limite
teste dedicado de widget
remover classe privada duplicada se estiver realmente sem uso
garantir que o card aparece so para Cliente dono de pedido concluido
```

Nao entra:

```text
mostrar reputacao no perfil publico
comentarios publicos
moderacao de reviews
denuncias
resposta do prestador
avaliacao do cliente pelo prestador
alterar Rules
alterar Cloud Functions
deploy
Android fisico
tester externo
pagamentos
KYC
ranking
```

## UX Recomendada

Formulario:

```text
titulo: Avalia este prestador
subtexto: A tua avaliacao ajuda outros clientes depois do servico.
estrelas com feedback visual claro
texto de apoio para 1..5
campo comentario opcional
contador 0/500
botao Enviar avaliacao
```

Resumo:

```text
titulo: Avaliacao enviada
mostrar estrelas
mostrar comentario se existir
texto curto: Obrigado pelo feedback.
nao permitir editar nesta fase
```

Estados:

```text
loading: skeleton/progresso discreto
erro: mensagem clara com retry se fizer sentido
sem estrela: SnackBar ou erro inline
comentario > 500: bloquear envio e explicar
envio em curso: botao disabled com progresso
```

## Regras de Produto

```text
avaliacao so aparece em pedido concluido
apenas Cliente dono do pedido ve formulario
Prestador nao avalia nesta fase
sem duplicacao
comentario publico continua fora
rating publico no perfil fica para M2.15.4
```

## Testes Obrigatorios/Recomendados

Criar ou atualizar:

```text
test/features/cliente/widgets/avaliacao_pedido_card_test.dart
```

Cobrir:

```text
renderiza formulario quando nao ha avaliacao
renderiza resumo quando avaliacao existe
selecionar estrela muda estado visual
enviar sem estrela mostra erro
comentario acima de 500 bloqueia envio
botao fica disabled durante envio
dark mode nao introduz texto preto hardcoded
StreamBuilder loading mostra estado adequado
StreamBuilder erro mostra estado adequado
```

Se a injecao de Firestore/Service for necessaria:

```text
preferir injecao opcional e retrocompativel
nao criar arquitetura pesada
nao alterar modelo de dados
```

## Validacoes

```text
git status
git diff --check
npm.cmd run test:scripts
flutter test --no-pub test/features/cliente/widgets/avaliacao_pedido_card_test.dart
flutter test --no-pub
```

Se tocar em fluxo principal Cliente/Prestador:

```text
npm.cmd run e2e:ui:dual
npm.cmd run e2e:ui:orcamento
```

## Prompt Operacional Para Codex

```text
Tarefa: M2.15.3 - UI de avaliacao pos-servico

Contexto:
M2.15.2 ja foi fechada com Cloud Function autoritativa para agregados e Rules
endurecidas. Nao mexer em Rules/Functions nesta fase.

Objetivo:
Melhorar AvaliacaoPedidoCard e sua integracao no detalhe do pedido concluido,
criando testes dedicados e mantendo reputacao publica fora do escopo.

Ficheiros obrigatorios a ler:
- docs/M2_15_AVALIACOES_REPUTACAO_SPEC.md
- docs/M2_15_2_RULES_AVALIACOES_STATUS.md
- docs/M2_15_3_UI_AVALIACAO_POS_SERVICO_SPEC.md
- lib/features/cliente/widgets/avaliacao_pedido_card.dart
- lib/features/cliente/pedido_detalhe_screen.dart
- lib/core/services/avaliacao_service.dart
- lib/l10n/app_pt.arb

Ficheiros provaveis:
- lib/features/cliente/widgets/avaliacao_pedido_card.dart
- lib/features/cliente/pedido_detalhe_screen.dart
- test/features/cliente/widgets/avaliacao_pedido_card_test.dart
- docs/M2_15_3_UI_AVALIACAO_POS_SERVICO_STATUS.md
- docs/ROADMAP_A_T_CHEGAJA.md

Fora do escopo:
- PublicProfileScreen
- reputacao publica
- reviews publicas
- moderacao
- denuncias
- Rules
- Functions
- deploy
- Android fisico
- tester externo
- pagamentos
- KYC

Validacoes:
- git diff --check
- npm.cmd run test:scripts
- flutter test --no-pub test/features/cliente/widgets/avaliacao_pedido_card_test.dart
- flutter test --no-pub

Commit recomendado:
Melhorar M2.15.3 UI avaliacao pos-servico
```

## Proximo Passo Depois da M2.15.3

```text
M2.15.4 - Reputacao leve no perfil publico do prestador
```
