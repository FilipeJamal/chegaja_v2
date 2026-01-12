# ChegaJá v2.5 — Mapa de fases SUPER completo (A → K)

Legenda: ✅ já tens / 🟡 próximo passo / ⛔ não implementado / ⭐ opcional mas forte

✅ BLOCO A — Fundação técnica, arquitetura e produção
A1 — Ambiente & projeto base ✅
- ✅ Flutter + estrutura lib/
- ✅ Temas / design tokens
- ✅ Testes automatizados base (unit/widget)
- ⭐ Flavors: dev / staging / prod (Firebase projects separados) ⛔
- ⭐ CI básico (build/test) + linters + format ⛔

A2 — Firebase Core ✅
- ✅ firebase_options.dart
- 🟡 Firebase Emulator Suite (BuildTools 2022 instalado; testes de fluxo rodam mas crasham no firebase_auth (Windows thread); falta estabilizar + testes de rules)
- ✅ Seed/migrations controladas para serviços/categorias (incremental)

A3 — Layout base & papéis ✅
- ✅ Role selector
- ✅ Bottom nav cliente/prestador
- ⭐ Switch role (mesmo user ser ambos) ⛔

A4 — Auth + Users + Device tokens ✅
- ✅ Anonymous auth + merge users/{uid}
- ✅ Guarda tokens e refresh
- ✅ Política de tokens (tokenUpdatedAt, limpeza inválidos, refresh periódico)
- ⭐ Upgrade auth (telefone/email/apple/google) ⛔

A5 — Fluxo base de pedidos ✅ (IMEDIATO + AGENDADO)
- ✅ criar/listar/aceitar/meus
- ✅ manual/automático (seleção manual de prestador)

A6 — Estados + ganhos simples ✅/🟡
- ✅ iniciar/concluir + confirmação valor
- 🟡 FSM explícita (transições/validações; timeout pendente)

A7 — Observabilidade & qualidade 🟡
- 🟡 Crashlytics
- 🟡 Performance
- ✅ Analytics (eventos base)
- 🟡 Remote Config
- ⭐ App Distribution ⛔

A8 — Segurança base (infra) 🟡
- ✅ Firestore rules hardening (devMode false; validações de estado)
- 🟡 App Check
- ⭐ Rate limiting backend ⛔

✅ BLOCO B — Experiência do pedido (UX + detalhe)
B1 — Detalhe do pedido ✅
- ✅ mapa + fullscreen
- ✅ chat no detalhe

B2 — Edição & cancelamento ✅
- ✅ política de cancelamento + limpeza de pendências
- ✅ motivos de cancelamento por estado

B3 — Timeline ✅/⭐
- ✅ labels amigáveis
- ⭐ audit trail (eventos reais) ⛔

B4 — Qualidade de endereço & localização 🟡
- ✅ seleção de local no mapa
- ✅ país/estado/cidade inteligentes nos perfis (autocomplete offline)
- 🟡 autocomplete de morada (Places/Mapbox/Nominatim)

B5 — Anexos no pedido 🟡
- ✅ chat com imagens/ficheiros/áudio/stickers/gif/emojis
- 🟡 anexos dedicados no pedido (fora do chat)

✅/🟡 BLOCO C — Preços, dinheiro e modelo de negócio
C1 — Valor final digitado pelo prestador ✅
C2 — Tipos de preço ✅/🟡
- ✅ a_combinar | fixo | por_orcamento (UI)
- 🟡 fluxo completo de orçamentos (propostas, validade, comparar)
C3 — Comissão & métricas 🟡 (base simples; falta ledger server-side)
C4 — Planos & créditos ⛔
C5 — Promoções e referrals ⛔

✅/🟡 BLOCO D — Serviços, categorias & matching
D1 — Catálogo global ✅ (seed + lista ampliada)
D2 — Perfil prestador: serviços & raio ✅
- ✅ multi-categoria + seleção no feed/perfil/settings
- ✅ filtro por categoria + raio no feed
- 🟡 geoqueries por geohash (geohash salvo; falta query eficiente)
D3 — Matching avançado ⛔
D4 — Disponibilidade & agenda do prestador ⛔
D5 — Pesquisa (keywords) 🟡
- ✅ busca inteligente com normalização de acentos (serviços/prestadores)
- 🟡 full-text externo (Algolia/Meili/Elastic)

✅/🟡 BLOCO E — Perfis, portfólio, favoritos e chat
E1 — Perfil prestador "Insta" ✅ (cross-platform + portfólio)
E2 — Favoritos ⛔
E3 — Chat ✅/🟡
- ✅ chat por pedido + inbox global
- ✅ anexos (imagem/arquivo/áudio) + stickers/gif/emojis
- 🟡 push server-side, typing, read receipts
E4 — Suporte interno ⛔

✅/🟡 BLOCO F — Localização, mapa e ETA
F1 — lastLocation do prestador ✅/🟡
- ✅ atualização online/offline
- 🟡 tracking contínuo (método existe; falta ligar no UI)
F2 — Mapa ✅ (flutter_map)
F3 — Rota/ETA ⛔
F4 — "A caminho" + tracking ao cliente ⛔

🟡/⛔ BLOCO G — Notificações & deep links
G0 — Deep links sem FDL 🟡 (app_links implementado; falta assetlinks/AASA e domínio)
G1 — Push real (backend) 🟡 (tokens OK; falta Cloud Functions fanout)
G2 — Notificações in-app ⛔
G3 — Lembretes agendados ⛔

🔒 BLOCO H — Segurança, verificação e confiança
H0 — Firestore Rules "produção" 🟡 (hardening ok; falta testes no emulator)
H1 — KYC / verificação ⛔
H2 — Avaliações ✅ (UI + service + rules; uma review por pedido)
H3 — No-show / disputas 🟡 (política base; falta fluxo completo)
H4 — App Check ⛔

🌍 BLOCO I — i18n / moeda / país 🟡
- ✅ base l10n (pt/en)
- 🟡 moeda/timezones/regras locais

💳 BLOCO J — Pagamentos online (marketplace) 🟡
J1 — Stripe Connect + pagamento do cliente 🟡 (Flutter + Functions implementados; requer setup)
J2 — Webhooks + ledger 🟡 (webhook existe; falta ledger/auditoria)
J3 — Alternativa rápida (subscriptions) ⛔

📊 BLOCO K — Admin, métricas, moderação, operações
K1 — Admin panel ⛔
K2 — Métricas + funil 🟡 (Analytics base feito; falta export)
K3 — Moderação de conteúdo ⛔
K4 — Custos + retenção 🟡 (TTL/limpeza pendente)
