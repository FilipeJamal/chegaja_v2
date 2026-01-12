# ChegaJá v2 — Mapa de Fases (Resumo atualizado)

Este resumo acompanha o estado real do código. Para o detalhe completo A → K,
ver `MAPA_DE_FASES_CHEGAJA_V2_5.md`.

Legenda: ✅ já tens / 🟡 próximo passo / ⛔ não implementado / ⭐ opcional mas forte

## A — Fundação técnica
- ✅ Flutter + estrutura lib/ + temas
- ✅ Firebase init + auth anónima + tokens FCM
- 🟡 Emulator/testes de rules + política de tokens
- ⛔ Flavors/CI

## B — Experiência do pedido
- ✅ criar/listar/detalhe/timeline/cancelamento base
- 🟡 motivos de cancelamento + autocomplete de morada

## C — Preços e dinheiro
- ✅ valor final pelo prestador
- 🟡 fluxo completo de orçamentos + ledger/comissão server-side
- ⛔ planos/referrals

## D — Serviços & matching
- ✅ catálogo global + categorias prestador + seleção manual/auto
- 🟡 geoqueries por geohash + ranking avançado

## E — Perfis & chat
- ✅ perfil prestador + portfólio
- ✅ chat com imagem/ficheiro/áudio + stickers/gif/emojis
- 🟡 push server-side + favoritos

## F — Localização & mapa
- ✅ mapa + lastLocation
- 🟡 tracking contínuo (método existe)
- ⛔ ETA/rotas e "a caminho"

## G — Notificações & deep links
- 🟡 app_links implementado (falta assetlinks/AASA)
- 🟡 push backend (Functions)

## H — Segurança & confiança
- 🟡 rules base (devMode true)
- ✅ avaliações base
- ⛔ KYC/no-show completo

## I — i18n / moeda
- 🟡 base pt/en + formatações pendentes

## J — Pagamentos online
- 🟡 Stripe/Connect/Functions implementados (setup pendente)

## K — Admin & métricas
- 🟡 métricas básicas
- ⛔ painel admin + moderação
