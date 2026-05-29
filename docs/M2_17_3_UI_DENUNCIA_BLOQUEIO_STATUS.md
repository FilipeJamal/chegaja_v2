# M2.17.3 - UI de Denuncia/Bloqueio

Data: 2026-05-29

## Estado

```text
M2.17.3 - concluida
M2.17 - ativa
M2.17.4 - proximo passo
Bloco F - parcial
Bloco H - parcial
R - pausado por falta de tester humano real
M - pausado por falta de Android fisico real
R1 - pendente
M2.6 - pendente
```

## Resultado

A M2.17.3 criou a primeira camada de UI para Trust & Safety usando a base da
M2.17.2. A fase adicionou componentes reutilizaveis para denuncia e bloqueio,
ligou essas acoes ao perfil publico, ao chat e ao portfolio, e manteve admin,
KYC, Rules, Functions e deploy fora do escopo.

## Componentes Criados

```text
lib/features/common/trust_safety/report_content_sheet.dart
lib/features/common/trust_safety/block_user_dialog.dart
lib/features/common/trust_safety/trust_safety_actions.dart
```

`ReportContentSheet` permite selecionar motivo, inserir detalhes opcionais ate
1000 caracteres, bloquear envio sem motivo, bloquear excesso de caracteres e
enviar a denuncia via `TrustSafetyService.createReport`.

`BlockUserDialog` confirma o bloqueio, evita duplo clique durante loading e
grava o bloqueio via `TrustSafetyService.blockUser`.

`TrustSafetyActionsMenu` centraliza as acoes discretas de denunciar/bloquear
para superficies como perfil publico.

## Integracoes

### Perfil Publico

`PublicProfileScreen` passou a ter menu discreto com:

```text
Denunciar perfil
Bloquear utilizador
```

O target usado e:

```text
provider_profile quando role == prestador
client_profile nos demais casos
targetId = userId
targetOwnerId = userId
```

### Chat

`ChatThreadScreen` passou a oferecer:

```text
Denunciar conversa
Bloquear utilizador
Denunciar mensagem
```

O bloqueio grava o estado em `users/{uid}/blockedUsers/{blockedUid}`. Nesta
fase ele ainda nao impede envio/leitura de mensagens por Rules ou logica de
chat. Esse enforcement fica para M2.17.4/M2.17.5.

### Portfolio

`MediaViewerScreen` passou a aceitar denuncia de imagem quando aberto pelo
portfolio do perfil publico. A denuncia usa:

```text
targetType = portfolio_media
targetId = mediaUrl
targetOwnerId = prestadorId
mediaUrl = imagem atual
```

## Testes

Testes criados/atualizados:

```text
test/features/common/trust_safety/report_content_sheet_test.dart
test/features/common/trust_safety/block_user_dialog_test.dart
test/features/common/perfil_publico_trust_safety_actions_test.dart
test/features/common/widgets/media_viewer_screen_test.dart
```

Cobertura principal:

```text
motivos de denuncia;
motivo obrigatorio;
limite de detalhes;
callback de denuncia;
erro de denuncia;
confirmacao de bloqueio;
loading de bloqueio;
erro de bloqueio;
acoes de denuncia/bloqueio no perfil publico;
denuncia de imagem no portfolio;
dark mode dos componentes.
```

## Fora do Escopo Mantido

```text
admin/backoffice completo;
fila visual de moderacao;
moderationCases automaticos;
ocultar conteudo automaticamente;
banimento automatico;
enforcement de bloqueio por Rules no chat;
KYC;
certificacao;
videos;
pagamentos;
ranking;
alteracao de Firestore Rules;
alteracao de Storage Rules;
alteracao de Cloud Functions;
deploy;
Android fisico;
tester externo;
fechar R;
fechar R1;
fechar M;
fechar M2.6.
```

## Riscos Remanescentes

```text
Bloqueio ainda e sinal gravado, nao enforcement completo no chat.
Reports ainda nao geram fila visual/admin.
Conteudo reportado ainda nao fica oculto automaticamente.
Portfolio nao tem moderacao por item alem da denuncia manual.
Discovery ainda precisa considerar moderationStatus/isSearchable em fase futura.
```

## Decisao

M2.17.3 fica concluida no escopo de UI inicial de denuncia/bloqueio.

Proximo passo recomendado:

```text
M2.17.4 - Fila basica de moderacao/admin leve
```
