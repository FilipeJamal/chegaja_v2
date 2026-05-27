# Workflow Codex App extraído do vídeo e adaptado ao ChegaJá

## 1. O vídeo não mostra apenas “coding”; mostra produto inteiro

O ponto forte do vídeo é que o autor não usa o Codex apenas para escrever código. Ele usa o Codex para:

- Criar conceito visual.
- Gerar assets.
- Scaffolding de app.
- Implementar comportamento.
- Testar no simulador.
- Corrigir bugs com screenshots.
- Priorizar funcionalidades a partir de feedback real.
- Melhorar marketing/copy.

Para o ChegaJá, isto significa que o Codex deve ajudar em:

- Código Flutter.
- Firebase/Functions.
- Fluxos Cliente/Prestador.
- UX.
- Textos das telas.
- Testes.
- Documentação.
- Deploy.
- Preparação comercial do app.

## 2. Prototipar antes de mexer no app principal

No vídeo, antes de trabalhar no app real, ele cria uma app pequena de timer de chá para validar design, layout e comportamento.

No ChegaJá, isto deve virar regra:

Antes de mexer em telas críticas como:
- Home Cliente
- Home Prestador
- Detalhe do Pedido
- Chat
- Pedidos por orçamento
- Notificações/deep link
- Dashboard de ganhos
- Conta/Planos PRO

o Codex deve, quando fizer sentido, criar primeiro:
- Um protótipo visual isolado.
- Um widget novo sem ligar a Firestore.
- Um teste/widget demo.
- Uma tela de sandbox.
- Ou uma alteração pequena e reversível.

## 3. Screenshots são ferramentas de debugging

No vídeo, quando a UI fica errada, o autor tira screenshot e diz ao Codex exatamente o que está errado.

No ChegaJá, quando uma tela ficar errada, o prompt certo não é:

> “Corrige a UI.”

O prompt certo é:

> “Nesta screenshot, o card está demasiado baixo, o botão ficou cortado, o texto não respeita o espaçamento antigo e o layout mobile quebrou. Corrige apenas este problema, sem alterar a lógica do pedido.”

## 4. Testar cenários, não apenas compilar

No vídeo, o autor não fica satisfeito quando a app abre. Ele testa:
- fullscreen;
- rato fora do ecrã;
- rato noutro monitor;
- settings panel;
- input inválido;
- reset;
- diferentes modos.

No ChegaJá, cada funcionalidade deve ter uma pequena matriz de cenários.

Exemplo para pedido imediato:

- Cliente cria pedido.
- Prestador vê pedido.
- Prestador aceita.
- Cliente vê estado atualizado.
- Prestador inicia.
- Prestador conclui.
- Ganhos atualizam.
- Cliente não consegue editar pedido depois de aceito.
- Cancelamento funciona só nos estados corretos.
- App não quebra em refresh.

## 5. Não acumular mudanças demais

No vídeo, depois de conseguir uma melhoria estável, o autor quer fazer commit antes de continuar, porque está preocupado que novas alterações quebrem algo.

No ChegaJá, isto é obrigatório:

Quando uma mudança estiver estável:
- correr testes;
- verificar `git status`;
- fazer commit;
- só depois avançar para a próxima melhoria.

## 6. Codex precisa de direção em UI

O vídeo deixa claro que a IA pode ser muito forte, mas em UI pode quebrar layout ou interpretar mal espaçamentos.

No ChegaJá:
- Nunca pedir “melhora a UI toda”.
- Pedir por tela, por componente, por comportamento.
- Usar screenshots.
- Preservar lógica.
- Pedir para não refatorar tudo.
- Testar desktop e mobile quando a tela for responsiva.

## 7. Método recomendado para o Filipe

Para cada tarefa nova:

1. Explicar objetivo em linguagem simples.
2. Dizer qual é a tela/fluxo.
3. Dizer o que não pode mudar.
4. Pedir plano curto.
5. Pedir implementação pequena.
6. Rodar app/testes.
7. Enviar screenshot/erro ao Codex.
8. Mandar corrigir ponto específico.
9. Fazer commit.
10. Só depois pedir a próxima melhoria.
