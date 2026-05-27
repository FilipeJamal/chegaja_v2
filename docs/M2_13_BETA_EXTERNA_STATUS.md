# M2.13 - Beta Externa / Tester Real

Data: 2026-05-23

## Estado

```text
M2.13: em preparacao para beta externa / tester real
Bloco R: iniciado
M2.13.1: preparada entrega ao tester, aguardando dados reais de envio
M2.13.2: beta solo assistida por Playwright executada, sem fechar entrega real
M2.13.3: documentacao de entrega real preparada, aguardando envio humano
M2.13.4: correcao de pesquisa do catalogo Cliente em beta solo manual
M2.13.5: correcao de modo escuro e localizacao do chat em beta solo manual
M2.12: pacote de entrega beta Web/Windows preparado
M2.11: fechada como beta interna controlada Web/Windows
M2.6: continua pendente de Android fisico real
```

## Base

Commit de referencia:

```text
6239f70 Avancar M2.12 pacote entrega beta
```

Pacote local de entrega herdado:

```text
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12
```

Conteudo confirmado na M2.12:

```text
web_beta_debug
windows_beta_debug
BETA_TESTER_GUIA_RAPIDO.md
BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
BETA_TESTER_FEEDBACK_FORM.md
BETA_TESTER_BUG_REPORT.md
BETA_TESTER_CHECKLIST_ENTREGA.md
BETA_TESTER_BUILD_INSTRUCTIONS.md
BETA_TESTER_MANIFEST_ENTREGA.md
```

## Spec

```text
docs/superpowers/specs/2026-05-23-m2-13-beta-externa-tester-real-design.md
```

## Objetivo

Executar uma beta externa controlada com tester real em Web/Windows, usando o pacote M2.12, e decidir com evidencia se a beta externa passa, reprova ou precisa de correcao de bloqueadores.

## Estado do Bloco R

```text
R1: PROXIMO - entregar app ao tester
R2: FUTURO - tester real executa roteiro
R3: FUTURO - recolher bugs reais
R4: FUTURO - classificar bugs
R5: FUTURO - corrigir bloqueadores
R6: FUTURO - decidir se beta externa passa
```

## M2.13.1 - Preparacao da Entrega

```text
Estado: preparada
Entrega real: pendente
Motivo: tester/canal/plataforma ainda nao foram informados
```

A M2.13.1 preparou:

```text
1. Verificacao local do pacote M2.12.
2. Registo de entrega pronto para preencher.
3. Mensagem pronta para enviar ao tester.
4. Confirmacao de que R1 nao deve ser fechado sem envio real.
```

## Proxima Execucao Recomendada

```text
M2.13.6 - Registar envio real e feedback inicial do tester
```

Essa execucao deve receber do responsavel humano:

```text
tester
canal de entrega
plataforma entregue: Web, Windows ou ambas
data/hora de envio
prazo esperado de retorno
confirmacao de que o tester recebeu os documentos
feedback inicial ou confirmacao de execucao, quando existir
```

## M2.13.2 - Beta Solo Assistida por Playwright

```text
Estado: executada
Tipo: beta solo assistida por IA/Playwright
Resultado: aprovada tecnicamente
Entrega real a tester: ainda pendente
```

Motivo:

```text
Nao havia tester humano disponivel no momento. Para nao bloquear a validacao,
foi executado um roteiro solo assistido por Playwright usando os fluxos E2E
ja aprovados da M2.11/M2.12.
```

Ambiente usado:

```text
Build Web estatico: build/web
Servidor local: http://127.0.0.1:5174
Emuladores: auth, firestore, storage, functions
Target E2E: http://127.0.0.1:5174
```

Observacao de ambiente:

```text
O alvo debug flutter run -d web-server em http://127.0.0.1:5173 carregou
HTML/DDC, mas nao montou a UI Flutter no Chromium Playwright dentro do tempo
esperado. O build Web estatico em http://127.0.0.1:5174 montou corretamente.
Isto foi tratado como limitacao de ambiente debug/DDC, nao como bug funcional
do produto.
```

Evidencia funcional:

```text
npm.cmd run e2e:ui:dual: passou
Resultado: FULL MULTI-SCENARIO FLOW OK
Cenarios: happy-path, cancelamento Cliente, convite manual Prestador, chat bidirecional, no-show Prestador
Screenshots: C:\Users\Jamal\AppData\Local\Temp\chegaja-m2132-beta-solo\screenshots\2026-05-27T08-52-18-042Z

npm.cmd run e2e:ui:orcamento: passou
Resultado: ORCAMENTO MIN-MAX FLOW OK
Cenarios: pedido por orcamento, proposta min/max, aceite Cliente, valor final, conclusao
Screenshots: C:\Users\Jamal\AppData\Local\Temp\chegaja-m2132-beta-solo\screenshots\2026-05-27T09-04-35-468Z
```

Evidencia visual:

```text
Matriz visual capturada:
C:\Users\Jamal\AppData\Local\Temp\chegaja-m2132-beta-solo\visual_matrix

Telas:
- Home Cliente mobile/tablet/desktop/wide
- Home Prestador mobile/tablet/desktop/wide
```

Notas runtime:

```text
Foram registados avisos esperados de WebGL/Firestore Listen abortado durante
trocas de pagina/contexto do Playwright.

Tambem surgiram logs iniciais de timeout no bootstrap Auth, mas o login anonimo
recuperou e os dois roteiros terminaram com sucesso ponta a ponta. Fica como
observacao tecnica para monitorizacao futura, nao como bloqueador desta beta
solo.
```

Decisao:

```text
A beta solo assistida por Playwright fica aprovada tecnicamente.
A beta externa real continua pendente, porque nenhum tester humano recebeu ou
executou o pacote.
R1 nao foi fechado.
```

## M2.13.3 - Preparar Entrega Real ao Tester

```text
Estado: preparada
Tipo: documentacao de entrega real
Entrega real a tester: ainda pendente
R1: ainda pendente
```

Objetivo:

```text
Deixar a entrega real pronta para uma pessoa humana receber, abrir, testar e
reportar feedback sem depender do ambiente de desenvolvimento.
```

Documentos criados:

```text
docs/BETA_EXTERNA_ENTREGA_TESTER.md
docs/BETA_EXTERNA_INSTRUCOES_TESTER.md
docs/BETA_EXTERNA_FEEDBACK_TEMPLATE.md
```

Documentos atualizados:

```text
docs/BETA_EXTERNA_REGISTO_ENTREGA.md
docs/BETA_EXTERNA_MENSAGEM_TESTER.md
docs/BETA_EXTERNA_DECISAO.md
docs/BETA_EXTERNA_BUGS_REPORTADOS.md
docs/ROADMAP_A_T_CHEGAJA.md
```

Criterio mantido:

```text
R1 so fecha quando um tester humano receber o link/pacote, confirmar acesso e
executar pelo menos o roteiro principal com feedback registado.
```

Decisao:

```text
A M2.13.3 prepara a entrega real, mas nao declara que a entrega aconteceu.
A beta externa real continua pendente.
```

## M2.13.4 - Corrigir Pesquisa do Catalogo Cliente

```text
Estado: corrigida e validada localmente
Tipo: bug de usabilidade/performance encontrado em beta solo manual
Entrega real a tester: ainda pendente
R1: ainda pendente
```

Problema reportado:

```text
A barra de pesquisa da Home Cliente ficava lenta e confusa. Ao digitar termos
como "retrato" ou "retratista", as sugestoes apareciam por cima da tela, mas a
grelha real continuava a mostrar servicos nao relacionados.
```

Causa:

```text
A barra usada nesse ponto era um autocomplete, nao um filtro real da grelha de
servicos. Alem disso, a grelha inicial renderizava muitos cards, tornando a
interacao mais pesada para o tester.
```

Correcao:

```text
1. A Home Cliente passou a filtrar a propria grelha de servicos.
2. O fluxo deixou de usar dropdown de sugestoes nesse catalogo.
3. A pesquisa passou a usar debounce.
4. O catalogo passou a limitar a renderizacao inicial e oferecer "Ver mais".
5. Foi adicionado teste do filtro/limite de catalogo.
```

Validacoes:

```text
flutter test --no-pub: 158/158 passou
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release: passou
Playwright/Chromium local: pesquisa por "retratista" filtrou resultados e removeu cards nao relacionados
```

Observacao:

```text
Esta correcao melhora a beta solo/manual, mas nao fecha R1. A entrega real a
tester humano externo continua pendente.
```

## M2.13.5 - Corrigir Modo Escuro e Localizacao do Chat

```text
Estado: corrigida e validada localmente
Tipo: bug visual/funcional encontrado em beta solo manual
Entrega real a tester: ainda pendente
R1: ainda pendente
```

Problemas reportados:

```text
1. No detalhe do pedido em modo escuro, blocos de informacao, contacto,
   endereco e no-show tinham texto ou fundo com cores claras/escuras fixas,
   ficando pouco legiveis.
2. Mensagens de localizacao no chat apareciam como texto plano e nao abriam o
   Google Maps.
```

Causa:

```text
O detalhe do pedido ainda tinha cores hardcoded como Colors.black54,
Colors.black87 e Colors.grey.shade100 em areas visiveis no dark mode.

As mensagens de localizacao antigas eram gravadas com latitude/longitude, mas
o modelo ChatMessage so reconhecia locationLat/locationLng. Assim, a UI nao
tratava essas mensagens como localizacao clicavel.
```

Correcao:

```text
1. PedidoInfoRow passou a usar colorScheme.onSurface/onSurfaceVariant.
2. ContatoSection passou a usar surfaceContainerHighest/outlineVariant e cores
   do tema.
3. Trechos de no-show, endereco e descricao no detalhe passaram a respeitar o
   tema.
4. ChatMessage passou a aceitar latitude/longitude legados e expor mapsUri.
5. O envio de localizacao grava tanto locationLat/locationLng como
   latitude/longitude para compatibilidade.
6. O ChatThreadScreen passou a renderizar localizacao como acao clicavel para
   abrir Google Maps.
```

Validacoes:

```text
flutter test --no-pub: 160/160 passou
npm.cmd run test:scripts: passou
flutter build web --release --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true --pwa-strategy=none -o build/web_manual_release: passou
Playwright/Chromium local: build Web em 127.0.0.1:5175 montou a Home Cliente
git diff --check: passou sem erros
```

Observacao:

```text
Esta correcao melhora a beta solo/manual, mas nao fecha R1. A entrega real a
tester humano externo continua pendente.
```

## M2.13.6 - Corrigir Contraste Dark Mode Transversal

```text
Estado: corrigida e validada localmente
Tipo: bug visual encontrado em beta solo manual
Entrega real a tester: ainda pendente
R1: ainda pendente
```

Problema reportado:

```text
Depois da primeira correcao de dark mode, ainda havia textos e cartoes em
outras areas com cores hardcoded, causando leitura fraca em telas de pedido,
chat, perfil, selecao de prestador, suporte, agenda e formularios auxiliares.
```

Causa:

```text
Varios widgets ainda usavam cores fixas como Colors.black54,
Colors.black87, Colors.grey ou superficies claras fixas em vez dos tokens do
tema. Em dark mode, isso deixava texto quase invisivel ou cartoes claros fora
do padrao visual da app.
```

Correcao:

```text
1. Acoes Cliente/Prestador passaram a usar colorScheme.onSurface e
   onSurfaceVariant.
2. Chat preview, bolhas de chat, anexos, audio, contacto e timeline passaram a
   respeitar o tema.
3. Perfil Cliente/Prestador, KYC, favoritos, suporte, report problem,
   selecionar prestador e novo pedido receberam surface/outline/texto do tema.
4. Foi criado teste de regressao para impedir texto preto hardcoded nas acoes
   Cliente/Prestador em dark mode.
```

Validacoes:

```text
flutter test --no-pub test/features/cliente/widgets/pedido_actions_visual_test.dart: passou
```

Observacao:

```text
Esta correcao melhora a beta solo/manual, mas nao fecha R1. A entrega real a
tester humano externo continua pendente.
```

## Fora do Escopo Mantido

```text
backend novo
Firestore Rules novas sem bug real comprovado
Storage Rules novas
Cloud Functions novas
deploy real
smoke real
cleanup real
health real
Android fisico real
pagamentos reais
Play Store
package id final
HTTPS App Links
fechar M2.6
novas funcionalidades grandes
redesign visual amplo
```

## Validacao Inicial

```text
git diff --check: passou
```
