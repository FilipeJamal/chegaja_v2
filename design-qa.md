# U1 — Design QA

Data da comparação final: 2026-07-25

Escopo: primeira experiência do Cliente no Design System ChegaJá 2.0.

## Alvo aprovado

A direção aprovada pelo fundador combina:

- a riqueza visual e a sensação agradável da opção 1;
- a proximidade das intenções `Agora`, `Agendar` e `Orçamentos` da opção 2;
- a clareza, confiança e proteção de dados da opção 3.

Referência original:
`docs/product/evidence/u1-2026-07-24/u1-selected-visual.png`.

Referência normalizada:
`docs/product/evidence/u1-2026-07-24/u1-selected-visual-390x844.png`.

Captura final:
`docs/product/evidence/u1-2026-07-24/u1-client-home-widget-final.png`.

Comparação final:
`docs/product/evidence/u1-2026-07-24/u1-home-side-by-side.png`.

## Método

- viewport de referência e implementação: `390 × 844`;
- escala visual: `1x`;
- estado: catálogo carregado, quatro serviços visíveis, pedido recente e
  aviso de privacidade;
- captura final renderizada com os componentes de produção, tema U1, fonte
  Inter empacotada, ilustração real e navegação real;
- comparação lado a lado: referência à esquerda, implementação à direita,
  separadas por 8 px;
- a captura Android anterior foi preservada apenas como prova complementar de
  execução no emulador e não como alvo final de fidelidade.

## Superfícies verificadas

1. **Marca e localização** — wordmark legível, mercado operacional explícito e
   hierarquia superior consistente.
2. **Hero e intenção** — pergunta em duas linhas, ilustração Coimbra real e
   seletor completo para `Agora`, `Agendar` e `Orçamentos`.
3. **Entrada e ação principal** — campo livre reconhecível, CTA de alto
   contraste e percurso principal sem elementos sobrepostos.
4. **Descoberta e continuidade** — quatro serviços rápidos, ação `Ver todos` e
   pedido recente no mesmo estado funcional da referência.
5. **Confiança e navegação** — aviso de dados privados antes da aceitação e
   cinco destinos estáveis do Cliente.

## Histórico de severidade

### P0

- Nenhum bloqueador de uso, overflow destrutivo ou ação principal inacessível
  permaneceu na revisão final.

### P1 corrigidos

- `Orçamentos` deixou de truncar no seletor mobile.
- O hero perdeu a moldura e o espaçamento excessivos no mobile.
- O título e a ilustração receberam a hierarquia visual aprovada.
- Os três modos ganharam largura e alvos táteis adequados.
- A prova final passou a usar o estado carregado, em vez do skeleton.
- O cabeçalho de serviços e a ação `Ver todos` permanecem numa linha a 390 px.

### P2 corrigidos ou deliberadamente adaptados

- wordmark, chip de Coimbra, pesquisa, CTA, densidade e navegação foram
  aproximados à síntese escolhida;
- o gradiente funcional evita o laranja sob texto branco por contraste;
- a ilustração final é um ativo original de Coimbra, não uma cópia literal da
  proposta visual;
- diferenças de barra de estado ou gesture bar do Android não fazem parte da
  superfície do produto.

## Resultado

Não existem problemas visuais P0, P1 ou P2 abertos no escopo comparado. A prova
não autoriza lançamento público e não substitui Android físico, revisão
jurídica, App Check produtivo ou piloto real.

final result: passed
