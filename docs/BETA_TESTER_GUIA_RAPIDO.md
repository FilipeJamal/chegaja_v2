# ChegaJa Beta - Guia Rapido do Tester

## Objetivo da Beta

Testar o ChegaJa como produto Web/Windows em fluxo Cliente e Prestador.

Esta beta serve para validar se uma pessoa real consegue entender a app, criar
pedidos, responder como prestador, conversar e reportar problemas com contexto.

## O Que Testar

```text
abrir a app
mudar entre Cliente e Prestador pela UI
criar pedido
acompanhar pedido na lista e no detalhe
aceitar/iniciar/concluir pedido como Prestador
testar orcamento/valor final quando aplicavel
testar mensagens
testar conta/perfil
reportar bugs com passos claros
```

## O Que Nao Esta Nesta Beta

```text
pagamentos reais
Play Store
Android fisico real
package id final
HTTPS App Links
release publico
```

## Como Abrir

### Web

```text
1. Abrir o link ou pasta Web indicada no pacote.
2. Confirmar que a primeira tela aparece sem erro bloqueador.
3. Usar a navegacao lateral ou inferior conforme o tamanho da janela.
```

### Windows

```text
1. Abrir a pasta Windows indicada no pacote.
2. Executar o ficheiro .exe da app.
3. Confirmar que a app abre e permite navegar.
```

## Como Mudar Cliente/Prestador

```text
1. Abrir Conta/Perfil.
2. Usar "Mudar para modo prestador" ou "Mudar para modo cliente".
3. Confirmar que a Home mudou para o papel escolhido.
```

O tester nao deve precisar editar URL para mudar de modo.

## Como Reportar Problemas

Para cada problema, enviar:

```text
plataforma: Web ou Windows
papel: Cliente ou Prestador
passos executados
resultado esperado
resultado obtido
screenshot ou video
severidade
frequencia
```

Usar o template:

```text
docs/BETA_TESTER_BUG_REPORT.md
```

## Como Dar Feedback Geral

Usar o template:

```text
docs/BETA_TESTER_FEEDBACK_FORM.md
```

O feedback deve focar clareza, confianca, visual, facilidade de usar e pontos
onde o tester ficou perdido.
