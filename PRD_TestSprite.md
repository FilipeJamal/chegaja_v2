# PRD TestSprite — ChegaJá v2.5 (Flutter + Firebase)

## Objetivo
Validar os fluxos principais do ChegaJá no ambiente local (Flutter Web + Firebase Emulators), cobrindo UI e endpoints HTTP das Functions.

## Escopo de Testes
1. UI Web (Flutter) com semântica habilitada para automação.
2. Backend (Cloud Functions em emulador) com chamadas HTTP públicas.

## Ambiente Local
1. Frontend (Flutter Web): http://localhost:5173
2. Functions Emulator (base): http://127.0.0.1:5001/chegaja-ac88d/us-central1
3. Firestore Emulator: 127.0.0.1:8080
4. Auth Emulator: 127.0.0.1:9099
5. Storage Emulator: 127.0.0.1:9199
6. Emulator UI: http://127.0.0.1:4000

## Perfis de Utilizador
1. Cliente (login anónimo)
2. Prestador (login anónimo)

## Fluxo UI — Cliente cria pedido
1. Abrir a app no browser.
2. Autenticar via fluxo de login anónimo (sem credenciais).
3. Criar um novo pedido com serviço, título e descrição.
4. Confirmar que o pedido aparece na lista com estado "criado".

## Fluxo UI — Prestador aceita pedido
1. Autenticar como Prestador via login anónimo (sem credenciais).
2. Aceder à lista de pedidos disponíveis.
3. Aceitar o pedido criado pelo Cliente.
4. Confirmar que o estado muda para "aceito".

## Fluxo UI — Chat básico
1. Com pedido aceito, abrir o chat relacionado.
2. Enviar mensagem curta.
3. Verificar que a mensagem aparece no histórico.

## API — Endpoints HTTP (Functions)
Base URL: http://127.0.0.1:5001/chegaja-ac88d/us-central1

1. GET /places_autocomplete
   Parâmetros: input, language, types, components (opcionais)
   Resultado esperado:
   - Se chaves Google NÃO estiverem configuradas: status REQUEST_DENIED (erro esperado)
   - Se chaves estiverem configuradas: JSON com status e predictions

2. GET /places_details
   Parâmetros: place_id, fields, language (opcionais)
   Resultado esperado:
   - Se chaves Google NÃO estiverem configuradas: status REQUEST_DENIED (erro esperado)
   - Se chaves estiverem configuradas: JSON com status e result

3. GET /directions_route
   Parâmetros: origin, destination, mode, language (opcionais)
   Resultado esperado:
   - Se chaves Google NÃO estiverem configuradas: status REQUEST_DENIED (erro esperado)
   - Se chaves estiverem configuradas: JSON com rotas

4. POST /payments_stripeWebhook
   Requer assinatura Stripe. Teste apenas se STRIPE_WEBHOOK_SECRET estiver configurado.

## Dados de Teste
1. Login anónimo: o TestSprite deve avançar sem credenciais.
2. Se forem configuradas chaves Google/Stripe no futuro, reativar os testes desses endpoints.

## Critérios de Sucesso
1. UI: criação e aceitação de pedido concluídas sem erro.
2. UI: chat envia e mostra mensagem.
3. API: endpoints públicos respondem conforme o estado das chaves (erro esperado se não configuradas).
