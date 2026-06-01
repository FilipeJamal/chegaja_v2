# M2.20.7 - Catalogo profissional, subcategorias e intencao de servico

Data: 2026-06-01

Estado: FECHADA no escopo documental/auditoria.

## Objetivo

A M2.20.7 existe para resolver um problema diferente da M2.20. A M2.20 fechou
categorias sensiveis e comprovativos profissionais; a M2.20.7 define como o
catalogo deve deixar de parecer uma lista de microservicos soltos e passar a
funcionar como uma taxonomia profissional, pesquisavel e clara para Cliente e
Prestador.

Esta fase nao implementa UI, nao altera Dart, nao altera Rules, nao altera
Functions e nao faz deploy. Ela prepara a M2.20.8, que deve criar o modelo de
taxonomia e aliases.

## Problema de produto

O catalogo atual tem boa cobertura, mas mistura tres conceitos:

- profissao ou servico canonico, como `Canalizador`;
- microtarefas, como instalacao/substituicao/reparacao de objetos especificos;
- intencao de pedido, como imediato, agendado ou por orcamento.

Isto aumenta a cobertura do MVP, mas cria sensacao amadora quando o Cliente
encontra muitas entradas parecidas, por exemplo:

- reparacao de torneiras;
- instalacao de torneiras;
- substituicao de torneiras;
- reparacao de chuveiros;
- instalacao de chuveiros;
- substituicao de chuveiros.

O produto deve parecer mais proximo de uma plataforma premium:

1. O Cliente escreve em linguagem simples.
2. O app entende termos populares e aliases.
3. O app sugere categoria/subcategoria canonica.
4. O Cliente decide quando precisa: agora, agendar ou orcamento.
5. O pedido guarda a intencao de forma estruturada.

## Principios

- O Cliente nao deve precisar saber o nome tecnico do servico.
- Microtermos devem virar aliases, exemplos ou frases comuns, nao necessariamente
  servicos principais.
- `imediato`, `agendado` e `orcamento` devem ser intencao do pedido, nao a unica
  forma de organizar o catalogo.
- Categorias sensiveis da M2.20 continuam validas e devem ser mapeadas para a
  nova taxonomia.
- A solucao inicial deve funcionar sem IA externa.
- A linguagem publica deve continuar segura: sem "certificado", "verificado",
  "garantido", "pagamento seguro" ou "aprovado oficialmente".

## Modelo conceitual recomendado

### ServiceCategory

Representa a categoria principal visivel.

Campos futuros recomendados:

- `id`
- `name`
- `description`
- `iconKey`
- `displayOrder`
- `isActive`

### ServiceSubcategory

Representa o nivel profissional pesquisavel.

Campos futuros recomendados:

- `id`
- `categoryId`
- `name`
- `description`
- `aliases`
- `commonPhrases`
- `examples`
- `allowedRequestIntents`
- `defaultRequestIntent`
- `riskLevel`
- `approvalRequirementId`
- `displayOrder`
- `isActive`

### ServiceIntent

Representa a escolha final no pedido.

Campos futuros recomendados no pedido:

- `serviceCategoryId`
- `serviceCategoryName`
- `serviceSubcategoryId`
- `serviceSubcategoryName`
- `rawServiceQuery`
- `matchedAlias`
- `requestTiming`: `now`, `scheduled`, `quote`
- `categoryApprovalRequired`
- `categoryRequirementId`
- `categoryRiskLevel`

## Taxonomia inicial recomendada

### Casa e reparacoes

Subcategorias:

- Canalizacao
  - aliases: canalizador, cano, tubo, fuga de agua, torneira, chuveiro,
    sanita, autoclismo, pia, lava-louca, agua a pingar.
  - frases comuns: "cano rebentou", "tenho agua a sair do tubo", "montar
    chuveiro", "a sanita nao descarrega".
  - sensibilidade: normal por defeito; pode exigir cuidado em gas/aquecimento.
- Eletricidade
  - aliases: eletricista, luz, tomada, quadro eletrico, disjuntor, lampada,
    curto-circuito, energia caiu.
  - sensibilidade: `electricity`, approval recomendado.
- Gas
  - aliases: esquentador, gas, fuga de gas, canalizacao de gas.
  - sensibilidade: `gas`, approval obrigatorio.
- Pintura
  - aliases: pintor, parede, tinta, pintar quarto, pintura de casa.
- Carpintaria
  - aliases: madeira, portas, armarios, prateleiras, moveis por medida.
- Montagem de moveis
  - aliases: montar armario, montar cama, montar mesa, montar movel.
- Ar condicionado
  - aliases: AC, climatizacao, manutencao ar condicionado, instalacao AC.
- Reparacoes gerais
  - aliases: faz tudo, pequenos arranjos, reparacoes domesticas.

### Limpeza e manutencao

Subcategorias:

- Limpeza domestica
  - aliases: senhora da limpeza, limpar casa, limpeza semanal, limpeza profunda.
- Limpeza pos-obra
  - aliases: pos obra, limpeza de obra, poeira de obra, final de obra.
- Lavandaria e engomadoria
  - aliases: lavar roupa, passar roupa, engomar, lavandaria.
- Jardinagem
  - aliases: jardineiro, cortar relva, podar, limpar jardim.
- Manutencao de espacos
  - aliases: condominio, manutencao, piscina, garagem, arrecadacao.

### Beleza e bem-estar

Subcategorias:

- Cabelo e barbearia
  - aliases: cabeleireiro, barbeiro, corte, escova, barba, degradado.
- Maquilhagem
  - aliases: maquilhadora, make, noiva, festa, evento.
- Unhas
  - aliases: manicure, pedicure, gel, nail design.
- Massagem
  - aliases: massagista, relaxamento, drenagem, terapeutica.
- Personal trainer
  - aliases: PT, treino, fitness, ganhar massa, perder peso.
  - sensibilidade: `training_nutrition` quando envolve treino/nutricao.
- Nutricao
  - aliases: nutricionista, dieta, plano alimentar, comida fitness.
  - sensibilidade: `training_nutrition` ou `health`, conforme politica futura.

### Alimentacao

Subcategorias:

- Bolos e confeitaria
  - aliases: bolo, bolos, aniversario, casamento, docinhos, sobremesa,
    confeiteira, cake design.
- Catering
  - aliases: comida para evento, buffet, festa, catering pequeno.
  - sensibilidade: `professional_food`.
- Marmitas semanais
  - aliases: marmita, comida da semana, meal prep, almoco semanal.
- Comida saudavel
  - aliases: comida fitness, comida saudavel, dieta, low carb.
- Comida para atletas
  - aliases: comida de treino, proteina, bulk, cutting, atleta.

### Eventos

Subcategorias:

- Fotografia
  - aliases: fotografo, fotos, sessao, casamento, aniversario.
- Video
  - aliases: videografo, filmagem, reels, edicao de video.
- Decoracao
  - aliases: decoradora, festa, baloes, mesa posta, decoracao infantil.
- DJ e som
  - aliases: dj, musica, som, luzes, festa.
- Organizacao de eventos
  - aliases: planeamento, organizador, coordenacao, evento completo.

### Tecnologia

Subcategorias:

- Reparacao de telemoveis
  - aliases: telemovel, ecra partido, bateria, iphone, android.
- Reparacao de computadores
  - aliases: computador, pc, portatil, formatar, lento, virus.
- Internet e redes
  - aliases: wifi, router, internet, instalar internet, rede em casa.
- Suporte informatico
  - aliases: tecnico, configuracao, email, impressora, software.
- Websites e apps
  - aliases: site, loja online, app, programador, landing page.

### Educacao

Subcategorias:

- Explicacoes
  - aliases: explicador, matematica, fisica, quimica, apoio escolar.
- Idiomas
  - aliases: ingles, frances, espanhol, aulas de lingua.
- Musica
  - aliases: guitarra, piano, canto, bateria, aulas de musica.
- Apoio escolar
  - aliases: estudo acompanhado, trabalhos de casa, preparacao testes.
- Programacao
  - aliases: codigo, python, flutter, javascript, aulas de programacao.

### Transporte

Subcategorias:

- Mudancas
  - aliases: mudanca, mover casa, transportar moveis, carrinha.
  - sensibilidade: `transport` quando exige transporte profissional.
- Entregas
  - aliases: entrega, recolha, levar encomenda, estafeta.
- Transporte de objetos
  - aliases: sofa, frigorifico, maquina de lavar, objeto pesado.
- Motorista e transfer
  - aliases: motorista, aeroporto, transfer, boleia profissional.
  - sensibilidade: `transport`.

### Cuidados

Subcategorias:

- Cuidados infantis
  - aliases: babysitter, ama, cuidar crianca, buscar escola.
  - sensibilidade: `child_care`.
- Cuidados a idosos
  - aliases: cuidador idosos, acompanhante, apoio domiciliario, pessoa
    vulneravel.
  - sensibilidade: `elder_care`.
- Pet care
  - aliases: dog walker, pet sitter, passeio cao, banho, tosa.
- Apoio domiciliario leve
  - aliases: ajuda em casa, companhia, tarefas simples.
  - sensibilidade: avaliar com `in_home_service` e regras futuras.

### Outros

Subcategorias:

- Assistente pessoal
  - aliases: recados, compras, organizacao, tarefas.
- Servico nao listado
  - aliases: outro, nao sei, preciso de ajuda, servico diferente.

## Relacao com imediato, agendado e orcamento

A M2.20.7 recomenda que `IMEDIATO`, `AGENDADO` e `ORCAMENTO` deixem de ser a
unica divisao visivel do catalogo.

Fluxo recomendado:

1. Passo 1 - Servico: "Que servico precisas?"
2. Passo 2 - Intencao: "Quando precisas?"
   - Preciso agora.
   - Quero agendar.
   - Quero receber orcamento.
3. Passo 3 - Detalhes: descricao, localizacao, data/hora, fotos futuras e
   informacao de preco quando aplicavel.

Cada subcategoria pode ter:

- intents permitidos;
- intent recomendado;
- mensagens de contexto.

Exemplo:

- Canalizacao permite agora, agendar e orcamento.
- Bolos e confeitaria recomenda orcamento/agendamento.
- Explicacoes recomenda agendamento.
- Eletricidade pode permitir agora/agendar, mas se for categoria sensivel deve
  exigir approval quando a politica da M2.20 indicar.

## Integracao com M2.20

A nova taxonomia deve preservar os mecanismos da M2.20:

- `categoryRequirements/{categoryId}` continua a indicar approval necessario.
- `approvedSensitiveCategoryIds` continua a ser o resumo publico seguro.
- Pedidos sensiveis continuam a gravar `categoryApprovalRequired`,
  `categoryRequirementId`, `categoryRequirementName` e `categoryRiskLevel`.
- Prestador nao pode fingir aprovacao por escrita client-side.

Mapeamentos sensiveis iniciais:

- Eletricidade -> `electricity`.
- Gas -> `gas`.
- Cuidados infantis -> `child_care`.
- Cuidados a idosos -> `elder_care`.
- Saude/Nutricao clinica -> `health` ou `training_nutrition`.
- Catering profissional -> `professional_food`.
- Transporte profissional -> `transport`.
- Servicos em casa do cliente -> avaliar com `in_home_service` quando a regra
  exigir.

## Search sem IA pesada

Recomendacao para M2.20.8/M2.20.9:

- normalizar input: lowercase, trim, remover acentos;
- comparar por nome canonico, aliases, keywords e common phrases;
- score local:
  - nome exato;
  - alias exato;
  - frase comum;
  - token parcial;
  - categoria principal;
- quando houver ambiguidade, mostrar duas ou tres sugestoes;
- guardar no pedido a escolha canonica e o texto original do Cliente.

Isto resolve casos como:

- "cano rebentou" -> Canalizacao;
- "arranjar luz" -> Eletricidade;
- "senhora para limpar casa" -> Limpeza domestica;
- "homem para montar armario" -> Montagem de moveis;
- "bolo aniversario" -> Bolos e confeitaria;
- "pc lento" -> Reparacao de computadores.

## Impacto esperado na UX

### NovoPedidoScreen

Recomendacao futura:

- substituir dropdown/lista longa por entrada principal "Que servico precisas?";
- mostrar exemplos pesquisaveis;
- mostrar cards de categoria principal;
- mostrar subcategorias apos escolha;
- mover agora/agendar/orcamento para etapa posterior;
- manter warning de categoria sensivel quando a subcategoria exigir approval.

### PrestadorSettingsScreen

Recomendacao futura:

- agrupar servicos por categoria principal;
- permitir selecao por subcategoria canonica;
- mostrar aliases apenas como ajuda, nao como servicos separados;
- manter secao de categorias sensiveis/comprovativos ligada ao requisito real.

## Fora do escopo

- implementar UI;
- alterar `Servico`;
- criar colecoes novas;
- alterar Firestore Rules;
- alterar Storage Rules;
- alterar Cloud Functions;
- usar IA externa;
- criar ranking avancado;
- pagamentos;
- KYC;
- upload real;
- deploy.

## Subfases recomendadas

- M2.20.7 - Catalogo profissional e intencao de servico: spec/auditoria. FECHADA.
- M2.20.8 - Modelo/taxonomia de catalogo profissional. FECHADA.
- M2.20.9 - UI profissional de escolha de servico. FECHADA.
- M2.20.9.1 - Servico personalizado, Outro profissional e bloqueio de servicos proibidos. FECHADA.
- M2.20.10 - QA final do catalogo profissional. PROXIMO.
- M2.21 - Conta, definicoes e suporte premium.

## Testes futuros necessarios

- taxonomia possui ids unicos;
- categorias principais renderizam em ordem;
- subcategorias pertencem a categoria valida;
- aliases e common phrases normalizam acentos/maiusculas;
- busca por linguagem popular sugere a categoria correta;
- ambiguidades mostram sugestoes seguras;
- pedido normal continua funcionando;
- pedido sensivel preserva `categoryApprovalRequired`;
- prestador seleciona subcategoria sem gravar microservicos duplicados;
- M2.20 continua a impedir prestador sem approval em categoria sensivel;
- textos proibidos continuam ausentes.

## Decisao para a M2.20.8

A M2.20.8 deve criar a base tecnica de taxonomia, mantendo compatibilidade com o
catalogo atual e sem refatorar a UI inteira no mesmo passo.

## Estado apos M2.20.8

A M2.20.8 criou `ServiceIntent`, `ServiceTaxonomyCategory`,
`ServiceTaxonomySubcategory`, catalogo canonico inicial, normalizador textual,
matcher deterministico e compatibilidade com o catalogo antigo por
`legacyServicoIds`/`legacyNames`.

O proximo passo passa a ser:

```text
M2.20.9 - UI profissional de escolha de servico
```

## Estado apos M2.20.9

A M2.20.9 aplicou a taxonomia profissional nas telas principais:

- `NovoPedidoScreen` passou a apresentar pesquisa por linguagem simples,
  categorias principais, subcategorias canonicas e intencao de pedido.
- `PrestadorSettingsScreen` passou a organizar os servicos por categoria e
  subcategoria profissional.
- A compatibilidade com `servicoId`, `servicoNome`, `categoria`, `modo`,
  `servicos` e `servicosNomes` foi preservada.
- Categorias sensiveis continuam a mostrar aviso seguro e a gravar campos de
  approval quando aplicavel.

O proximo passo passa a ser:

```text
M2.20.10 - QA final do catalogo profissional
```

## Estado apos M2.20.9.1

A M2.20.9.1 refinou a opcao "Outro servico" para deixar de ser generica:

- Prestador descreve servicos personalizados com nome, descricao e aliases.
- Cliente descreve pedidos personalizados antes de criar pedido fora do catalogo.
- `CustomServiceSafetyValidator` valida nome, descricao, aliases e query
  original com `TrustSafetyClassifier`.
- Servicos proibidos sao bloqueados antes de gravar e usam a mensagem segura:
  "Este tipo de serviço não é permitido no ChegaJá."
- Servicos personalizados permitidos entram em campos pesquisaveis do perfil e
  do pedido, sem virarem categoria oficial global.
- Discovery/search usa `customServices`, `customServiceNames` e
  `customServiceSearchTerms`.
- `other_service` generico nao cria match amplo indevido.
- Hotfix critico reforcou o bloqueio robusto de termos obscenos/proibidos:
  `puta`, `prostituta`, `vadia`, variacoes e obfuscacoes simples nao entram,
  nao aparecem, nao pesquisam e nao fazem matching.
- A protecao usa `ServiceSafetyGuard` com tokenizacao, phrase matching, stem
  seguro `prostitu...` e falsos positivos testados para `computador`,
  `reputacao online` e `disputa contratual`.
- Firestore Rules e Cloud Functions nao foram alteradas.

O proximo passo continua a ser:

```text
M2.20.10 - QA final do catalogo profissional
```
