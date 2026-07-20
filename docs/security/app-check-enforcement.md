# App Check, endpoints e quotas — runbook P1.6

Estado do código:

- todas as Callable Functions usam `enforceAppCheck: true` fora dos emuladores;
- `places_autocomplete`, `places_details` e `directions_route` verificam App Check e Firebase Auth;
- CORS web aceita apenas os domínios definidos em `ALLOWED_WEB_ORIGINS`;
- os proxies têm limites por utilizador/minuto e validação de tamanho dos parâmetros;
- as chaves Google ficam em Firebase Secrets, nunca no binário Flutter;
- o Stripe webhook não usa App Check porque é servidor-a-servidor; a assinatura Stripe é obrigatória;
- o app ativa App Check antes de renderizar a aplicação ou iniciar chamadas Firebase.

Estado Firebase observado em 2026-07-20:

- certificado SHA-256 da release registado;
- Play Integrity configurado para o piloto fora da Play Store: versão não
  reconhecida permitida, licença Play não exigida e `MEETS_DEVICE_INTEGRITY`
  obrigatório;
- Firestore, Storage e Authentication ainda estão `UNENFORCED`;
- snapshot auditável em `firebase-app-check-status-2026-07-20.json`;
- `npm run p1:appcheck:status` repete a consulta sem mostrar credenciais.

O enforcement não deve ser ligado antes da matriz física passar com a APK e o
`applicationId` finais. Fazê-lo agora bloquearia clientes do piloto sem uma
prova de attestation válida.

## Ativação obrigatória antes do piloto

1. Registar a aplicação Android do piloto no Firebase App Check com Play Integrity.
2. Confirmar `applicationId`, SHA-256 da chave de assinatura e conta Google Play corretos.
3. Distribuir primeiro uma build release interna e confirmar tráfego verificado nas métricas.
4. Em Firebase Console > Security > App Check, ativar enforcement para:
   - Cloud Firestore;
   - Cloud Storage;
   - Authentication;
   - quaisquer APIs Google expostas diretamente no futuro.
5. Fazer deploy das Functions; o enforcement das callables é ativado pelo código.
6. Aguardar até 15 minutos e repetir o teste numa build release e num cliente sem attestation.
7. Configurar TTL Firestore no campo `expiresAt` das coleções `endpoint_rate_limits` e `kyc_upload_grants`.

O Firebase recomenda observar as métricas antes de ativar enforcement, porque clientes antigos sem token serão recusados. O App Check complementa Auth, Rules e validação; não os substitui.

Referências oficiais:

- https://firebase.google.com/docs/app-check/enable-enforcement
- https://firebase.google.com/docs/app-check/cloud-functions
- https://firebase.google.com/docs/app-check/custom-resource-backend

## Quotas externas iniciais do piloto

Limites internos por utilizador:

- Places Autocomplete: 30/minuto;
- Place Details: 20/minuto;
- Directions: 20/minuto;
- conjunto de Callable Functions: 90/minuto.

Configurar também alertas de orçamento e quotas diárias no Google Cloud. Restringir cada chave às APIs estritamente necessárias. Começar com limites baixos para o coorte do piloto e aumentar apenas com métricas reais. Nunca remover os limites internos por existir uma quota do fornecedor.

## Verificação de lançamento

- Chamada callable sem App Check: HTTP 401.
- Proxy sem `X-Firebase-AppCheck`: HTTP 401.
- Proxy sem Firebase ID token: HTTP 401.
- Origem web não autorizada: recusada pelo CORS.
- Excesso por minuto: HTTP 429 / `resource-exhausted`.
- Build Android release: Firestore, Storage, Auth e Functions continuam funcionais após enforcement.
- Cliente modificado/debug não registado: recusado.
