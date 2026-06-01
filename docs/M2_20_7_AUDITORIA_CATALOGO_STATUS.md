# M2.20.7 - Auditoria do catalogo profissional

Data: 2026-06-01

Estado: FECHADA no escopo documental/auditoria.

## Resultado

A auditoria confirmou que o catalogo atual tem amplitude suficiente para o MVP,
mas ainda nao tem uma estrutura profissional de categoria principal,
subcategoria, aliases, frases comuns e intencao de pedido. A fase M2.20.7
criou a especificacao de reorganizacao do catalogo e definiu M2.20.8 como
proximo passo para modelo/taxonomia.

## Estado atual do catalogo

O modelo atual `Servico` contem:

- `id`;
- `name`;
- `nameI18n`;
- `mode`;
- `keywords`;
- `iconKey`;
- `isActive`;
- `createdAt`.

O repositório `ServicosRepo` le a colecao `servicos`, filtra ativos no lado da
app para manter compatibilidade com documentos antigos e usa fallback local em
emulador via `initialServicosFull`.

O generator `servicos_catalogo_generator.dart` cria uma lista ampla com:

- servicos fixos;
- grupos macro;
- subgrupos;
- combinacao de acoes com objetos;
- keywords com prefixos informais como `s:`, `m:`, `p:`, `o:` e `i:`.

Isto da cobertura, mas nao cria uma taxonomia de produto. O Cliente ainda ve
nomes resultantes da expansao de microtarefas, enquanto o app deveria mapear
esses termos para subcategorias profissionais.

## Servicos demasiado especificos

A auditoria encontrou padroes que devem virar aliases, exemplos ou frases
comuns, nao necessariamente servicos principais:

- `Reparacao de torneiras`;
- `Instalacao de torneiras`;
- `Substituicao de torneiras`;
- `Reparacao de chuveiros`;
- `Instalacao de chuveiros`;
- `Diagnostico de iluminacao`;
- `Configuracao de routers`;
- `Limpeza de sofas`;
- `Tratamento de tapetes`;
- `Entrega de encomendas`;
- `Transporte de moveis`;
- `Sessao de retratos`;
- `Criacao de logotipos`;
- `Aulas de guitarra`;
- `Explicacoes de matematica`.

Estes termos continuam uteis para pesquisa, mas devem alimentar aliases e
common phrases de uma subcategoria canonica.

## Servicos que devem virar categoria, subcategoria ou alias

Exemplos de reorganizacao:

| Termo atual | Destino recomendado |
| --- | --- |
| Canalizador | Subcategoria `Canalizacao` em `Casa e reparacoes` |
| Torneira, chuveiro, cano, tubo | Aliases/frases de `Canalizacao` |
| Eletricista | Subcategoria `Eletricidade` |
| Luz, tomada, quadro, disjuntor | Aliases/frases de `Eletricidade` |
| Confeitaria, cake designer, bolos personalizados | Subcategoria `Bolos e confeitaria` |
| Bolo, aniversario, docinhos | Aliases/frases de `Bolos e confeitaria` |
| Babysitter | Subcategoria `Cuidados infantis` |
| Ama, cuidar crianca, buscar escola | Aliases/frases de `Cuidados infantis` |
| Cuidador de idosos | Subcategoria `Cuidados a idosos` |
| Apoio domiciliario, acompanhante | Aliases/frases de `Cuidados a idosos` |
| Dog walker, pet sitter | Subcategoria `Pet care` |
| Passeio cao, banho, tosa | Aliases/frases de `Pet care` |

## Organizacao recomendada

A estrutura futura deve ser:

```text
categoria principal
  subcategoria canonica
    aliases
    commonPhrases
    examples
    intents permitidos
    requirement sensivel opcional
```

Exemplo:

```text
Casa e reparacoes
  Canalizacao
    aliases: canalizador, cano, tubo, fuga de agua, torneira, chuveiro
    phrases: cano rebentou, agua a pingar, montar chuveiro
    intents: now, scheduled, quote
```

## Relacao com imediato, agendado e orcamento

Hoje `mode` vive no servico e influencia listas por `IMEDIATO`, `AGENDADO` ou
`POR_PROPOSTA`. Isto funciona tecnicamente, mas mistura catalogo com intencao do
pedido.

Decisao recomendada:

- a categoria/subcategoria responde a "o que precisas?";
- a intencao responde a "quando e como queres resolver?";
- `now`, `scheduled` e `quote` devem ser campos de pedido/intencao;
- a subcategoria pode definir quais intents sao permitidos e qual e o default.

## Como manter M2.20

A M2.20 continua fechada e valida. A nova taxonomia deve apenas apontar
subcategorias para requisitos existentes:

- `electricity`;
- `gas`;
- `child_care`;
- `elder_care`;
- `health`;
- `professional_food`;
- `training_nutrition`;
- `transport`;
- `in_home_service`.

O app deve continuar a respeitar:

- `categoryRequirements`;
- `sensitiveCategoryRequests`;
- `prestadores/{uid}/categoryApprovals/{categoryId}`;
- `approvedSensitiveCategoryIds`;
- `approvedSensitiveCategoryNames`;
- bloqueio de escrita client-side dos resumos de approval.

## NovoPedidoScreen

Estado atual:

- carrega todos os servicos ativos;
- usa selecao de servico por lista/dropdown;
- usa `_modo` e `_entradaOrcamento`;
- classifica Trust & Safety;
- grava campos auxiliares de categoria sensivel quando necessario.

Melhoria recomendada:

- entrada principal "Que servico precisas?";
- exemplos clicaveis;
- sugestoes por aliases;
- cards de categoria principal;
- subcategorias apos escolher categoria;
- depois escolher `Preciso agora`, `Quero agendar` ou `Quero receber orcamento`;
- manter aviso de categoria sensivel quando houver requirement.

## PrestadorSettingsScreen

Estado atual:

- le todos os servicos ativos;
- pesquisa com `ServicoSearchIndex`;
- grava `servicos` e `servicosNomes` no documento do prestador;
- agrupa por modo normalizado;
- inclui a secao de categorias sensiveis/comprovativos.

Melhoria recomendada:

- agrupar por categoria principal e subcategoria;
- reduzir microtarefas visiveis;
- usar aliases apenas como ajuda de pesquisa;
- permitir ao prestador escolher subcategorias canonicas;
- manter fluxo de pedido de approval para subcategorias sensiveis.

## Matching/search sem IA pesada

Preparacao recomendada:

- normalizador local de texto;
- tabela de aliases e frases comuns;
- score deterministico;
- sugestoes quando houver ambiguidade;
- fallback para "Outro servico";
- campos canonicos no pedido para evitar matching por texto livre.

Exemplos:

- "arranjar luz" -> Eletricidade;
- "cano rebentou" -> Canalizacao;
- "bolo aniversario" -> Bolos e confeitaria;
- "pc lento" -> Reparacao de computadores;
- "senhora limpar casa" -> Limpeza domestica.

## Riscos encontrados

- catalogo amplo pode parecer amador se microtarefas forem mostradas como itens
  principais;
- aliases sem taxonomia podem aumentar duplicacao;
- mover `mode` sem compatibilidade pode quebrar fluxo de pedido;
- categorias sensiveis podem perder enforcement se ids antigos mudarem sem
  mapeamento;
- UI nova pode quebrar E2E de pedido se for feita junto com modelo;
- `categoryRequirements` precisa acompanhar ids canonicos futuros;
- search deterministico precisa de testes para ambiguidades.

## Testes necessarios futuros

- modelo de taxonomia parseia categorias/subcategorias;
- ids canonicos sao unicos e estaveis;
- aliases normalizam acentos;
- frases populares sugerem categoria correta;
- query ambigua mostra sugestoes;
- NovoPedidoScreen preserva pedido normal;
- NovoPedidoScreen preserva pedido sensivel com approval;
- PrestadorSettingsScreen grava subcategorias canonicas;
- ProviderSearch/matching nao dependem de microtexto;
- M2.20 continua a bloquear prestador sem approval.

## Fora do escopo desta fase

- implementar UI;
- alterar Dart;
- alterar Firestore Rules;
- alterar Storage Rules;
- alterar Cloud Functions;
- deploy;
- IA externa;
- pagamentos;
- KYC;
- upload real;
- ranking avancado.

## Validacoes

Executadas nesta fase:

- `git diff --check`
- `npm.cmd run test:scripts`

## Decisao final

A M2.20.7 fica fechada como spec/auditoria. O proximo passo recomendado e:

```text
M2.20.8 - Modelo/taxonomia de catalogo profissional
```

M2.21 continua futuro, depois do fecho do trilho de catalogo profissional.
