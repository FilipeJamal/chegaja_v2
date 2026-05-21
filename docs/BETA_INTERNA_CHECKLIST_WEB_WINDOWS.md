# Beta Interna - Checklist Web/Windows

Data base: 2026-05-21

## Pre-check

```cmd
git branch --show-current
git status --short
git log -1 --oneline
```

Esperado:

```text
branch main
sem alteracoes inesperadas alem de temporarios conhecidos fora do commit
commit correto da beta no topo
```

## Validacoes Tecnicas

```cmd
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter build windows --debug
```

Se `flutter build windows --debug` nao for o comando correto para o ambiente,
usar o equivalente atual e documentar o comando executado.

## Web

Validar:

```text
Web local/emulador abre
Web build estatico abre
login/Auth anonimo funciona
Firestore emulador funciona
Storage emulador funciona quando aplicavel
navegacao por tabs funciona
sidebar desktop funciona
bottom navigation em viewport estreito funciona
responsividade basica sem overflow critico
nenhum botao principal fica escondido
troca Cliente/Prestador pela UI funciona
Mensagens funciona
Pedidos funciona
Conta/Perfil funciona
```

## Windows

Validar:

```text
Windows debug/build abre
layout desktop continua utilizavel
sidebar nao fica estreita ou vazia demais
scroll funciona
inputs recebem foco
SVGs e icones renderizam
pedidos/listas/detalhe abrem
mensagens abrem
conta/perfil abre
troca Cliente/Prestador pela UI funciona
```

## Proibido Nesta Fase

```text
deploy Firebase real
smoke real em producao
cleanup real
health real
pagamentos reais
Play Store
Android fisico real
fechar M2.6
backend novo
Firestore Rules novas
Storage Rules novas
Cloud Functions novas
```

## Evidencia a Registar

```text
data/hora
commit testado
plataforma
comandos executados
resultado de cada comando
prints ou videos quando houver bug visual
bloqueios ambientais
bugs encontrados
decisao final: aprovado / reprovado / aprovado com pendencias
```

## Execucao 2026-05-21 - M2.11.1

Commit base:

```text
42841ff Avancar M2.11 pacote beta interna
```

Resultado do checklist:

```text
Pre-check: passou, com alteracoes antigas fora do escopo mantidas fora do commit
flutter test: passou, 149/149
npm.cmd run test:scripts: passou
Firestore/Storage/Functions emulator: passou, 37/37
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true: passou
Web local em 127.0.0.1:5173: respondeu HTTP 200
flutter build windows --debug: passou
Windows cross-role integration: passou, 5/5 fluxos
e2e:ui:dual Web: bloqueado no runner E2E
e2e:ui:orcamento Web: bloqueado no runner E2E
```

Checklist Web:

```text
Web abre: passou
Auth/Firestore emulador: passou parcialmente; houve timeouts de bootstrap em runs longos do runner
Build Web estatico: passou
Troca Cliente/Prestador pela UI: coberta por flutter test
Fluxo Cliente/Prestador por E2E Web: bloqueado no runner
Mensagens Web: nao aprovado por E2E nesta execucao
Pedidos Web: criado/aceite no runner, mas fluxo nao concluiu
```

Checklist Windows:

```text
Windows debug/build abre no teste: passou
Fluxo Cliente pedido normal: passou
Fluxo Prestador pedido normal: passou
Fluxo Cliente orcamento: passou
Fluxo Prestador orcamento: passou
Chat cliente/prestador: passou apos correcao do seed do teste
```

Decisao:

```text
aprovado parcialmente com pendencia alta no E2E Web.
nao aprovado como beta interna completa ate refatorar e passar os runners Web.
```
