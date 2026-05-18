# M2.9.1 Detalhe do Pedido UX Design

Data: 2026-05-19

## Estado

M2.9 abre a fase de beta Web funcional e experiencia real Cliente/Prestador.
M2.9.1 foca apenas no detalhe do pedido, estados e acoes.

## Objetivo

Melhorar a clareza operacional do detalhe do pedido para Cliente e Prestador.
A tela deve responder rapidamente:

```text
1. Em que estado esta este pedido?
2. Quem tem de fazer a proxima acao?
3. O que acontece depois?
```

## Escopo aprovado

Abordagem A2:

```text
Melhorar detalhe do pedido, proxima acao, timeline e UX de
orcamento/valor final, com bom impacto e sem mexer em infraestrutura.
```

## Nao objetivos

Esta subfase nao deve:

```text
alterar regras Firestore/Storage
alterar Cloud Functions
adicionar pagamentos reais
mexer em Play Store
alterar package id final
alterar HTTPS App Links
fechar M2.6
adicionar Android fisico
redesenhar a app inteira
```

## Principios de UX

- O detalhe do pedido deve destacar o estado atual antes de mostrar dados
  secundarios.
- A proxima acao deve ser explicita e diferente para Cliente e Prestador.
- Estados finais (`concluido`, `cancelado`) devem parecer finais e nao sugerir
  acoes indevidas.
- Fluxos de orcamento e valor final devem explicar a diferenca entre:
  proposta/faixa, servico em andamento, valor final proposto e confirmacao do
  cliente.
- Mensagens de erro devem ser curtas, acionaveis e sem expor detalhes tecnicos
  brutos ao utilizador final.
- A UI deve manter o padrao visual existente do app, sem landing page,
  refatoracao visual grande ou novo design system.

## Proposta de produto

### 1. Banner principal de estado

Adicionar um banner compacto no topo do detalhe do pedido com:

```text
estado legivel
icone contextual
texto curto da situacao
indicacao de quem deve agir
```

Exemplos:

```text
Cliente, pedido criado:
"A procurar prestador"
"Estamos a procurar alguem disponivel para este pedido."
"Proxima acao: aguardar ou escolher manualmente."

Prestador, convite pendente:
"Convite recebido"
"O cliente escolheu-te para este servico."
"Proxima acao: aceitar ou recusar."

Cliente, valor final pendente:
"Confirma o valor final"
"O prestador terminou o servico e enviou o valor final."
"Proxima acao: confirmar ou rejeitar."
```

### 2. Bloco "Proxima acao"

Criar uma secao pequena antes das acoes existentes. Ela nao substitui os
botoes; apenas explica o que deve acontecer.

Conteudo esperado:

```text
titulo: Proxima acao
descricao: texto especifico para role + estado
nota opcional: o que acontece depois
```

Exemplos:

```text
Cliente em `aguarda_resposta_cliente`:
"Revê a proposta do prestador. Se aceitares, o pedido avanca para servico
aceite. Se rejeitares, voltamos a procurar."

Prestador em `em_andamento`:
"Quando terminares o trabalho, envia o valor final para o cliente confirmar."

Cliente em `concluido`:
"Pedido concluido. Podes consultar o historico e avaliar o servico."
```

### 3. Timeline mais compreensivel

Manter o componente existente, mas melhorar a leitura:

```text
Criado -> Prestador -> Em andamento -> Concluido
```

Para estados intermediarios, a timeline deve continuar simples, mas o banner e
o bloco de proxima acao explicam o detalhe.

Quando o estado for `cancelado`, a ultima etapa deve comunicar cancelamento
sem sugerir conclusao.

### 4. Orçamento e valor final

Melhorar textos e confirmacoes visuais nos widgets existentes:

```text
ClientePedidoAcoes
PrestadorPedidoAcoes
```

O objetivo e reduzir ambiguidade:

```text
orcamento/faixa estimada != valor final
valor final precisa confirmacao do cliente
backend calcula comissao/ganhos
```

Sucesso e erro devem usar SnackBars com mensagens humanas:

```text
"Valor final confirmado. O pedido ficou concluido."
"Nao conseguimos confirmar o valor agora. Tenta novamente."
```

### 5. Fallbacks e erros

No detalhe do pedido:

```text
loading: indicador simples
pedido nao encontrado: mensagem clara
erro ao carregar: mensagem curta + opcao de voltar/tentar novamente quando
for simples de aplicar
```

Erros tecnicos completos devem ficar no debug/log, nao no texto principal para
utilizador final.

## Arquitetura proposta

Criar helpers/widgets pequenos em vez de aumentar muito `pedido_detalhe_screen.dart`.

Arquivos candidatos:

```text
lib/features/cliente/widgets/pedido_status_summary.dart
lib/features/cliente/widgets/pedido_next_action_card.dart
lib/features/cliente/widgets/pedido_banners.dart
lib/features/cliente/widgets/pedido_timeline.dart
lib/features/cliente/widgets/cliente_pedido_acoes.dart
lib/features/prestador/widgets/prestador_pedido_acoes.dart
lib/features/cliente/pedido_detalhe_screen.dart
```

Preferencia:

```text
criar widgets focados para status/proxima acao
manter a tela de detalhe como composicao
nao mover regras de negocio para UI
usar Pedido + role para derivar textos
```

## Dados e regras

Nao ha mudanca de schema.

O comportamento deve usar campos ja existentes:

```text
estado
statusProposta
statusConfirmacaoValor
tipoPreco
precoPropostoPrestador
precoFinal
valorMinEstimadoPrestador
valorMaxEstimadoPrestador
canceladoPor
prestadorId
clienteId
```

## Testes esperados

Adicionar testes focados de widget/helper para garantir:

```text
Cliente ve proxima acao correta em valor final pendente
Prestador ve proxima acao correta em convite pendente
Pedido concluido mostra estado final sem acao indevida
Pedido cancelado mostra cancelamento
Timeline continua a mapear estados principais
```

Rodar validacoes:

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Se a alteracao ficar apenas em Flutter/UI, os testes Firebase podem ser rodados
como regressao de seguranca antes do commit final, sem deploy.

## Criterios de aceitacao

M2.9.1 pode ser considerada avancada quando:

```text
detalhe do pedido mostra estado atual em banner claro
detalhe do pedido mostra proxima acao especifica por role/estado
orcamento e valor final usam textos mais claros
erros principais deixam de despejar detalhe tecnico bruto no utilizador
testes Flutter cobrem pelo menos os helpers/widgets novos
flutter test passa
nao ha deploy, smoke real, cleanup real, pagamentos ou Android fisico
docs/status M2.9 atualizados
```

## Riscos

- `pedido_detalhe_screen.dart` ja concentra muitas responsabilidades. A subfase
  deve evitar aumentar a complexidade criando widgets auxiliares.
- Alguns textos atuais estao hardcoded em portugues. A M2.9.1 pode manter esse
  padrao para escopo curto, mas deve preferir l10n quando a tela ja usar a chave
  correspondente.
- Alteracoes visuais devem preservar os testes Android/Web ja existentes.

## Decisao

Avancar com M2.9.1 usando a abordagem A2:

```text
Detalhe do pedido + estados + proxima acao + melhorias de orcamento/valor final
```

Sem mudar backend, pagamentos, deploy, Play Store ou Android fisico.
