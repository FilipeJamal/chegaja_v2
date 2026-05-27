# Beta Externa - Bugs Reportados

Data de abertura: 2026-05-23

## Estado

```text
Nenhum bug externo reportado ainda.
Beta externa ainda nao foi executada por tester real.
Beta solo assistida por Playwright foi executada em 2026-05-27 sem bug funcional bloqueador.
M2.13.3 preparou template externo de feedback, mas ainda nao ha bugs de tester humano.
```

## Formato de Registo

Cada bug deve ser registado neste formato:

```text
ID:
Data:
Tester:
Plataforma: Web / Windows
Papel: Cliente / Prestador
Severidade: bloqueador / alto / medio / baixo
Frequencia: sempre / as vezes / uma vez
Estado: aberto / em analise / corrigido / adiado

Passos:
1.
2.
3.

Resultado esperado:

Resultado obtido:

Evidencia:

Notas tecnicas:
```

## Bugs

```text
Sem bugs registados.
```

## Como Converter Feedback em Bug

Quando o tester preencher `docs/BETA_EXTERNA_FEEDBACK_TEMPLATE.md`, cada problema
deve ser copiado para este ficheiro no formato de registo acima.

Classificacao recomendada:

```text
bloqueador: impede abrir app ou concluir fluxo principal
alto: quebra fluxo importante, mas ha contorno
medio: atrapalha uso, mas nao bloqueia
baixo: texto, polimento visual ou pequena melhoria
```

## Observacoes Tecnicas da Beta Solo

```text
Data: 2026-05-27
Tipo: observacao tecnica, nao bug externo
Estado: documentado
```

### M2.13-SOLO-ENV-001 - Debug web-server nao montou no Playwright

```text
Severidade: baixa
Impacto: ambiente de QA automatizado
Estado: contornado com build Web estatico

Resumo:
O alvo http://127.0.0.1:5173 servido por flutter run -d web-server carregou
HTML/DDC, mas nao montou a UI Flutter no Chromium Playwright no tempo esperado.
O build Web estatico servido em http://127.0.0.1:5174 montou corretamente e
permitiu executar os roteiros E2E.

Decisao:
Nao classificar como bug funcional do produto nesta fase. Para beta solo e
entrega Web, usar build estatico.
```

### M2.13-SOLO-RUNTIME-001 - Bootstrap Auth com timeout inicial recuperavel

```text
Severidade: baixa
Impacto: logs durante E2E
Estado: monitorizar

Resumo:
Durante os roteiros Playwright surgiram logs iniciais de timeout no bootstrap
Auth, mas os UIDs foram obtidos, o login anonimo recuperou e os fluxos dual e
orcamento terminaram ponta a ponta.

Decisao:
Nao bloqueia a beta solo. Manter observacao para investigar se reaparecer em
teste humano ou ambiente de entrega real.
```

### M2.13-SOLO-UX-001 - Pesquisa de servicos da Home Cliente lenta/bugada

```text
Data: 2026-05-27
Tester: Filipe/Jamal em beta solo manual
Plataforma: Web release local
Papel: Cliente
Severidade: alta
Frequencia: sempre
Estado: corrigido

Resumo:
Na Home Cliente, a pesquisa de servicos ficava muito lenta e confusa ao digitar.
Ao pesquisar termos como "retrato" ou "retratista", a UI mostrava sugestoes
sobrepostas, mas a grelha principal continuava com cards sem relacao, como
"Assentamento...". O tester nao conseguia usar a pesquisa de forma fluida.

Causa tecnica:
A barra anterior era um autocomplete de sugestoes. Ela nao filtrava os cards
visiveis do catalogo e ainda renderizava demasiados servicos iniciais, criando
sensacao de bloqueio e resultado errado.

Correcao:
- A Home Cliente passou a usar pesquisa real do catalogo.
- A grelha de servicos agora e filtrada pelo texto digitado.
- A pesquisa passou a usar indice de servicos existente.
- O dropdown de sugestoes foi removido desse fluxo.
- A renderizacao inicial do catalogo foi limitada e ganhou "Ver mais servicos".
- A barra recebeu debounce para evitar rebuild pesado a cada tecla.

Validacao:
- Pesquisa por "retratista" testada em Chromium/Playwright contra
  http://127.0.0.1:5175.
- Resultado esperado encontrado.
- Cards nao relacionados, como "Assentamento...", deixaram de aparecer quando
  a pesquisa esta ativa.
- flutter test --no-pub passou com 158/158.
```

### M2.13-SOLO-UX-002 - Modo escuro do detalhe com contraste quebrado

```text
Data: 2026-05-27
Tester: Filipe/Jamal em beta solo manual
Plataforma: Web release local
Papel: Prestador
Severidade: alta
Frequencia: sempre nas areas afetadas
Estado: corrigido
```

Resumo:
No detalhe do pedido em modo escuro, areas como No-show, Informacoes do pedido,
Contacto, endereco e descricao usavam cores hardcoded. O resultado era texto
quase invisivel e blocos claros dentro de uma tela escura.

Causa tecnica:
Alguns widgets do detalhe ainda usavam `Colors.black54`, `Colors.black87` e
`Colors.grey.shade100`, em vez de `Theme.of(context).colorScheme`.

Correcao:
- `PedidoInfoRow` passou a usar cores do tema.
- `ContatoSection` passou a usar surface/outline/texto do tema.
- No-show, endereco e descricao no detalhe passaram a respeitar o tema.

Validacao:
- `flutter test --no-pub` passou com 160/160.
- `npm.cmd run test:scripts` passou.
- Build Web release local passou em `build/web_manual_release`.
```

### M2.13-SOLO-UX-003 - Localizacao do chat nao abria Google Maps

```text
Data: 2026-05-27
Tester: Filipe/Jamal em beta solo manual
Plataforma: Web release local
Papel: Cliente/Prestador
Severidade: alta
Frequencia: sempre em mensagens antigas de localizacao
Estado: corrigido
```

Resumo:
A mensagem de localizacao aparecia como texto plano, com URL do Google Maps,
mas nao se comportava como acao clicavel para abrir o mapa.

Causa tecnica:
As mensagens antigas de localizacao usavam `latitude` e `longitude`, enquanto
`ChatMessage` so reconhecia `locationLat` e `locationLng`. Por isso a UI nao
identificava a mensagem como localizacao.

Correcao:
- `ChatMessage` passou a aceitar os campos legados `latitude/longitude`.
- `ChatMessage` ganhou `mapsUri`.
- O envio de localizacao passou a gravar os dois formatos de coordenadas.
- `ChatThreadScreen` passou a renderizar localizacao como item clicavel.

Validacao:
- Novo teste `test/core/chat_message_location_test.dart`.
- `flutter test --no-pub` passou com 160/160.
- Build Web release local passou em `build/web_manual_release`.
```

### M2.13-SOLO-UX-004 - Contraste dark mode inconsistente em areas adicionais

```text
Data: 2026-05-27
Tester: Filipe/Jamal em beta solo manual
Plataforma: Web release/local
Papel: Cliente/Prestador
Severidade: alta
Frequencia: sempre nas areas afetadas
Estado: corrigido localmente
```

Resumo:
Depois da primeira correcao do detalhe, ainda havia areas com texto quase
invisivel no modo escuro, especialmente nos painéis de acoes, chat/preview,
perfil, favoritos, suporte, agenda, KYC, selecao de prestador e formularios de
novo pedido.

Causa tecnica:
Widgets diferentes ainda usavam `Colors.black54`, `Colors.black87`,
`Colors.grey` ou superficies claras fixas. Esses valores funcionam em light
mode, mas quebram contraste quando a app esta em dark mode.

Correcao:
- Acoes Cliente/Prestador migradas para tokens do tema.
- Chat preview, bolhas, audio, timeline e contacto usam `colorScheme`.
- Perfil Cliente/Prestador, favoritos, KYC, suporte, report problem, agenda,
  selecionar prestador e novo pedido deixaram de usar texto/superficie fixa
  nos pontos encontrados.
- Adicionado teste de regressao para bloquear texto preto hardcoded em dark
  mode nas acoes Cliente/Prestador.

Validacao:
- `flutter test --no-pub test/features/cliente/widgets/pedido_actions_visual_test.dart` passou.
```
