# M2.17.1 - Auditoria Trust & Safety

Data: 2026-05-29

## Estado

```text
M2.17.1 - CONCLUIDA
M2.17 - INICIADA
M2.17.2 - PROXIMO PASSO
```

Estado global mantido:

```text
M2.14 - fechada no escopo atual
M2.15 - fechada no escopo atual
M2.16 - fechada no escopo atual
Bloco F - parcial
Bloco H - parcial
R - pausado por falta de tester humano real
M - pausado por falta de Android fisico real
R1 - pendente
M2.6 - pendente
```

## Objetivo da Fase

Mapear as superficies de risco de Trust & Safety antes de implementar denuncia,
bloqueio, moderacao, filtros ou fila admin.

Esta fase foi documental/auditoria. Nao houve implementacao de UI, Rules,
Functions ou deploy.

## Ficheiros Analisados

Documentacao:

```text
docs/CHEGAJA_PRODUCT_MASTER_VISION.md
docs/CHEGAJA_TRUST_SAFETY_POLICY_DRAFT.md
docs/CHEGAJA_DISCOVERY_SEARCH_PROFILE_SPEC.md
docs/M2_16_FINAL_REPORT.md
docs/M2_16_6_QA_FINAL_DISCOVERY_STATUS.md
docs/ROADMAP_A_T_CHEGAJA.md
```

Codigo e regras:

```text
lib/features/common/perfil_publico_screen.dart
lib/features/common/mensagens/chat_thread_screen.dart
lib/features/cliente/discovery/provider_search_screen.dart
lib/features/cliente/discovery/provider_search_profile.dart
lib/features/prestador/prestador_perfil_screen.dart
lib/features/prestador/widgets/prestador_portfolio_manager_section.dart
lib/features/cliente/widgets/avaliacao_pedido_card.dart
lib/features/common/report_problem_screen.dart
firestore.rules
storage.rules
functions/index.js
```

Testes identificados para fases futuras:

```text
functions/test/firestore.test.js
functions/test/avaliacaoFunctions.test.js
test/features/common/perfil_publico_screen_test.dart
test/features/cliente/discovery/provider_search_screen_test.dart
test/features/cliente/discovery/provider_search_card_test.dart
test/features/cliente/discovery/provider_search_profile_test.dart
test/features/cliente/widgets/avaliacao_pedido_card_test.dart
test/features/prestador/prestador_perfil_portfolio_test.dart
test/core/chat_call_services_test.dart
test/core/chat_message_location_test.dart
```

## Superficies de Risco Encontradas

### Perfil publico

`PublicProfileScreen` le `prestadores/{uid}` para prestadores e `users/{uid}`
para clientes. O perfil publico mostra:

```text
foto/avatar;
nome;
bio;
area/cidade/pais;
servicos;
portfolio;
reputacao leve;
telefone de contacto quando o campo existe;
badges leves de confianca.
```

Riscos:

```text
nao ha filtro por moderationStatus;
nao ha isPublic/isSearchable;
nao ha reportar perfil;
nao ha bloquear usuario;
telefone pode aparecer em contexto publico se existir no documento;
portfolio nao tem status individual de moderacao.
```

### Discovery/search

`ProviderSearchScreen` e sugestoes da Home usam `prestadores` como fonte,
`ProviderSearchProfile` como whitelist local e abrem `PublicProfileScreen`.

Pontos positivos:

```text
nao usa users como fonte principal;
nao mostra telefone/email/ratingSum nos cards;
usa modelo publico whitelisted;
abre perfil unico.
```

Riscos:

```text
nao ha isPublic/isSearchable vindo do backend;
nao ha filtro de suspended/banned;
nao ha moderationStatus;
nao ha filtro real de servicos proibidos;
ranking/score local ainda nao considera Trust & Safety.
```

### Portfolio e media

`PrestadorPerfilScreen` e `PrestadorPortfolioManagerSection` permitem gerir
imagens de portfolio. Storage permite leitura publica de caminhos de portfolio e
stories.

Riscos:

```text
nao ha reportar imagem;
nao ha ocultar media especifica;
nao ha moderationStatus por imagem;
nao ha analise antes de aparecer no perfil publico;
nao ha fila admin de media reportada.
```

### Chat e mensagens

`ChatThreadScreen` suporta mensagens, imagens, ficheiros e audio. Rules permitem
participantes criarem mensagens nos chats em que participam.

Riscos:

```text
nao ha denunciar mensagem;
nao ha bloquear usuario;
nao ha impeditivo de mensagem quando um usuario bloqueia outro;
nao ha moderationStatus por mensagem;
anexos de chat ainda nao tem fluxo de denuncia/moderacao.
```

### Avaliacoes

M2.15 protegeu a criacao de avaliacoes e agregados. `AvaliacaoPedidoCard` mostra
formulario/resumo para cliente apos pedido concluido. Comentarios publicos ainda
ficam fora.

Pontos positivos:

```text
avaliacao so por cliente do pedido concluido;
docId correto;
agregados por Function autoritativa;
comentarios nao sao publicados no perfil.
```

Riscos futuros:

```text
se reviews publicas entrarem, sera preciso denunciar/ocultar comentario;
sera preciso moderationStatus/hiddenByAdmin para reviews publicas;
sera preciso evitar exposicao de nome/foto do cliente sem decisao de privacidade.
```

### Pedidos/servicos personalizados

Pedidos e descricoes podem conter texto livre. Categorias/servicos podem ser
usados como superficie para servicos proibidos ou sensiveis.

Riscos:

```text
servicos proibidos ainda nao tem filtro dedicado;
categorias sensiveis ainda nao tem workflow de aprovacao;
pedidos com texto problematico ainda nao entram em fila de analise.
```

### Suporte existente

Existe `support_tickets` e `SupportService`, alem de admin listar tickets. Isso
serve suporte, mas nao substitui Trust & Safety.

Tambem existe `ReportProblemScreen`, mas ele e focado em problema/no-show de
pedido e chama cancelamento de pedido. Nao e denuncia generica de conteudo,
perfil, portfolio, mensagem ou usuario.

## O Que Ja Existe

```text
support_tickets;
ReportProblemScreen para problema de pedido/no-show;
AdminPanel com areas de suporte/no-show/stories;
AdminService para algumas operacoes internas;
Rules de suporte;
Rules de avaliacoes endurecidas;
Function autoritativa de agregados de avaliacao;
ProviderSearchProfile com whitelist publica;
PublicProfileScreen unico.
```

## O Que Ainda Nao Existe

```text
reports/{reportId};
moderationCases/{caseId};
userBlocks;
blockedUsers por usuario;
moderationActions;
auditLogs de moderacao;
moderationStatus em prestadores/portfolio/stories/messages/reviews;
isPublic/isSearchable persistido;
filtro de perfis suspensos na pesquisa;
denunciar perfil;
denunciar portfolio;
denunciar mensagem;
denunciar avaliacao futura;
bloquear usuario;
fila de moderacao;
admin/moderador com estados;
filtros de servicos proibidos;
workflow de categorias sensiveis.
```

## Firestore Rules - Situacao Atual

Achados principais:

```text
prestadores/{prestadorId} tem read publico;
prestador dono pode atualizar perfil, mas nao rating aggregates;
avaliacoes so podem ser criadas pelo cliente dono do pedido concluido;
users/{uid}/favorites e privado ao proprio usuario/admin;
support_tickets existe para suporte;
chats/messages sao acessiveis aos participantes;
stories tem read publico;
servicos tem read publico e escrita admin/dev.
```

Riscos para M2.17:

```text
nao ha colecao reports;
nao ha Rules de blocks;
nao ha Rules de moderationCases;
nao ha protecao de moderationStatus porque o campo ainda nao existe;
nao ha regra para esconder perfis suspensos em discovery, porque Rules nao
filtram listas por si so sem a query/campos corretos;
nao ha testes de Rules para denuncia/bloqueio/moderacao.
```

## Storage Rules - Situacao Atual

Achados principais:

```text
portfolio de prestador tem leitura publica;
prestadores/{prestadorId}/portfolio tem leitura publica;
stories tem leitura publica;
chats/anexos sao restritos a participantes;
kyc ja esta em caminho privado.
```

Riscos:

```text
media publica ainda nao tem status de moderacao;
nao ha fluxo para ocultar item especifico sem remover do documento;
nao ha denuncia de media;
stories/portfolio publicos precisam de campos/colecoes auxiliares para hide.
```

## Functions - Situacao Atual

Achados principais:

```text
existem Functions para chat/notificacoes, matching, avaliacoes, financeiro,
suporte e admin parcial;
nao foi encontrada Function especifica para reports/moderationCases/userBlocks;
nao ha trigger para abrir caso de moderacao a partir de denuncia.
```

## Servicos Proibidos Definidos

```text
prostituicao;
pornografia/servicos sexuais;
trafico humano;
drogas ilegais;
armas ilegais;
fraude;
falsificacao de documentos;
servicos violentos/criminosos;
exploracao de menores;
venda de bens/servicos ilegais;
qualquer servico ilegal ou que viole regras da plataforma.
```

## Conteudo Proibido Definido

```text
nudez sexual;
imagens obscenas;
violencia grafica;
ameacas;
assedio;
discurso de odio;
dados pessoais expostos indevidamente;
fotos/videos sem consentimento;
spam/fraude;
links maliciosos;
tentativa de contornar a plataforma.
```

## Categorias Sensiveis Definidas

```text
saude;
cuidados infantis;
eletricidade/gas;
seguranca;
alimentacao profissional;
treino/nutricao;
transporte;
servicos em casa do cliente;
servicos envolvendo menores;
servicos que exijam certificados/licenca local.
```

## Estados de Moderacao Propostos

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

## Tipos e Motivos de Denuncia Propostos

Tipos:

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

Motivos:

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

Severidade:

```text
low
medium
high
critical
```

## Modelo Futuro Recomendado

```text
reports/{reportId}
moderationCases/{caseId}
users/{uid}/blockedUsers/{otherUid}
userBlocks/{blockId}
moderationActions/{actionId}
auditLogs/{logId}
categorySuggestions/{id}
sensitiveCategoryRequests/{id}
```

## Relacao com Discovery

Discovery/search da M2.16 so e seguro a longo prazo se M2.17 introduzir:

```text
isPublic;
isSearchable;
moderationStatus;
suspendedAt/bannedAt;
filtro de servicos proibidos;
bloqueio de usuarios;
controle de media publica;
publicProfiles/providerSearchIndex futuro.
```

## Relacao com KYC

M2.17 nao fecha KYC. KYC/documentos/selfie/liveness ficam para M2.23. A M2.17
apenas prepara denuncias, estados, visibilidade e moderacao basica.

Textos como `verificado`, `certificado`, `garantido`, `pagamento seguro` ou
`identidade confirmada` continuam proibidos antes de processo real.

## Relacao com Admin

Admin/backoffice completo continua em M2.18. A M2.17 deve preparar os dados e
estados que o admin vai operar:

```text
fila de denuncias;
casos de moderacao;
acoes de moderador;
audit logs;
ocultar/restaurar conteudo;
suspender/restaurar utilizador;
aprovar/rejeitar categorias sensiveis.
```

## Riscos Encontrados

```text
prestadores tem read publico sem campo de visibilidade/moderacao;
portfolio e stories tem leitura publica;
PublicProfileScreen pode mostrar telefone se existir no documento;
chat nao tem report/block;
ReportProblemScreen atual nao e denuncia generica;
nao ha modelo reports/moderationCases/userBlocks;
nao ha testes de Rules para Trust & Safety;
nao ha admin queue de moderacao;
discovery nao filtra suspensao/moderacao.
```

## Decisao Recomendada Para M2.17.2

Avancar para:

```text
M2.17.2 - Modelo de denuncias, bloqueios e moderacao
```

Escopo recomendado:

```text
criar modelo minimo de reports;
criar modelo de userBlocks/blockedUsers;
definir campos moderationStatus/isPublic/isSearchable em prestadores sem
quebrar perfis existentes;
endurecer Rules com testes RED/GREEN;
impedir usuario comum de alterar moderationStatus;
preparar discovery para respeitar visibilidade quando os campos existirem;
nao criar admin completo ainda;
nao criar KYC.
```

## Fora do Escopo Mantido

```text
UI de denuncia;
UI de bloqueio;
fila admin;
KYC;
videos;
pagamentos;
ranking;
alteracao de Rules;
alteracao de Functions;
deploy;
Android fisico;
tester externo;
fechar R;
fechar M;
fechar R1;
fechar M2.6.
```

## Validacoes

Executadas para a fase documental:

```text
git status
git diff --check
npm.cmd run test:scripts
```

## Decisao Final

M2.17.1 fica concluida como spec/auditoria. O produto deve seguir para M2.17.2
antes de adicionar botoes de denuncia ou UI de moderacao. A ordem correta e:

```text
modelo e Rules primeiro;
UI depois;
admin/fila depois;
filtros de servicos proibidos e categorias sensiveis depois.
```
