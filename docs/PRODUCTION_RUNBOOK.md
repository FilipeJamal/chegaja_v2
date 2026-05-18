# Production Runbook

Data: 2026-05-18

Este runbook cobre operacoes manuais e controladas para o ambiente Firebase real
do ChegaJa v2.

## Escopo

Projeto Firebase:

```text
chegaja-ac88d
```

Regra operacional:

```text
nao fazer deploy generico sem necessidade
nao apagar dados reais sem dry-run e confirmacao explicita
nao commitar segredos, key.properties, keystore ou service accounts
```

## Autenticacao Firebase CLI

Confirmar conta local:

```powershell
npx.cmd firebase login:list
```

Confirmar projeto ativo:

```powershell
npx.cmd firebase use
```

Projeto esperado:

```text
chegaja-ac88d
```

Se nao houver conta autenticada, executar login manual numa janela PowerShell:

```powershell
npx.cmd firebase login
```

## Pre-check antes de deploy

Executar antes de publicar regras ou Functions:

```powershell
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
flutter test
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"
npx.cmd firebase emulators:exec --only auth,firestore,storage,functions "npm.cmd run test:android:functions"
```

Para release Android:

```powershell
flutter build apk --release
flutter build appbundle --release
```

## Deploy separado

Publicar apenas a area alterada:

```powershell
npx.cmd firebase deploy --only firestore:rules --project chegaja-ac88d
npx.cmd firebase deploy --only storage --project chegaja-ac88d
npx.cmd firebase deploy --only functions --project chegaja-ac88d
```

Evitar:

```powershell
npx.cmd firebase deploy
```

## Smoke real de producao

Smoke padrao, mantendo evidencia:

```powershell
npm.cmd run smoke:firebase:production
```

Equivalente explicito:

```powershell
npm.cmd run smoke:firebase:production -- --keep-evidence
```

Smoke com cleanup no fim:

```powershell
npm.cmd run smoke:firebase:production -- --cleanup
```

O modo `--cleanup` usa Admin SDK. A maquina precisa ter credencial admin local
segura, por exemplo `GOOGLE_APPLICATION_CREDENTIALS`, ou outra credencial ADC
valida. Nao guardar essa credencial no repositorio.

## Health check de producao

Validacao read-only, sem criar pedidos, uploads ou deletes:

```powershell
npm.cmd run health:firebase:production
```

O health check verifica:

```text
Firebase CLI autenticado
projeto ativo chegaja-ac88d
functions:list com 27 Functions
todas as Functions em nodejs22
npm audit --omit=dev em functions sem critical/high/moderate
```

Output esperado:

```text
firebaseLogin=ok
project=chegaja-ac88d
functionCount=27
runtimes=nodejs22=27
auditCritical=0
auditHigh=0
auditModerate=0
auditLow=9
status=OK
```

Usar para validacao rapida diaria ou antes de deploy quando nao se quer criar
dados reais. Isto nao substitui o smoke real quando houver mudanca critica em
regras, Functions ou Storage.

## CI sem deploy

Workflow:

```text
.github/workflows/ci.yml
```

Dispara em:

```text
push para main
pull_request para main
```

O CI configura Node.js 22, Java 17 e Flutter stable, instala dependencias com
`npm ci`, `cd functions && npm ci` e `flutter pub get`, depois roda:

```powershell
npm run test:scripts
npx firebase emulators:exec --only firestore,storage,functions "cd functions && npm test"
flutter test --no-pub
```

O CI nao executa:

```text
deploy Firebase
smoke:firebase:production
health:firebase:production
admin:cleanup:smoke
testes Android com emulador
testes Windows desktop
```

Deploy, smoke real, health de producao e cleanup continuam manuais/controlados
por este runbook.

## Limpeza segura de dados de smoke

Dry-run por defeito:

```powershell
npm.cmd run admin:cleanup:smoke:dry
```

Esse comando usa `--verbose` e lista o plano auditavel antes de qualquer delete.

Dry-run em JSON:

```powershell
npm.cmd run admin:cleanup:smoke:json
```

Com prefixo explicito em texto:

```powershell
node scripts/admin/cleanup_smoke_data.js --prefix=m274_smoke_ --dry-run --verbose
```

Com prefixo explicito em JSON:

```powershell
node scripts/admin/cleanup_smoke_data.js --prefix=m274_smoke_ --dry-run --json
```

Apagar exige `--confirm` e tambem repetir o prefixo em `--confirm-prefix`:

```powershell
npm.cmd run admin:cleanup:smoke
```

Ou:

```powershell
node scripts/admin/cleanup_smoke_data.js --prefix=m274_smoke_ --confirm --confirm-prefix=m274_smoke_ --verbose
```

O script so deve ser usado para dados de teste controlados. Ele procura:

```text
pedidos com id prefixado
users com smokeRunId prefixado
prestadores com smokeRunId prefixado
Storage em pedidos/{pedidoId}/anexos
Storage em temp/{uid}/anexos contendo o prefixo
Auth users ligados a docs users com smokeRunId
```

O dry-run verbose mostra:

```text
doc: pedidos/...
doc: users/...
doc: prestadores/...
storage: pedidos/.../anexos/...
storage: temp/.../anexos/...
auth: uid...
```

Dados de smoke criados antes da M2.8 podem nao ter `smokeRunId` em `users`.
Nesses casos, o script ainda consegue encontrar pedidos por id prefixado, mas
users/Auth/temp uploads antigos devem ser revistos manualmente antes de qualquer
delete.

Antes de apagar, verificar o output do dry-run. Se o plano listar algo fora do
prefixo esperado, nao executar `--confirm`.

## Verificar runtime das Functions

Listar Functions:

```powershell
npx.cmd firebase functions:list --project chegaja-ac88d --json
```

Resumo esperado apos M2.7.5:

```text
FUNCTION_COUNT=27
RUNTIMES=nodejs22=27
```

## Logs das Functions

Consultar logs recentes:

```powershell
npx.cmd firebase functions:log --project chegaja-ac88d --limit 50
```

Filtrar localmente por Functions de pedidos:

```powershell
npx.cmd firebase functions:log --project chegaja-ac88d --limit 100 | Select-String "proporValorFinalPedido|confirmarValorFinalPedido|pedido="
```

Logs novos de M2.8 usam formato estruturado para:

```text
proporValorFinalPedido
confirmarValorFinalPedido
```

Os UIDs sao mascarados nos logs. Nao escrever tokens, passwords, chaves ou
conteudo sensivel nos logs.

## Se Storage devolver 403

Checklist:

```text
1. Confirmar que o caminho esta dentro de regras conhecidas.
2. Confirmar contentType e tamanho.
3. Confirmar que o utilizador e owner/participante/admin.
4. Confirmar que o pedido existe e tem clienteId/prestadorId esperados.
5. Confirmar IAM cross-service para Storage Rules consultar Firestore.
6. Reexecutar teste com Firebase Emulator Suite.
7. Se for producao, rodar smoke real apenas se a investigacao exigir.
```

IAM esperado para Storage Rules com Firestore:

```text
serviceAccount:service-767588494857@gcp-sa-firebasestorage.iam.gserviceaccount.com
roles/firebaserules.firestoreServiceAgent
```

## Se Function falhar

Checklist:

```text
1. Ver logs da Function.
2. Confirmar auth.uid e permissao do papel esperado.
3. Confirmar estado atual do pedido.
4. Confirmar runtime em nodejs22.
5. Reproduzir no Emulator Suite.
6. Rodar functions tests.
7. Evitar hotfix direto em producao sem commit/teste.
```

Comando principal:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

## Estado Android real

M2.8 nao fecha M2.6. Continuam pendentes:

```text
push real Android
upload nativo real de anexos
permissoes nativas negadas
```
