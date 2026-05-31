# M2.19 - Relatorio Final Link Publico, @handle e Partilha Social

Data: 2026-05-31

## Estado Final

M2.19 fechada no escopo atual de link publico, @handle e partilha social.

```text
M2.19.1 - FECHADA - Spec e auditoria de link publico, @handle e partilha social
M2.19.2 - FECHADA - Modelo, normalizacao e reserva de @handle
M2.19.3 - FECHADA - UI de @handle no perfil do prestador
M2.19.4 - FECHADA - Rota publica/deep link por @handle
M2.19.5 - FECHADA - Partilha social, copiar link e QR futuro
M2.19.6 - FECHADA - Testes, E2E, QA visual e documentacao final
```

Blocos relacionados continuam assim:

```text
Bloco F - PARCIAL
Bloco H - PARCIAL
Bloco J - PARCIAL
R - pausado
M - pausado
R1 - pendente
M2.6 - pendente
```

## Objetivo da M2.19

Permitir que cada prestador tenha uma identidade publica partilhavel:

```text
@handle publico;
link publico;
abertura do perfil por link;
partilha social;
base futura para QR Code e descoberta externa.
```

O bloco transforma o perfil do prestador numa pagina ChegaJa divulgavel em
Instagram, Facebook, WhatsApp, site, cartao ou outros canais, sem depender de
partilha manual por `uid`.

## Commits Principais

```text
6eff8ba86c3a78862eab5217a8f0f9191c04b6e5
Iniciar M2.19 link publico handle

88894621bd3d946cad5e72658d41d5b2c36445f4
Criar M2.19.2 modelo reserva handle

3f3412deea8e164dfae0187bf1c6fa01970d9348
Criar M2.19.3 UI handle prestador

12e3a85dd81332bf7ce437922be9cf896683ef56
Criar M2.19.4 rota publica handle

844ef9c8b4ca667842155ff4c7365ab60ba47e7b
Criar M2.19.5 partilha perfil publico
```

## Fases

### M2.19.1

Criou a spec e auditoria de link publico, @handle e partilha social. A fase
confirmou que o `PublicProfileScreen` ja era a tela unica de perfil publico,
mas ainda nao havia rota publica por handle, resolver, colecao `handles`, UI de
handle, 404 amigavel ou partilha.

Decisao principal:

```text
link publico: /p/{handle}
fonte de unicidade: handles/{handleNormalized}
copia de leitura rapida: prestadores/{uid}.handle/handleDisplay/handleUpdatedAt
```

### M2.19.2

Criou a base tecnica de handle:

```text
HandleNormalizer;
HandleValidator;
ReservedHandles;
PublicHandle;
HandleService;
handle_checkAvailability;
handle_reserveProviderHandle;
Rules para handles/{handleNormalized};
protecao de handle/handleDisplay/handleUpdatedAt em prestadores/{uid}.
```

A troca de handle ficou conservadora: o handle antigo fica `released`, com
`previousOwnerUid`, mas continua indisponivel para outros nesta fase.

### M2.19.3

Criou a experiencia visual do prestador:

```text
PrestadorHandleSection;
secao "Pagina publica" no PrestadorPerfilScreen;
validacao local;
check availability;
reserva/guardar handle;
handle atual;
preview de link;
display de @handle no PublicProfileScreen;
display de @handle no ProviderSearchCard.
```

A fase nao prometeu link ativo antes de a rota publica existir.

### M2.19.4

Criou a rota publica/deep link por handle:

```text
DeepLinkService suporta /p/{handle}, chegaja://p/{handle} e ?handle={handle};
PublicHandleResolver resolve handles/{handleNormalized};
PublicProfileByHandleScreen faz loading/404/indisponivel/erro;
PublicProfileScreen continua sendo a tela final;
firebase.json recebeu rewrite SPA;
telefone deixou de aparecer por defeito no perfil publico.
```

### M2.19.5

Criou a partilha simples:

```text
PublicProfileLinkService;
PublicProfileShareActions;
copiar link;
WhatsApp por https://wa.me/?text=...;
Facebook por sharer URL;
Instagram tratado como copiar link;
link publico real no PrestadorHandleSection;
acoes de partilha no PublicProfileScreen para prestador com handle.
```

Nao foram adicionadas dependencias pesadas de partilha nativa nem QR Code real.

### M2.19.6

Fechou o bloco com documentacao final, testes focados, Functions, Flutter
completo, build Web, E2E, QA visual e validacao headless de `/p/{handle}`.

Durante o QA final, foi corrigido um bloqueador simples e direto da M2.19:
abertura direta de `/p/{handle}` em Flutter Web entrava no `home` inicial em vez
do wrapper de perfil publico. A correcao ficou limitada a `lib/app.dart` e ao
teste `test/app_public_handle_route_test.dart`, sem alterar Rules, Functions ou
deploy.

## Implementado no Escopo

```text
@handle normalizado e validado;
lista de handles reservados;
bloqueio Trust & Safety para handles proibidos;
colecao tecnica handles/{handleNormalized};
reserva/unicidade por Cloud Function;
HandleService para UI;
UI do prestador para escolher/editar handle;
rota publica /p/{handle};
resolver de handle para uid;
404 amigavel;
perfil publico por handle;
telefone oculto por defeito;
link publico centralizado;
copiar link;
partilha WhatsApp/Facebook por URL;
Instagram como copiar link;
documentacao final.
```

## Validado

```text
test:scripts - passou;
node --check functions/index.js - passou;
Functions tests - 134 passing com emulador configurado;
testes focados de handle, rota, perfil publico e partilha - passaram;
flutter test --no-pub - 371/371;
build Web release - passou;
E2E dual - FULL MULTI-SCENARIO FLOW OK;
E2E orcamento - ORCAMENTO MIN-MAX FLOW OK;
QA visual - 8 screenshots;
/p/handle-inexistente - 404 amigavel, consoleErrors = 0.
```

## Decisoes Tecnicas Importantes

```text
usar /p/{handle} em vez de /@{handle};
usar handles/{handleNormalized} como fonte de verdade para unicidade;
guardar copia do handle em prestadores/{uid} apenas para leitura rapida;
nao liberar handle antigo para outro usuario nesta fase;
manter PublicProfileScreen como tela final, sem duplicar perfil;
ocultar telefone/email por defeito no perfil publico;
preparar rewrite SPA sem deploy;
centralizar URL publica em PublicProfileLinkService;
tratar Instagram como copiar link;
deixar QR real, SEO dinamico e dominio customizado para fases futuras.
```

## Fora do Escopo Mantido

```text
QR Code real
SEO/metatags dinamicas
dominio customizado
deploy
Firebase Dynamic Links
App Links/Universal Links reais
analytics de partilha
partilha nativa com nova dependencia
KYC
pagamentos
Android fisico
tester externo
fechar R
fechar R1
fechar M
fechar M2.6
```

## Riscos Remanescentes

```text
SEO e preview social seguem limitados por Flutter Web SPA;
dominio customizado ainda nao definido;
QR Code real ainda nao implementado;
App Links/Universal Links reais ainda nao existem;
sem analytics de uso dos links;
sem politica comercial de limite de mudancas de handle;
handles antigos ficam indisponiveis, mas sem redirect publico;
contacto publico opt-in ainda precisa de produto/regra propria;
categorias sensiveis ainda precisam de comprovativos e analise humana.
```

## Proximo Passo Recomendado

```text
M2.20 - Categorias sensiveis e comprovativos profissionais
```

Nao iniciar M2.20 neste fecho.
