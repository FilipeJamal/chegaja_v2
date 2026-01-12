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
