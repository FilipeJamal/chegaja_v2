# M2.19 - Link Publico, @handle e Partilha Social

Data: 2026-05-31

## Estado

M2.19 iniciada com spec e auditoria.

```text
M2.14 - FECHADA no escopo atual de perfil, portfolio e confianca leve
M2.15 - FECHADA no escopo atual de avaliacoes e reputacao leve
M2.16 - FECHADA no escopo atual de pesquisa manual/discovery
M2.17 - FECHADA no escopo atual de Trust & Safety basico
M2.18 - FECHADA no escopo atual de Admin/backoffice leve
M2.19.1 - FECHADA com spec e auditoria
M2.19.2 - PROXIMO passo
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

## Objetivo da M2.19

Permitir que cada prestador tenha uma identidade publica partilhavel:

```text
@handle publico;
link publico;
abertura do perfil por link;
partilha social;
base futura para QR Code e descoberta externa.
```

A M2.19 responde a visao de produto em que o prestador pode divulgar a pagina
ChegaJa no Instagram, Facebook, WhatsApp, site, cartao ou outros canais, e o
cliente pode abrir esse perfil como uma montra social.

## Principio de Escopo

M2.19 nao deve criar links publicos frageis nem handles sem unicidade.

A ordem recomendada e:

```text
M2.19.1 - spec e auditoria;
M2.19.2 - modelo, normalizacao e reserva de @handle;
M2.19.3 - UI para escolher/editar @handle;
M2.19.4 - rota publica/deep link por @handle;
M2.19.5 - partilha social/copiar link/QR futuro;
M2.19.6 - QA final e documentacao.
```

Ficam fora desta spec:

```text
implementacao de UI;
criacao de colecao handles;
alteracao de Rules;
alteracao de Cloud Functions;
deploy;
KYC;
pagamentos;
SEO real com metatags dinamicas;
QR Code implementado;
partilha social implementada.
```

## Estado Atual dos Perfis Publicos

Arquivos principais:

```text
lib/features/common/perfil_publico_screen.dart
lib/features/common/utils/open_public_profile.dart
lib/features/cliente/discovery/provider_search_screen.dart
lib/features/cliente/discovery/provider_search_profile.dart
```

Hoje o perfil publico e aberto por `userId` e `role`.

Fluxo atual:

```text
ProviderSearchScreen
-> openPublicProfile(context, userId, role, initialName, initialPhotoUrl)
-> Navigator.push(MaterialPageRoute)
-> PublicProfileScreen(userId: uid, role: prestador)
```

O `PublicProfileScreen` le:

```text
prestadores/{uid}, se role == prestador;
users/{uid}, se role != prestador.
```

O discovery ja esta parcialmente preparado para handle porque
`ProviderSearchProfile` possui `handle` e inclui esse campo nos termos de busca,
quando existir no documento `prestadores/{uid}`.

Ainda nao existe:

```text
rota publica por handle;
resolver de handle para uid;
colecao handles;
validacao de unicidade;
UI de escolha/edicao de handle;
partilha/copia de link;
fallback 404 para handle inexistente.
```

## Risco Atual de Privacidade

O `PublicProfileScreen` ainda pode mostrar telefone quando o campo existe no
documento do prestador. A tela usa valores como:

```text
phoneE164;
phoneNumber;
phone;
phoneRaw.
```

Para link publico externo, isso precisa de regra mais conservadora:

```text
telefone nao deve aparecer por defeito;
email nao deve aparecer por defeito;
contacto publico deve ser opt-in futuro;
KYC/documentos nunca aparecem;
reports/moderacao/audit logs nunca aparecem;
dados internos nao devem viver em documento publico pesquisavel.
```

Antes de abrir perfil por link externo em escala, o perfil publico deve garantir
que so mostra dados publicos intencionais.

## Estado Atual de Navegacao e Rotas

Arquivos principais:

```text
lib/app.dart
lib/main.dart
lib/core/services/deep_link_service.dart
firebase.json
```

O app usa `MaterialApp` com `home`, `Navigator` e `MaterialPageRoute`.

Nao ha `go_router`, tabela de rotas publica nem `onGenerateRoute` para
resolver `/p/{handle}`.

O `RoleModeService` usa `Uri.base.queryParameters['role']` para escolher:

```text
cliente;
prestador;
admin;
role selector.
```

O `DeepLinkService` atual suporta:

```text
/pedido/{pedidoId};
/chat/{pedidoId};
chegaja://pedido/{pedidoId};
chegaja://chat/{pedidoId};
?pedidoId={pedidoId}.
```

Nao suporta:

```text
/p/{handle};
/@{handle};
/prestador/{handle}.
```

O `firebase.json` atual nao possui secao `hosting` nem rewrites para SPA.
Isso significa que refresh direto em `/p/{handle}` pode falhar em Firebase
Hosting se a rota nao for reescrita para `index.html`.

## Modelo de @handle

O handle deve aparecer visualmente com `@`, mas ser armazenado sem `@`.

Regras recomendadas:

```text
minimo 3 caracteres;
maximo 30 caracteres;
lower-case;
sem espacos;
sem acentos no valor final;
permitir letras a-z;
permitir numeros 0-9;
permitir ponto, underline e hifen;
nao permitir separador no inicio;
nao permitir separador no fim;
nao permitir separadores repetidos em sequencia;
armazenar normalizado.
```

Expressao de referencia para valor final:

```text
^[a-z0-9](?:[a-z0-9._-]{1,28}[a-z0-9])$
```

Observacao:

```text
o valor visual e @handle;
o valor persistido e handle;
o documentId em handles deve ser handleNormalized.
```

Exemplos validos:

```text
@maria_bolos
@joao-eletricista
@studioarte
@coach.fit
```

Exemplos invalidos:

```text
@ab
@maria bolos
@maria_
@-joao
@coach..fit
@maria+bolos
```

## Normalizacao de Handle

Normalizacao recomendada:

```text
trim;
remover @ inicial, se existir;
lowercase;
remover acentos;
normalizar espacos;
rejeitar espacos no resultado final;
rejeitar caracteres fora de a-z, 0-9, ponto, underline e hifen;
validar tamanho;
validar inicio/fim;
validar separadores repetidos.
```

O normalizador de Trust & Safety existente pode ser reaproveitado para comparar
termos proibidos, mas a normalizacao de handle deve ter regras proprias porque
handle e identificador publico, nao texto livre.

## Handles Reservados e Proibidos

Lista inicial de handles reservados:

```text
admin
administrator
suporte
support
help
ajuda
chegaja
chegajaapp
oficial
official
verified
verificado
pagamento
pagamentos
payment
seguranca
security
termos
terms
privacidade
privacy
login
logout
signup
api
app
root
null
undefined
firebase
moderacao
moderation
```

Handles tambem devem ser bloqueados quando baterem em termos claros de Trust &
Safety, incluindo:

```text
prostituicao;
servicos sexuais;
pornografia;
trafico humano;
drogas ilegais;
armas ilegais;
fraude/golpe;
falsificacao de documentos;
exploracao de menores;
servicos violentos/criminosos.
```

A M2.19.2 deve usar o `TrustSafetyClassifier` como barreira adicional, sem
expor ao utilizador a lista completa de termos internos.

## Modelo de Dados Recomendado

### Opcao A - Apenas `prestadores/{uid}.handle`

Campos:

```text
prestadores/{uid}.handle
prestadores/{uid}.handleNormalized
```

Vantagem:

```text
leitura simples no perfil e discovery.
```

Problema:

```text
unicidade e dificil de garantir apenas com Rules;
duas escritas simultaneas podem tentar o mesmo handle;
pesquisa por handle dependeria de query e indice.
```

### Opcao B - Colecao `handles/{handleNormalized}`

Colecao:

```text
handles/{handleNormalized}
```

Campos recomendados:

```text
uid
role
status
createdAt
updatedAt
reservedUntil
releasedAt
previousOwnerUid
source
```

Status iniciais:

```text
active
reserved
blocked
released
```

Vantagens:

```text
unicidade natural pelo documentId;
lookup rapido por handle;
facil bloquear/reservar handles;
facil resolver /p/{handle} para uid;
evita query por campo em prestadores.
```

### Recomendacao

Usar a Opcao B como fonte de reserva/unicidade e guardar copia no prestador para
leitura rapida:

```text
handles/{handleNormalized}
  uid: prestadorUid
  role: prestador
  status: active
  createdAt
  updatedAt
  source: prestador_profile

prestadores/{uid}
  handle: handleNormalized
  handleDisplay: "@handleNormalized"
  handleUpdatedAt
```

A reserva deve ser feita de forma atomica. Na primeira versao, isso pode ser
feito com transaction/batch e Rules bem testadas. Antes de escala publica, a
operacao critica deve ser avaliada para callable server-side, porque client-side
e Rules podem ficar complexos para troca, liberacao e historico.

## Troca de Handle

Regra inicial recomendada:

```text
um prestador tem apenas um handle ativo;
troca exige reservar o novo handle primeiro;
handle antigo nao deve ser liberado imediatamente;
handle antigo fica reserved por periodo curto, por exemplo 30 dias;
historico simples deve ser documentado para evitar impersonation;
redirecionamento automatico de handle antigo fica fora do escopo inicial.
```

Nao implementar limite comercial de trocas na M2.19.2 sem necessidade. A regra
operacional pode evoluir depois.

## Link Publico

Opcoes avaliadas:

```text
https://chegaja-ac88d.web.app/p/{handle}
https://chegaja-ac88d.web.app/@{handle}
https://chegaja-ac88d.web.app/prestador/{handle}
```

Recomendacao:

```text
/p/{handle}
```

Motivos:

```text
curto;
facil de partilhar;
evita problemas com @ em URL;
facil de distinguir de /pedido e /chat;
funciona bem em Flutter Web se houver rewrite SPA;
mantem espaco para futuras rotas /c, /s ou /u.
```

Exemplo inicial:

```text
https://chegaja-ac88d.web.app/p/maria_bolos
```

Com dominio futuro:

```text
https://chegaja.pt/p/maria_bolos
```

## Resolucao de Link

Fluxo recomendado para M2.19.4:

```text
1. app recebe /p/{handle};
2. normaliza handle;
3. consulta handles/{handleNormalized};
4. se nao existir, mostra 404 amigavel;
5. se status != active, mostra perfil indisponivel;
6. se role != prestador, mostra erro controlado ou rota futura adequada;
7. obtem uid;
8. abre PublicProfileScreen(userId: uid, role: prestador);
9. PublicProfileScreen carrega dados publicos do prestador.
```

O resolver nao deve depender de query em `prestadores` para descobrir uid.

## 404 e Estados Restritos

Estados recomendados:

```text
handle inexistente - pagina "Perfil nao encontrado";
handle reservado/bloqueado - pagina "Perfil indisponivel";
perfil suspenso/moderado - pagina "Perfil temporariamente indisponivel";
erro de rede - estado de retry;
link invalido - estado de rota invalida.
```

Nao mostrar informacao interna sobre bloqueio, denuncia ou moderacao ao publico.

## Privacidade

O link publico deve mostrar apenas dados publicos:

```text
nome publico;
foto/avatar publico;
bio publica;
cidade/regiao ampla;
servicos/categorias;
portfolio publico;
rating medio e count, quando valido;
badges leves permitidos;
@handle;
acoes de denunciar/bloquear quando usuario estiver autenticado.
```

Nao mostrar:

```text
telefone por defeito;
email por defeito;
morada completa;
localizacao precisa;
KYC/documentos;
dados de pagamento;
reports;
adminAuditLogs;
dados internos de moderacao;
ratingSum;
campos privados do documento.
```

Contacto publico deve ser uma decisao opt-in futura, nao consequencia automatica
de existir telefone no documento.

## Trust & Safety

O handle e o perfil publico precisam respeitar M2.17:

```text
handle passa por lista de reservados;
handle passa por TrustSafetyClassifier;
perfil suspenso nao deve resolver como publico;
perfil pending_review pode ficar restrito em fase futura;
servicos proibidos nao devem aparecer por link publico;
links publicos nao podem contornar moderacao;
denuncia/bloqueio continuam disponiveis no perfil.
```

Observacao importante:

```text
filtros client-side ajudam na UX, mas nao substituem enforcement server-side
antes de producao publica em escala.
```

## Relacao com Discovery

O discovery atual continua funcionando por:

```text
nome;
servicos;
cidade;
pais;
termos normalizados.
```

`ProviderSearchProfile` ja possui `handle` e inclui esse campo nos termos de
busca quando existir. Fases futuras devem:

```text
preencher handle real em prestadores/{uid};
mostrar @handle nos cards, se fizer sentido;
permitir pesquisa por @handle;
manter telefone/email fora dos cards;
excluir perfis suspensos/restritos quando houver campo de moderacao publico.
```

## Relacao com Perfil do Prestador

`PrestadorPerfilScreen` ainda nao possui UI para escolher/editar handle. A
M2.19.3 deve adicionar:

```text
campo de @handle;
preview de link publico;
validacao local;
validacao de disponibilidade;
feedback de handle reservado/proibido;
estado loading;
mensagem clara para troca de handle.
```

O fluxo de salvar perfil ja usa `TrustSafetyClassifier` para nome/bio. O handle
deve ter validacao propria e tambem passar por filtro de termos proibidos.

## Relacao com Admin

Admin/backoffice leve ja existe, mas M2.19 nao deve criar admin enterprise.

Futuro admin pode precisar:

```text
ver handle do prestador;
bloquear handle ofensivo;
reservar handle institucional;
ver historico simples de troca;
auditar alteracao de handle.
```

Isso fica fora da M2.19.1 e deve ser tratado apenas se a fase tecnica exigir.

## Partilha Social

M2.19.5 deve preparar:

```text
copiar link;
partilhar via WhatsApp;
partilhar por Web Share API quando disponivel;
abrir dialog/URL de Facebook share, se adequado;
copiar link para usar no Instagram;
QR Code futuro.
```

Instagram nao oferece partilha direta simples de URL para post/story via Web
com garantia universal. O comportamento mais seguro e copiar link e orientar o
prestador a colar no Instagram/bio/story.

## SEO e Metatags

Flutter Web SPA tem limitacoes para SEO e previews sociais.

Riscos:

```text
metatags dinamicas nao aparecem por perfil sem render/server;
preview em WhatsApp/Facebook pode mostrar metatags genericas;
refresh direto exige Hosting rewrite;
dominio customizado ainda nao esta definido.
```

M2.19 pode criar link funcional, mas SEO/social preview robusto fica para fase
posterior com Hosting/SSR/prerender ou Functions se necessario.

## Subfases da M2.19

| Fase | Estado | Descricao |
| --- | --- | --- |
| M2.19.1 | FECHADO | Spec e auditoria de link publico, @handle e partilha social |
| M2.19.2 | PROXIMO | Modelo, normalizacao e reserva de @handle |
| M2.19.3 | FUTURO | UI de @handle no perfil do prestador |
| M2.19.4 | FUTURO | Rota publica/deep link por @handle |
| M2.19.5 | FUTURO | Partilha social, copiar link e QR futuro |
| M2.19.6 | FUTURO | Testes, E2E, QA visual e documentacao final |

## Riscos

```text
colisao de handles;
handles ofensivos;
roubo/impersonation de nome;
links quebrados;
refresh direto em Flutter Web sem rewrite;
exposicao de telefone/email por perfil publico;
perfil suspenso ainda acessivel por link;
dependencia de Hosting rewrites;
mudanca de handle quebrar links antigos;
falta de dominio customizado;
SEO limitado em Flutter Web SPA;
partilha social sem metatags reais;
validacao client-side insuficiente para escala publica;
Rules complexas para troca/liberacao de handle.
```

## Testes Necessarios

M2.19.2:

```text
normalizacao de handle;
validacao de tamanho;
validacao de caracteres;
handles reservados;
handle ofensivo bloqueado;
unicidade via handles/{handle};
troca de handle preserva unicidade;
prestador nao reserva handle de outro uid;
campos extras bloqueados, se Rules forem criadas.
```

M2.19.3:

```text
campo de handle renderiza;
preview de link renderiza;
handle valido salva;
handle indisponivel mostra erro;
handle proibido bloqueia;
dark mode;
loading evita duplo clique.
```

M2.19.4:

```text
abrir /p/{handle};
handle inexistente mostra 404;
handle reservado/bloqueado mostra indisponivel;
perfil publico abre com uid resolvido;
refresh direto na rota;
private data nao aparece;
rota /pedido e /chat continuam funcionando.
```

M2.19.5:

```text
copiar link;
share WhatsApp;
Web Share API com fallback;
texto de partilha;
sem expor dados privados;
dark mode;
build Web.
```

## Decisao Recomendada para M2.19.2

Implementar apenas a base de modelo, normalizacao e reserva:

```text
criar normalizador/validador de handle;
criar lista de reservados;
usar TrustSafetyClassifier como barreira adicional;
criar modelo/servico de reserva;
criar colecao handles/{handleNormalized};
guardar copia em prestadores/{uid};
criar Rules e testes, se a fase alterar Firestore;
nao criar rota publica ainda;
nao criar UI de partilha ainda.
```

M2.19.2 deve preparar o dado certo. A UI e a rota publica ficam para fases
seguintes.
