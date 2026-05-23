# ChegaJa Beta - Instrucoes de Build

## Web

Gerar build:

```powershell
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Saida esperada:

```text
build/web
```

Validacao rapida:

```powershell
Test-Path build\web\index.html
```

Resultado esperado:

```text
True
```

## Windows

Gerar build:

```powershell
flutter build windows --debug
```

Saida esperada:

```text
build/windows/x64/runner/Debug
```

Validacao rapida:

```powershell
Get-ChildItem build\windows\x64\runner\Debug -Filter *.exe
```

Resultado esperado:

```text
um executavel da app aparece na pasta
```

## Validacoes Antes da Entrega

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

## Artefatos

```text
Builds gerados ficam em build/ e nao devem ser commitados.
Documentos do tester ficam em docs/ e devem ser versionados.
Pasta local de entrega pode ser montada em C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12.
```

## Pasta Local da Entrega M2.12

```text
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\web_beta_debug
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12\windows_beta_debug
```

Esta pasta e o pacote local para tester. Os builds dentro dela nao sao versionados no Git.

## Limitacoes

```text
Android fisico real continua pendente da M2.6.
Pagamentos reais nao fazem parte desta beta.
Play Store nao faz parte desta beta.
Package id final e HTTPS App Links nao fazem parte desta beta.
Deploy real so deve ocorrer com decisao explicita.
```
