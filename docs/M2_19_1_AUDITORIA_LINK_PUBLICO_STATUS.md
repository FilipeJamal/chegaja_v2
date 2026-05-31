# M2.19.1 - Auditoria Link Publico, @handle e Partilha Social

Data: 2026-05-31

## Estado

M2.19.1 concluida.

```text
M2.19 - iniciada
M2.19.1 - FECHADA
M2.19.2 - PROXIMO passo
M2.18 - FECHADA no escopo atual
Bloco F - PARCIAL
Bloco H - PARCIAL
Bloco J - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo

Fazer spec e auditoria antes de implementar @handle, rotas publicas ou partilha
social.

Esta fase foi documental/auditoria.

## Ficheiros Lidos

```text
docs/CHEGAJA_PRODUCT_MASTER_VISION.md
docs/CHEGAJA_DISCOVERY_SEARCH_PROFILE_SPEC.md
docs/CHEGAJA_TRUST_SAFETY_POLICY_DRAFT.md
docs/M2_16_FINAL_REPORT.md
docs/M2_17_FINAL_REPORT.md
docs/M2_18_FINAL_REPORT.md
docs/ROADMAP_A_T_CHEGAJA.md
lib/features/common/perfil_publico_screen.dart
lib/features/common/utils/open_public_profile.dart
lib/features/cliente/discovery/provider_search_profile.dart
lib/features/cliente/discovery/provider_search_screen.dart
lib/features/prestador/prestador_perfil_screen.dart
lib/features/prestador/widgets/prestador_portfolio_manager_section.dart
lib/core/trust_safety/trust_safety_classifier.dart
lib/core/trust_safety/trust_safety_text_normalizer.dart
lib/app.dart
lib/main.dart
lib/core/services/deep_link_service.dart
firestore.rules
storage.rules
functions/index.js
firebase.json
```

Tambem foram procurados termos relacionados com:

```text
handle;
username;
slug;
share;
copiar link;
public profile;
deep link;
/pedido/;
Uri;
Navigator;
MaterialPageRoute;
Firebase Hosting rewrites;
web routing.
```

## Conclusoes da Auditoria

### Perfil Publico

O perfil publico existe e e o destino correto para a futura rota publica.

Hoje ele abre assim:

```text
openPublicProfile
-> Navigator.push(MaterialPageRoute)
-> PublicProfileScreen(userId, role)
```

Para prestadores, a tela le:

```text
prestadores/{uid}
```

Pontos existentes positivos:

```text
PublicProfileScreen ja e a tela unica de perfil publico;
perfil pode ser aberto a partir da pesquisa manual;
denuncia/bloqueio ja existem no perfil;
portfolio publico ja existe;
rating leve ja existe;
ProviderSearchProfile ja possui campo handle opcional.
```

Lacunas:

```text
nao existe rota publica por handle;
nao existe resolver de handle para uid;
nao existe 404 amigavel para perfil publico;
nao existe colecao handles;
nao existe validacao de handle;
nao existe UI para escolher/editar handle.
```

### Privacidade

O principal risco encontrado e que `PublicProfileScreen` ainda pode mostrar
telefone se o documento do prestador possuir `phoneE164`, `phoneNumber`,
`phone` ou `phoneRaw`.

Para link publico externo, a decisao recomendada e:

```text
telefone nao aparece por defeito;
email nao aparece por defeito;
contacto publico deve ser opt-in futuro;
KYC/documentos nunca aparecem;
reports/moderacao/audit logs nunca aparecem;
dados privados nao devem ser copiados para documentos publicos.
```

### Navegacao e Rotas

O app usa `MaterialApp` com `home`, `Navigator` e `MaterialPageRoute`.

Nao foi encontrado:

```text
go_router;
onGenerateRoute publico;
tabela de rotas para /p/{handle};
resolver de perfil por URL.
```

O `DeepLinkService` existe, mas hoje resolve apenas:

```text
/pedido/{pedidoId};
/chat/{pedidoId};
chegaja://pedido/{pedidoId};
chegaja://chat/{pedidoId};
?pedidoId={pedidoId}.
```

M2.19.4 deve estender a navegacao com cuidado para nao quebrar `/pedido` e
`/chat`.

### Firebase Hosting

O `firebase.json` atual possui Firestore, Storage, Functions e Emulators, mas
nao possui secao `hosting` nem rewrites para SPA.

Risco:

```text
refresh direto em /p/{handle} pode falhar em Hosting se nao houver rewrite para index.html.
```

M2.19.4 ou fase de deploy/web deve tratar isso antes de links publicos reais.

### Firestore Rules

Nao existe regra para:

```text
handles/{handleNormalized}
```

`prestadores/{prestadorId}` esta com leitura publica:

```text
allow read: if true;
```

Isso reforca a necessidade de manter dados privados fora do documento publico ou
rever a modelagem antes de escala publica externa.

Reports e blockedUsers ja possuem regras de Trust & Safety criadas na M2.17.

### Functions

Nao existe callable para:

```text
reservar handle;
trocar handle;
listar/validar handle;
resolver handle.
```

As Functions admin de M2.18 existem para reports, suporte, no-show, stories,
ledger e audit logs. M2.19.1 nao alterou Functions.

## Decisoes Recomendadas

### Formato de Link

Recomendado:

```text
/p/{handle}
```

Exemplo:

```text
https://chegaja-ac88d.web.app/p/maria_bolos
```

Motivo:

```text
curto;
simples;
nao depende de @ na URL;
nao colide com /pedido ou /chat;
facil de resolver no Flutter Web.
```

### Modelo de Handle

Recomendado:

```text
handles/{handleNormalized}
```

Campos:

```text
uid;
role;
status;
createdAt;
updatedAt;
reservedUntil;
releasedAt;
previousOwnerUid;
source.
```

Tambem guardar copia em:

```text
prestadores/{uid}.handle
prestadores/{uid}.handleDisplay
prestadores/{uid}.handleUpdatedAt
```

Motivo:

```text
handles/{handleNormalized} garante unicidade natural pelo documentId;
prestadores/{uid}.handle facilita leitura no perfil e discovery.
```

### Regras de Handle

Definidas na spec:

```text
3 a 30 caracteres;
lowercase;
sem espacos;
sem acentos no valor final;
letras, numeros, ponto, underline e hifen;
sem separador no inicio/fim;
sem separadores repetidos.
```

### Trust & Safety

O handle deve passar por:

```text
lista de handles reservados;
normalizador proprio;
TrustSafetyClassifier para termos proibidos;
regras futuras de perfil ativo/publico/moderado.
```

Links publicos nao podem contornar moderacao.

## Riscos Encontrados

```text
colisao de handles sem colecao dedicada;
handle ofensivo ou reservado;
impersonation de marca/nome;
telefone exposto no perfil publico atual;
prestadores/{uid} tem leitura publica;
refresh direto em /p/{handle} sem Hosting rewrite;
SEO e preview social limitados em Flutter Web SPA;
mudanca de handle quebrar links antigos;
perfil suspenso ainda acessivel por link se nao houver regra;
validacao client-side insuficiente para escala publica;
falta de dominio customizado.
```

## Fora do Escopo Mantido

```text
implementar handle;
criar colecao handles;
alterar Firestore Rules;
alterar Storage Rules;
alterar Cloud Functions;
criar UI;
criar rota publica;
criar partilha;
criar QR;
deploy;
KYC;
pagamentos;
Android fisico;
tester externo;
fechar R;
fechar M;
fechar R1;
fechar M2.6.
```

## Validacoes

```text
git status - executado
git diff --check - passou
npm.cmd run test:scripts - passou
```

## Decisao Final

M2.19.1 fica fechada como fase documental/auditoria.

Proximo passo:

```text
M2.19.2 - Modelo, normalizacao e reserva de @handle
```

M2.19.2 deve implementar a base tecnica sem criar ainda rota publica ou partilha
social.
