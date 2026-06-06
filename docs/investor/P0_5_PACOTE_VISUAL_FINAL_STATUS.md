# P0.5 - Pacote visual final para investidor

Data: 2026-06-06

Estado: FECHADO no escopo atual.

## Objetivo

Transformar o material P0.1-P0.4 num pacote visual apresentavel para conversas
com investidor anjo/pre-seed:

- PowerPoint editavel;
- PDF para envio;
- HTML navegavel para revisao local;
- preview visual;
- manifesto de geracao;
- geracao Figma Slides editavel via widget do conector Figma.

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

Foi gerada uma versao editavel no Figma Slides via conector Figma.

Contexto de autenticacao:

```text
Utilizador Figma: Filipe Filipe
Email: bentojamalfilipe@gmail.com
Plan key usado: team::1635528922743542004
```

Resultado:

```text
O conector apresentou o widget de Figma Slides com opcoes de apresentacao.
```

Observacao:

- O conector nao devolveu URL textual no terminal.
- A selecao/edicao final acontece no widget Figma apresentado ao utilizador.
- Os artefatos locais PPTX/PDF/HTML continuam versionados no repo como copia
  independente e reutilizavel.

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

O pacote visual local esta pronto e a versao Figma foi disponibilizada no widget
do conector. Antes de uma apresentacao externa, e recomendavel fazer uma
revisao humana do texto final e substituir screenshots se houver capturas mais
recentes do app.

## Proximo passo

```text
Usar o PDF/PPTX local para marcar conversas com investidores e, se preferires
editar no Figma, abrir uma das opcoes apresentadas no widget Figma Slides.
```
