# P0.2 - Roteiro de demo do app para investidor

Data: 2026-06-06

Estado: FECHADO no escopo documental.

## Objetivo

Este documento define o roteiro de demo do ChegaJa para conversas com
investidor anjo/pre-seed. A demo deve apoiar o deck P0.1 e mostrar que o app ja
tem um MVP navegavel, com fluxo Cliente/Prestador, discovery, perfil publico,
reputacao leve, catalogo profissional e Trust & Safety.

Tese que a demo deve provar:

```text
ChegaJa nao e so uma ideia. Ja existe uma base funcional para organizar
servicos locais com descoberta, contexto, reputacao e seguranca.
```

Esta tarefa nao altera produto, Dart, Rules, Functions, Storage, deploy,
pagamentos, KYC ou M2.21.

## Principio da demo

A demo nao deve ser uma visita exaustiva a todos os botoes. Deve contar uma
historia simples:

```text
Cliente precisa de ajuda.
ChegaJa estrutura o pedido.
Prestador aparece com perfil e contexto.
O pedido vira conversa/trabalho.
A plataforma protege categorias e servicos proibidos.
Com investimento, isto vira piloto real em Maputo.
```

## Duracao recomendada

- Versao curta: 5 minutos.
- Versao principal: 10-12 minutos.
- Versao aprofundada: 18-20 minutos, apenas se o investidor pedir detalhes.

Para primeira conversa, usar a versao principal. Se houver pouco tempo, cortar
portfolio/admin e manter Cliente, Prestador, Trust & Safety e pedido de
investimento.

## Preparacao antes da chamada

Checklist operacional:

- Abrir o app em browser local ou build estavel.
- Ter uma aba Cliente e uma aba Prestador prontas.
- Confirmar que o emulador/ambiente esta estavel, se a demo for local.
- Ter um pedido de exemplo simples e seguro.
- Ter um prestador de exemplo com categorias, portfolio e perfil preenchidos.
- Ter uma alternativa de screenshots caso internet, emulador ou browser falhem.
- Nao abrir Firestore, codigo ou terminal durante a demo, salvo pergunta tecnica.

URLs uteis em ambiente local:

```text
Cliente:   http://127.0.0.1:5174/?role=cliente
Prestador: http://127.0.0.1:5174/?role=prestador
```

Se a porta local mudar, usar a porta ativa do servidor atual.

## Dados de demo recomendados

Cliente:

```text
Nome: Ana
Necessidade: reparacao de computador lento
Modo: receber orcamento
Descricao: O computador liga, mas esta muito lento e preciso de ajuda hoje ou amanha.
Local: Maputo
```

Prestador:

```text
Nome: Carlos Fix
Categoria principal: Tecnologia
Servicos: Reparacao de computadores, assistencia tecnica, instalacao de software
Portfolio: 2-3 exemplos visuais de trabalhos
@handle: carlosfix
```

Servico personalizado seguro para demonstrar "Outro servico":

```text
Nome: Consultoria de imagem
Descricao: Ajudo clientes a organizar roupas, estilo e apresentacao pessoal.
Palavras: moda, estilo, guarda-roupa, imagem
```

Nao usar termos proibidos ao vivo como exemplo principal. Se o investidor pedir
Trust & Safety em detalhe, explicar a politica e usar uma captura/estado seguro
preparado. Evitar transformar a conversa em teste de palavroes.

## Roteiro principal - 10 a 12 minutos

### 0. Abertura - 30 segundos

Objetivo:

- Enquadrar o que sera mostrado.
- Evitar que a demo pareca tour aleatorio.

Fala sugerida:

```text
Vou mostrar uma demo curta do ChegaJa em dois lados: Cliente e Prestador. A
ideia e mostrar como um pedido local ganha estrutura, como o prestador ganha
perfil e como a plataforma ja nasceu com regras de seguranca.
```

Mensagem-chave:

```text
Isto ainda e MVP, mas ja nao e so prototipo visual.
```

### 1. Home Cliente e problema - 1 minuto

Acao:

- Abrir a aba Cliente.
- Mostrar entrada de pedido/pesquisa.
- Explicar que o cliente normalmente comecaria por WhatsApp/contactos soltos.

Fala sugerida:

```text
Hoje, quando alguem precisa de um servico local, muitas vezes pede contactos em
grupos, fala com varias pessoas e nao tem contexto suficiente. Aqui o Cliente
comeca pelo trabalho que precisa, nao por uma lista confusa.
```

Ponto a demonstrar:

- O app transforma necessidade em pedido estruturado.

### 2. Criar pedido com catalogo profissional - 2 minutos

Acao:

- Criar pedido como Cliente.
- Usar exemplo: `reparacao de computador lento`.
- Mostrar que o app organiza por servico/categoria.
- Escolher intencao: receber orcamento.
- Preencher detalhes.

Fala sugerida:

```text
O catalogo nao e uma lista gigante de microtarefas. O ChegaJa separa Servico,
Intencao e Detalhes. O Cliente pode falar em linguagem simples, mas o app
organiza isso em categorias profissionais para pesquisa e matching.
```

Pontos a demonstrar:

- Servico.
- Intencao: agora, agendar ou orcamento.
- Detalhes do pedido.
- Compatibilidade com fluxo antigo.

Nao alongar:

- Nao explicar todos os campos.
- Nao abrir discussoes tecnicas sobre modelo de dados nesta parte.

### 3. Mostrar discovery/perfil publico - 1 minuto

Acao:

- Ir para pesquisa/discovery se estiver disponivel no fluxo.
- Procurar por `computador` ou `reparacao`.
- Abrir perfil de prestador.
- Mostrar portfolio, reputacao leve e contexto.

Fala sugerida:

```text
O Cliente nao esta apenas a ver um nome. Ele consegue ver perfil, portfolio,
servicos, reputacao leve e sinais de confianca. Isto reduz a incerteza antes da
conversa.
```

Pontos a demonstrar:

- Pesquisa manual/discovery.
- Perfil publico.
- Portfolio.
- Avaliacoes/reputacao leve.
- @handle/link publico, se estiver visivel.

### 4. Trocar para Prestador - 1 minuto

Acao:

- Abrir a aba Prestador.
- Mostrar Home Prestador.
- Mostrar disponibilidade e pedidos perto.
- Mostrar categorias de atuacao.

Fala sugerida:

```text
Do outro lado, o Prestador tambem tem produto. Ele nao e so um registo numa base
de dados. Ele tem painel, categorias, perfil, portfolio e canal de pedidos.
```

Pontos a demonstrar:

- Home Prestador.
- Receber pedidos.
- Categorias de atuacao.
- Botao de editar categorias.

### 5. Area de atuacao e "Outro servico" profissional - 1 minuto

Acao:

- Abrir Area de atuacao/editar categorias.
- Mostrar categorias profissionais.
- Mostrar que "Outro servico" pede nome, descricao e palavras de pesquisa.
- Se for seguro no estado atual, usar exemplo permitido: `Consultoria de imagem`.

Fala sugerida:

```text
Antes, "outro servico" podia virar uma gaveta generica. Agora, se o prestador
faz algo fora do catalogo, ele descreve o trabalho, adiciona termos de pesquisa
e passa pela politica de admissao. Isto ajuda o catalogo a crescer sem abrir uma
porta para abuso.
```

Pontos a demonstrar:

- Categorias principais.
- Subcategorias.
- Servico personalizado permitido.
- Nao prometer que vira categoria oficial automaticamente.

Se houver risco de dado sujo no ambiente:

- Nao guardar durante a chamada.
- Mostrar o formulario e explicar o comportamento.

### 6. Trust & Safety e politica de admissao - 1 minuto

Acao:

- Explicar a politica sem transformar a demo em lista de termos proibidos.
- Se houver material preparado, mostrar tela/estado seguro ou falar com base no
  QA validado.

Fala sugerida:

```text
Uma parte importante e que texto livre nao fica completamente aberto. O ChegaJa
classifica servicos como permitido, sensivel, proibido ou desconhecido para
revisao. Servico proibido bloqueia; servico vago nao fica publico
automaticamente; servico sensivel pode precisar de aprovacao.
```

Politica:

```text
allow            - entra no fluxo normal
sensitiveReview  - pode exigir analise/aprovacao
block            - bloqueia e nao guarda
unknownReview    - nao publica automaticamente
```

Mensagem-chave:

```text
O ChegaJa trata seguranca como parte da infraestrutura, nao como detalhe para
depois.
```

Nao fazer:

- Nao revelar listas internas de termos.
- Nao escrever exemplos obscenos ao vivo sem necessidade.
- Nao prometer "verificado", "certificado" ou "garantido" sem processo real.

### 7. Pedido/orcamento e conversa - 1 minuto

Acao:

- Mostrar pedido por orcamento ou pedido em andamento.
- Mostrar que o Prestador pode enviar proposta/orcamento.
- Mostrar contexto do pedido e conversa, se estiver estavel.

Fala sugerida:

```text
O pedido nao termina no formulario. Ele entra num fluxo de resposta, proposta e
conversa. Isto e importante porque marketplace de servicos precisa coordenar
expectativas, valor, disponibilidade e comunicacao.
```

Pontos a demonstrar:

- Orcamento min/max ou proposta.
- Estado do pedido.
- Chat no contexto do pedido.

### 8. Encerrar com plano de piloto - 1 minuto

Acao:

- Voltar verbalmente ao deck/ask.
- Ligar produto ao pedido de investimento.

Fala sugerida:

```text
O que queremos financiar agora nao e construir do zero. E transformar esta base
em piloto real: recrutar prestadores em Maputo, medir procura, medir resposta,
melhorar UX, preparar operacao e reforcar seguranca antes de uma beta publica
maior.
```

Pedido recomendado:

```text
700.000 MZN
```

Usos principais:

- Polimento UI/UX.
- Piloto com clientes reais.
- Recrutamento de prestadores.
- Marketing inicial.
- Operacao, moderacao e suporte.
- Juridico/politicas/documentacao.
- Reserva.

Fecho sugerido:

```text
O ChegaJa ja tem base tecnica e produto navegavel. O investimento serve para
validar mercado com pessoas reais, medir sinais certos e preparar a proxima
fase com disciplina.
```

## Versao curta - 5 minutos

Usar quando o investidor so quer uma visao rapida.

```text
0:00 - 0:30  Abertura: ChegaJa organiza servicos locais com confianca.
0:30 - 1:45  Cliente cria pedido por servico/intencao/detalhes.
1:45 - 2:45  Prestador recebe/mostra perfil, categorias e portfolio.
2:45 - 3:45  Trust & Safety: allow/sensitiveReview/block/unknownReview.
3:45 - 5:00  Piloto Maputo + ask 700.000 MZN.
```

Cortar:

- Admin.
- Todos os detalhes de chat.
- Explicacao extensa de catalogo.
- Testes tecnicos.

## Versao aprofundada - 18 a 20 minutos

Usar apenas se houver interesse claro.

Adicionar:

- Perfil publico e @handle.
- Portfolio do Prestador.
- Favoritos/discovery.
- Categorias sensiveis e comprovativos.
- Admin/backoffice leve.
- Detalhe de orcamento min/max.
- Explicacao de risco remanescente server-side/callable antes de producao
  publica ampla.

## Ordem ideal de abas

Preparar antes da chamada:

```text
Aba 1 - Deck ou nota de abertura
Aba 2 - Cliente
Aba 3 - Prestador
Aba 4 - Perfil publico de prestador
Aba 5 - Screenshot/backup de Trust & Safety
```

Evitar:

- Procurar ficheiros durante a chamada.
- Reiniciar servidor ao vivo.
- Abrir logs com erros antigos.
- Mostrar dados contaminados usados em QA.

## Perguntas provaveis durante a demo

### "Ja tem usuarios reais?"

Resposta recomendada:

```text
Ainda nao estamos a vender tracao que nao foi medida. O produto esta em MVP
funcional e o proximo passo e piloto controlado em Maputo para medir pedidos,
resposta, qualidade e repeticao.
```

### "Como ganham dinheiro?"

Resposta recomendada:

```text
O modelo principal pode evoluir para comissao, planos PRO e leads qualificados,
mas a prioridade agora e validar liquidez e confianca. Nao faz sentido forcar
pagamentos antes de provar que clientes pedem e prestadores respondem.
```

### "O que impede conteudo ilegal?"

Resposta recomendada:

```text
O app ja tem politica de admissao: permitido, sensivel, bloqueado e desconhecido
para revisao. Alem disso, dados antigos contaminados sao filtrados antes de
aparecerem, pesquisarem ou fazerem matching. Antes de producao publica ampla, a
proxima camada recomendada e enforcement server-side/callable.
```

### "Por que Maputo primeiro?"

Resposta recomendada:

```text
Porque reduz complexidade operacional. A ideia e validar densidade, resposta e
categorias frequentes numa cidade antes de expandir. Marketplace local precisa
de foco geografico para aprender rapido.
```

### "Por que 700.000 MZN?"

Resposta recomendada:

```text
Porque e um valor suficiente para um piloto serio sem fingir uma rodada grande.
Ele cobre polimento, recrutamento de prestadores, marketing inicial, operacao,
moderacao, suporte, juridico/documentacao e reserva.
```

## Plano de contingencia

Se o app falhar ao vivo:

1. Nao tentar debug tecnico em frente ao investidor.
2. Dizer que ha screenshots e QA recente.
3. Seguir com a narrativa usando imagens.
4. Voltar ao app se estabilizar.

Frase segura:

```text
Como isto ainda e demo local, vou continuar com os screenshots de backup para
nao desperdicarmos a conversa tecnica. O ponto aqui e mostrar o fluxo e a tese
de produto.
```

## Screenshots recomendados para P0.5

Capturar futuramente:

- Home Cliente.
- Novo Pedido com Servico -> Intencao -> Detalhes.
- Pedido por orcamento.
- Discovery/pesquisa de prestadores.
- Perfil publico do prestador.
- Home Prestador.
- Area de atuacao com categorias profissionais.
- Formulario de servico personalizado permitido.
- Estado seguro de Trust & Safety, sem expor termos internos.
- Admin/backoffice leve, se visualmente apresentavel.

## Criterios de sucesso da demo

A demo e bem-sucedida se o investidor entender:

- qual problema local o ChegaJa resolve;
- que existe produto funcional;
- que Cliente e Prestador tem valor claro;
- que o app nao depende so de texto livre fragil;
- que Trust & Safety foi pensado desde o MVP;
- que o pedido de investimento financia piloto e aprendizagem, nao fantasia de
  escala;
- que o proximo passo e medir mercado com pessoas reais.

## Fora do escopo deste P0.2

- Criar PowerPoint final.
- Criar Figma final.
- Criar PDF final.
- Criar video HyperFrames.
- Alterar codigo Dart.
- Alterar Firestore Rules, Storage Rules ou Cloud Functions.
- Fazer deploy.
- Criar dados reais de producao.
- Iniciar M2.21.

## Validacoes

Executadas nesta fase:

```text
git diff --check - passou
npm.cmd run test:scripts - passou
```

## Proximo passo

```text
P0.3 - One-pager para investidor
```
