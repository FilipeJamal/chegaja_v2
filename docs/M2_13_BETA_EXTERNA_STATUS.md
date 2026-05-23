# M2.13 - Beta Externa / Tester Real

Data: 2026-05-23

## Estado

```text
M2.13: iniciada como beta externa / tester real
Bloco R: iniciado
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
R2: FUTURO - tester executa roteiro
R3: FUTURO - recolher bugs reais
R4: FUTURO - classificar bugs
R5: FUTURO - corrigir bloqueadores
R6: FUTURO - decidir se beta externa passa
```

## Proxima Execucao Recomendada

```text
M2.13.1 - Preparar e registar entrega ao tester real
```

Essa execucao deve:

```text
1. Confirmar quem sera o tester.
2. Confirmar plataforma inicial: Web, Windows ou ambas.
3. Confirmar canal de entrega.
4. Registar a data de entrega.
5. Registar o pacote entregue.
6. Garantir que o tester recebeu guia, roteiro, feedback form e bug report.
7. Aguardar ou recolher feedback real.
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
