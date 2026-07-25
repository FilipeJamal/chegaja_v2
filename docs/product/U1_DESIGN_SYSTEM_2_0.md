# U1 — Design System ChegaJá 2.0

Data: 2026-07-24

Estado: candidato final em validação na branch `agent/u1-design-system-2`

## Decisão visual

O alvo aprovado combina:

- a sensação calorosa, agradável e visualmente rica da direção 1;
- o acesso imediato a `Agora`, `Agendar` e `Orçamentos` da direção 2;
- a clareza operacional, confiança e privacidade da direção 3.

A referência aprovada está versionada em
`docs/product/evidence/u1-2026-07-24/u1-selected-visual.png`.

A implementação final e a comparação no mesmo viewport/estado estão em:

- `docs/product/evidence/u1-2026-07-24/u1-client-home-widget-final.png`;
- `docs/product/evidence/u1-2026-07-24/u1-home-side-by-side.png`;
- `design-qa.md`.

## Princípios

1. A missão é inclusiva, mas a interface não promete emprego nem rendimento.
2. O pedido começa pela intenção do Cliente, não por uma taxonomia rígida.
3. A localização pública é aproximada; os detalhes privados não aparecem na
   descoberta.
4. A identidade visual é expressiva nas superfícies de marca e acessível nas
   ações funcionais.
5. Cliente e Prestador têm navegações próprias, previsíveis e com cinco
   destinos.
6. Carregamento, vazio, offline, erro, dados antigos e recuperação são estados
   de produto, não exceções improvisadas.
7. Android é o primeiro alvo operacional. Web e Windows mantêm consistência
   responsiva, sem afirmar prontidão pública.

## Fundação visual

### Marca

- gradiente decorativo: laranja → magenta → roxo;
- gradiente de ação: rosa escuro → violeta → roxo, com contraste AA para texto
  branco;
- primária funcional: roxo `#6D3BD1`;
- fundo claro: branco quente;
- fundo escuro: ameixa quase preto;
- sucesso, aviso, erro e informação mantêm significado próprio.

O laranja é um acento de marca. Não deve receber texto branco pequeno porque
não mantém contraste suficiente.

### Tipografia

`Inter` é a família canónica e está incluída localmente no pacote da aplicação.
O produto não depende de download de fontes em runtime.

### Escala

- espaçamento: 4, 8, 12, 16, 20, 24, 32, 40 e 48;
- raios: 8, 12, 16, 20 e 28;
- alvos táteis: mínimo de 48 × 48;
- botões: 48, 52 e 56 de altura;
- movimento: 120, 180 e 260 ms, respeitando transições simples.

## Navegação

### Cliente

1. Início
2. Pedidos
3. Mensagens
4. Guardados
5. Perfil

### Prestador

1. Oportunidades
2. Agenda
3. Trabalhos
4. Mensagens
5. Negócio

### Comportamento responsivo

- menos de 600 px: barra inferior;
- 600–1023 px: `NavigationRail`;
- 1024 px ou mais: barra lateral;
- destinos ainda não visitados são inicializados de forma lazy;
- o estado de um destino visitado é preservado ao mudar de separador;
- IDs estáveis impedem que uma alteração de ordem troque estados internos.

### Rollback atómico

O nome histórico `u1NavigationV2` representa agora a experiência U1 completa,
e não apenas a barra de navegação. A mesma decisão controla:

- a seleção de papel;
- a nova Home do Cliente;
- a navegação de Cliente e Prestador;
- o destino Guardados e a Agenda U1.

Com `feature_u1_navigation_v2=false`, essas superfícies mantêm o comportamento
anterior. Com `true`, entram juntas. Tokens, tema e componentes base são
aditivos e compatíveis com as duas superfícies. Assim, um único kill switch
remoto reverte a experiência visível sem migração de dados nem nova versão da
aplicação.

### Matriz de verificação do rollback

| Superfície | Flag OFF | Flag ON |
| --- | --- | --- |
| Seleção de papel | composição anterior | composição U1 |
| Home do Cliente | hero e descoberta anteriores | hero, modos e descoberta U1 |
| Shell do Cliente | navegação anterior | cinco destinos U1 |
| Shell do Prestador | navegação anterior | cinco destinos U1 |
| Guardados | destino anterior | destino U1 |
| Agenda do Prestador | superfície anterior | superfície U1 |

Os testes de rollback exercitam os dois estados. O define local
`U1_PREVIEW=true` só pode forçar o estado ON em builds não-release; um build
`release` ignora-o.

## Início do Cliente

A primeira dobra apresenta:

- marca e mercado operacional (`Coimbra`);
- pergunta principal;
- ilustração original;
- seletor `Agora`, `Agendar`, `Orçamentos`;
- descrição livre do pedido;
- ação `Continuar`;
- acesso secundário à pesquisa de Prestadores.

Depois aparecem serviços rápidos, pedido recente quando existir e uma mensagem
explícita de privacidade. O mapa só entra quando acrescentar valor ao modo e à
categoria.

## Acessibilidade

- texto e ações funcionais cumprem WCAG AA nos pares canónicos;
- semântica explícita em marca, ações, estados e seleção;
- estados dinâmicos usam regiões vivas;
- ícones decorativos não duplicam a leitura;
- controlos essenciais mantêm alvos de 48 px;
- a primeira experiência não deve transbordar a 200% de escala de texto;
- claro e escuro expõem os mesmos contratos semânticos.

## Segurança de lançamento

O U1 prepara o produto, mas não autoriza produção:

- flags de risco permanecem desligadas;
- capacidades críticas falham fechadas sem aprovação de backend;
- KYC e pagamentos públicos continuam bloqueados;
- `pt-coimbra` e `mz-maputo` têm contratos explícitos e separados no cliente
  e no backend; moeda, telefone, limites, locale, fuso e coorte não podem ser
  inferidos por texto da interface;
- a versão jurídica `legal-2026-07-20-pilot-v3` continua vinculada ao mercado
  histórico `mz-maputo` e não pode ser aceite em `pt-coimbra`;
- ações reais em Coimbra permanecem bloqueadas até existir uma nova versão
  revista para Portugal, contacto jurídico oficial e configuração
  correspondente no backend;
- não existe deploy de produção implícito;
- `com.pontosegaja.app` continua dependente do registo do cliente Android no
  Firebase e da migração controlada da identidade da aplicação.

## Critério de conclusão

O U1 só fica concluído quando:

- código, testes e documentação estiverem no GitHub;
- análise focada não tiver erros;
- testes Flutter e backend estiverem verdes;
- APK de validação for construído;
- referência e implementação forem comparadas no mesmo viewport e estado;
- os problemas visuais P0, P1 e P2 forem corrigidos;
- o pull request tiver CI verde e for integrado na `main`.

## Evidência de fecho

- índice: `docs/product/evidence/u1-2026-07-24/README.md`;
- Design QA: `design-qa.md`;
- resultados técnicos:
  `docs/product/evidence/u1-2026-07-24/u1-validation-results.md`;
- manifesto de builds:
  `docs/product/evidence/u1-2026-07-24/u1-build-manifest.json`.

Os resultados técnicos, hashes e ligação do pull request só são declarados
depois da execução real. O merge não implica deploy, publicação de Remote
Config ou abertura do piloto.
