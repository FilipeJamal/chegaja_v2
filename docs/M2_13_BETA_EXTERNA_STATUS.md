# M2.13 - Beta Externa / Tester Real

Data: 2026-05-23

## Estado

```text
M2.13: em preparacao para beta externa / tester real
Bloco R: iniciado
M2.13.1: preparada entrega ao tester, aguardando dados reais de envio
M2.13.2: beta solo assistida por Playwright executada, sem fechar entrega real
M2.12: pacote de entrega beta Web/Windows preparado
M2.11: fechada como beta interna controlada Web/Windows
M2.6: continua pendente de Android fisico real
```

## Base

Commit de referencia:

```text
6239f70 Avancar M2.12 pacote entrega beta
```

Pacote local de entrega herdado:

```text
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12
```

Conteudo confirmado na M2.12:

```text
web_beta_debug
windows_beta_debug
BETA_TESTER_GUIA_RAPIDO.md
BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
BETA_TESTER_FEEDBACK_FORM.md
BETA_TESTER_BUG_REPORT.md
BETA_TESTER_CHECKLIST_ENTREGA.md
BETA_TESTER_BUILD_INSTRUCTIONS.md
BETA_TESTER_MANIFEST_ENTREGA.md
```

## Spec

```text
docs/superpowers/specs/2026-05-23-m2-13-beta-externa-tester-real-design.md
```

## Objetivo

Executar uma beta externa controlada com tester real em Web/Windows, usando o pacote M2.12, e decidir com evidencia se a beta externa passa, reprova ou precisa de correcao de bloqueadores.

## Estado do Bloco R

```text
R1: PROXIMO - entregar app ao tester
R2: FUTURO - tester real executa roteiro
R3: FUTURO - recolher bugs reais
R4: FUTURO - classificar bugs
R5: FUTURO - corrigir bloqueadores
R6: FUTURO - decidir se beta externa passa
```

## M2.13.1 - Preparacao da Entrega

```text
Estado: preparada
Entrega real: pendente
Motivo: tester/canal/plataforma ainda nao foram informados
```

A M2.13.1 preparou:

```text
1. Verificacao local do pacote M2.12.
2. Registo de entrega pronto para preencher.
3. Mensagem pronta para enviar ao tester.
4. Confirmacao de que R1 nao deve ser fechado sem envio real.
```

## Proxima Execucao Recomendada

```text
M2.13.3 - Registar entrega real ao tester
```

Essa execucao deve receber do responsavel humano:

```text
tester
canal de entrega
plataforma entregue: Web, Windows ou ambas
data/hora de envio
prazo esperado de retorno
confirmacao de que o tester recebeu os documentos
```

## M2.13.2 - Beta Solo Assistida por Playwright

```text
Estado: executada
Tipo: beta solo assistida por IA/Playwright
Resultado: aprovada tecnicamente
Entrega real a tester: ainda pendente
```

Motivo:

```text
Nao havia tester humano disponivel no momento. Para nao bloquear a validacao,
foi executado um roteiro solo assistido por Playwright usando os fluxos E2E
ja aprovados da M2.11/M2.12.
```

Ambiente usado:

```text
Build Web estatico: build/web
Servidor local: http://127.0.0.1:5174
Emuladores: auth, firestore, storage, functions
Target E2E: http://127.0.0.1:5174
```

Observacao de ambiente:

```text
O alvo debug flutter run -d web-server em http://127.0.0.1:5173 carregou
HTML/DDC, mas nao montou a UI Flutter no Chromium Playwright dentro do tempo
esperado. O build Web estatico em http://127.0.0.1:5174 montou corretamente.
Isto foi tratado como limitacao de ambiente debug/DDC, nao como bug funcional
do produto.
```

Evidencia funcional:

```text
npm.cmd run e2e:ui:dual: passou
Resultado: FULL MULTI-SCENARIO FLOW OK
Cenarios: happy-path, cancelamento Cliente, convite manual Prestador, chat bidirecional, no-show Prestador
Screenshots: C:\Users\Jamal\AppData\Local\Temp\chegaja-m2132-beta-solo\screenshots\2026-05-27T08-52-18-042Z

npm.cmd run e2e:ui:orcamento: passou
Resultado: ORCAMENTO MIN-MAX FLOW OK
Cenarios: pedido por orcamento, proposta min/max, aceite Cliente, valor final, conclusao
Screenshots: C:\Users\Jamal\AppData\Local\Temp\chegaja-m2132-beta-solo\screenshots\2026-05-27T09-04-35-468Z
```

Evidencia visual:

```text
Matriz visual capturada:
C:\Users\Jamal\AppData\Local\Temp\chegaja-m2132-beta-solo\visual_matrix

Telas:
- Home Cliente mobile/tablet/desktop/wide
- Home Prestador mobile/tablet/desktop/wide
```

Notas runtime:

```text
Foram registados avisos esperados de WebGL/Firestore Listen abortado durante
trocas de pagina/contexto do Playwright.

Tambem surgiram logs iniciais de timeout no bootstrap Auth, mas o login anonimo
recuperou e os dois roteiros terminaram com sucesso ponta a ponta. Fica como
observacao tecnica para monitorizacao futura, nao como bloqueador desta beta
solo.
```

Decisao:

```text
A beta solo assistida por Playwright fica aprovada tecnicamente.
A beta externa real continua pendente, porque nenhum tester humano recebeu ou
executou o pacote.
R1 nao foi fechado.
```

## Fora do Escopo Mantido

```text
backend novo
Firestore Rules novas sem bug real comprovado
Storage Rules novas
Cloud Functions novas
deploy real
smoke real
cleanup real
health real
Android fisico real
pagamentos reais
Play Store
package id final
HTTPS App Links
fechar M2.6
novas funcionalidades grandes
redesign visual amplo
```

## Validacao Inicial

```text
git diff --check: passou
```
