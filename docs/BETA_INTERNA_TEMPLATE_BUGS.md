# Beta Interna - Template de Feedback e Bugs

Data do teste:
Tester:
Commit/build testado:
Plataforma: Web / Windows
Papel: Cliente / Prestador / ambos

## Resumo da Sessao

```text
Fluxo Cliente: passou / bloqueado / nao testado
Fluxo Prestador: passou / bloqueado / nao testado
Mensagens: passou / bloqueado / nao testado
Conta/Perfil: passou / bloqueado / nao testado
Troca Cliente/Prestador pela UI: passou / bloqueado / nao testado
Build Web: passou / bloqueado / nao testado
Build Windows: passou / bloqueado / nao testado
```

## Registo de Bug

```text
ID do teste:
Titulo:
Papel: Cliente / Prestador / ambos
Plataforma: Web / Windows / ambos
Fluxo:
Frequencia: sempre / as vezes / uma vez
Severidade: bloqueador / alto / medio / baixo
Estado: aberto / em analise / corrigido / adiado
```

### Passos Executados

1.
2.
3.

### Resultado Esperado

```text
Descrever o que deveria acontecer.
```

### Resultado Obtido

```text
Descrever exatamente o que aconteceu.
```

### Evidencia

```text
Screenshot, video, log, URL local, viewport ou nota visual.
```

### Observacoes

```text
Contexto adicional, workaround usado ou impacto percebido pelo tester.
```

## Escala de Severidade

```text
Bloqueador: impede concluir fluxo principal Cliente/Prestador.
Alto: quebra acao importante, estado do pedido, dados ou permissao.
Medio: confusao de UX, texto ruim, visual quebrado ou workaround necessario.
Baixo: polish, copy, ajuste visual sem impacto forte.
```

## Criterios de Aprovacao

A beta interna pode ser aprovada se:

```text
fluxo Cliente/Prestador principal passa
criacao de pedido funciona
aceitar/iniciar/concluir funciona
orcamento/valor final funciona
mensagens funcionam
troca de modo funciona pela UI
Web e Windows abrem sem bloqueio
nao ha bug bloqueador
nao ha erro visual grave
testes tecnicos passam
bugs medios/baixos ficam documentados
```

## Criterios de Reprovacao

A beta interna reprova se:

```text
Cliente nao consegue criar pedido
Prestador nao consegue aceitar pedido
pedido nao muda de estado corretamente
valor final/conclusao falha
app crasha em fluxo principal
troca Cliente/Prestador nao funciona
Web ou Windows nao abre
mensagens quebram fluxo principal
ha bug de seguranca ou permissao evidente
ha overflow/erro visual que impede uso
```
