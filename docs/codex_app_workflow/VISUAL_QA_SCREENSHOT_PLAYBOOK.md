# Playbook de UI com screenshots para o Codex

## Quando usar

Usar sempre que houver:

- tela desalinhada;
- card cortado;
- botão fora do sítio;
- texto ilegível;
- problema de responsividade;
- modal que não cabe;
- loading feio;
- imagem quebrada;
- diferença entre desktop e mobile;
- comportamento estranho depois de uma alteração.

## Como fazer

1. Correr a app.
2. Abrir a tela problemática.
3. Tirar screenshot.
4. Enviar screenshot ao Codex.
5. Descrever o problema em linguagem concreta.
6. Pedir correção limitada.
7. Testar de novo.
8. Fazer commit se ficou bom.

## Prompt recomendado

```txt
Analisa esta screenshot do ChegaJá.

Problema visível:
- [descrever problema 1]
- [descrever problema 2]
- [descrever problema 3]

Objetivo:
Corrigir apenas o layout/visual desta tela.

Regras:
- Não alterar regras Firebase.
- Não alterar estados dos pedidos.
- Não refatorar arquitetura.
- Não mexer em funcionalidades que não aparecem nesta tela.
- Preservar o comportamento atual.

Depois de corrigir:
- Executa `flutter test --no-pub`.
- Explica quais ficheiros alteraste.
- Diz como devo testar manualmente.
```

## Bons exemplos de feedback

Mau:

```txt
Está feio, melhora.
```

Bom:

```txt
O botão “Aceitar pedido” está demasiado encostado ao fundo no mobile.
O card do prestador ficou com altura maior do que o necessário.
O texto do estado está a quebrar em duas linhas quando há espaço.
Corrige apenas espaçamento e alinhamento.
```

## Teste visual mínimo para ChegaJá

Para cada tela alterada, testar:

- largura desktop;
- largura mobile;
- modo Cliente;
- modo Prestador;
- estado vazio;
- estado com dados;
- texto grande;
- loading;
- erro;
- refresh da página.
