# MAPA DE FASES - CHEGAJÁ V2.5 (ATUALIZADO)

> **ESTADO ATUAL**: 🟡 **Fase de Consolidação (Bloco I)**
> **Foco**: Internacionalização, Idiomas e Correção de Bugs.
> **Nota**: C4 (Créditos) e C5 (Cupões) foram saltados/removidos por decisão estratégica (Bootstrapping).
> **Legenda**: `[x]` concluído | `[🟡]` parcial | `[ ]` faltando real | `[🚫]` removido | `[⏭️]` saltado

---

## 🏗️ FASE 1: FUNDAÇÃO & INFRAESTRUTURA (CONCLUÍDO)
- [x] **A1: Setup Inicial & CI** (GitHub Actions, Linters, Flavors)
- [x] **A2: Autenticação Robusta** (Phone Auth, Roles)

---

## ⚡ FASE 2: CORE LOOP (PEDIDOS)
### **B: Experiência do Pedido (CONCLUÍDO)**
- [x] **B1: State Machine** (Criado -> Aceito -> Em Andamento -> Concluído)
- [x] **B2: Cancelamentos** (Lógica transacional robusta no Repo)
- [x] **B3: Timeline/Audit Trail** (Histórico visível)
- [x] **B4: Endereços** (Autocomplete & Mapas)
- [x] **B5: Anexos** (Fotos/Áudio no pedido)

### **C: Monetização e Crescimento (ADAPTADO)**
- [x] **C1: Comissão Básica** (15% manual/log)
- [x] **C2: Carteira Digital** (Visualização básica)
- [x] **C3: Pagamentos** (Integração Stripe/MbWay placeholder)
- [🚫] **C4: Planos & Créditos** (REMOVIDO - Redundante com comissão)
- [⏭️] **C5: Promoções & Referrals** (SALTADO - Foco em lucro/bootstrapping)

### **D: Serviços e Matching (EM PROGRESSO)**
- [x] **D1: Catálogo de Serviços** (Taxonomia, Keywords)
- [x] **D2: Pesquisa Inteligente** (Fuzzy search textual)
- [x] **D3: Matching Avançado (Geospatial + Availability)**
    - [x] GeoQueries (Raio x Km)
    - [x] Filtro por Horário (`workingHours`)
    - [x] Filtro por Status (`isOnline`)

---

## 🚀 FASE 3: ESCALA & RETENÇÃO
- [x] **E1: Chat Real-time** (Adiantado)
- [x] **E2: Notificações Push** (Targeting inteligente)
- [x] **E3: Backoffice Admin** (painel operacional admin implementado)
- [x] **E4: Suporte interno** (triagem e gestão de status em backoffice)
- [🟡] **E5: Histórias (Stories)** (upload/feed base existe; falta moderação/gestão e métricas)

## ✅/🟡 BLOCO F — Localização, mapa e ETA
- [x] **F1: lastLocation do prestador**
- [x] **F2: Mapa**
- [x] **F3: Rota/ETA**
- [x] **F4: "A caminho"**

## ✅ BLOCO G — Notificações & deep links
- [x] **G0: Deep links**
- [x] **G1: Push real**
- [x] **G2: Notificações in-app**
- [x] **G3: Lembretes agendados** (job agendado + deduplicação + push/in-app por janela)

## 🔒 BLOCO H — Segurança, verificação e confiança
- [x] **H0: Firestore Rules**
- [x] **H1: KYC / verificação**
- [x] **H2: Avaliações**
- [x] **H3: No-show / disputas**
- [x] **H4: App Check**

## 🌍 BLOCO I — i18n / moeda / país 🟡
- [x] **I1: Base l10n**
- [x] **I2: Moeda/timezones** (DateTimeUtils)
- [x] **I3: Seleção dinâmica (LocaleService)**
- [x] **I4: Suporte a 7 línguas (RTL included)**

## 💳 BLOCO J — Pagamentos online (marketplace) 🟡
- [x] **J1: Stripe Connect**
- [🟡] **J2: Webhooks + ledger** (ledger imutável e webhook->ledger prontos; falta reconciliação/alertas)
- [x] **J3: Assinaturas** (checkout + portal + sincronização via webhook)

## 📊 BLOCO K — Admin, métricas, moderação
- [x] **K1: Admin panel** (tela admin com operação, suporte e moderação)
- [x] **K2: Métricas** (funnel, receita e KPIs operacionais no painel)
- [x] **K3: Moderação** (workflow no-show com decisão e auditoria)
- [x] **K4: Custos + retenção** (snapshot CAC/LTV/churn/cohorts)

---

## 🛠️ Ordem de Implementação (2 Sprints)

### Sprint 1 (Operação + Confiabilidade)
- [x] **E3/K1: Backoffice Admin v1**
  - fila de tickets, gestão de pedidos críticos, visão de pagamentos
- [x] **E4: Suporte interno v1**
  - triagem, status, prioridade, SLA básico
- [🟡] **J2: Ledger v1**
  - eventos imutáveis por pagamento, reconciliação webhook -> Firestore
- [x] **G3: Lembretes agendados v1**
  - lembretes para pedidos agendados (cliente/prestador) com janelas simples

### Sprint 2 (Monetização + Gestão)
- [x] **J3: Assinaturas**
  - planos, ciclo de cobrança, estados de assinatura
- [x] **K2: Métricas v1**
  - funil (pedido -> aceito -> concluído), no-show, receita líquida
- [x] **K3: Moderação v1**
  - workflow de disputa/no-show com decisão e auditoria
- [x] **K4: Custos + retenção v1**
  - CAC/LTV básico, cohort simples, churn operacional
