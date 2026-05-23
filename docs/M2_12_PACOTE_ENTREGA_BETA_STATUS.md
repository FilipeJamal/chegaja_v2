# M2.12 - Pacote de Entrega Beta

Data: 2026-05-22

## Estado

```text
M2.12: iniciada com spec de pacote de entrega beta
M2.11: fechada como beta interna controlada Web/Windows
M2.6: continua pendente de Android fisico real
```

## Base

Commit de referencia:

```text
296d4bd Fechar M2.11 beta interna controlada
```

Estado herdado da M2.11:

```text
Beta Web automatizada: aprovada
Windows tecnico: aprovado
e2e:ui:dual: FULL MULTI-SCENARIO FLOW OK
e2e:ui:orcamento: ORCAMENTO MIN-MAX FLOW OK
flutter test: 152/152 passou
Firestore/Storage/Functions emulator: 68/68 passou
```

## Objetivo

Preparar um pacote de entrega beta para tester real, com:

```text
build Web beta
build Windows beta
guia rapido do tester
roteiro simplificado Cliente/Prestador
template de feedback
template de bug
criterios de aprovacao/reprovacao
limitacoes conhecidas
```

## Spec

```text
docs/superpowers/specs/2026-05-22-m2-12-pacote-entrega-beta-design.md
```

## Roadmap Oficial

O roadmap oficial atual do projeto passa a ser o mapa A-T:

```text
docs/ROADMAP_A_T_CHEGAJA.md
```

Neste mapa, a M2.12 corresponde ao Bloco Q:

```text
Q - Pacote de entrega beta para tester real
```

## Plano

```text
docs/superpowers/plans/2026-05-23-m2-12-pacote-entrega-beta.md
```

Ordem planeada:

```text
1. Consolidar estrutura da entrega beta.
2. Criar guia rapido para tester.
3. Criar roteiro simplificado Cliente/Prestador.
4. Criar templates de feedback e bug report.
5. Criar checklist e instrucoes de build.
6. Rodar validacoes tecnicas.
7. Gerar build Web beta.
8. Gerar build Windows beta.
9. Montar manifest do pacote final para tester.
10. Atualizar status e roadmap.
```

## Documentos Esperados

```text
docs/BETA_TESTER_GUIA_RAPIDO.md
docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
docs/BETA_TESTER_FEEDBACK_FORM.md
docs/BETA_TESTER_BUG_REPORT.md
```

## Fora do Escopo

```text
backend novo
Firestore Rules novas
Storage Rules novas
Cloud Functions novas
deploy real sem decisao explicita
smoke real
cleanup real
health real
pagamentos reais
Play Store
Android fisico real
fechar M2.6
novas funcionalidades grandes
```

## Validacao Inicial

```text
git diff --check: passou
```
