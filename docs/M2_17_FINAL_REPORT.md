# M2.17 - Relatorio Final Trust & Safety Basico

Data: 2026-05-29

## Estado Final

M2.17 fechada no escopo atual de Trust & Safety basico.

```text
M2.17.1 - FECHADA
M2.17.2 - FECHADA
M2.17.3 - FECHADA
M2.17.4 - FECHADA
M2.17.5 - FECHADA
M2.17.6 - FECHADA
```

Blocos relacionados:

```text
Bloco F - PARCIAL
Bloco H - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo da M2.17

Criar a primeira base real de Trust & Safety do ChegaJa depois da abertura de
discovery manual na M2.16.

A M2.17 protege o crescimento de perfis publicos, pesquisa, portfolio, chat,
avaliacoes e pedidos com uma camada basica de:

```text
politica e auditoria;
denuncias;
bloqueios;
moderacao leve;
fila admin;
filtros preventivos.
```

## Commits Principais

```text
688806cfba08aecaf0c018b3b2a614fb0cd6531a
Iniciar M2.17 trust safety moderacao

321ee20637dcfaf0b6d09851d2d2be7f4c0df9f9
Criar M2.17.2 modelos denuncias bloqueios

42b4561b643ec0de33df4a284f16b9b6b30b83ca
Criar M2.17.3 UI denuncia bloqueio

5897516b1b1d77392f04fb88b2d8b8c89211fa9a
Criar M2.17.4 fila moderacao admin

a9e8859b30515e498b9c7602310f230a8ab89190
Criar M2.17.5 filtros servicos proibidos
```

## Resumo por Fase

### M2.17.1

Criou a spec e auditoria de Trust & Safety.

Mapeou superficies de risco:

```text
perfil publico;
bio/descricao;
foto/avatar;
portfolio;
chat/mensagens;
avaliacoes;
pedidos;
discovery/search;
futura partilha publica.
```

Definiu servicos proibidos, conteudo proibido, categorias sensiveis, tipos de
denuncia, severidade, estados de moderacao e modelo futuro de dados.

### M2.17.2

Criou a base tecnica minima:

```text
lib/core/models/moderation_types.dart
lib/core/models/trust_safety_report.dart
lib/core/models/user_block.dart
lib/core/models/moderation_case.dart
lib/core/services/trust_safety_service.dart
```

Adicionou Rules e testes para:

```text
reports/{reportId}
users/{uid}/blockedUsers/{blockedUid}
```

Garantiu que utilizador comum nao cria denuncia em nome de outro, nao altera
status de denuncia, nao le denuncia alheia e nao bloqueia a si proprio.

### M2.17.3

Criou a primeira UI real de denuncia/bloqueio:

```text
ReportContentSheet
BlockUserDialog
TrustSafetyActionsMenu
```

Integracoes feitas:

```text
PublicProfileScreen - Denunciar perfil e Bloquear utilizador
ChatThreadScreen - Denunciar conversa, Denunciar mensagem e Bloquear utilizador
MediaViewerScreen - Denunciar imagem de portfolio
```

### M2.17.4

Transformou `reports/{reportId}` na fila inicial de moderacao.

Criou:

```text
admin_listReports
admin_updateReportStatus
AdminService.listReports
AdminService.updateReportStatus
AdminReportsSection
```

Admin/dev consegue listar reports e atualizar status de triagem. Utilizador
comum e anonimo nao conseguem acessar as callables.

### M2.17.5

Criou filtros simples e auditaveis:

```text
TrustSafetyTextNormalizer
ProhibitedTerms
SensitiveCategories
TrustSafetyClassifier
TrustSafetyClassification
```

Decisoes:

```text
allow - segue normalmente
warn - mostra aviso e permite continuar
needsReview - mostra aviso e permite continuar
block - bloqueia envio/gravacao
```

Integracao leve:

```text
PrestadorPerfilScreen - nome/bio
NovoPedidoScreen - titulo/descricao/categoria
```

### M2.17.6

Fechou QA final:

```text
testes focados;
Functions tests;
Flutter completo;
build Web release;
E2E dual;
E2E orcamento;
QA visual;
documentacao final.
```

## O Que Foi Implementado

```text
politica tecnica inicial de Trust & Safety;
modelos de report, block e moderation;
Rules para reports e blockedUsers;
servico de Trust & Safety;
UI de denunciar/bloquear;
denuncia em perfil, chat e imagem de portfolio;
fila admin basica de reports;
callables admin para listar/atualizar reports;
classifier client-side de termos proibidos e categorias sensiveis;
testes de Rules, Functions, modelos, services, widgets e fluxos principais.
```

## O Que Ficou Fora

```text
KYC completo;
documentos/selfie/liveness;
validacao server-side definitiva de filtros;
moderacao automatica com IA;
ocultacao automatica de conteudo;
banimento automatico;
moderationCases automaticos;
admin/backoffice completo;
roles granulares de moderador;
custom claims novos;
categorias sensiveis com comprovativos;
videos no portfolio;
pagamentos;
ranking;
deploy;
Android fisico;
tester externo.
```

## Decisoes Importantes

Denuncia sem fila de analise nao era suficiente. Por isso a M2.17 criou dado,
UI e fila admin basica.

Bloqueio foi implementado primeiro como sinal persistido. Enforcement completo
no chat continua futuro porque exige regras/logica de envio e mais QA.

Reports viraram a fila inicial. `ModerationCase` ficou como contrato/modelo
para evolucao futura, sem automacao prematura.

Os filtros da M2.17.5 sao preventivos e client-side. Eles melhoram UX e reduzem
entrada obvia de conteudo proibido, mas nao substituem enforcement server-side
antes de producao publica em escala.

Nao foram usados textos de confianca indevida como "verificado",
"certificado", "garantido" ou "aprovado oficialmente".

## Validacoes

```text
git diff --check - passou
npm.cmd run test:scripts - passou
node --check functions/index.js - passou
npm.cmd --prefix functions test - passou, 119 passing
testes focados de Trust & Safety - passaram
testes focados de UI denuncia/bloqueio - passaram
flutter test --no-pub - passou, 289/289
flutter build web release - passou
e2e:ui:dual - passou, FULL MULTI-SCENARIO FLOW OK
e2e:ui:orcamento - passou, ORCAMENTO MIN-MAX FLOW OK
QA visual - passou, 8 screenshots gerados
```

## Riscos Remanescentes

```text
filtros client-side podem ser contornados sem validacao server-side;
bloqueio ainda nao impede chat por enforcement completo;
conteudo denunciado nao e ocultado automaticamente;
admin atual ainda e fila leve, nao backoffice completo;
discovery ainda precisa considerar isPublic/isSearchable/moderationStatus;
categorias sensiveis ainda nao tem comprovativos/KYC;
moderacao assistida/automatica ainda nao existe.
```

## Decisao Final

M2.17 esta fechada no escopo atual de Trust & Safety basico.

O proximo bloco recomendado e:

```text
M2.18 - Admin/backoffice leve para operacao interna
```
