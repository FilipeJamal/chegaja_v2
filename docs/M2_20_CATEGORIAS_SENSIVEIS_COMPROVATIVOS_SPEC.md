# M2.20 - Categorias Sensiveis e Comprovativos Profissionais

Data: 2026-05-31

## Estado

M2.20 fechada no escopo atual de categorias sensiveis e comprovativos
profissionais.

```text
M2.14 - FECHADA no escopo atual de perfil, portfolio e confianca leve
M2.15 - FECHADA no escopo atual de avaliacoes e reputacao leve
M2.16 - FECHADA no escopo atual de pesquisa manual/discovery
M2.17 - FECHADA no escopo atual de Trust & Safety basico
M2.18 - FECHADA no escopo atual de Admin/backoffice leve
M2.19 - FECHADA no escopo atual de link publico, @handle e partilha social
M2.20 - FECHADA no escopo atual de categorias sensiveis e comprovativos profissionais
M2.20.1 - FECHADA com spec e auditoria
M2.20.2 - FECHADA com modelo, service e Rules
M2.20.3 - FECHADA com UI do prestador para pedido de aprovacao
M2.20.4 - FECHADA com admin leve para analisar comprovativos
M2.20.5 - FECHADA com integracao em perfil/discovery/pedido
M2.20.6 - FECHADA com QA final, E2E e documentacao
```

Blocos relacionados:

```text
Bloco F - parcial
Bloco H - parcial
Bloco J - parcial
R - pausado por falta de tester humano real
M - pausado por falta de Android fisico real
R1 - pendente
M2.6 - pendente
```

## Objetivo da M2.20

Criar a base de categorias sensiveis e comprovativos profissionais, para que
determinados servicos so possam ser anunciados, destacados ou tratados como
aprovados apos analise adequada.

Esta fase responde a tres necessidades do produto:

```text
categorias ilegais/proibidas continuam bloqueadas;
categorias sensiveis podem exigir analise ou comprovativo;
o perfil publico nao deve prometer certificacao sem processo real.
```

M2.20 nao e KYC completo. KYC de identidade, documento pessoal, selfie/liveness
e validacao de identidade fica para fase propria futura.

## Principio de Escopo

M2.20 deve criar qualificacao por categoria, nao verificacao total de pessoa.

Separacao:

```text
M2.20 - comprovativo profissional/categoria sensivel;
M2.23 futuro - KYC, identidade, documento pessoal, selfie/liveness;
M2.24 futuro - monetizacao/pagamentos reais.
```

Nesta M2.20.1 nao houve implementacao de Dart, Rules, Storage Rules, Functions,
UI, upload ou deploy.

Na M2.20.2 foram criados modelos Dart, service minimo e Firestore Rules para a
base de `categoryRequirements`, `sensitiveCategoryRequests` e
`prestadores/{uid}/categoryApprovals/{categoryId}`. Nao houve UI, upload,
admin visual, Functions, Storage Rules, deploy, KYC ou integracao com
matching/discovery.

Na M2.20.3 foi criada a UI do prestador em `PrestadorSettingsScreen` para
listar categorias sensiveis, ver status de pedido/aprovacao, abrir formulario
de pedido, enviar evidencia textual e referenciar portfolio publico como
evidencia informal. Nao houve upload real, admin visual, discovery/matching,
badges publicos, KYC, Functions, Storage Rules ou deploy.

Na M2.20.4 foi criada a fila admin leve para analisar pedidos de categorias
sensiveis: listar requests, ver evidencia textual/referencias de portfolio,
aprovar, rejeitar, pedir mais informacao, criar `categoryApprovals` quando
aprovado e registar `adminAuditLogs` pequenos. Nao houve upload real,
visualizacao de documentos privados, KYC, badges publicos, discovery/matching,
pagamentos ou deploy.

Na M2.20.5 as aprovacoes admin passaram a publicar resumo publico seguro em
`prestadores/{uid}` (`approvedSensitiveCategoryIds`,
`approvedSensitiveCategoryNames`, `categoryApprovalsUpdatedAt`), protegido por
Rules contra escrita client-side. O perfil publico e o discovery mostram
categorias com aprovacao usando linguagem conservadora, e pedidos sensiveis
criados pelo cliente passam a gravar `categoryApprovalRequired` e metadados
auxiliares. O aceite direto respeita aprovacao nas Rules e as
propostas/orcamentos passam pela mesma regra no `PedidoService`.
Nao houve upload real, KYC, Storage Rules, badges "certificado/verificado",
ranking avancado, pagamentos ou deploy.

Na M2.20.6 o bloco foi fechado com documentacao final, testes focados,
Functions/Rules, Flutter completo, build Web, E2E e QA visual. A decisao final
mantem fora upload real, documentos privados, KYC, selfie/liveness, badges
"certificado/verificado", ranking avancado, pagamentos e deploy.

## Atualizacao M2.20.3 - UI do Prestador

Arquivos criados:

```text
lib/features/prestador/widgets/prestador_sensitive_categories_section.dart
lib/features/prestador/widgets/sensitive_category_request_sheet.dart
lib/features/prestador/widgets/category_approval_status_chip.dart
```

Arquivos atualizados:

```text
lib/features/prestador/prestador_settings_screen.dart
lib/core/services/category_approval_service.dart
```

Comportamento:

```text
prestador ve "Categorias sensiveis e comprovativos";
prestador ve categoria sensivel, requisitos e status;
prestador abre formulario de pedido;
prestador seleciona tipo de comprovativo;
prestador descreve experiencia/comprovativo textual;
prestador pode referenciar portfolio publico;
prestador reenvia informacao quando status for needs_more_info;
upload real continua fora;
admin visual continua fora.
```

Fallback:

```text
se categoryRequirements ainda nao estiver semeada;
a UI deriva requisitos locais dos servicos selecionados;
usa SensitiveCategories como base;
nao cria aprovacao falsa.
```

Textos seguros continuam obrigatorios. A UI privada e o perfil publico podem
mostrar "Aprovacao ativa", "Categoria aprovada" ou "Categorias com aprovacao"
quando houver approval real, mas continuam proibidos "certificado",
"verificado", "garantido" e "aprovado oficialmente".

## Atualizacao M2.20.4 - Admin de Comprovativos

Arquivos criados:

```text
lib/features/admin/widgets/admin_sensitive_category_requests_section.dart
lib/features/admin/widgets/admin_sensitive_category_decision_sheet.dart
functions/test/adminSensitiveCategoryRequests.test.js
test/features/admin/admin_sensitive_category_requests_section_test.dart
test/features/admin/admin_sensitive_category_decision_sheet_test.dart
docs/M2_20_4_ADMIN_COMPROVATIVOS_STATUS.md
```

Arquivos atualizados:

```text
functions/index.js
lib/core/services/admin_service.dart
lib/features/admin/admin_panel_screen.dart
lib/features/admin/widgets/admin_panel_content.dart
lib/features/admin/widgets/admin_queue_status_chip.dart
test/features/admin/admin_panel_navigation_test.dart
docs/ROADMAP_A_T_CHEGAJA.md
```

Callables criadas:

```text
admin_listSensitiveCategoryRequests
admin_reviewSensitiveCategoryRequest
```

Comportamento:

```text
admin lista pedidos de categoria sensivel;
admin filtra por status/provider/category;
admin ve evidencia textual e URLs publicas de portfolio;
admin aprova pedido;
approval e criado em prestadores/{providerId}/categoryApprovals/{categoryId};
admin rejeita pedido;
admin pede mais informacao;
decisoes geram audit log leve;
evidenceText completo nao e copiado para audit log;
upload real continua fora;
discovery/matching continuam fora.
```

## Atualizacao M2.20.2 - Modelo Tecnico

Arquivos criados:

```text
lib/core/models/category_approval_types.dart
lib/core/models/category_requirement.dart
lib/core/models/sensitive_category_request.dart
lib/core/models/provider_category_approval.dart
lib/core/services/category_approval_service.dart
```

Colecoes decididas:

```text
categoryRequirements/{categoryId}
sensitiveCategoryRequests/{requestId}
prestadores/{uid}/categoryApprovals/{categoryId}
```

`categoryRequirements` define risco, exigencia de aprovacao e tipos de
evidencia aceites. `sensitiveCategoryRequests` guarda pedidos do prestador com
status e evidencias textuais/referencias. `categoryApprovals` guarda aprovacao
por prestador/categoria e e escrito apenas por admin/dev.

Status principais:

```text
draft
submitted
pending_review
approved
rejected
needs_more_info
expired
revoked
```

Decisoes de seguranca:

```text
prestador nao cria approval para si;
prestador nao escreve reviewedBy/reviewedAt/decisionReason;
prestador so edita pedidos em draft ou needs_more_info;
documentRefs guardam apenas referencias/metadados;
upload real e caminho privado de Storage ficam fora desta fase;
KYC continua separado de comprovativo profissional por categoria.
```

## Estado Atual das Categorias e Servicos

Arquivos principais:

```text
lib/core/models/servico.dart
lib/core/repositories/servico_repo.dart
lib/seed/servicos_catalogo_generator.dart
lib/features/cliente/novo_pedido_screen.dart
lib/features/prestador/prestador_settings_screen.dart
lib/features/prestador/prestador_home_screen.dart
lib/features/cliente/discovery/provider_search_profile.dart
firestore.rules
```

O catalogo atual usa a colecao:

```text
servicos/{servicoId}
```

Campos do modelo `Servico`:

```text
id
name
name_i18n
mode
keywords
iconKey
isActive
createdAt
```

Compatibilidade legada:

```text
name/nome
mode/modo
isActive/ativo
```

O `ServicosRepo` le a colecao `servicos`, filtra ativos no cliente e usa fallback
local em emulador via `initialServicosFull`. O catalogo local e amplo e inclui
areas potencialmente sensiveis, como:

```text
Eletricista
Babysitter
Cuidador de idosos
Mudancas e entregas
Saude ao domicilio
Bem-estar e saude
Fitness e danca
Eventos e catering
Reparacao tecnica
Servicos em casa do cliente
```

Ainda nao existe campo formal no catalogo para:

```text
sensitive
needsReview
approvalRequired
requiredEvidence
minimumApprovalStatus
riskLevel
```

## Uso Atual em Pedido

`NovoPedidoScreen` carrega servicos ativos por `ServicosRepo` e guarda no pedido:

```text
servicoId
servicoNome
categoria
titulo
descricao
modo
tipoPreco
tipoPagamento
```

Antes de submeter, a tela usa `TrustSafetyClassifier.classifyFields` com:

```text
titulo
descricao
categoria selecionada
```

Resultado atual:

```text
allow - segue normalmente
warn - mostra aviso e permite continuar
needsReview - mostra aviso e permite continuar
block - bloqueia
```

Limite importante: `needsReview` hoje nao cria pedido de aprovacao, nao cria
fila admin especifica, nao bloqueia matching e nao exige comprovativo.

## Uso Atual no Perfil do Prestador

O prestador define servicos/categorias principalmente em:

```text
lib/features/prestador/prestador_settings_screen.dart
```

Ao guardar, a tela escreve em:

```text
prestadores/{uid}.servicos
prestadores/{uid}.servicosNomes
prestadores/{uid}.radiusKm
prestadores/{uid}.country/state/city
```

`prestadores/{uid}.servicos` guarda IDs do catalogo. `servicosNomes` guarda
nomes visiveis usados tambem no matching com pedidos.

O perfil publico do prestador le:

```text
servicosNomes
portfolioUrls
handle/handleDisplay
ratingAvg/ratingCount
city/country
bio
photoUrl
```

Ainda nao existe no perfil:

```text
categoryApprovals
sensitiveCategoryStatus
approvedSensitiveCategories
professionalEvidence
certificationStatus
```

## Estado Atual do Trust & Safety para Categorias

Arquivos principais:

```text
lib/core/trust_safety/sensitive_categories.dart
lib/core/trust_safety/trust_safety_classifier.dart
lib/core/models/trust_safety_classification.dart
```

`SensitiveCategories` ja define categorias sensiveis por termos:

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

Quando uma categoria sensivel aparece no texto, o classifier devolve
`TrustSafetyDecision.needsReview`.

Limites atuais:

```text
needsReview so mostra aviso;
nao ha persistencia de caso;
nao ha approval por categoria;
nao ha comprovativo;
nao ha enforcement server-side;
nao ha diferenca entre prestador aprovado e nao aprovado;
nao ha badge publico seguro para categoria aprovada.
```

## Proibido vs Sensivel vs Normal

A M2.20 deve manter uma separacao clara:

| Tipo | Decisao | Exemplo | Tratamento |
| --- | --- | --- | --- |
| Proibido | block | drogas ilegais, prostituicao, fraude, documentos falsos | Nao permitir anunciar/prestar |
| Sensivel | needs_review / approval_required | saude, criancas, idosos, eletricidade, gas | Exigir analise/comprovativo antes de aprovar |
| Normal | allow | limpeza comum, pintura simples, montagem de moveis | Permitido sem aprovacao especial |

Categoria sensivel nao significa proibida. Significa que o ChegaJa precisa de
mais cuidado antes de permitir destaque, badge, matching preferencial ou
afirmacao publica de qualificacao.

## Categorias Sensiveis Iniciais

Lista inicial recomendada:

```text
saude e atos de bem-estar sensivel;
cuidados infantis;
cuidados a idosos ou pessoas vulneraveis;
eletricidade;
gas;
seguranca privada;
alimentacao profissional/catering;
treino, fitness e nutricao;
transporte de pessoas ou bens;
servicos em casa do cliente;
servicos envolvendo menores;
servicos que possam exigir certificado/licenca local.
```

Esta lista deve ser tratada como configuracao de produto e pode evoluir.

## Modelo de Dados Recomendado

### categoryRequirements/{categoryId}

Fonte de configuracao para categorias sensiveis.

Campos:

```text
categoryId
categoryName
serviceIds
terms
riskLevel
approvalRequired
allowedEvidenceTypes
publicLabel
internalNotes
isActive
createdAt
updatedAt
```

### sensitiveCategoryRequests/{requestId}

Pedido de aprovacao feito pelo prestador.

Campos recomendados:

```text
providerId
categoryId
categoryName
serviceIds
requestedAt
status
evidenceType
evidenceText
portfolioUrls
documentRefs
reviewedBy
reviewedAt
decisionReason
expiresAt
createdAt
updatedAt
```

Status:

```text
draft
submitted
pending_review
approved
rejected
needs_more_info
expired
revoked
```

### prestadores/{uid}/categoryApprovals/{categoryId}

Leitura rapida por prestador.

Campos:

```text
categoryId
categoryName
status
approvedAt
approvedBy
expiresAt
sourceRequestId
publicDisplayAllowed
updatedAt
```

### providerCategoryApprovals/{approvalId}

Opcional para consultas admin globais. Pode ser adiado se a subcolecao por
prestador e `sensitiveCategoryRequests` forem suficientes.

## Comprovativos

Tipos aceites para fases futuras:

```text
certificado/licenca profissional;
prova de experiencia;
fotos de trabalhos anteriores;
link externo profissional;
declaracao/contrato;
documento profissional;
comprovativo manual sem ficheiro.
```

Portfolio publico pode ajudar como evidencia informal, mas nao deve substituir
automaticamente comprovativo formal quando a categoria exige licenca/certificado.

## Storage e Privacidade

Regra conservadora:

```text
comprovativos privados nao sao publicos por defeito;
documentos/certificados nao aparecem no perfil publico;
apenas o prestador dono, admin/dev ou analista autorizado deve ver ficheiros;
URLs privadas nao devem ser copiadas para documentos publicos pesquisaveis;
audit logs nao devem guardar payloads completos ou dados sensiveis grandes.
```

Estado atual:

```text
portfolio publico usa prestadores/{uid}/portfolio e leitura publica;
existe caminho kyc/{prestadorId}/{fileName} privado para KYC legado/futuro;
nao existe caminho especifico para comprovativos profissionais por categoria.
```

Recomendacao futura:

```text
professionalEvidence/{providerId}/{requestId}/{fileName}
```

ou caminho equivalente privado, separado de `portfolio` publico e de `kyc` de
identidade.

## UI Futura do Prestador

Secao recomendada:

```text
Categorias e comprovativos
```

Comportamento:

```text
mostrar categorias normais selecionadas;
mostrar categorias sensiveis com estado;
permitir pedir aprovacao;
explicar que algumas categorias exigem analise;
mostrar estados: em analise, aprovado, rejeitado, precisa de mais info;
permitir adicionar texto, portfolio relevante e documentos quando a fase permitir;
nao usar "certificado" sem aprovacao real.
```

Textos seguros:

```text
Categoria em analise
Aprovacao de categoria
Comprovativo profissional enviado
Precisa de mais informacao
```

Evitar:

```text
identidade verificada;
prestador certificado;
garantido pelo ChegaJa;
aprovado oficialmente;
pagamento seguro.
```

## Admin Futuro

O AdminPanel ja possui:

```text
Visao geral;
Moderacao;
Suporte;
No-show;
Conteudo;
Financeiro;
Auditoria.
```

Tambem ja existem:

```text
reports;
adminAuditLogs;
callables admin;
AdminService;
AdminReportsSection;
AdminAuditLogsSection.
```

M2.20 adicionou na M2.20.4 uma fila leve:

```text
Comprovativos
```

Acoes implementadas:

```text
ver pedido de aprovacao;
ver evidencia textual;
ver URLs publicas de portfolio;
aprovar;
rejeitar;
pedir mais informacao;
gravar audit log.
```

Nao criar admin enterprise nem roles granulares nesta fase.

## Atualizacao M2.20.5 - Perfil, Discovery e Pedido

Arquivos principais atualizados:

```text
functions/index.js
firestore.rules
lib/core/models/pedido.dart
lib/core/repositories/pedido_repo.dart
lib/core/services/pedido_service.dart
lib/features/common/perfil_publico_screen.dart
lib/features/cliente/discovery/provider_search_profile.dart
lib/features/cliente/discovery/widgets/provider_search_card.dart
lib/features/cliente/novo_pedido_screen.dart
lib/features/cliente/selecionar_prestador_screen.dart
lib/features/prestador/prestador_home_screen.dart
```

Comportamento:

```text
admin approve atualiza resumo publico minimo no prestador;
resumo publico nao inclui evidencia completa nem documentos;
prestador nao consegue escrever campos de resumo diretamente;
perfil publico mostra categorias com aprovacao quando existe resumo real;
discovery/card mapeia e mostra aprovacao com linguagem segura;
pedido sensivel mostra aviso ao cliente;
pedido sensivel grava categoryApprovalRequired e metadados auxiliares;
aceite direto exige approvedSensitiveCategoryIds nas Rules quando o pedido exige
aprovacao;
propostas/orcamentos exigem approvedSensitiveCategoryIds no `PedidoService`.
```

Limites:

```text
sem upload real;
sem KYC;
sem documentos privados;
sem badge "certificado";
sem ranking avancado;
sem deploy.
```

## Impacto em Discovery, Perfil e Pedidos

Decisao implementada na M2.20.5:

```text
prestador sem aprovacao nao aparece como aprovado naquela categoria;
perfil publico so mostra categoria aprovada com approval real;
discovery mostra apenas indicacao discreta baseada no resumo publico seguro;
pedido sensivel grava categoryApprovalRequired;
aceite direto exige approvedSensitiveCategoryIds nas Rules quando
categoryApprovalRequired == true;
propostas/orcamentos exigem approvedSensitiveCategoryIds no `PedidoService`.
```

Enforcement server-side inicial foi adicionado nas Rules para aceite direto de
pedidos marcados com `categoryApprovalRequired == true`; propostas/orcamentos
ficam protegidos pelo `PedidoService` para evitar ultrapassar o limite de
expressoes das Firestore Rules. Expiracao, revogacao e politica completa de
revisao ficam para fase futura.

## Relacao com KYC

M2.20 nao valida identidade civil. M2.20 valida ou analisa qualificacao por
categoria.

Separacao:

```text
M2.20: "Pode prestar/ser destacado nesta categoria?"
KYC futuro: "Esta pessoa e quem diz ser?"
Pagamentos futuro: "Esta conta pode receber/pagar dinheiro real?"
```

As camadas podem se cruzar no futuro, mas a M2.20 deve evitar misturar
documento de identidade, selfie/liveness e comprovativo profissional.

## Subfases da M2.20

| Fase | Estado | Descricao |
| --- | --- | --- |
| M2.20.1 | FECHADO | Spec e auditoria de categorias sensiveis/comprovativos |
| M2.20.2 | FECHADO | Modelo de categoria sensivel e pedido de aprovacao |
| M2.20.3 | FECHADO | UI do prestador para pedir aprovacao |
| M2.20.4 | FECHADO | Admin leve para analisar comprovativos |
| M2.20.5 | FECHADO | Integracao com perfil/discovery/pedido |
| M2.20.6 | FECHADO | Testes, E2E, QA visual e documentacao final |

## Riscos

```text
confundir KYC com comprovativo profissional;
expor documentos privados;
prometer "certificado" sem processo real;
deixar categoria sensivel entrar como normal;
bloquear categorias legitimas por excesso;
falta de expiracao/revisao de aprovacao;
upload privado real ainda inexistente;
seed/configuracao operacional de categoryRequirements ainda pendente;
badges fortes continuam fora;
custos de Storage;
privacidade/GDPR;
responsabilidade juridica por categorias sensiveis;
server-side enforcement cobre apenas pedidos marcados como categoryApprovalRequired;
Rules protegem aceite direto e `PedidoService` protege propostas/orcamentos;
modelos duplicados entre prestadores, requests e catalogo.
```

## Testes Necessarios Futuros

```text
classifier marca categoria sensivel;
pedido de aprovacao e criado;
prestador so ve seus pedidos;
prestador nao altera status de aprovacao diretamente;
admin ve fila;
admin aprova/rejeita/pede mais info;
audit log e criado;
documento privado nao e publico;
perfil nao mostra badge sem aprovacao;
discovery nao mostra estado falso;
pedido em categoria sensivel respeita aprovacao;
Rules bloqueiam escrita indevida;
Storage Rules protegem comprovativos privados.
```

## Fora do Escopo da M2.20.2

```text
criar UI;
criar upload;
alterar Storage Rules;
alterar Cloud Functions;
deploy;
KYC;
selfie/liveness;
pagamentos;
Android fisico;
tester externo;
fechar R;
fechar M;
fechar R1;
fechar M2.6.
```

## Proximo Bloco Recomendado

Depois da M2.20, o proximo bloco recomendado e:

```text
M2.21 - Conta, definicoes e suporte premium
```

M2.21 nao foi iniciada nesta fase. M2.20 fica fechada no escopo atual de
categorias sensiveis e comprovativos profissionais.
