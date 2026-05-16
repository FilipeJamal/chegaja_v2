# Production Hardening Status - M2.7

Data: 2026-05-16

## Estado

M2.7 foi iniciada para endurecer a base de producao enquanto M2.6 continua
bloqueada por falta de Android fisico.

Estado oficial:

```text
M0: fechado
M2.5: parcial
M2.6: avancado tecnicamente, pendente de Android fisico
M2.7: iniciado / avancado em seguranca Firebase e preparacao de QA real
```

## Alteracoes aplicadas

| Area | Estado | Evidencia | Observacoes |
| --- | --- | --- | --- |
| Storage Rules | endurecido | `functions/test/storage.test.js` | O bucket deixou de ser publico. |
| Anexos de pedidos | endurecido | participantes podem ler/enviar; nao participantes sao negados | Caminho permitido: `pedidos/{pedidoId}/anexos/{file}`. |
| Anexos temporarios | endurecido | `temp/{uid}/anexos/{file}` | O upload antes de criar pedido deixou de usar pasta global `temp/anexos_*`. |
| Chat media | endurecido | participantes do pedido podem usar `chats/{pedidoId}/images|files` | Tipos e tamanho maximo validados por regras. |
| KYC | endurecido | owner/admin podem ler; terceiros negados | Caminho `kyc/{prestadorId}/{file}` nao fica publico. |
| Perfis/portfolio/stories | limitado | owner escreve; leitura publica apenas onde esperado | Imagens limitadas por tipo e tamanho. |
| Firestore pedidos | endurecido | teste bloqueia aceitar pedido para outro prestador | Prestador compativel so pode aceitar pedido aberto para o proprio UID. |
| FCM tokens | coberto por teste | teste nega escrita em token de outro utilizador | Mantem `users/{uid}/fcmTokens/{token}` owner/admin. |
| Upload de anexos no app | ajustado | `StoragePathPolicy` | Sanitiza nomes, define MIME e bloqueia tipos nao suportados. |

## Regras Storage

Antes da M2.7, `storage.rules` tinha:

```text
allow read, write: if true;
```

Agora os acessos sao segmentados:

```text
pedidos/{pedidoId}/anexos/{file}
temp/{uid}/anexos/{file}
chats/{pedidoId}/images/{file}
chats/{pedidoId}/files/{file}
users/{uid}/{file}
prestadores/{uid}/{file}
prestadores/{uid}/portfolio/{file}
portfolio/{uid}/{file}
kyc/{uid}/{file}
stories/{uid}/{file}
```

Os uploads validam:

- utilizador autenticado quando aplicavel;
- owner/participante/admin conforme o caminho;
- tamanho maximo;
- `contentType` permitido.

Tipos permitidos para anexos:

```text
image/*
application/pdf
text/plain
```

## Regras Firestore

Foi adicionada validacao para a transicao de `prestadorId` em pedidos:

- pedido aberto com `prestadorId == null` pode continuar sem prestador;
- prestador compativel pode aceitar apenas se o novo `prestadorId` for o proprio UID;
- pedido ja atribuido nao pode trocar `prestadorId` por outro UID via cliente.

Isto reduz o risco de um prestador manipular um pedido aberto para atribui-lo a
outra conta.

## Testes adicionados

```text
functions/test/storage.test.js
test/core/storage_path_policy_test.dart
```

Cobertura nova:

- upload anonimo para caminho aleatorio e negado;
- participante consegue enviar/ler anexo de pedido;
- nao participante nao consegue enviar/ler anexo de pedido;
- tipo e tamanho de anexo sao validados;
- pasta temporaria exige UID autenticado;
- KYC nao e publico para outros utilizadores;
- caminhos e MIME de anexos sao normalizados no app.

## Riscos restantes

| Risco | Estado | Proxima acao |
| --- | --- | --- |
| Push real Android | pendente M2.6 | Validar em telemovel fisico. |
| Picker/upload real Android | pendente M2.6 | Validar em telemovel fisico com Storage real/emulado. |
| Permissoes nativas negadas | pendente M2.6 | Validar notificacoes, galeria e camera negadas. |
| Campos economicos em `pedidos` | parcial | Antes de pagamentos reais, migrar calculos criticos para Functions/admin. |
| Package id final | futuro | Definir antes de Play Store/Firebase Android final. |
| HTTPS App Links | futuro | Publicar `assetlinks.json` nos dominios reais. |

## Comandos de validacao M2.7

Usar Firestore e Storage em conjunto para os testes de regras:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage "cd functions && npm.cmd test"
flutter test
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mvp"
npx.cmd firebase emulators:exec --only auth,firestore,storage "npm.cmd run test:android:mobile"
flutter build apk --release
flutter build appbundle --release
```

## Decisao

M2.7 nao fecha M2.6. Ela melhora seguranca, estabilidade e readiness enquanto a
validacao em Android fisico continua bloqueada.
