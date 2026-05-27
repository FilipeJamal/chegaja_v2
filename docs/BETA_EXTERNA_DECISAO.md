# Beta Externa - Decisao

Data de abertura: 2026-05-23

## Estado Atual

```text
Decisao: pendente
Motivo: beta externa ainda nao foi executada por tester real.
Beta solo assistida por Playwright foi aprovada tecnicamente, mas nao substitui teste humano.
```

## Criterios para Aprovar

```text
tester consegue abrir a app
tester entende como usar Cliente e Prestador
fluxo principal Cliente/Prestador passa sem bloqueio
mensagens funcionam no uso real
pedido/orcamento/valor final funcionam no uso real
nao ha bug bloqueador
bugs medios/baixos ficam documentados
```

## Criterios para Reprovar

```text
tester nao consegue abrir a app
tester nao consegue criar pedido
prestador nao consegue aceitar/iniciar pedido
mensagens impedem fluxo principal
troca Cliente/Prestador nao funciona
crash ou erro visual impede uso
ha bug de permissao/seguranca evidente
```

## Decisao Final

Preencher apos execucao da beta externa:

```text
Resultado: aprovada / aprovada com pendencias / reprovada
Resumo dos testes:
Bugs bloqueadores:
Bugs altos:
Bugs medios/baixos:
Proximo passo recomendado:
```

## Decisao Parcial - Beta Solo Assistida

Data: 2026-05-27

```text
Resultado: beta solo assistida aprovada tecnicamente
Escopo: Web local com build estatico + emuladores Firebase
Tester humano: nao executado
Beta externa real: pendente
```

Evidencia:

```text
npm.cmd run e2e:ui:dual: passou
FULL MULTI-SCENARIO FLOW OK

npm.cmd run e2e:ui:orcamento: passou
ORCAMENTO MIN-MAX FLOW OK

Matriz visual local capturada:
Home Cliente mobile/tablet/desktop/wide
Home Prestador mobile/tablet/desktop/wide
```

Decisao:

```text
Nao fechar beta externa real.
Nao fechar R1.
Usar esta execucao como validacao solo antes de entregar o pacote a uma pessoa real.
```

Proximo passo recomendado:

```text
M2.13.3 - Registar entrega real ao tester
```
