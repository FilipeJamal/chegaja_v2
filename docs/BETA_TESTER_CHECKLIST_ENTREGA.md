# ChegaJa Beta - Checklist de Entrega

## Antes de Entregar

```text
flutter test passou
npm.cmd run test:scripts passou
Firebase emulator tests passaram
build Web gerado
build Windows gerado
guia rapido incluido
roteiro simplificado incluido
feedback form incluido
bug report incluido
limitacoes conhecidas comunicadas
```

## Conteudo do Pacote

```text
build Web ou link de acesso
build Windows ou caminho do executavel
docs/BETA_TESTER_GUIA_RAPIDO.md
docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
docs/BETA_TESTER_FEEDBACK_FORM.md
docs/BETA_TESTER_BUG_REPORT.md
docs/BETA_TESTER_BUILD_INSTRUCTIONS.md
```

## Checklist Web

```text
app abre no browser
navegacao principal funciona
troca Cliente/Prestador funciona
criar pedido funciona
pedidos/lista/detalhe abrem
mensagens abrem
conta/perfil abre
sem erro visual bloqueador
```

## Checklist Windows

```text
executavel abre
layout desktop utilizavel
inputs recebem foco
navegacao principal funciona
troca Cliente/Prestador funciona
pedidos/mensagens/conta abrem
sem erro visual bloqueador
```

## Criterio de Aprovacao

```text
tester abre a app
tester alterna Cliente/Prestador
tester cria pedido
tester testa mensagens
tester testa orcamento/valor final
nao ha bug bloqueador
bugs medios/baixos ficam documentados
```

## Criterio de Reprovacao

```text
app nao abre
tester nao consegue alternar Cliente/Prestador
Cliente nao consegue criar pedido
Prestador nao consegue aceitar/iniciar pedido
mensagens quebram fluxo principal
orcamento/valor final bloqueia conclusao
ha crash em fluxo principal
ha erro visual que impede uso
```

## Limitacoes Conhecidas

```text
Android fisico real continua pendente da M2.6
pagamentos reais fora do escopo
Play Store fora do escopo
package id final fora do escopo
HTTPS App Links fora do escopo
deploy real depende de decisao explicita
```
