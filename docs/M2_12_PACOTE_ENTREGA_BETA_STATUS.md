# M2.12 - Pacote de Entrega Beta

Data: 2026-05-23

## Estado

```text
M2.12: avancada com pacote de entrega beta Web/Windows preparado
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

## Plano de Execucao

```text
Q1: FECHADO - spec/plano do pacote de entrega beta
Q2: FECHADO - build Web beta preparado
Q3: FECHADO - build Windows beta preparado
Q4: FECHADO - guia rapido para tester
Q5: FECHADO - roteiro simplificado
Q6: FECHADO - template de feedback externo
Q7: FECHADO - checklist de entrega
Q8: FECHADO - pasta/pacote final para tester
```

## Documentos Esperados

```text
docs/BETA_TESTER_GUIA_RAPIDO.md
docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
docs/BETA_TESTER_FEEDBACK_FORM.md
docs/BETA_TESTER_BUG_REPORT.md
docs/BETA_TESTER_CHECKLIST_ENTREGA.md
docs/BETA_TESTER_BUILD_INSTRUCTIONS.md
docs/BETA_TESTER_MANIFEST_ENTREGA.md
```

## Documentos Criados

```text
docs/BETA_TESTER_GUIA_RAPIDO.md:
guia de abertura, contexto da beta, troca Cliente/Prestador e limites da entrega

docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md:
roteiro T01-T08 para testar abertura, pedido, prestador, orcamento, mensagens, conta, cancelamento e no-show

docs/BETA_TESTER_FEEDBACK_FORM.md:
formulario simples para experiencia geral, notas e recomendacoes

docs/BETA_TESTER_BUG_REPORT.md:
template de bug com passos, esperado/obtido, severidade, frequencia e evidencia

docs/BETA_TESTER_CHECKLIST_ENTREGA.md:
checklist para confirmar conteudo, Web, Windows, criterios de aprovacao e limites

docs/BETA_TESTER_BUILD_INSTRUCTIONS.md:
instrucoes tecnicas para gerar/abrir builds Web e Windows

docs/BETA_TESTER_MANIFEST_ENTREGA.md:
manifest do pacote com base, builds, documentos, limitacoes e criterio de entrega
```

## Validacoes Tecnicas Executadas

```text
flutter test: 152/152 passou
npm.cmd run test:scripts: passou
Firestore/Storage/Functions emulator: 68/68 passou
```

## Build Web Beta

Comando executado:

```text
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Resultado:

```text
passou
build/web gerado
build/web/index.html confirmado
```

Observacao:

```text
O Flutter registou avisos de compatibilidade futura com WebAssembly em dart_webrtc.
Esses avisos nao bloquearam o build Web debug e nao fazem parte da entrega funcional atual.
```

## Build Windows Beta

Comando executado:

```text
flutter build windows --debug
```

Resultado:

```text
passou
build/windows/x64/runner/Debug/chegaja_v2.exe gerado
```

## Pacote Local para Tester

```text
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12
```

Conteudo copiado para a pasta local:

```text
BETA_TESTER_GUIA_RAPIDO.md
BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
BETA_TESTER_FEEDBACK_FORM.md
BETA_TESTER_BUG_REPORT.md
BETA_TESTER_CHECKLIST_ENTREGA.md
BETA_TESTER_BUILD_INSTRUCTIONS.md
```

Builds copiados para a pasta local:

```text
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\web_beta_debug
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\windows_beta_debug
```

Confirmacoes locais:

```text
web_beta_debug/index.html: presente
windows_beta_debug/chegaja_v2.exe: presente
```

Os builds foram copiados para a pasta local de entrega, mas nao foram versionados no Git.

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

## Validacao Final

```text
git diff --check: passou
```

## Limitacoes Mantidas

```text
Android fisico real continua pendente da M2.6.
Pagamentos reais continuam fora do escopo.
Play Store continua fora do escopo.
Package id final continua fora do escopo.
HTTPS App Links continuam fora do escopo.
Deploy real, smoke real, cleanup real e health real nao foram executados nesta fase.
```

## Decisao

```text
M2.12 avancada: o Bloco Q esta preparado para entrega beta Web/Windows a tester real.
Proximo bloco oficial: R - Beta externa / tester real.
```
