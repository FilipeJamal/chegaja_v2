# Beta Interna - Roteiro de Teste

Data base: 2026-05-21

## Objetivo

Validar o ChegaJa como produto real em Web/Windows, percorrendo os fluxos
principais de Cliente e Prestador com tester interno, sem pagamentos reais, sem
Play Store, sem Android fisico real e sem deploy novo.

## Preparacao

Antes de iniciar:

```text
Confirmar o commit/build testado.
Confirmar se o ambiente usa Firebase Emulator Suite ou ambiente controlado.
Confirmar que nao serao usados dados sensiveis, cartoes ou pagamentos reais.
Confirmar que a troca Cliente/Prestador esta disponivel pela UI em Conta/Perfil.
Confirmar que a M2.6 continua pendente de Android fisico real.
```

## Fluxo Cliente

1. Abrir a app como Cliente.
2. Confirmar que Home, categorias e catalogo visual sao compreensiveis.
3. Escolher um servico.
4. Criar pedido imediato, se disponivel.
5. Criar pedido agendado, se disponivel.
6. Criar pedido por orcamento, se disponivel.
7. Confirmar que o pedido aparece na lista.
8. Abrir o detalhe do pedido.
9. Confirmar que "estado" e "proxima acao" sao claros.
10. Acompanhar o estado "aguardando prestador" quando aplicavel.
11. Aceitar proposta/orcamento quando o fluxo apresentar essa acao.
12. Rejeitar proposta quando o fluxo apresentar essa acao.
13. Confirmar valor final quando o fluxo apresentar essa acao.
14. Questionar valor final quando o fluxo apresentar essa acao.
15. Cancelar pedido apenas quando o fluxo permitir.
16. Consultar pedidos concluidos e cancelados.
17. Abrir Mensagens e testar conversa com Prestador quando existir.
18. Abrir Conta/Perfil.
19. Usar "Mudar para modo prestador" e confirmar que a app muda sem editar URL.

## Fluxo Prestador

1. Abrir a app como Prestador.
2. Confirmar que Home, estado online/offline e categorias sao compreensiveis.
3. Mudar estado online/offline.
4. Ver pedidos disponiveis.
5. Aceitar pedido quando disponivel.
6. Ignorar pedido quando aplicavel.
7. Abrir detalhe do pedido.
8. Iniciar servico quando a acao estiver disponivel.
9. Enviar estimativa/orcamento quando aplicavel.
10. Enviar valor final quando aplicavel.
11. Consultar pedidos em curso.
12. Consultar pedidos concluidos e cancelados.
13. Abrir Mensagens e testar conversa com Cliente.
14. Abrir Conta/Perfil.
15. Usar "Mudar para modo cliente" e confirmar que a app muda sem editar URL.

## Mensagens e Chat

Validar em Cliente e Prestador:

```text
lista de conversas abre
pesquisa/filtros nao quebram layout
conversa abre corretamente
mensagem enviada aparece no historico
contador de nao lidas aparece quando houver dado
input nao fica tapado em viewport estreito
```

## Conta e Perfil

Validar em Cliente e Prestador:

```text
cartao de perfil
papel atual
acoes de perfil existentes
definicoes existentes
ajuda/suporte quando disponivel
troca Cliente/Prestador pela UI
ausencia de promessas falsas de pagamento real, KYC real ou documentos reais
```

## Plataformas

Testar no minimo:

```text
Web local/emulador
Web build estatico
Windows debug/build quando disponivel
```

Windows nao substitui Android fisico real. A M2.6 continua pendente.

## Resultado Esperado

```text
Fluxo Cliente principal passa sem bloqueador.
Fluxo Prestador principal passa sem bloqueador.
Pedidos aparecem em lista e detalhe.
Estados e proximas acoes sao compreensiveis.
Mensagens funcionam no fluxo testado.
Troca Cliente/Prestador funciona pela UI.
Bugs restantes ficam classificados e documentados.
```
