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
M2.13.4 - Registar envio real e feedback inicial do tester
```

## Criterio de Fecho de R1

R1 nao pode ser fechado apenas por testes automatizados.

Para fechar R1, e necessario:

```text
1. tester humano recebe link/pacote;
2. tester confirma que conseguiu abrir ou recebeu instrucoes suficientes;
3. tester executa pelo menos os fluxos principais;
4. feedback e registado;
5. bugs bloqueantes sao classificados;
6. decisao final e documentada.
```

## M2.13.3 - Preparacao da Entrega Real

Data: 2026-05-27

```text
Resultado: documentacao preparada
Entrega real: pendente
R1: pendente
```

Documentos criados:

```text
docs/BETA_EXTERNA_ENTREGA_TESTER.md
docs/BETA_EXTERNA_INSTRUCOES_TESTER.md
docs/BETA_EXTERNA_FEEDBACK_TEMPLATE.md
```

Decisao:

```text
A M2.13.3 deixa a entrega pronta para o tester real, mas nao declara execucao
humana. A beta externa real continua pendente.
```
