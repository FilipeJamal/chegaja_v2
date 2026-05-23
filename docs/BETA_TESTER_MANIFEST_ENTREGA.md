# Manifest da Entrega Beta - ChegaJa M2.12

Data: 2026-05-23

## Base da Entrega

```text
Roadmap: Bloco Q - Pacote de entrega beta para tester real
Commit base da execucao: ecfeb5d Planear M2.12 pacote entrega beta
M2.10: fechada como Visual Product System
M2.11: fechada como beta interna Web/Windows
M2.12: pacote de entrega beta preparado
M2.6: continua pendente de Android fisico real
```

## Builds Gerados

```text
Web beta debug:
build/web
build/web/index.html confirmado

Windows beta debug:
build/windows/x64/runner/Debug/chegaja_v2.exe
```

## Documentos Incluidos

```text
docs/BETA_TESTER_GUIA_RAPIDO.md
docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
docs/BETA_TESTER_FEEDBACK_FORM.md
docs/BETA_TESTER_BUG_REPORT.md
docs/BETA_TESTER_CHECKLIST_ENTREGA.md
docs/BETA_TESTER_BUILD_INSTRUCTIONS.md
docs/BETA_TESTER_MANIFEST_ENTREGA.md
```

## Pasta Local de Entrega

```text
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12
```

Conteudo local preparado:

```text
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\web_beta_debug
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\windows_beta_debug
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\BETA_TESTER_GUIA_RAPIDO.md
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\BETA_TESTER_FEEDBACK_FORM.md
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\BETA_TESTER_BUG_REPORT.md
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\BETA_TESTER_CHECKLIST_ENTREGA.md
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\BETA_TESTER_BUILD_INSTRUCTIONS.md
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\BETA_TESTER_MANIFEST_ENTREGA.md
```

Os builds foram copiados para a pasta local de entrega, mas continuam fora do Git.

## Validacoes da Entrega

```text
flutter test: 152/152 passou
npm.cmd run test:scripts: passou
Firestore/Storage/Functions emulator: 68/68 passou
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true: passou
flutter build windows --debug: passou
```

## Limitacoes Conhecidas

```text
Android fisico real continua pendente da M2.6.
Pagamentos reais continuam fora do escopo.
Play Store continua fora do escopo.
Package id final continua fora do escopo.
HTTPS App Links continuam fora do escopo.
Deploy real, smoke real, cleanup real e health real nao foram executados nesta fase.
```

## Criterio de Entrega

O pacote esta pronto para ser entregue a um tester real em Web/Windows quando:

```text
1. O tester recebe o guia rapido.
2. O tester recebe o roteiro simplificado.
3. O tester recebe o template de feedback.
4. O tester recebe o template de bug.
5. O tester sabe que Android fisico e pagamentos reais nao fazem parte desta beta.
6. O responsavel tecnico disponibiliza o build Web ou Windows conforme o ambiente de teste escolhido.
```
