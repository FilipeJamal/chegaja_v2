# P0.3 - One-pager para investidor

Data: 2026-06-06

Estado: FECHADO no escopo documental.

## Objetivo

Este documento cria uma versao curta, clara e enviavel do ChegaJa para
investidor anjo/pre-seed. O one-pager deve funcionar antes ou depois da demo:

- antes, para abrir conversa;
- depois, para deixar a tese e o pedido de investimento por escrito.

Esta tarefa nao altera produto, Dart, Rules, Functions, Storage, deploy,
pagamentos, KYC, Figma, PowerPoint, PDF, video ou M2.21.

## One-pager principal

### ChegaJa

```text
Infraestrutura local de confianca para servicos sob demanda.
```

ChegaJa e um marketplace de servicos locais que liga Clientes e Prestadores com
mais estrutura, contexto e seguranca. O produto ja tem um MVP funcional com
fluxo Cliente/Prestador, pedidos, pesquisa manual, perfil publico, portfolio,
avaliacoes, link publico, admin leve, Trust & Safety, categorias sensiveis,
catalogo profissional e politica de admissao de servicos.

## Problema

Encontrar um prestador confiavel ainda depende muito de contactos soltos,
grupos, recomendacoes informais e conversas dispersas. O Cliente muitas vezes
nao consegue ver reputacao, portfolio, disponibilidade ou historico. O
Prestador pequeno tambem perde oportunidades porque nao tem uma montra digital
organizada, pesquisavel e partilhavel.

O problema nao e apenas descoberta. E confianca, contexto e organizacao.

## Solucao

O ChegaJa transforma a procura por servicos locais num fluxo estruturado:

- Cliente descreve o que precisa.
- O app organiza o pedido por Servico -> Intencao -> Detalhes.
- Cliente pode pedir agora, agendar ou receber orcamento.
- Prestador cria perfil, escolhe categorias, adiciona portfolio e recebe
  pedidos compativeis.
- Perfil publico, reputacao leve e @handle ajudam a ganhar confianca.
- Trust & Safety bloqueia servicos proibidos e separa categorias sensiveis.

## O que ja existe

O MVP atual ja cobre:

- app Cliente/Prestador;
- criacao e acompanhamento de pedidos;
- pedido por orcamento;
- chat/negociacao no contexto do pedido;
- perfil publico de prestador;
- portfolio;
- avaliacoes e reputacao leve;
- favoritos;
- pesquisa manual/discovery;
- @handle, link publico e partilha social;
- admin/backoffice leve;
- categorias sensiveis e comprovativos profissionais;
- catalogo profissional com categorias, subcategorias, aliases e frases comuns;
- servico personalizado seguro;
- politica global de admissao de servicos.

## Diferencial

ChegaJa nao e so uma lista de nomes. A base do produto combina:

- catalogo profissional;
- perfil e reputacao;
- pedidos estruturados;
- contexto de conversa;
- descoberta por pesquisa;
- seguranca desde o MVP;
- filtros contra servicos ilicitos;
- crescimento futuro de catalogo sem abrir texto livre sem controlo.

A politica de admissao classifica novos servicos como:

```text
allow            - permitido
sensitiveReview  - sensivel, pode exigir analise
block            - proibido, bloqueia e nao guarda
unknownReview    - desconhecido/vago, nao publica automaticamente
```

## Mercado inicial

O foco recomendado e Maputo/Mocambique, com piloto controlado em categorias de
alta frequencia:

- casa e reparacoes;
- limpeza e manutencao;
- beleza e bem-estar;
- alimentacao;
- eventos;
- tecnologia.

A estrategia e validar densidade local antes de expandir: recrutar prestadores
selecionados, ativar clientes, medir pedidos, medir resposta, medir qualidade e
aprender com uso real.

## Modelo de negocio futuro

O modelo pode evoluir por etapas:

- comissao por servico quando pagamentos reais forem integrados;
- plano PRO para prestadores;
- destaques pagos transparentes;
- leads qualificados;
- parcerias locais.

No momento, a prioridade nao e fingir receita antes da hora. A prioridade e
validar liquidez, confianca e repeticao no piloto.

## Pedido de investimento

Valor recomendado:

```text
700.000 MZN
```

Cenarios possiveis:

```text
Enxuto:      350.000 MZN
Recomendado: 700.000 MZN
Robusto:   1.250.000 MZN
```

Uso sugerido dos 700.000 MZN:

- 20% - UI/UX e polimento do produto;
- 15% - testes reais e piloto;
- 20% - marketing inicial e recrutamento de prestadores;
- 15% - operacao, moderacao e suporte inicial;
- 10% - infraestrutura, ferramentas e servicos;
- 10% - juridico, politicas e documentacao;
- 10% - reserva/imprevistos.

## Proximos 60 a 90 dias

Com investimento, o objetivo e sair de MVP funcional para piloto real:

- preparar apresentacao e demo final;
- polir pontos visuais e friccoes do produto;
- validar Android em dispositivo fisico;
- recrutar prestadores iniciais;
- executar piloto controlado em Maputo;
- medir pedidos criados, pedidos aceites, tempo de resposta e repeticao;
- recolher feedback real;
- corrigir bloqueadores;
- reforcar enforcement server-side/callable antes de producao publica ampla.

## Risco reconhecido

O produto ja tem protecao client-side e filtragem defensiva contra servicos
proibidos. Antes de uma producao publica ampla, ainda e recomendado criar uma
camada server-side/callable para impedir escrita direta maliciosa fora da UI.

Este risco esta identificado e e parte do roadmap de hardening, nao da tese de
demo/piloto controlado.

## Frase de fecho

```text
ChegaJa ja tem base tecnica, produto navegavel e uma narrativa clara: organizar
servicos locais com mais confianca. O investimento serve para validar mercado
com prestadores reais, clientes reais e metricas reais.
```

## Versao curta para WhatsApp/email

```text
O ChegaJa e uma infraestrutura local de confianca para servicos sob demanda.

Ja temos um MVP funcional com fluxo Cliente/Prestador, pedidos, pesquisa,
perfil publico, portfolio, avaliacoes, link publico, admin leve, Trust &
Safety, categorias sensiveis e catalogo profissional.

O problema que atacamos e simples: encontrar prestadores confiaveis ainda
depende de contactos soltos, pouca informacao e pouca reputacao visivel. O
ChegaJa organiza isso num fluxo com Servico -> Intencao -> Detalhes, perfil do
Prestador e regras de seguranca.

Estamos a preparar um piloto controlado em Maputo. O ask recomendado e
700.000 MZN para polimento, piloto, recrutamento de prestadores, marketing
inicial, operacao, moderacao, suporte, juridico/documentacao e reserva.

O objetivo nao e vender tracao inventada. E transformar um MVP funcional num
piloto real com metricas: pedidos criados, pedidos aceites, tempo de resposta,
qualidade e repeticao.
```

## Versao ainda mais curta

```text
ChegaJa e um marketplace local de servicos sob demanda com foco em confianca.
O MVP ja tem Cliente/Prestador, pedidos, perfis, portfolio, avaliacoes,
discovery, link publico, admin leve, Trust & Safety e catalogo profissional.

Procuramos 700.000 MZN para transformar a base atual num piloto controlado em
Maputo, recrutando prestadores, ativando clientes e medindo sinais reais de
procura, resposta e repeticao.
```

## O que nao dizer

Evitar:

- "Ja somos lideres."
- "Mercado garantido."
- "Receita comprovada."
- "Prestadores verificados" sem processo formal completo.
- "Pagamento seguro" antes de pagamentos reais estarem integrados.
- "Escala nacional imediata."
- "Sem risco."

Usar:

- MVP funcional.
- Piloto controlado.
- Sinais reais.
- Trust & Safety desde o MVP.
- Foco inicial em Maputo.
- Investimento para validar mercado.

## Fora do escopo deste P0.3

- Criar PDF final.
- Criar PowerPoint final.
- Criar Figma final.
- Criar video HyperFrames.
- Alterar codigo Dart.
- Alterar Firestore Rules, Storage Rules ou Cloud Functions.
- Fazer deploy.
- Criar metricas ficticias.
- Iniciar M2.21.

## Validacoes

Executadas nesta fase:

```text
git diff --check - passou
npm.cmd run test:scripts - passou
```

## Proximo passo

```text
P0.4 - Q&A para perguntas dificeis
```
