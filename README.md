# ChegaJá v2.5 (Flutter + Firebase)

Este repositório é o **projeto completo** do ChegaJá (Android / iOS / Web), com:
- Flutter app (Cliente & Prestador)
- Firestore (schema + regras)
- FCM (tokens no `users/{uid}/fcmTokens`)
- Cloud Functions (push + Stripe)

> **Nota:** este repo vem pronto para ligar a um projeto Firebase, mas **tu** deves configurar o teu próprio projeto (recomendado) com `flutterfire configure`.

---

## 1) Requisitos
- Flutter SDK instalado
- Firebase CLI instalado (`npm i -g firebase-tools`)

> Depois de abrir o projeto, corre sempre:

```bash
flutter pub get
```

Se o VS Code mostrar erros tipo "Target of URI doesn't exist", normalmente é porque o `pub get` ainda não correu (ou falhou).

### Nota sobre `firebase_auth` local
O `pubspec.yaml` usa:

```yaml
dependency_overrides:
  firebase_auth:
    path: packages/firebase_auth
```

Este override existe para aplicar ajustes locais no plugin enquanto o upstream não é adotado no projeto.

- Mantém a pasta `packages/firebase_auth` versionada no repo.
- Em CI e em novas máquinas, corre `flutter pub get` na raiz normalmente (sem `pub add` do plugin externo).
- Se removeres o override, valida antes os fluxos de Auth (anónimo, role selector e sessão).

---

## 2) Variáveis de ambiente

### App (Flutter)
1. Copia `.env.example` para `.env`.
2. Preenche:
   - `FCM_VAPID_KEY` (obrigatório para Web push)
   - `STRIPE_PUBLISHABLE_KEY` (para pagamentos online)

### Functions
1. Copia `functions/.env.example` para `functions/.env`.
2. Preenche:
   - `STRIPE_SECRET_KEY`
   - (Opcional) `STRIPE_WEBHOOK_SECRET`
   - `APP_BASE_URL`

---

## 3) Emuladores Firebase (recomendado em dev)

### ⚠️ IMPORTANTE: Inicia os emuladores ANTES de correr o app!

1. Copia `.firebaserc.example` para `.firebaserc`.

2. **Inicia os emuladores primeiro:**

```bash
# Windows
start-emulators.bat

# Linux/Mac
./start-emulators.sh

# Ou manualmente
firebase emulators:start
```

3. **Aguarda a mensagem "All emulators ready!"**

4. **Num novo terminal, inicia o app:**

```bash
flutter run -d chrome
```

> **Nota:** O app está configurado para usar emuladores automaticamente quando `USE_FIREBASE_EMULATORS=true` no ficheiro `.env`. Se vires erros de "network-request-failed", significa que os emuladores não estão a correr. Consulta `DEVELOPMENT.md` para mais detalhes.

### Modo rápido de desenvolvimento

Para reduzir o tempo de `flutter run` no dia a dia, usa o script:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\run_flutter_fast.ps1
```

O que ele faz:
- reutiliza sempre o mesmo `target` (`lib/main_dev.dart`) e as mesmas flags, o que ajuda a cache incremental do Flutter;
- evita `flutter pub get` quando `pubspec.yaml` e `pubspec.lock` não mudaram;
- corre com `FAST_DEV_MODE=true`, que desliga bootstrap opcional pesado no arranque local;
- fixa `host` e `port` web para manter o fluxo previsível.

Opções úteis:

```powershell
# Se mudaste dependências
powershell -ExecutionPolicy Bypass -File scripts\run_flutter_fast.ps1 -ForcePubGet

# Se queres o arranque completo, sem o modo rápido
powershell -ExecutionPolicy Bypass -File scripts\run_flutter_fast.ps1 -FullBoot

# Se queres pré-aquecer a toolchain web
powershell -ExecutionPolicy Bypass -File scripts\run_flutter_fast.ps1 -Precache

# Se queres medir startup
powershell -ExecutionPolicy Bypass -File scripts\run_flutter_fast.ps1 -TraceStartup
```

Boas práticas para manter o arranque rápido:
- não alternes sem necessidade entre `lib/main.dart` e `lib/main_dev.dart`;
- não mudes constantemente os `--dart-define`, porque isso invalida parte da cache;
- evita `flutter clean` salvo quando há corrupção real de build;
- depois de `flutter pub get`, prefere `--no-pub` ou usa o script acima.

### Emuladores disponíveis:
- **Auth Emulator:** http://localhost:9099
- **Firestore Emulator:** http://localhost:8080
- **Functions Emulator:** http://localhost:5001
- **Storage Emulator:** http://localhost:9199
- **Emulator UI:** http://localhost:4000 (interface web para gerir tudo)

---

## 4) Cloud Functions

As Functions estão em `functions/index.js` e incluem:
- `onChatMessageCreated` → push de chat + update `chats/{pedidoId}`
- `onPedidoCreated` → matching geo + push para prestadores
- `onPedidoUpdated` → push por mudança de estado
- `payments_createOnboardingLink` (callable)
- `payments_createPaymentIntent` (callable)
- `payments_stripeWebhook` (HTTP)

Para instalar deps localmente:

```bash
cd functions
npm install
```

Para deploy (produção):

```bash
firebase deploy --only functions
```

---

## 5) Firestore

- Regras: `firestore.rules`
- Indexes: `firestore.indexes.json`

Deploy:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 6) Deep links

O app suporta deep links via `app_links`:
- `/pedido/<pedidoId>`
- `/chat/<pedidoId>`

Para Universal/App Links em produção, configura:
- Android: `assetlinks.json`
- iOS: `apple-app-site-association`

---

## 7) Pagamentos (Stripe)

- Prestador ativa recebimentos no ecrã **Conta → Pagamentos (Stripe)**
- Cliente paga no momento de **Confirmar valor final** quando `tipoPagamento != dinheiro`

> Para produção, **ativa webhooks** no Stripe e guarda o webhook secret nas Functions.

---

## 8) MCP (Stitch)

Este repo **não** guarda chaves. O Stitch MCP deve ser configurado **localmente**.

1. Usa o arquivo de exemplo `mcp.example.json`.
2. Copia/mescla o conteúdo no teu config local de MCP:
   - Windows: `%USERPROFILE%\.verdent\mcp.json`
   - Linux/Mac: `$HOME/.verdent/mcp.json`
3. Substitui `YOUR_API_KEY` pela tua chave.

Alternativa via VS Code (Antigravity):
1. Agent Panel → ⋯ → **MCP Servers** → **Manage MCP Servers** → **View raw config**.
2. Adiciona o bloco de `mcp.example.json` e guarda.

> **Importante:** nunca faças commit de chaves. Usa apenas o arquivo local.
