# M2.10.6 - Responsividade e QA visual Web/Windows/Android

## Contexto

A M2.10 esta a transformar o ChegaJa de uma app funcional com aspeto de
prototipo para um produto visualmente mais profissional, organizado e
responsivo.

Estado recente:

```txt
M2.10.1: spec visual audit e design direction
M2.10.2: avancado com design system foundation
M2.10.3: avancado com Home Cliente redesign
M2.10.4: avancado com Home Prestador redesign
M2.10.5: avancado com Pedido, listas e detalhe polish
```

Commit de referencia mais recente:

```txt
82618ebeadfd129d9228cb3e0af365c35ffccd54
Avancar M2.10.5 pedido listas detalhe polish
```

A base visual ja melhorou: as Homes tem CTAs mais fortes, cards mais
consistentes, melhor mobile e o sistema de pedidos passou a usar a mesma
foundation visual. Mas a fase ainda nao deve ser fechada sem uma passada
deliberada de QA visual e responsividade.

## Evidencia visual atual

Foram capturados screenshots locais a partir de build Web em modo emulador.

Resumo observado:

```txt
Home Cliente desktop: melhor estruturada, mas ainda com bastante espaco vazio em alguns estados.
Home Cliente mobile: mais limpa e utilizavel, com cards e CTA fortes.
Home Prestador mobile: melhor, mas precisa validar conteudo completo e scroll.
Home Prestador desktop: ainda precisa evidencia visual com dados carregados.
Lista de pedidos desktop/mobile: precisa validacao visual real.
Detalhe do pedido desktop/mobile: precisa validacao visual real.
Banner vermelho de emulador: sobrepoe a navegacao mobile e atrapalha QA.
```

Tambem foi observado que o `flutter run -d web-server` em debug pode ficar no
splash quando capturado por Playwright, enquanto o build Web local serviu a UI
corretamente. A M2.10.6 deve tratar isso como detalhe de ambiente de QA, sem
confundir com problema funcional da app.

## Problema

A app ja nao parece prototipo cru em varias areas, mas ainda pode comunicar
produto inacabado em situacoes visuais reais:

- desktop pode ter espaco vazio excessivo;
- algumas composicoes ainda podem parecer mobile esticado;
- colunas laterais podem ficar pobres quando ha pouco conteudo;
- cards podem ficar demasiado largos, estreitos ou desalinhados entre telas;
- botoes podem quebrar linha ou perder hierarquia em larguras intermediarias;
- o banner de emulador pode tapar navegacao e botoes em mobile;
- Home Cliente, Home Prestador, lista e detalhe precisam parecer parte do
  mesmo produto;
- loading, empty e error precisam manter a mesma qualidade visual;
- screenshots reais ainda nao cobrem toda a matriz Web/Windows/Android.

O problema nao e adicionar funcionalidade. E verificar a experiencia visual
como produto.

## Objetivo

Executar QA visual e responsividade para Web, Windows e Android, corrigindo
problemas visuais pequenos e medios antes de fechar a M2.10.

A fase deve responder:

```txt
1. A app usa bem a largura em desktop?
2. A app continua limpa e utilizavel em mobile?
3. A navegacao nao fica tapada por banners, barras ou elementos fixos?
4. Homes, listas e detalhe parecem do mesmo sistema visual?
5. Existem overflows, quebras estranhas ou espacos vazios sem funcao?
6. O estado de emulador ajuda o QA sem esconder a UI?
```

## Direcao escolhida

### QA visual controlado com correcoes pequenas/medias

A M2.10.6 deve ser uma fase pratica:

```txt
capturar screenshots
avaliar problemas por viewport
corrigir apenas problemas visuais dentro do escopo
documentar evidencias
manter backend e producao intocados
```

Nao e uma nova fase de redesign amplo. As fundacoes e as telas principais ja
foram alteradas nas subfases anteriores. Agora a tarefa e ajustar o conjunto.

## Alternativas consideradas

### A1 - Fechar M2.10 agora

Fechar a fase com base nos testes automatizados e screenshots parciais.

**Rejeitada.** Testes de widget e unitarios nao substituem revisao visual. Ainda
ha problemas claros de responsividade, especialmente banner de emulador e uso de
desktop.

### A2 - QA visual controlado

Criar matriz de screenshots, validar viewports, corrigir pequenos problemas e
documentar evidencias.

**Escolhida.** E o menor passo que aumenta a confianca visual sem abrir nova
frente funcional.

### A3 - Redesign visual completo novamente

Reabrir Homes, detalhe, listas e navegacao como redesign total.

**Rejeitada por agora.** A M2.10 ja fez esse trabalho por blocos. A fase atual
deve corrigir o que a inspeccao real revelar, nao recomecar a arquitetura.

## Escopo

### Telas a validar

```txt
Home Cliente
Home Prestador
lista de pedidos Cliente
lista/pedidos disponiveis Prestador
detalhe do pedido Cliente
detalhe do pedido Prestador
loading
empty states
error/not found
```

### Viewports minimos

```txt
mobile estreito: 390x844
tablet: 768x1024
desktop padrao: 1366x768
desktop largo: 1920x1080
```

Se o ambiente permitir, tambem validar janela Windows redimensionada e Chrome
desktop com altura menor, porque muitos problemas aparecem em altura util curta.

### Tipos de problema a corrigir

```txt
espaco vazio excessivo
max-width demasiado estreito em desktop
cards com largura estranha
coluna lateral vazia ou pobre
overflow horizontal ou vertical
botoes com texto quebrado de forma ruim
conteudo tapado por bottom navigation
conteudo tapado pelo banner de emulador
hierarquia visual fraca
inconsistencia entre Home Cliente, Home Prestador e Pedido
loading/empty/error com aspeto de prototipo
```

### Banner de emulador

O banner `Running in emulator mode. Do not use with production credentials.`
deve continuar existindo em ambiente local, mas nao pode tapar navegacao ou
botoes.

Direcao preferida:

```txt
desktop: banner discreto, fora do fluxo critico
mobile: respeitar bottom navigation ou virar aviso compacto dentro da safe area
testes: nao depender de posicao visual fragil do banner
producao: nunca mostrar o banner
```

## Fora do escopo

```txt
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
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
mudancas de schema
mudancas de regra de negocio
```

## Guardrails tecnicos

- Nao alterar `functions/**`.
- Nao alterar `firestore.rules`.
- Nao alterar `storage.rules`.
- Nao alterar services/repos de negocio salvo se for bug visual impossivel de
  corrigir de outra forma, e nesse caso documentar antes.
- Preservar keys de testes Cliente/Prestador.
- Nao commitar `android/key.properties`, keystore, `.env` ou segredos.
- Nao misturar delecoes antigas dos ficheiros `~$*.pptx`.
- Nao commitar `.superpowers/`.

## Plano macro esperado

```txt
1. Preparar ambiente local de QA visual.
2. Capturar screenshots por tela e viewport.
3. Classificar problemas como:
   - bloqueador visual
   - ajuste medio
   - aceitavel para fase futura
4. Corrigir apenas bloqueadores visuais e ajustes medios dentro do escopo.
5. Repetir screenshots das telas corrigidas.
6. Atualizar docs/M2_10_VISUAL_PRODUCT_STATUS.md com evidencias.
7. Rodar validacoes finais.
```

## Evidencias esperadas

Documentar no status da M2.10:

```txt
comandos usados para servir app local
viewports capturados
screenshots gerados
problemas encontrados
problemas corrigidos
problemas adiados
resultado dos testes finais
```

Nao e necessario commitar imagens pesadas se forem apenas evidencia local
transitoria. Se for util commitar imagens, elas devem ficar em pasta clara de
artefatos/documentacao e ser escolhidas com criterio.

## Validacoes finais

```txt
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Nao rodar smoke real, cleanup real, health real ou deploy nesta fase.

## Criterios de aceitacao

- matriz minima de viewports executada ou bloqueio documentado;
- Home Cliente validada em desktop e mobile;
- Home Prestador validada em desktop e mobile;
- listas de pedidos validadas em pelo menos um estado carregado;
- detalhe do pedido validado em desktop e mobile;
- banner de emulador nao tapa navegacao/acoes em mobile;
- problemas visuais pequenos/medios corrigidos ou documentados;
- status M2.10 atualizado com evidencias;
- testes finais passam;
- M2.6 permanece pendente de Android fisico.
