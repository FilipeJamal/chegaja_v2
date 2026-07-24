# U0 — auditoria e baseline protegida

Data: 2026-07-20

Branch: `agent/u0-market-leadership-baseline`

Base auditada: `7230b4406338666c399ec3c5f0f3cb204c61b04e`

## Objetivo

Proteger o produto demonstrável antes de iniciar U1. U0 não redesenha a app e
não ativa produção. Regista o estado real, elimina alegações contraditórias,
fecha fronteiras críticas encontradas na auditoria e cria regressões
automatizadas.

## Baseline técnica

O inventário detalhado e reproduzível está em
`docs/product/U0_TECHNICAL_INVENTORY_2026-07-20.md`.

- Flutter/Firebase com fluxos Cliente, Prestador e Admin.
- Separação P1 disponível no código para dados públicos/privados, dispatch,
  KYC privado, pagamentos e suporte.
- Catálogo com 12 grupos profissionais e 55 políticas server-side.
- Pedido concentra pedido, proposta, execução e economia; a separação em
  entidades próprias continua evolutiva.
- `functions/index.js` e `PedidoService` ainda são pontos monolíticos de risco.
- Feature flags existem em `.env`, mas não formam um contrato tipado e
  observável.
- Analytics cobre sobretudo eventos de pedido; não cobre o funil adaptativo.

## Bloqueadores encontrados

### 1. Telefone e coorte não cobriam todos os caminhos

As callables principais exigiam telefone, consentimento e allowlist, mas
transições diretas de `pedidos`, chat e uploads dependiam parcialmente apenas de
sessão autenticada/participação. Uma conta anónima ou fora da coorte podia
tentar caminhos que o readiness não exercitava.

Decisão U0:

- exigir telefone confirmado e papel ativo na coorte nas Rules para ler ou
  alterar pedidos privados, usar dispatch, chat e oportunidades;
- exigir os mesmos gates nos uploads privados, temporários, perfil e portefólio;
- aplicar defesa equivalente às callables de Storage;
- testar explicitamente conta sem telefone e conta fora da coorte.

### 2. A UI mostrava uma comissão diferente do backend

O resumo do Prestador simulava 15% antes da confirmação. A política em dinheiro
é calculada no servidor e atualmente pode aplicar isenção aos primeiros dois
trabalhos e 10% depois.

Decisão U0: antes de existir cálculo autoritativo, mostrar o bruto e explicar
que comissão/líquido serão calculados no backend. Depois da conclusão, mostrar
apenas os campos persistidos pelo servidor.

### 3. Feature flag de chamadas era incompleta

Os botões desapareciam, mas o listener de chamadas recebidas continuava ativo.
A flag passa a governar botões, listener, criação e abertura do ecrã; Firestore
e Storage já mantêm chamadas bloqueadas no piloto.

### 4. Evidência P1 não estava ligada aos fontes atuais

O JSON de preparação produtiva contém hashes de uma revisão anterior. O
readiness passa a comparar os hashes atuais de Firestore Rules, Storage Rules e
Functions com a captura. Divergência é bloqueador e exige repetir auditoria e
migração imediatamente antes do cutover; os hashes não devem ser atualizados à
mão.

Os hashes textuais usam `sha256-canonical-text-v1`, que normaliza UTF-8 e
CRLF/CR para LF. Assim, Windows e Linux produzem a mesma prova. A impressão
auditável dos hashes é feita com `npm run p1:source:hashes` e cobre as duas
Rules, `functions/index.js`, `functions/package.json`, `functions/package-lock.json`
e o fingerprint conjunto do deploy de Functions. O comando não marca a
migração como repetida e não atualiza a evidência produtiva.

### 5. Anexos partilhados podiam ser alterados pelo outro participante

Os caminhos de pedido e chat não codificam o autor do upload. Permitir
`update` ou `delete` a qualquer participante deixava Cliente e Prestador
sobrescrever ou apagar prova do outro. Até existir ownership persistido e
auditável por objeto, anexos partilhados passam a ser imutáveis para
participantes: podem criar e ler; apenas a operação administrativa pode
substituir ou eliminar. Uma regressão automatizada cobre overwrite e delete
cruzados.

### 6. Roadmaps e materiais externos contradiziam a decisão atual

- A–T apresentava segurança/produção como fechadas em termos demasiado amplos.
- O pacote de investimento de junho usa Maputo e 700.000 MZN.
- A decisão atual é Coimbra primeiro e ronda anunciada de €300.000.
- A landing local contém métricas e testemunhos não comprovados.

A fonte canónica é
`docs/product/MARKET_LEADERSHIP_SOURCE_OF_TRUTH.md`. O pacote antigo não está
apto para envio externo.

## Auditoria visual

A captura inicial em debug mostrou apenas os assets de splash porque o servidor
de desenvolvimento não completou a ligação ao runtime do Browser. Uma build Web
estática reproduziu corretamente o gate atual: Web está bloqueada no release do
piloto e apresenta «Piloto disponível apenas em Android», ainda com texto
Maputo/Matola.

Para observar os fluxos reais sem alterar produção foi gerada uma build Web de
debug ligada aos emuladores. As capturas atuais de U1 devem cobrir seleção de
papel, homes Cliente/Prestador, novo pedido, pesquisa, detalhe, chat, perfis e
pagamentos em mobile/desktop antes de escolher uma nova direção visual.

Achados estruturais que seguem para U1:

- contraste do CTA primário abaixo de WCAG AA;
- fonte `Inter` declarada no tema, mas não empacotada;
- adoção parcial dos tokens/componentes;
- navegação fragmentada em dezenas de `MaterialPageRoute`;
- perfil sem scroll seguro em ecrãs pequenos;
- formulário de pedido longo e ainda não adaptativo;
- telefone, moeda, locale e textos presos a Moçambique;
- estados de erro sem ação real de retry;
- ausência de testes de semântica, text scale e golden baselines.

As três capturas úteis foram preservadas no repositório em
`docs/product/evidence/u0-2026-07-20/`; deixaram de depender do diretório
temporário da máquina de auditoria.

## Captação — baseline

Existem deck, one-pager e roteiro antigos, mas faltam ou estão incompletos:

- modelo financeiro mensal de 24 meses;
- plano operacional Coimbra;
- plano de contratação e liderança técnica humana;
- vídeo de 60–90 segundos;
- site e email profissionais verdadeiros;
- LinkedIn confirmado;
- data room privado;
- tracker e contactos verificados em fontes oficiais;
- tração, entrevistas e manifestações de interesse reais.

Nenhum contacto com investidores deve usar métricas/testemunhos fictícios ou
apresentar o projeto como empresa constituída.

## Critérios de saída U0

- [x] fonte canónica U0–U12, mercado e ronda;
- [x] inventário técnico, UX e fundraising;
- [x] telefone/coorte nas fronteiras diretas de pedido/chat/storage;
- [x] anexos partilhados imutáveis para participantes;
- [x] comissão pré-confirmação sem estimativa falsa;
- [x] flag de chamadas aplicada ao comportamento;
- [x] gate de proveniência P1;
- [x] testes Flutter, Rules/Functions e scripts verdes;
- [ ] CI verde no pull request;
- [ ] pull request revisto e mergeado em `main`.

Os dois últimos itens só podem ser assinalados depois da prova real desta branch.

## Validação local final

Executada em 2026-07-24 sobre a branch U0, antes da criação do pull request:

- Flutter: **522 testes aprovados** em 105 ficheiros;
- Functions/Firestore/Storage: **167 testes aprovados** em 24 ficheiros, com
  emuladores Firebase;
- scripts de migração, reconciliação, readiness, proveniência e release:
  **14 grupos aprovados**;
- análise estática Flutter: **0 erros** e 328 avisos/informações não fatais,
  mantidos visíveis;
- `node --check functions/index.js`: aprovado;
- `git diff --check`: aprovado, sem erros de whitespace;
- varredura de segredos e dados pessoais: nenhum NUIT/NIF pessoal, chave
  privada ou credencial live introduzido pela branch.

Esta validação não substitui CI, revisão do pull request, Android físico,
cutover produtivo, enforcement App Check ou piloto real.
