# Beta Externa - Bugs Reportados

Data de abertura: 2026-05-23

## Estado

```text
Nenhum bug externo reportado ainda.
Beta externa ainda nao foi executada por tester real.
Beta solo assistida por Playwright foi executada em 2026-05-27 sem bug funcional bloqueador.
```

## Formato de Registo

Cada bug deve ser registado neste formato:

```text
ID:
Data:
Tester:
Plataforma: Web / Windows
Papel: Cliente / Prestador
Severidade: bloqueador / alto / medio / baixo
Frequencia: sempre / as vezes / uma vez
Estado: aberto / em analise / corrigido / adiado

Passos:
1.
2.
3.

Resultado esperado:

Resultado obtido:

Evidencia:

Notas tecnicas:
```

## Bugs

```text
Sem bugs registados.
```

## Observacoes Tecnicas da Beta Solo

```text
Data: 2026-05-27
Tipo: observacao tecnica, nao bug externo
Estado: documentado
```

### M2.13-SOLO-ENV-001 - Debug web-server nao montou no Playwright

```text
Severidade: baixa
Impacto: ambiente de QA automatizado
Estado: contornado com build Web estatico

Resumo:
O alvo http://127.0.0.1:5173 servido por flutter run -d web-server carregou
HTML/DDC, mas nao montou a UI Flutter no Chromium Playwright no tempo esperado.
O build Web estatico servido em http://127.0.0.1:5174 montou corretamente e
permitiu executar os roteiros E2E.

Decisao:
Nao classificar como bug funcional do produto nesta fase. Para beta solo e
entrega Web, usar build estatico.
```

### M2.13-SOLO-RUNTIME-001 - Bootstrap Auth com timeout inicial recuperavel

```text
Severidade: baixa
Impacto: logs durante E2E
Estado: monitorizar

Resumo:
Durante os roteiros Playwright surgiram logs iniciais de timeout no bootstrap
Auth, mas os UIDs foram obtidos, o login anonimo recuperou e os fluxos dual e
orcamento terminaram ponta a ponta.

Decisao:
Nao bloqueia a beta solo. Manter observacao para investigar se reaparecer em
teste humano ou ambiente de entrega real.
```
