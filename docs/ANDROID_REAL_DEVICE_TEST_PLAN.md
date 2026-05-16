# Android Real Device Test Plan

Data: 2026-05-16

## Objetivo

Este roteiro fecha as provas reais pendentes de M2.6 quando houver um Android
fisico disponivel. O foco e provar que o APK release funciona fora do emulador:
push real, clique em notificacao, anexos reais e permissoes negadas.

## Preparacao

No PC:

```powershell
cd C:\Users\Jamal\Documents\ProjetosFlutter\chegaja_v2
flutter build apk --release
```

Artefato:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Instalacao por USB:

```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" devices
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-release.apk
```

Se `adb` nao estiver disponivel, copiar o APK para o telemovel e instalar
manualmente.

## Checklist base

| Passo | Resultado |
| --- | --- |
| Instalar APK release | Pendente |
| Abrir app sem crash | Pendente |
| Login anonimo como cliente | Pendente |
| Login anonimo como prestador | Pendente |
| Criar pedido como cliente | Pendente |
| Prestador ve pedido aberto | Pendente |
| Prestador aceita pedido | Pendente |
| Cliente ve estado atualizado | Pendente |

## Push real

Fluxo minimo:

| Passo | Resultado | Evidencia |
| --- | --- | --- |
| Abrir app no Android como prestador | Pendente | UID do prestador |
| Confirmar permissao de notificacao aceite | Pendente | Android settings/app dialog |
| Confirmar token em `users/{uid}/fcmTokens/{token}` | Pendente | Firestore path |
| Abrir web/desktop como cliente | Pendente | UID do cliente |
| Cliente cria pedido compativel | Pendente | Pedido ID |
| Prestador recebe push | Pendente | Screenshot/log |
| Clicar na notificacao | Pendente | Resultado visual |
| App abre o pedido correto | Pendente | Pedido ID na tela |
| Repetir para chat, se aplicavel | Pendente | Chat do pedido |

Se o push nao chegar, verificar:

- token FCM real existe na subcolecao `fcmTokens`;
- permissao Android 13+ foi aceite;
- Cloud Function encontrou token;
- payload contem dados de pedido/chat;
- app estava em background/foreground;
- canal de notificacao Android existe.

## Anexos reais

| Passo | Resultado | Evidencia |
| --- | --- | --- |
| Cliente abre criacao/detalhe de pedido | Pendente | Tela |
| Escolhe imagem da galeria | Pendente | Nome/tamanho |
| Upload conclui sem erro | Pendente | URL Storage |
| Firestore guarda URL no pedido/chat | Pendente | Campo/documento |
| Cliente reabre detalhe e ve anexo | Pendente | Screenshot |
| Prestador abre detalhe/chat e ve anexo | Pendente | Screenshot |
| Repetir com PDF/TXT permitido | Pendente | URL Storage |
| Tentar ficheiro nao suportado | Pendente | Mensagem clara |
| Tentar imagem grande | Pendente | Mensagem clara |
| Cancelar picker | Pendente | Sem crash |

Regras M2.7 esperadas:

```text
pedidos/{pedidoId}/anexos/{file}: so participantes/admin
temp/{uid}/anexos/{file}: so owner/admin
chats/{pedidoId}/images|files/{file}: so participantes/admin
```

## Permissoes negadas

| Permissao | Passo | Resultado esperado |
| --- | --- | --- |
| Notificacoes | Negar dialogo Android | App continua sem crash; push fica indisponivel; fluxo principal continua. |
| Galeria/imagens | Negar acesso no picker | App mostra erro simples ou volta ao fluxo sem crash. |
| Camera | Negar acesso no picker/camera | App mostra erro simples ou volta ao fluxo sem crash. |
| Ficheiros | Cancelar ou negar picker | Botao continua seguro; nenhum upload parcial fica obrigatorio. |

Depois de negar, testar tambem reativar permissao nas definicoes do Android e
repetir o fluxo.

## Evidencia a registar

Para fechar M2.6, atualizar:

```text
docs/ANDROID_MOBILE_REAL_STATUS.md
docs/ANDROID_RELEASE_READINESS.md
```

Com:

- modelo do telemovel;
- versao Android;
- commit testado;
- caminho do APK;
- pedido ID;
- UID cliente/prestador;
- token FCM confirmado;
- resultado do push;
- resultado dos anexos;
- resultado das permissoes negadas.

## Criterio de fecho M2.6

M2.6 so pode ser fechado quando todos estiverem provados:

```text
[ ] APK release instalado em Android fisico
[ ] Push real recebido
[ ] Clique na notificacao abre pedido/chat correto
[ ] Upload real de anexos funciona
[ ] Permissoes negadas nao causam crash
[ ] Docs atualizadas com evidencia real
```
