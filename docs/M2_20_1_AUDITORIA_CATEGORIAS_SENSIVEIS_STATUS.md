# M2.20.1 - Auditoria de Categorias Sensiveis e Comprovativos

Data: 2026-05-31

## Estado

M2.20.1 concluida.

```text
M2.20 - iniciada
M2.20.1 - FECHADA
M2.20.2 - PROXIMO passo
M2.19 - FECHADA no escopo atual
Bloco F - PARCIAL
Bloco H - PARCIAL
Bloco J - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo

Auditar o estado atual de categorias, servicos, Trust & Safety, perfil,
discovery, pedidos, Admin, Rules, Storage e Functions antes de implementar
qualquer modelo, UI, upload ou fila de aprovacao.

## Ficheiros Lidos

```text
docs/CHEGAJA_PRODUCT_MASTER_VISION.md
docs/CHEGAJA_TRUST_SAFETY_POLICY_DRAFT.md
docs/CHEGAJA_DISCOVERY_SEARCH_PROFILE_SPEC.md
docs/M2_17_FINAL_REPORT.md
docs/M2_18_FINAL_REPORT.md
docs/M2_19_FINAL_REPORT.md
docs/M2_19_6_QA_FINAL_LINK_PUBLICO_STATUS.md
docs/ROADMAP_A_T_CHEGAJA.md
lib/core/trust_safety/sensitive_categories.dart
lib/core/trust_safety/trust_safety_classifier.dart
lib/core/models/trust_safety_classification.dart
lib/core/models/servico.dart
lib/core/repositories/servico_repo.dart
lib/seed/servicos_catalogo_generator.dart
lib/features/prestador/prestador_perfil_screen.dart
lib/features/prestador/prestador_settings_screen.dart
lib/features/prestador/widgets/prestador_handle_section.dart
lib/features/prestador/widgets/prestador_portfolio_manager_section.dart
lib/features/common/perfil_publico_screen.dart
lib/features/cliente/discovery/provider_search_profile.dart
lib/features/cliente/discovery/provider_search_screen.dart
lib/features/cliente/discovery/widgets/provider_search_card.dart
lib/features/cliente/novo_pedido_screen.dart
lib/features/admin/admin_panel_screen.dart
lib/features/admin/widgets/admin_panel_content.dart
lib/features/admin/widgets/admin_reports_section.dart
lib/features/admin/widgets/admin_audit_logs_section.dart
lib/core/services/admin_service.dart
firestore.rules
storage.rules
functions/index.js
firebase.json
```

## Estado Atual das Categorias e Servicos

O catalogo atual vive em:

```text
servicos/{servicoId}
```

O modelo `Servico` contem:

```text
id;
name/name_i18n;
mode;
keywords;
iconKey;
isActive;
createdAt.
```

`ServicosRepo` le todos os documentos, filtra `isActive` no lado da app e usa
fallback local em emulador. O catalogo gerado por `servicos_catalogo_generator`
e amplo e ja contem servicos potencialmente sensiveis, mas ainda nao marca risco
ou exigencia de aprovacao.

O prestador escolhe servicos em `PrestadorSettingsScreen`. A tela grava:

```text
prestadores/{uid}.servicos
prestadores/{uid}.servicosNomes
```

`servicos` guarda IDs e `servicosNomes` guarda nomes usados em matching e
exibicao.

No pedido, `NovoPedidoScreen` grava:

```text
servicoId
servicoNome
categoria
```

## Estado Atual do Matching

`firestore.rules` usa `prestadorMatchesPedido`:

```text
pedido.servicoId precisa existir em prestadores/{uid}.servicos
ou pedido.servicoNome/categoria precisa existir em prestadores/{uid}.servicosNomes
```

Nao ha regra de aprovacao por categoria sensivel. Um prestador com categoria
sensivel selecionada pode fazer match se o ID/nome estiver no perfil.

## Estado Atual do Trust & Safety

`SensitiveCategories` ja cobre:

```text
health
child_care
elder_care
electricity
gas
private_security
professional_food
training_nutrition
transport
in_home_service
```

`TrustSafetyClassifier` devolve:

```text
allow
warn
needsReview
block
```

Integracoes atuais:

```text
NovoPedidoScreen - classifica titulo, descricao e categoria antes de submeter;
PrestadorPerfilScreen - classifica nome e bio antes de guardar perfil.
```

Limite: `needsReview` so mostra aviso e permite continuar. Nao cria fila, nao
cria approval, nao bloqueia matching e nao guarda comprovativo.

## Estado Atual do Perfil do Prestador

`PrestadorPerfilScreen` permite editar:

```text
nome;
bio;
cidade/pais;
raio;
foto;
portfolio;
@handle.
```

Portfolio:

```text
upload em prestadores/{uid}/portfolio/...;
URLs guardadas em prestadores/{uid}.portfolioUrls;
leitura publica no Storage;
visivel no PublicProfileScreen.
```

Nao existe secao de comprovativos profissionais. O portfolio pode ajudar como
evidencia informal no futuro, mas hoje e conteudo publico, nao comprovativo
privado.

## Estado Atual de KYC

Existe uma area legada/futura em `PrestadorPagamentosScreen`:

```text
kycStatus
kycDocs
kycSubmittedAt
kycUpdatedAt
Storage: kyc/{prestadorId}/{fileName}
```

Isto nao deve ser usado como base direta da M2.20 sem separacao clara. KYC trata
identidade/documento pessoal. M2.20 trata comprovativo profissional por
categoria.

## Estado Atual do Perfil Publico e Discovery

`PublicProfileScreen` mostra:

```text
nome;
@handle;
bio;
localizacao;
servicosNomes;
portfolio;
reputacao leve;
sinais de confianca factuais;
acoes de partilha.
```

Telefone fica oculto por defeito desde M2.19.4.

`ProviderSearchProfile` mapeia:

```text
servicosNomes -> services
servicos/categories -> categories
portfolioUrls -> portfolioPreviewUrls
handle -> searchTerms
```

Nao ha:

```text
approvalStatus por categoria;
approvedSensitiveCategories;
badge de categoria aprovada;
filtro de discovery por categoria aprovada.
```

## Estado Atual do Admin

O AdminPanel ja possui secoes:

```text
Visao geral
Moderacao
Suporte
No-show
Conteudo
Financeiro
Auditoria
```

Callables existentes no `AdminService`:

```text
admin_getDashboardSnapshot
admin_getOpsMetrics
admin_getCostRetentionSnapshot
admin_listSupportTickets
admin_updateSupportTicketStatus
admin_listReports
admin_updateReportStatus
admin_listNoShowCases
admin_setNoShowDecision
admin_listStories
admin_deleteStory
admin_getLedgerAnomalies
admin_listAuditLogs
```

Nao existe fila especifica de categorias sensiveis ou comprovativos.

O admin ja tem `adminAuditLogs`, que deve ser reaproveitado no futuro para:

```text
sensitive_category_request.approve
sensitive_category_request.reject
sensitive_category_request.needs_more_info
sensitive_category_request.revoke
```

## Estado Atual de Rules e Storage

Firestore:

```text
servicos/{servicoId} - leitura publica; escrita por admin/dev;
prestadores/{uid} - leitura publica; dono pode criar/atualizar, exceto campos protegidos como rating e handle;
reports/{reportId} - fila de moderacao existente;
handles/{handleId} - leitura publica; escrita bloqueada no client.
```

Storage:

```text
portfolio publico - leitura publica;
prestadores/{uid}/portfolio - leitura publica;
kyc/{prestadorId}/{fileName} - leitura para dono/admin; escrita dono/admin;
stories publico - leitura publica.
```

Nao existe caminho dedicado e privado para comprovativos profissionais.

## Conclusoes da Auditoria

```text
o catalogo e amplo, mas nao tem metadados de sensibilidade;
SensitiveCategories ja existe, mas so gera aviso;
PrestadorSettingsScreen permite selecionar qualquer servico ativo;
matching ainda nao conhece approval de categoria;
PublicProfileScreen nao mostra telefone por defeito, mas tambem nao mostra approval;
portfolio e publico e nao deve ser tratado como comprovativo formal;
KYC existe como area tecnica separada, mas nao deve ser confundido com comprovativo profissional;
AdminPanel tem estrutura suficiente para receber fila futura;
adminAuditLogs ja e base adequada para auditar decisoes futuras;
Rules/Storage ainda nao protegem modelo de comprovativos porque ele nao existe.
```

## Riscos Encontrados

```text
categoria sensivel hoje pode ser selecionada como servico comum;
needsReview nao gera workflow operacional;
prestador pode parecer qualificado sem approval real se textos futuros forem mal usados;
portfolio publico pode ser confundido com comprovativo;
documentos privados podem vazar se forem guardados em caminhos publicos;
KYC e comprovativo profissional podem ser misturados por acidente;
matching por servicosNomes e fragil para enforcement fino;
catalogo nao possui riskLevel/approvalRequired;
sem expiracao/revisao de approvals;
sem audit log especifico de decisoes de categoria;
sem admin especifico para fila de comprovativos.
```

## Decisao Recomendada para M2.20.2

Criar a base tecnica de dados antes da UI:

```text
modelo de categoria sensivel;
modelo de pedido de aprovacao;
status/enums;
helper/service Dart puro;
campos minimos para categoryRequirements e sensitiveCategoryRequests;
Rules/Functions apenas se necessarias para ownership/admin;
testes unitarios e, se houver Rules/Functions, testes dedicados.
```

Nao criar ainda:

```text
UI do prestador;
upload real;
Admin visual;
integracao com discovery/pedido;
KYC;
deploy.
```

## Validacoes

```text
git status - executado
git diff --check - passou
npm.cmd run test:scripts - passou
```

## Fora do Escopo Mantido

```text
codigo Dart;
Firestore Rules;
Storage Rules;
Cloud Functions;
upload;
UI;
deploy;
KYC;
selfie/liveness;
pagamentos;
Android fisico;
tester externo;
fechar R;
fechar R1;
fechar M;
fechar M2.6.
```
