# Ciclo de funcionalidade para o ChegaJá

Usa este ciclo para qualquer nova funcionalidade.

## Fase 1 — Intenção

Responder:

- O que queremos melhorar?
- Quem usa? Cliente, Prestador, Admin ou ambos?
- Qual dor resolve?
- Qual é o resultado visível na app?

Exemplo:

> Queremos melhorar o fluxo de pedido por orçamento. O Cliente cria pedido sem preço fechado, o Prestador aceita interesse, envia proposta, e o Cliente aceita ou recusa.

## Fase 2 — Escopo pequeno

Definir o primeiro MVP.

Não construir a funcionalidade perfeita de uma vez.

Exemplo de MVP:

- Prestador consegue enviar proposta simples com valor e mensagem.
- Cliente vê proposta e aceita/recusa.
- Estado muda corretamente.
- Testes básicos passam.

Fica fora do MVP:

- Chat completo.
- Pagamento online.
- Histórico avançado.
- Várias propostas concorrentes.
- Ranking inteligente.

## Fase 3 — Ficheiros prováveis

Antes de editar, o Codex deve listar os ficheiros prováveis.

Exemplo:

- `lib/features/cliente/...`
- `lib/features/prestador/...`
- `lib/features/pedidos/...`
- `lib/core/models/pedido.dart`
- `lib/core/repositories/pedidos_repository.dart`
- `test/...`

## Fase 4 — Implementação pequena

O Codex deve alterar o mínimo necessário para atingir o MVP.

Não fazer:
- redesign completo;
- renomeação global;
- mudança de arquitetura;
- migração complexa;
- alteração de regras Firebase sem necessidade.

## Fase 5 — Teste manual orientado

O Codex deve explicar como testar em duas janelas:

- Janela Cliente.
- Janela Prestador.
- Passo a passo.
- Resultado esperado em cada tela.

## Fase 6 — Testes automatizados

Quando aplicável, adicionar ou atualizar:

- unit tests;
- widget tests;
- integration tests;
- tests de Functions;
- tests de scripts.

## Fase 7 — Commit seguro

Só fazer commit quando:

- app compila;
- testes relevantes passam;
- fluxo principal foi testado;
- `git status` está compreensível;
- relatório final está claro.

Mensagem de commit:

```txt
Avancar <milestone> <descrição curta>
```

Exemplo:

```txt
Avancar M2.9 proposta prestador cliente
```
