# M2.17 - Trust & Safety, Servicos Proibidos e Moderacao Basica

Data: 2026-05-29

## Estado

M2.17 iniciada.

```text
M2.14 - FECHADA no escopo atual de perfil, portfolio e confianca leve
M2.15 - FECHADA no escopo atual de avaliacoes e reputacao leve
M2.16 - FECHADA no escopo atual de pesquisa manual e discovery
M2.17.1 - FECHADA com spec e auditoria
M2.17.2 - FECHADA com modelo de denuncias, bloqueios e moderacao
M2.17.3 - FECHADA com UI inicial de denuncia/bloqueio
M2.17.4 - PROXIMO passo
```

Blocos relacionados continuam parciais:

```text
Bloco F - parcial: KYC, verificacao oficial e identidade real ainda faltam.
Bloco H - parcial: reviews publicas, denuncias, moderacao e ranking ainda faltam.
R - pausado por falta de tester humano real.
M - pausado por falta de Android fisico real.
R1 - pendente.
M2.6 - pendente.
```

## Fundamentacao

A M2.16 abriu discovery manual, pesquisa de prestadores e sugestoes compactas na
Home Cliente. Isso aumenta a exposicao publica de perfis, portfolio, servicos,
bio, reputacao leve e futuros pontos de contacto. A partir daqui, Trust &
Safety deixa de ser detalhe futuro e passa a ser fundacao para escalar a
descoberta de prestadores.

As diretrizes oficiais de lojas reforcam essa necessidade:

```text
Apple App Store Review Guidelines:
https://developer.apple.com/app-store/review/guidelines/

Google Play User Generated Content policy:
https://support.google.com/googleplay/android-developer/answer/9876937
```

Resumo pratico para o ChegaJa:

```text
apps com UGC precisam de filtragem/moderacao;
apps com UGC precisam de denuncia;
apps com interacao entre usuarios precisam de bloqueio;
conteudo proibido e comportamento abusivo precisam estar definidos;
conteudo sexual, exploracao, trafico humano, drogas, violencia e fraude precisam
ser tratados como risco critico, nao como melhoria estetica.
```

## Objetivo da M2.17

Criar a base de Trust & Safety do ChegaJa para impedir que discovery, perfis
publicos, portfolio, chat, avaliacoes e servicos personalizados exponham
conteudo proibido, servicos ilegais ou abuso.

A M2.17 deve preparar:

```text
servicos proibidos;
conteudo proibido;
denuncia;
bloqueio;
moderacao basica;
estados de analise;
categorias sensiveis;
auditoria interna;
visibilidade segura em discovery/search;
modelo para fila/admin leve.
```

## Fora do Escopo da M2.17 Inicial

```text
KYC completo;
selfie/liveness;
validacao documental real;
moderacao automatica com IA;
videos no portfolio;
admin completo;
painel financeiro;
ranking avancado;
pagamentos;
patrocinados;
Play Store;
Android fisico;
beta externa real.
```

## Superficies de Risco

O ChegaJa ja tem ou prepara as seguintes superficies de conteudo gerado por
utilizadores:

```text
perfil publico do prestador;
foto/avatar;
nome/displayName;
bio/descricao;
portfolio;
stories;
servicos/categorias associados ao prestador;
pedidos e descricoes de pedido;
chat/mensagens;
anexos de chat;
avaliacao pos-servico;
comentario opcional de avaliacao;
favoritos e discovery/search;
Home Cliente com sugestoes de prestadores;
contacto telefonico quando exposto em perfil;
futuro link publico/handle/partilha social;
futuros videos de portfolio.
```

Estas superficies devem ser tratadas como UGC ou como dados com impacto de
seguranca operacional.

## Servicos Proibidos

O ChegaJa nao deve permitir oferta, solicitacao, promocao ou facilitacao de:

```text
prostituicao;
pornografia/servicos sexuais;
trafico humano;
exploracao sexual;
drogas ilegais;
armas ilegais;
fraude;
burla;
phishing;
falsificacao de documentos;
servicos violentos ou criminosos;
ameacas ou extorsao;
exploracao de menores;
venda de bens ou servicos ilegais;
servicos que exijam licenca obrigatoria sem comprovativo futuro;
qualquer servico que viole lei, seguranca publica ou regras da plataforma.
```

## Conteudo Proibido

Conteudo proibido em perfil, portfolio, stories, chat, avaliacoes, descricoes de
pedido ou categorias sugeridas:

```text
nudez sexual;
imagens obscenas;
conteudo sexual explicito;
violencia grafica;
ameacas;
assedio;
discurso de odio;
discriminacao;
exposicao indevida de dados pessoais;
fotos/videos sem consentimento;
conteudo envolvendo menores de forma insegura;
spam;
fraude;
links maliciosos;
personificacao/impersonation;
tentativa de contornar a plataforma;
promessas falsas de certificacao, verificacao ou pagamento seguro.
```

## Categorias Sensiveis

Categorias que podem exigir analise humana, comprovativo profissional ou bloqueio
ate existir processo real:

```text
saude;
cuidados infantis;
cuidados a idosos ou pessoas vulneraveis;
eletricidade;
gas;
seguranca privada;
alimentacao profissional;
treino/nutricao;
transporte;
servicos em casa do cliente;
servicos envolvendo menores;
qualquer categoria que exija licenca/certificado local.
```

M2.17 nao implementa KYC. A regra de produto e simples: se a plataforma ainda
nao consegue provar certificacao, nao pode chamar o prestador de verificado,
certificado, aprovado oficialmente ou garantido.

## Estados de Moderacao

Estados recomendados para perfis, media, categorias, mensagens reportadas,
reviews publicas futuras e casos de moderacao:

```text
clean
approved
pending_review
flagged
hidden
rejected
suspended
banned
appeal_requested
restored
```

Interpretacao inicial:

```text
clean/approved - conteudo pode aparecer.
pending_review - conteudo aguarda analise; por defeito deve ficar fora de
discovery publico se o risco for medio/alto.
flagged - conteudo recebeu denuncia ou sinal automatico; pode ficar limitado.
hidden - conteudo oculto do publico, preservado para auditoria.
rejected - conteudo recusado.
suspended - utilizador/perfil temporariamente bloqueado.
banned - utilizador/perfil banido.
appeal_requested - recurso pedido.
restored - conteudo/perfil restaurado apos analise.
```

## Tipos de Denuncia

Campo recomendado:

```text
targetType
```

Valores iniciais:

```text
provider_profile
client_profile
portfolio_media
story
chat_message
review
service_category
service_request
user
other
```

## Motivos de Denuncia

Campo recomendado:

```text
reasonCode
```

Valores iniciais:

```text
illegal_service
sexual_content
drugs
fraud
harassment
hate_speech
violence
child_safety
personal_data
spam
scam
impersonation
unsafe_service
copyright_or_stolen_media
off_platform_circumvention
other
```

## Severidade

Campo recomendado:

```text
severity
```

Valores:

```text
low
medium
high
critical
```

Exemplos:

```text
critical - trafico humano, exploracao de menores, ameaca grave, drogas,
violencia, armas ilegais.

high - fraude, assedio grave, conteudo sexual, impersonation com dano, servico
sensivel sem comprovativo.

medium - spam recorrente, informacao enganosa, categoria errada com risco,
conteudo suspeito.

low - perfil incompleto, texto ambigio, problema leve de classificacao.
```

## Modelo de Dados Futuro

Colecoes recomendadas para M2.17.2/M2.17.4:

```text
reports/{reportId}
moderationCases/{caseId}
userBlocks/{blockId}
users/{uid}/blockedUsers/{otherUid}
moderationActions/{actionId}
auditLogs/{logId}
categorySuggestions/{id}
sensitiveCategoryRequests/{id}
```

### reports/{reportId}

Campos recomendados:

```text
reporterId
reporterRole
targetType
targetId
targetOwnerId
relatedPedidoId
relatedChatId
relatedMessageId
reasonCode
severity
description
evidenceUrls
status
createdAt
updatedAt
assignedTo
decision
decisionReason
resolvedAt
```

### moderationCases/{caseId}

Campos recomendados:

```text
caseType
targetType
targetId
targetOwnerId
sourceReportIds
status
severity
queue
assignedTo
createdAt
updatedAt
resolvedAt
resolution
notesInternal
```

### userBlocks

Opcoes possiveis:

```text
users/{uid}/blockedUsers/{otherUid}
userBlocks/{blockId}
```

Campos recomendados:

```text
blockerId
blockedUserId
context
createdAt
reason
```

Regra futura: utilizador bloqueado nao deve conseguir iniciar ou continuar
interacao 1:1 com quem o bloqueou, salvo excecoes de suporte/disputa.

### moderationActions/{actionId}

Campos recomendados:

```text
actorId
actorRole
actionType
targetType
targetId
before
after
reason
createdAt
caseId
```

### auditLogs/{logId}

Campos recomendados:

```text
actorId
actorRole
eventType
entityType
entityId
metadata
createdAt
```

## Campos de Visibilidade Futuros

Para `prestadores`, `portfolio`, `stories`, `avaliacoes` publicas futuras e
perfis pesquisaveis, a M2.17 deve preparar:

```text
isPublic
isSearchable
moderationStatus
moderationUpdatedAt
suspendedAt
bannedAt
hiddenAt
hiddenReason
lastReportAt
reportsCount
```

Para discovery, a regra futura deve ser:

```text
so aparece se isPublic == true;
so aparece se isSearchable == true;
nao aparece se moderationStatus for pending_review, flagged, hidden, rejected,
suspended ou banned, conforme politica final;
nao aparece se o prestador estiver suspenso/bloqueado;
nao mostra media de rating invalida;
nao mostra dados privados.
```

## Regras de Visibilidade

Regras esperadas para fases seguintes:

```text
perfis suspensos nao aparecem na pesquisa;
perfis pending_review podem ficar ocultos ate analise;
portfolio media flagged fica escondido do perfil publico;
stories flagged ficam fora do carousel publico;
usuario bloqueado nao pode enviar mensagem ao bloqueador;
mensagens reportadas entram em fila de moderacao;
reviews publicas reportadas podem ser ocultadas;
categorias sugeridas so entram no catalogo apos aprovacao;
servicos proibidos nao entram em discovery;
dados privados continuam fora de cards/listas.
```

## Relacao com M2.16 Discovery

A M2.16 criou discovery inicial usando `prestadores` como fonte, com
`ProviderSearchProfile`, cards compactos, pesquisa manual, favoritos e sugestoes
na Home Cliente. Isso e correto para a primeira versao, mas nao e suficiente
para escala publica sem campos de Trust & Safety.

Dependencias futuras para discovery seguro:

```text
isPublic;
isSearchable;
moderationStatus;
suspendedAt/bannedAt;
filtro de servicos proibidos;
bloqueio entre usuarios;
separacao futura publicProfiles/providerSearchIndex;
admin/moderacao para remover ou restaurar conteudo.
```

## Relacao com KYC

M2.17 nao e KYC.

KYC/documentos/selfie/liveness ficam para M2.23. M2.17 apenas prepara estados,
denuncias, filas e regras de visibilidade para reduzir risco operacional.

Textos proibidos antes de processo real:

```text
verificado;
certificado;
garantido;
pagamento seguro;
identidade confirmada;
aprovado oficialmente;
garantido pelo ChegaJa;
certificado pelo ChegaJa.
```

## Relacao com Admin

M2.17 prepara o modelo de moderacao. M2.18 deve criar backoffice/admin leve para
operar essa fila.

Capacidades futuras do admin:

```text
ver denuncias;
abrir caso;
atribuir severidade;
ocultar/restaurar conteudo;
suspender/restaurar utilizador;
aprovar/rejeitar categoria sensivel;
registar decisao;
consultar audit log;
responder recurso;
ver metricas basicas de abuso.
```

## Testes Necessarios Futuramente

Rules/Functions:

```text
cliente/prestador cria denuncia valida;
utilizador anonimo nao cria denuncia;
reporter nao altera status da denuncia;
usuario comum nao altera moderationStatus;
apenas admin/moderador altera moderationStatus;
perfil suspenso nao aparece em discovery;
portfolio hidden nao aparece no perfil publico;
story hidden nao aparece no carousel;
usuario bloqueado nao envia mensagem ao bloqueador;
audit log e criado quando admin altera estado;
categoria proibida/sensivel nao vira publica sem aprovacao.
```

UI:

```text
denunciar perfil;
denunciar portfolio;
denunciar mensagem;
denunciar avaliacao futura;
bloquear usuario;
confirmacao clara;
erro/loading;
dark mode;
acessibilidade;
E2E report/block.
```

## Subfases M2.17

```text
M2.17.1 - Spec e auditoria Trust & Safety
M2.17.2 - Modelo de denuncias, bloqueios e moderacao
M2.17.3 - UI de denuncia/bloqueio em perfil, chat e portfolio
M2.17.4 - Fila basica de moderacao/admin leve
M2.17.5 - Filtros de servicos proibidos e categorias sensiveis
M2.17.6 - Testes, E2E, QA visual e documentacao final
```

## Decisao Tecnica

M2.17 deve avancar em camadas:

```text
1. modelo e regras de dados;
2. Rules e testes de seguranca;
3. UI de denuncia/bloqueio;
4. fila/admin leve;
5. filtros de categorias proibidas/sensiveis;
6. QA final.
```

Nao e seguro adicionar apenas botoes de denuncia sem modelo, estados,
permissoes e auditoria. Tambem nao e seguro expandir discovery publico sem
campo de visibilidade/moderacao.

## Implementacao M2.17.2

A M2.17.2 criou a base tecnica minima:

```text
lib/core/models/moderation_types.dart
lib/core/models/trust_safety_report.dart
lib/core/models/user_block.dart
lib/core/models/moderation_case.dart
lib/core/services/trust_safety_service.dart
```

Rules adicionadas:

```text
reports/{reportId}
users/{uid}/blockedUsers/{blockedUid}
```

Testes adicionados:

```text
functions/test/firestore.test.js
test/core/trust_safety_models_test.dart
test/core/trust_safety_service_test.dart
```

Decisao:

```text
reports e blockedUsers foram implementados agora;
ModerationCase foi criado como modelo/contrato;
moderationCases automaticos e fila visual ficam para M2.17.4/M2.18;
UI de denuncia/bloqueio fica para M2.17.3.
```

## Implementacao M2.17.3

```text
lib/features/common/trust_safety/report_content_sheet.dart
lib/features/common/trust_safety/block_user_dialog.dart
lib/features/common/trust_safety/trust_safety_actions.dart
```

A M2.17.3 criou a primeira UI reutilizavel de denuncia/bloqueio:

```text
ReportContentSheet - motivo, detalhes opcionais, limite de 1000 caracteres e envio via TrustSafetyService.
BlockUserDialog - confirmacao de bloqueio, loading e feedback de erro/sucesso.
TrustSafetyActionsMenu - menu discreto para perfil publico.
PublicProfileScreen - Denunciar perfil e Bloquear utilizador.
ChatThreadScreen - Denunciar conversa, Denunciar mensagem e Bloquear utilizador.
MediaViewerScreen - Denunciar imagem de portfolio quando aberto pelo perfil publico.
```

A fase nao alterou Rules, Storage Rules, Cloud Functions nem deploy. O bloqueio
fica gravado em `blockedUsers`, mas ainda nao impede mensagens por regra de
seguranca ou logica de envio; esse enforcement fica para fase posterior.

## Proximo Passo

```text
M2.17.4 - Fila basica de moderacao/admin leve
```

Objetivo recomendado da M2.17.4:

```text
criar a primeira fila interna de reports;
permitir leitura/triagem basica por admin/dev;
preparar moderationCases reais;
documentar decisoes de aprovacao/rejeicao;
sem KYC, pagamentos ou admin completo ainda.
```
