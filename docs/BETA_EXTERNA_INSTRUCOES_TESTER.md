# Beta Externa - Instrucoes para Tester

Data de criacao: 2026-05-27

## Objetivo do Teste

Usar o ChegaJa como uma pessoa real usaria, procurando problemas, partes
confusas, botoes que nao funcionam, erros visuais, lentidao ou qualquer coisa
que atrapalhe o fluxo.

Nao ha resposta certa ou errada. O objetivo e descobrir o que precisa melhorar
antes de abrir a app para mais pessoas.

## Antes de Comecar

Confirmar:

```text
Recebeste o link/pacote da beta.
Consegues abrir a app.
Sabes se vais testar Web, Windows ou ambas.
Tens este documento e o template de feedback.
```

## Como Testar como Cliente

1. Abrir a app.
2. Entrar no modo Cliente, se a app perguntar.
3. Ver se a Home Cliente esta clara.
4. Escolher um servico.
5. Criar um pedido imediato.
6. Ver se o pedido aparece nos pedidos ativos.
7. Abrir o detalhe do pedido.
8. Enviar uma mensagem no chat, se o fluxo permitir.
9. Cancelar um pedido e confirmar se o estado muda.

## Como Testar Pedido por Orcamento

1. Criar um pedido por orcamento.
2. Mudar para modo Prestador pela UI.
3. Procurar o pedido.
4. Aceitar ou abrir o pedido.
5. Enviar proposta/orcamento.
6. Voltar para modo Cliente.
7. Ver a proposta.
8. Aceitar ou rejeitar a proposta.
9. Continuar ate valor final, se o fluxo estiver disponivel.

## Como Testar como Prestador

1. Mudar para modo Prestador pela UI.
2. Ver a Home Prestador.
3. Mudar disponibilidade online/offline, se estiver disponivel.
4. Ver pedidos disponiveis.
5. Abrir um pedido.
6. Aceitar ou ignorar pedido, se o fluxo permitir.
7. Iniciar servico.
8. Enviar valor final ou orcamento quando aplicavel.
9. Ver se o pedido muda de estado corretamente.

## Como Testar Mensagens

1. Abrir Mensagens.
2. Confirmar se a lista abre sem erro.
3. Abrir uma conversa.
4. Enviar uma mensagem simples.
5. Verificar se a mensagem aparece no lado correto.
6. Se estiveres a testar com outra pessoa, confirmar se a outra pessoa recebeu.

## Como Testar Conta e Perfil

1. Abrir Conta/Perfil.
2. Ver se o nome, papel e informacoes principais fazem sentido.
3. Testar o botao de mudar entre Cliente e Prestador.
4. Ver se a app muda de modo sem perder sessao.
5. Registar qualquer texto confuso ou botao que pareca quebrado.

## O que Reportar

Reportar qualquer caso destes:

```text
app nao abre
botao nao funciona
tela fica em branco
pedido nao aparece
estado do pedido fica errado
chat nao envia mensagem
texto ou card fica cortado
algo fica confuso
erro aparece no ecra
app fica lenta ou bloqueada
```

Sempre que possivel, enviar screenshot ou video curto.

## O que Nao Faz Parte Desta Beta

```text
Pagamentos reais.
Play Store.
Android fisico real.
Package id final.
HTTPS App Links.
Funcionalidades fora do roteiro.
```
