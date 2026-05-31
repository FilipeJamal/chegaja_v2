# M2.19.2 - Modelo, Normalizacao e Reserva de @handle

Data: 2026-05-31

## Estado

M2.19.2 concluida.

```text
M2.19 - ativa
M2.19.1 - FECHADA
M2.19.2 - FECHADA
M2.19.3 - PROXIMO passo
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

Criar a base tecnica segura de @handle antes de UI, rota publica e partilha
social.

## Implementado

### Normalizacao e validacao Dart

Criado:

```text
lib/core/handles/handle_normalizer.dart
lib/core/handles/handle_validator.dart
lib/core/handles/reserved_handles.dart
```

O normalizador:

```text
aceita input com ou sem @;
aplica trim;
lowercase;
remove acentos;
preserva espacos/caracteres invalidos para o validator rejeitar;
nao converte silenciosamente caracteres invalidos.
```

O validator:

```text
exige 3 a 30 caracteres;
aceita apenas a-z, 0-9, ponto, underline e hifen;
bloqueia separador no inicio/fim;
bloqueia separadores repetidos;
bloqueia handles reservados;
usa TrustSafetyClassifier para bloquear handles proibidos;
retorna mensagem segura ao utilizador.
```

### Reserved handles

Criada lista inicial para impedir uso de handles institucionais, tecnicos ou
sensiveis:

```text
admin
administrador
support
suporte
help
ajuda
chegaja
chegajaoficial
oficial
official
verified
verificado
certificado
pagamento
pagamentos
seguranca
termos
privacidade
login
api
app
root
null
undefined
system
moderator
moderador
staff
team
```

### Modelo PublicHandle

Criado:

```text
lib/core/models/public_handle.dart
```

Campos representados:

```text
handle
uid
role
status
handleDisplay
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
released
reserved
blocked
```

### HandleService

Criado:

```text
lib/core/services/handle_service.dart
```

Metodos:

```text
checkAvailability(String rawHandle)
reserveProviderHandle(String rawHandle)
```

O service chama:

```text
handle_checkAvailability
handle_reserveProviderHandle
```

Ele aceita caller injetado para testes e nao inicializa Firebase Functions
quando o caller fake e usado.

### Cloud Functions

Criadas:

```text
handle_checkAvailability
handle_reserveProviderHandle
```

`handle_checkAvailability`:

```text
normaliza handle;
valida formato;
bloqueia reservados/proibidos;
consulta handles/{handleNormalized};
retorna available/reason/message.
```

`handle_reserveProviderHandle`:

```text
exige request.auth;
exige doc prestadores/{uid};
normaliza e valida handle;
usa transaction;
cria/atualiza handles/{handleNormalized};
atualiza prestadores/{uid}.handle;
atualiza prestadores/{uid}.handleDisplay;
atualiza prestadores/{uid}.handleUpdatedAt;
permite idempotencia para o mesmo uid;
bloqueia outro uid no mesmo handle.
```

### Decisao sobre troca de handle

Se o prestador trocar para novo handle:

```text
o handle antigo fica com status released;
previousOwnerUid aponta para o uid anterior;
releasedAt e atualizado;
o handle antigo continua indisponivel para outros utilizadores nesta fase.
```

Motivo:

```text
evitar impersonation e roubo de nome ate existir politica mais completa de historico/redirect.
```

### Firestore Rules

Adicionado:

```text
handles/{handleNormalized}
```

Regra:

```text
read: true;
create/update/delete: false;
```

Motivo:

```text
links publicos futuros precisam resolver handles;
escrita deve ser feita apenas por Cloud Functions/Admin SDK.
```

Tambem foi protegido em `prestadores/{uid}`:

```text
handle
handleDisplay
handleUpdatedAt
```

O prestador nao consegue criar/alterar esses campos diretamente pelo client.
Functions/Admin SDK continuam conseguindo atualizar porque bypassam Rules.

## Testes Criados/Atualizados

```text
test/core/handle_normalizer_test.dart
test/core/handle_validator_test.dart
test/core/public_handle_test.dart
test/core/handle_service_test.dart
functions/test/publicHandles.test.js
functions/test/firestore.test.js
test/features/cliente/discovery/provider_search_profile_test.dart
```

Cobertura principal:

```text
normalizacao de handle;
validacao de formato;
reserved handles;
TrustSafetyClassifier bloqueando handle proibido;
modelo PublicHandle;
HandleService com callable fake;
check availability;
reserve provider handle;
idempotencia;
colisao entre uids;
troca de handle;
Rules bloqueando escrita client-side em handles;
Rules bloqueando escrita direta de handle fields em prestadores;
ProviderSearchProfile mapeando handle.
```

## Fora do Escopo Mantido

```text
UI de @handle;
rota publica /p/{handle};
PublicProfile por handle;
partilha social;
QR Code;
SEO/metatags;
deploy;
KYC;
pagamentos;
Android fisico;
tester externo;
fechar R;
fechar R1;
fechar M;
fechar M2.6.
```

## Validacoes

```text
flutter test --no-pub test/core/handle_normalizer_test.dart test/core/handle_validator_test.dart test/core/public_handle_test.dart test/core/handle_service_test.dart test/features/cliente/discovery/provider_search_profile_test.dart - passou
node --check functions/index.js - passou
functions public handle/rules focused tests - passou, 11 passing
```

As validacoes completas da fase foram executadas no fecho antes do commit.

## Riscos Remanescentes

```text
UI de escolha/edicao ainda nao existe;
rota publica /p/{handle} ainda nao existe;
PublicProfileScreen ainda precisa revisao de contacto publico antes de escala externa;
Hosting rewrite para refresh direto ainda nao foi implementado;
SEO/social preview real continua limitado por Flutter Web SPA;
politica definitiva de liberacao/redirect de handles antigos ainda e futura.
```

## Decisao Final

M2.19.2 fica fechada como base tecnica de @handle.

Proximo passo:

```text
M2.19.3 - UI para escolher/editar @handle no perfil do prestador
```
