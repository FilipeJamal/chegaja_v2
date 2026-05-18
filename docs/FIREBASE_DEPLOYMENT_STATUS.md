# Firebase Deployment Status - M2.7.4

Data: 2026-05-17

## Estado

M2.7.4 publicou no Firebase real o hardening de regras e Functions preparado
nas fases M2.7.1, M2.7.2 e M2.7.3.

Isto nao fecha M2.6, porque Android fisico continua pendente para push real,
upload nativo real e permissoes nativas negadas.

## Ambiente

| Item | Valor |
| --- | --- |
| Projeto Firebase | `chegaja-ac88d` |
| Conta Firebase CLI | `bentojamalfilipe@gmail.com` |
| Commit base publicado | `ae5e063ed3ba73c3b5c913968cf6f2f6586b7dc3` |
| Data/hora local | `2026-05-17 17:19:37 +01:00` |

## Pre-checks antes do deploy

| Comando | Resultado |
| --- | --- |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |
| `flutter test` | passou, 49/49 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"` | passou, 5/5 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"` | passou, 4/4 |
| `npx.cmd firebase emulators:exec --only auth,firestore,storage,functions "npm.cmd run test:android:functions"` | passou, 1/1 |
| `flutter build apk --release` | passou, `build/app/outputs/flutter-apk/app-release.apk` |
| `flutter build appbundle --release` | passou, `build/app/outputs/bundle/release/app-release.aab` |

Durante a pre-validacao, o Android MVP expos uma corrida no teste: duas
leituras diretas eram feitas logo apos confirmacao de valor em outro
`FirebaseApp`. O teste foi ajustado para esperar explicitamente o estado
`concluido`.

## Deploy executado

| Area | Comando | Resultado |
| --- | --- | --- |
| Firestore Rules | `npx.cmd firebase deploy --only firestore:rules --project chegaja-ac88d` | passou |
| Storage Rules | `npx.cmd firebase deploy --only storage --project chegaja-ac88d` | passou |
| Functions | `npx.cmd firebase deploy --only functions --project chegaja-ac88d` | passou |
| Storage Rules apos IAM | `npx.cmd firebase deploy --only storage --project chegaja-ac88d` | passou |

Observacoes:

- Firestore Rules compilaram com warnings de lint em `immutableField` e nomes
  de variavel reservados, mas o deploy foi aceite.
- Functions foram publicadas em Node.js 20. O Firebase CLI avisou que Node.js
  20 esta depreciado desde 2026-04-30 e sera descontinuado em 2026-10-30.
- O Firebase CLI tambem avisou que `firebase-functions` esta desatualizado.
  Isto fica como divida tecnica futura, sem bloquear M2.7.4.

## IAM Storage -> Firestore

O primeiro smoke real provou que:

- upload autenticado em `temp/{uid}/anexos` passava;
- upload em `pedidos/{pedidoId}/anexos` era negado com 403, mesmo para o
  cliente participante.

A causa foi falta do binding IAM necessario para Storage Rules lerem Firestore
via `firestore.exists()` / `firestore.get()`.

Foi adicionado o binding:

```text
member: serviceAccount:service-767588494857@gcp-sa-firebasestorage.iam.gserviceaccount.com
role: roles/firebaserules.firestoreServiceAgent
```

Depois disso, as Storage Rules foram republicadas e o smoke real passou.

Referencia oficial:
`https://firebase.google.com/docs/rules/manage-deploy#manage_permissions_for_cross-service_cloud_storage_security_rules`
documenta que regras de Storage que usam conteudo do Firestore precisam desta
permissao cross-service.

## Smoke test real

Foi criado o script:

```text
scripts/smoke/firebase_production_smoke.js
```

Comando:

```powershell
npm.cmd run smoke:firebase:production
```

Resultado final:

```text
[M2.7.4 smoke] authoritative pedido flow concluded with 15/85 split
[M2.7.4 smoke] malicious direct economic update denied (403)
[M2.7.4 smoke] allowed temp attachment upload succeeded
[M2.7.4 smoke] allowed pedido attachment upload succeeded
[M2.7.4 smoke] outsider attachment upload denied (403)
[M2.7.4 smoke] OK
```

Cobertura real:

| Area | Resultado |
| --- | --- |
| Auth anonimo real | passou |
| Cliente cria `users/{uid}` | passou |
| Prestador cria `users/{uid}` e `prestadores/{uid}` | passou |
| Cliente cria pedido real | passou |
| Prestador le pedido aberto | passou |
| Prestador aceita pedido | passou |
| Prestador inicia servico | passou |
| `proporValorFinalPedido` real | passou |
| `confirmarValorFinalPedido` real | passou |
| `commissionPlatform = 15%` | passou |
| `earningsProvider = 85%` | passou |
| `lastAuthoritativeFunction = confirmarValorFinalPedido` | passou |
| Cliente tenta adulterar `commissionPlatform` diretamente | negado, 403 |
| Upload temporario permitido | passou |
| Upload de anexo do pedido por participante | passou |
| Upload de anexo do pedido por outsider | negado, 403 |

O smoke cria dados reais isolados com prefixo `m274_smoke_`. Como as regras de
producao nao permitem delete de pedidos/users por cliente comum, estes registos
ficam como evidencia rastreavel ate haver rotina admin de limpeza.

## M2.7.5 - Runtime Functions

Data: 2026-05-18

M2.7.5 tratou a divida tecnica registrada no deploy M2.7.4: runtime Node.js
20 depreciado e `firebase-functions` desatualizado.

Alteracoes:

| Item | Antes | Depois |
| --- | --- | --- |
| `functions/package.json` `engines.node` | `20` | `22` |
| `firebase-functions` | `^5.0.1` | `^7.2.5` |
| `firebase-admin` | `^12.7.0` | `^13.10.0` |
| Module system | CommonJS | CommonJS, sem migracao para ESM |

Referencia oficial:

- `https://cloud.google.com/functions/docs/runtime-support`
- `https://firebase.google.com/docs/functions/manage-functions?gen=2nd#set_node.js_version`

O deploy foi feito apenas para Functions:

```powershell
npx.cmd firebase deploy --only functions --project chegaja-ac88d
```

O Firebase CLI reportou update em:

```text
Node.js 22 (2nd Gen)
```

Confirmacao pos-deploy:

```powershell
npx.cmd firebase functions:list --project chegaja-ac88d --json
```

Resultado resumido:

```text
FUNCTION_COUNT=27
RUNTIMES=nodejs22=27
```

Smoke real pos-deploy:

```powershell
npm.cmd run smoke:firebase:production
```

Resultado:

```text
[M2.7.4 smoke] authoritative pedido flow concluded with 15/85 split
[M2.7.4 smoke] malicious direct economic update denied (403)
[M2.7.4 smoke] allowed temp attachment upload succeeded
[M2.7.4 smoke] allowed pedido attachment upload succeeded
[M2.7.4 smoke] outsider attachment upload denied (403)
[M2.7.4 smoke] OK
```

Audit de dependencias de producao:

```powershell
cd functions
npm.cmd audit --omit=dev --json
```

Resultado resumido:

```text
critical: 0
high: 0
moderate: 0
low: 9
```

Foi executado `npm.cmd audit fix --omit=dev`, que removeu os achados
criticos/altos/moderados sem `--force`. Os 9 lows restantes exigem
`npm audit fix --force` e downgrade/breaking change para `firebase-admin`
10.3.0 / `firebase-functions` 4.9.0, por isso ficaram documentados como
divida futura em vez de serem forcados nesta fase.

## Estado apos M2.7.4

```text
M0     - fechado
M2.5   - parcial
M2.6   - avancado tecnicamente, pendente de Android fisico
M2.7   - avancado
M2.7.1 - avancado em estados, pedidos e valores
M2.7.2 - avancado em Functions autoritativas para valores
M2.7.3 - avancado em testes Android com Functions Emulator
M2.7.4 - avancado com deploy controlado Firebase e smoke real
M2.7.5 - avancado com runtime Functions Node.js 22 e smoke real
```

M2.7 ainda nao deve ser marcada como fechada automaticamente. A decisao de
fechar M2.7 deve considerar a divida tecnica remanescente e se a validacao
real de Firebase e suficiente para o objetivo da fase.
