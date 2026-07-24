# U0 — inventário técnico e funcional

Data: 2026-07-20

Base: `7230b4406338666c399ec3c5f0f3cb204c61b04e`

Âmbito: fotografia da base antes do Design System 2.0; sem deploy produtivo

Este inventário regista a superfície encontrada no código. Contagens servem
para orientar modularização e testes; não são métricas de tração ou alegações
de conclusão operacional.

## Superfície técnica

| Área | Baseline | Observação |
| --- | ---: | --- |
| Ecrãs Flutter com sufixo `screen` | 34 | Cliente, Prestador, Admin, autenticação e fluxos comuns |
| Serviços em `lib/core/services` | 43 | Firebase, pedidos, pagamentos, localização, segurança e suporte |
| Modelos em `lib/core/models` | 19 | Pedido continua a concentrar várias fases do trabalho |
| Rotas `MaterialPageRoute` | 72 ocorrências | Navegação fragmentada; alvo de U1 |
| Blocos `match` em Firestore Rules | 45 | Inclui fronteiras P1 e negação final por omissão |
| Blocos `match` em Storage Rules | 15 | Inclui anexos, chat, perfil, portefólio e KYC |
| `functions/index.js` | 6.526 linhas | Monólito server-side a modularizar de forma aditiva |
| `PedidoService` | 1.102 linhas | Compatibilidade e operações de pedido no mesmo serviço |

Estas duas contagens pertencem à base auditada. No fecho local de U0, depois de
centralizar no backend as transições de pedido, matching, recuperação de
eliminação, quotas e validações autoritativas, `functions/index.js` passou a
aproximadamente 9.200 linhas e `PedidoService` a 883 linhas. A redução no
cliente é intencional; o crescimento do ficheiro de Functions reforça a
necessidade de modularização aditiva nas fases seguintes.

## Mapa funcional existente

### Cliente

- seleção de papel e confirmação de telefone;
- catálogo, pesquisa de Prestadores e favoritos;
- criação, detalhe e acompanhamento de pedidos;
- seleção de Prestador, chat e anexos;
- perfil, avaliações, denúncias, suporte, privacidade e eliminação de conta.

### Prestador

- perfil público/privado, serviços, categorias, portefólio e agenda;
- disponibilidade e oportunidades compatíveis;
- ações do ciclo do pedido e resumo financeiro;
- chat, pagamentos, suporte e definições;
- KYC, subscrição e funcionalidades avançadas presentes no código, mas
  desligadas no piloto.

### Operação e backend

- backoffice administrativo e moderação;
- catálogo e políticas Trust & Safety server-side;
- dispatch sanitizado e métricas agregadas do piloto;
- ledger/comissão e abstração de pagamento;
- Storage privado com grants, consentimento e caminhos por finalidade;
- migrações aditivas, readiness, auditorias e limpeza de dados de teste.

## Feature flags encontradas

Os defaults documentados em `.env.example` mantêm desligados KYC, Stripe,
M-Pesa, e-Mola, stories, chamadas, subscrições, ranking avançado e Windows
público. `PILOT_MODE` fica ativo; a baseline ainda usa português, Maputo e MZN.

| Flag | Default | Estado U0 |
| --- | --- | --- |
| `ENABLE_KYC` | `false` | desligada |
| `ENABLE_STRIPE` | `false` | desligada |
| `ENABLE_MPESA` | `false` | desligada |
| `ENABLE_EMOLA` | `false` | desligada |
| `ENABLE_STORIES` | `false` | desligada |
| `ENABLE_CALLS` | `false` | desligada; U0 passa a bloquear também listener e ações |
| `ENABLE_SUBSCRIPTIONS` | `false` | desligada |
| `ENABLE_ADVANCED_RANKING` | `false` | desligada |
| `ENABLE_WINDOWS_PUBLIC` | `false` | desligada |
| `PILOT_PORTUGUESE_ONLY` | `true` | baseline histórica a substituir por configuração de mercado |
| `PILOT_MAPUTO_ONLY` | `true` | baseline histórica; Coimbra é o primeiro piloto decidido |

As flags atuais são lidas de `.env` e não formam ainda um contrato remoto
tipado, auditável e com rollback. Essa fundação pertence a U1. Qualquer
funcionalidade nova U1–U12 deve nascer desligada por omissão.

## Legado, sobreposição e dívida identificados

- `functions/index.js` e `PedidoService` são pontos monolíticos de risco.
- A navegação usa 72 ocorrências de `MaterialPageRoute`, sem uma árvore única e
  observável.
- `lib/core/catalog/provider_custom_service.dart` é um export de
  compatibilidade para o modelo canónico em `lib/core/models`; deve permanecer
  até os imports antigos serem migrados.
- `ServiceSafetyGuard` e `ServiceAdmissionGuard` têm responsabilidades
  próximas e precisam de fronteiras explícitas antes de nova taxonomia.
- U0 removeu do `RemoteConfigService` o default de comissão de 15% sem
  consumidor. A política financeira autoritativa permanece exclusivamente no
  backend.
- Locale, telefone, zonas, textos, moeda e configuração operacional ainda
  contêm pressupostos de Moçambique.
- Pedido, proposta, execução e economia continuam parcialmente agregados no
  mesmo documento por compatibilidade com o modelo legado.
- Stories, chamadas, subscrições, KYC, Stripe e Windows público são código
  existente fora do piloto; não são prioridade de manutenção nesta fase.

## Fronteiras de dados e regras

- públicos: perfis autorizados, serviços, portefólio permitido e indicadores
  de confiança específicos;
- privados: identidade/contactos, localização exata, KYC, finanças, suporte,
  bloqueios e decisões internas;
- pedido aberto: dispatch sanitizado, nunca leitura pública do documento bruto;
- pedido/chat privado: telefone confirmado, papel correto e participação ativa
  na coorte;
- anexos partilhados: criação/leitura pelo participante correto e imutabilidade
  para não-admin enquanto não existir ownership por objeto;
- KYC e pagamentos digitais: desligados por omissão;
- última regra: negação por omissão em Firestore e Storage.

## Evidência visual versionada

As três capturas originais de U0 estão em
`docs/product/evidence/u0-2026-07-20/`:

- gate release Android-only, 1280×720;
- home Cliente em debug, 1280×720;
- home Prestador em debug, 1280×720.

São referência da interface existente, não uma aprovação visual. A captura
nomeada originalmente como mobile tinha viewport real de 1280×720 e foi
renomeada corretamente ao ser versionada.

## Validação e publicação

As contagens finais de testes, análise, APK e readiness ficam registadas em
`docs/pilot/p1-completion-audit.md` depois de executadas sobre o commit desta
branch. O baseline U0 guarda os critérios de saída; merge não autoriza deploy
produtivo.

No fecho local de 2026-07-24 foram aprovados 522 testes Flutter em 105
ficheiros, 167 testes de Functions/Firestore/Storage em 24 ficheiros e 14
grupos de scripts. A análise estática terminou com 0 erros e 328
avisos/informações não fatais. CI, revisão, merge, APK proveniente do commit
final e readiness continuam a exigir prova própria.
