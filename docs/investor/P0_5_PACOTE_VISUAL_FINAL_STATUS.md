# P0.5 - Pacote visual final para investidor

Data: 2026-06-06

Estado: FECHADO para artefatos locais. Figma Slides pendente de selecao de
team/organization no conector Figma.

## Objetivo

Transformar o material P0.1-P0.4 num pacote visual apresentavel para conversas
com investidor anjo/pre-seed:

- PowerPoint editavel;
- PDF para envio;
- HTML navegavel para revisao local;
- preview visual;
- manifesto de geracao;
- tentativa de geracao Figma Slides editavel.

Esta fase nao altera produto, Dart, Firestore Rules, Storage Rules, Cloud
Functions, pagamentos, KYC, deploy ou M2.21.

## Fontes usadas

```text
docs/investor/P0_1_DECK_INVESTIDOR_STRUCTURE.md
docs/investor/P0_2_ROTEIRO_DEMO_APP.md
docs/investor/P0_3_ONE_PAGER_INVESTIDOR.md
docs/investor/P0_4_QA_PERGUNTAS_DIFICEIS_INVESTIDOR.md
```

## Artefatos gerados

```text
artifacts/investor/ChegaJa_Investor_Deck_P0_5.pptx
artifacts/investor/ChegaJa_Investor_Deck_P0_5.pdf
artifacts/investor/ChegaJa_Investor_Deck_P0_5.html
artifacts/investor/ChegaJa_Investor_Deck_P0_5_preview.png
artifacts/investor/ChegaJa_Investor_Deck_P0_5_manifest.json
```

Media empacotada:

```text
artifacts/investor/media/clientHome.png
artifacts/investor/media/providerHome.png
artifacts/investor/media/orderDetail.png
artifacts/investor/media/chat.png
artifacts/investor/media/admin.png
artifacts/investor/media/logo.png
```

QA visual local:

```text
artifacts/investor/qa/slide_01.png
artifacts/investor/qa/slide_05.png
artifacts/investor/qa/slide_08.png
artifacts/investor/qa/slide_11.png
artifacts/investor/qa/slide_13.png
```

## Gerador

Foi criado um gerador reproduzivel:

```text
scripts/investor/generate_investor_deck.js
```

Comando:

```text
node scripts\investor\generate_investor_deck.js
```

O gerador cria:

- deck PowerPoint com 13 slides;
- speaker notes no PPTX;
- HTML 16:9 com os mesmos 13 slides;
- PDF 16:9 com 13 paginas;
- preview PNG da primeira slide;
- manifesto com fontes e media usadas.

## Estrutura do deck

```text
1. ChegaJa
2. Problema
3. Solucao
4. Produto atual
5. Cliente
6. Prestador
7. Diferenciais
8. Trust & Safety
9. Mercado inicial: Maputo
10. Modelo de negocio futuro
11. Pedido recomendado: 700.000 MZN
12. 60 a 90 dias: piloto controlado
13. Fecho
```

## Mensagem central

```text
ChegaJa ja tem MVP funcional e precisa de investimento para validar mercado em
piloto controlado com clientes e prestadores reais.
```

## Ask usado no deck

```text
Valor recomendado: 700.000 MZN
Cenario enxuto: 350.000 MZN
Cenario robusto: 1.250.000 MZN
```

Uso sugerido:

- 20% UI/UX e polimento;
- 15% testes reais/piloto;
- 20% marketing inicial e recrutamento de prestadores;
- 15% operacao, moderacao e suporte;
- 10% infraestrutura, ferramentas e servicos;
- 10% juridico, politicas e documentacao;
- 10% reserva/imprevistos.

## Validacao local dos artefatos

Verificacao estrutural:

```text
PPTX slides: 13
PPTX notes: 13
PDF page markers: 13
HTML slides: 13
```

Verificacao visual:

```text
Preview da slide 1 criado e inspecionado.
Slides 5, 8, 11 e 13 capturadas em PNG e inspecionadas.
Nao foi observado texto cortado critico nem sobreposicao incoerente nas slides verificadas.
```

## Figma Slides

Foi feita tentativa de gerar versao editavel no Figma Slides via conector
Figma.

Resultado:

```text
O conector pediu selecao de team/organization no widget antes de gerar o deck.
```

Mensagem devolvida pelo conector:

```text
You'll need to select a team or organization in the widget before I can
generate your "ChegaJa Investor Deck P0.5" presentation.
Once you pick the correct plan, the tool will create several professional and
readable presentation options for you to choose from.
```

Decisao:

- PPTX/PDF/HTML locais ficam prontos e versionados.
- Figma Slides fica pendente ate o Filipe selecionar o plan/team no widget do
  Figma.
- Depois da selecao, o mesmo brief usado nesta fase pode ser reenviado ao
  conector para gerar a versao editavel.

## Validacoes executadas

```text
node --check scripts\investor\generate_investor_deck.js - passou
node scripts\investor\generate_investor_deck.js - passou
git diff --check - passou
npm.cmd run test:scripts - passou
```

## Fora do escopo mantido

- Alterar app Flutter.
- Alterar Firestore Rules.
- Alterar Storage Rules.
- Alterar Cloud Functions.
- Fazer deploy.
- Criar metricas ficticias.
- Iniciar M2.21.
- Validar investimento real.

## Risco remanescente

O pacote visual local esta pronto, mas a versao Figma editavel depende da
selecao de team/organization no conector Figma. Alem disso, antes de uma
apresentacao externa, e recomendavel fazer uma revisao humana do texto final e
substituir screenshots se houver capturas mais recentes do app.

## Proximo passo

```text
Selecionar team/organization no widget Figma para gerar a versao Figma Slides
ou usar diretamente o PPTX/PDF local para marcar conversas com investidores.
```
