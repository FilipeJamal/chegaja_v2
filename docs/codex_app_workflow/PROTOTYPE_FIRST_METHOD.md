# Método Prototype First para o ChegaJá

## Ideia

Quando a funcionalidade for incerta, frágil ou visual, não mexer diretamente no fluxo principal.

Primeiro criar um protótipo pequeno.

## Quando usar

Usar em:

- Chat estilo Instagram.
- Nova Home Cliente.
- Nova Home Prestador.
- Cards de pedidos.
- Tela de proposta/orçamento.
- Portfólio do prestador.
- Planos PRO.
- Dashboard de ganhos.
- Perfil público do prestador.
- Sistema de filtros/categorias.
- Fluxo de agendamento.

## Tipos de protótipo

### 1. Widget isolado

Criar um widget visual sem Firestore.

Exemplo:

```txt
lib/features/dev_sandbox/widgets/proposta_card_preview.dart
```

### 2. Tela sandbox

Criar uma rota temporária apenas para visualizar.

Exemplo:

```txt
lib/features/dev_sandbox/screens/chegaja_ui_lab_screen.dart
```

### 3. Dados mockados

Usar dados falsos para testar layout antes de ligar ao backend.

### 4. Spike documentado

Criar uma pequena experiência e documentar resultado em:

```txt
docs/spikes/
```

## Regra

Protótipo não é produto final.

Depois de validar:
- retirar código morto;
- integrar no fluxo real;
- testar;
- fazer commit.

## Prompt para Codex

```txt
Quero fazer um protótipo pequeno antes de mexer no fluxo real.

Funcionalidade:
[descrever]

Objetivo do protótipo:
[descrever o que quero ver/aprender]

Regras:
- Não ligar ainda a Firestore.
- Não alterar fluxo Cliente/Prestador real.
- Criar dados mockados.
- Criar widget/tela isolada.
- Permitir testar visualmente.
- No fim, explicar como integrar no fluxo real.

Depois:
- correr `flutter test --no-pub`;
- não fazer commit sem eu validar o visual.
```
