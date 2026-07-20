# P1.8 - Validacao Android e permissoes reais

## Estado desta execucao

- Data: 2026-07-20
- Android SDK/licencas: pronto; todas as licencas aceites.
- Assinatura release: `android/key.properties` e ficheiro de keystore presentes.
- Chave Google Maps Android: configurada em `android/local.properties`.
- Dispositivos detetados por `flutter devices`: Windows, Chrome e Edge.
- Dispositivo Android fisico: **nao detetado**.
- AVDs disponiveis: API 34, 35 e 36.
- Validacao emulada: **EXECUTADA** num AVD Android 14/API 34 x86_64.
- Validacao fisica: **NAO EXECUTADA**. Nao substituir por alegacao baseada em
  emulador.

## Evidencia automatizada desta execucao

- APK: `build/app/outputs/flutter-apk/app-release.apk` (release, `--no-shrink`).
- Tamanho do APK: `123074424` bytes (release final desta execução).
- SHA-256 do APK: `F9D29A1D38DCA520E9CB68EB83DD72666C177A0442C6012F535BB36D5589AD13`.
- Fingerprint das 351 entradas de release:
  `3e22cfa0c4a5366e6866ba5c011e6da9e4b2e86d708f0b2edd500e2fe2d7cae3`.
- Assinatura: APK Signature Scheme v2, um signatario RSA 2048, certificado
  `CN=ChegaJa, OU=App, O=ChegaJa, L=Maputo, ST=Maputo, C=MZ`.
- SHA-256 do certificado:
  `1336ff14c1ddf09440387bbdf9f48d5a09602a87d1062ae6fce2a5072bac1f81`.
- Permissoes empacotadas: Internet, localizacao aproximada/precisa,
  notificacoes, camara e permissoes operacionais de rede/FCM.
- Permissoes ausentes e comprovadas: microfone, configuracao de audio,
  Bluetooth, `AD_ID` e Advertising Services.
- Instalacao ADB: `Success`.
- Runtime: `com.chegaja.app/.MainActivity` ficou em primeiro plano e
  manteve o processo vivo depois de uma interação de scroll;
  seletor de função em português renderizado; nenhum `FATAL EXCEPTION`,
  `E/flutter`, `FirebaseException`, `MissingPluginException`,
  `GeneratedPluginsRegister` ou `ClassNotFoundException` no arranque.
- Prompt no arranque: nenhum. A aplicacao abriu diretamente no seletor de
  funcao.
- Captura: `build/p1_8_launch.png`; hierarquia de acessibilidade:
  `build/p1_8_ui.xml`.

O AVD API 35 listado nesta maquina aponta para arquitetura ARM e nao pode ser
executado pelo QEMU2 neste host x86. Isso nao afeta a prova API 34, mas reforca
que a matriz num Android 13+ fisico continua obrigatoria.

O APK release deve ser gerado com o wrapper reproduzivel:

```text
powershell -ExecutionPolicy Bypass -File scripts/build_android_release.ps1
```

O wrapper regenera o `GeneratedPluginRegistrant.java`, preserva os plugins de
producao e remove exclusivamente o bloco `integration_test`. Sem essa
sanitizacao, o source set release pode tentar compilar uma classe que existe
apenas durante testes; apagar o registrador inteiro tambem e invalido porque
deixaria os canais Firebase ausentes no runtime.

`--no-shrink` e aceitavel para o piloto interno: aumenta o tamanho do APK, mas
nao desativa autenticacao, Rules, App Check, assinatura ou validacoes do backend.

## Permissoes declaradas no piloto

- Internet: operacao Firebase/HTTPS.
- Localizacao aproximada e precisa: sugerir zona, distancia e matching.
- Notificacoes Android 13+: pedidos, chat e mudancas de estado.
- Camara: apenas quando o utilizador escolhe tirar fotografia para perfil,
  portfolio, anexo ou chat.

Microfone, audio e Bluetooth foram removidos do manifesto do piloto porque
chamadas de audio/video estao fora do piloto. Galeria e ficheiros usam os
seletores do sistema e nao pedem acesso amplo ao armazenamento.

## Politica de pedido

1. Nao pedir notificacoes ao arrancar.
2. Explicar a finalidade antes de cada pedido.
3. Pedir uma permissao de cada vez, em resposta a acao do utilizador.
4. Se for recusada, manter alternativa manual quando existe.
5. Se for recusada permanentemente, oferecer acesso as definicoes Android.
6. Nunca tornar a morada exata publica por a localizacao ter sido autorizada.

O ecrã `PermissionSettingsScreen` permite verificar e autorizar separadamente
localizacao, notificacoes e camara. O arranque apenas inicializa os listeners de
notificacao; o prompt e disparado por acao explicita.

## Matriz obrigatoria no Android fisico

Executar num Android 13 ou superior, preferencialmente um aparelho de gama baixa
com rede movel mocambicana:

| Caso | Passos | Resultado esperado |
|---|---|---|
| Instalacao limpa | Desinstalar, instalar APK assinado, abrir | Arranca sem crash; nenhum prompt em cascata |
| Notificacoes recusadas | Abrir Permissoes, explicar, recusar | App continua utilizavel; sem token indevidamente gravado |
| Notificacoes aceites | Autorizar e enviar push de teste | Push recebido e abre o pedido/chat correto |
| Localizacao recusada | Criar pedido e recusar | Campo manual continua disponivel; nenhuma morada exata no dispatch |
| Localizacao aproximada | Autorizar apenas aproximada | Pedido criado com zona util; UI nao exige precisao |
| Localizacao precisa | Autorizar durante utilizacao | Posicao obtida; dispatch continua arredondado/sanitizado |
| Camara recusada | Tentar fotografia e recusar | Volta ao fluxo sem crash; galeria/ficheiro continua opcional |
| Camara aceite | Tirar foto de perfil/anexo/chat | Upload permitido apenas no caminho autorizado |
| Permissao permanente | Marcar "nao perguntar novamente" | Botao abre definicoes do Android |
| App em background | Receber chat/pedido | Push chega; nenhum tracking de localizacao em background |
| Rede fraca/offline | Alternar dados durante pedido/chat | Mensagem clara; sem duplicar pedido ou pagamento |
| Reinicio | Fechar e reabrir | Sessao e estado preservados; sem novo prompt automatico |

## Evidencia a recolher

- fabricante/modelo e versao Android;
- versao do APK, SHA-256 e assinatura;
- capturas dos tres estados de permissao;
- logs de crash sem telefone, morada, tokens ou documentos;
- IDs de pedidos de teste prefixados para limpeza;
- resultado de cada linha: aprovado, falhou ou bloqueado, com observacao.

O resultado deve ser gravado em
`docs/pilot/evidence/android-physical-validation.json`, usando o modelo da
pasta `templates`. O verificador exige o mesmo SHA-256 da APK e os 12 casos com
`result: "passed"`.

P1.8 só pode ser declarado fisicamente validado depois de esta matriz ser
executada num aparelho real. A ausência de aparelho nesta máquina é uma
dependência externa, não uma aprovação implícita.
