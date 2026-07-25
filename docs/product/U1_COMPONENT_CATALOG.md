# U1 — Catálogo de componentes

Data: 2026-07-24

Este catálogo descreve os blocos reutilizáveis do Design System ChegaJá 2.0.
Os exemplos executáveis vivem nos testes de widgets; este documento define o
contrato de uso.

## Identidade e estrutura

| Componente | Responsabilidade |
| --- | --- |
| `AppBrandWordmark` | ícone real e palavra ChegaJá com gradiente de marca |
| `AppProductHeader` | cabeçalho de produto reutilizável |
| `AppContentShell` | largura máxima e espaçamento de página |
| `AppShellScaffold` | navegação móvel, tablet e desktop com estado lazy |
| `AppTopBar` | barra superior coerente |
| `AppResponsiveGrid` | grelha adaptativa sem larguras mágicas por ecrã |

## Ações e entrada

| Componente | Variantes ou uso |
| --- | --- |
| `AppButton` | `primary`, `brand`, `secondary`, `ghost`; 48/52/56 px |
| `AppTextField` | preenchido ou contornado; ajuda, erro, prefixo e sufixo |
| `AppChip` | filtro, escolha e estado; seleção semântica |
| `AppFilterButton` | acionador de filtro com área tátil segura |
| `AppPremiumSearchBar` | pesquisa principal em superfícies de descoberta |
| `AppSegmentedTabs` | escolhas mutuamente exclusivas |
| `AppTabBar` | navegação local dentro de uma área |

## Conteúdo

| Componente | Responsabilidade |
| --- | --- |
| `AppCard` | cartão elevado, contornado ou plano; opcionalmente acionável |
| `AppActionPanel` | bloco de decisão com ação principal |
| `AppListTile` | linha coerente de conteúdo e ação |
| `AppMetricTile` | métrica com rótulo e contexto |
| `AppSectionHeader` | título, descrição e ação de secção |
| `AppStatusPill` | estado curto, nunca verificação genérica |
| `AppUnreadBadge` | indicação compacta de conteúdo não lido |
| `AppAvatar` | identidade visual com fallback controlado |
| `PrivateStorageImage` | imagem protegida sem expor URL persistente |
| `ServiceVisuals` | recursos visuais reais por serviço |

## Estados

| Componente | Quando usar |
| --- | --- |
| `AppLoadingView` | operação sem conteúdo anterior |
| `AppSkeletonBox`, `AppSkeletonLine`, `AppSkeletonList` | estrutura previsível durante carregamento |
| `AppEmptyView` | resultado válido sem itens e com próximo passo |
| `AppOfflineView` | ligação ausente e dados locais possíveis |
| `AppErrorView` | falha recuperável com retry e, quando necessário, suporte |
| `AppRecoveryView` | fluxo interrompido que pode ser retomado |
| `AppStaleDataBanner` | conteúdo visível, mas potencialmente desatualizado |

## Composição da Home do Cliente

| Componente | Contrato |
| --- | --- |
| `ClienteHomeHero` | marca, mercado, intenção, descrição e CTA |
| `ClienteServiceModeSelector` | `IMEDIATO`, `AGENDADO`, `ORCAMENTO` |
| `ClienteQuickServicesStrip` | atalhos visuais baseados no catálogo real |
| `ClienteRecentRequestCard` | pedido recente com estado e ação |
| `ClientePrivacyNotice` | localização aproximada antes da relação legítima |

## Regras de uso

- Não criar um botão, cartão, chip ou estado local se o componente canónico
  cobrir o caso.
- Não usar o gradiente decorativo como superfície de texto funcional.
- Não usar emoji, ASCII, caixas vazias ou SVG artesanal como recurso visível.
- Não confundir `loading`, `empty`, `offline` e `error`.
- Não remover rótulos essenciais apenas para caber; adaptar o layout.
- Não inserir destinos adicionais na navegação sem rever os cinco contratos de
  cada papel.
- Não apresentar «verificado» sem dizer exatamente o que foi confirmado.

## Testes contratuais

O catálogo é protegido por testes de:

- contraste;
- modo claro e escuro;
- semântica;
- alvos táteis;
- escala de texto a 200%;
- estados e ações de recuperação;
- navegação em três breakpoints;
- preservação lazy do estado;
- seleção e callbacks dos três modos de serviço.

