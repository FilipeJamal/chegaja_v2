# M2.11 - Beta Interna Controlada

Data: 2026-05-21

## Contexto

A M2.10 foi fechada como Visual Product System. Depois disso, os ajustes
visuais pos-fecho tambem ficaram controlados:

```text
catalogo visual de servicos expandido
assets SVG locais por area de servico
Home Cliente com direcao visual Image2
navegacao desktop/mobile melhorada
QA visual local documentada
```

O ChegaJa ja tem uma base tecnica, operacional e visual muito mais madura:

```text
M2.7: hardening de producao fechado
M2.8: operacoes de producao fechado
M2.9: beta Web UX fechado
M2.10: visual product system fechado
```

A M2.6 continua pendente de Android fisico real. Esta fase nao deve fechar a
M2.6 nem fingir validacao nativa Android.

## Problema

O projeto ja passou por testes automatizados, emuladores, smoke real controlado
e QA visual. Ainda falta validar a app como produto usado por uma pessoa real:

```text
um cliente precisa criar e acompanhar um pedido sem orientacao tecnica
um prestador precisa perceber o que aceitar, iniciar, orcamentar e concluir
mensagens precisam ser usadas dentro do fluxo real
perfil/conta precisam estar compreensiveis
bugs precisam ser reportados com contexto e prioridade
Web e Windows precisam ter diferencas conhecidas documentadas
```

Sem uma beta interna controlada, a equipa continua a construir sem evidencias de
uso real ponta a ponta.

## Objetivo

Preparar uma beta interna controlada do ChegaJa para validar a experiencia como
produto real, com Cliente e Prestador, sem pagamentos reais, sem Play Store e sem
Android fisico.

O objetivo nao e adicionar funcionalidades novas. O objetivo e criar um pacote
de teste:

```text
roteiro de teste
contas/roles de teste
build Web
build Windows
checklist de bugs
estrutura de feedback
criterios de aprovacao/reprovacao
triagem dos problemas encontrados
```

## Principios

### Beta controlada, nao lancamento

A M2.11 deve ser tratada como uma beta interna, com testers conhecidos e escopo
controlado. Nao e lancamento publico.

### Validar produto, nao tecnologia isolada

O tester deve percorrer fluxos completos. O foco e perceber se a app faz sentido
para uma pessoa que nao conhece a implementacao.

### Evidencia antes de decisoes

Cada bug ou aprovacao precisa ter contexto:

```text
plataforma
role
passos para reproduzir
resultado esperado
resultado observado
screenshot ou nota visual quando aplicavel
prioridade
```

### Sem misturar producao sensivel

Nao devem entrar pagamentos reais, deploys desnecessarios, cleanup real ou
alteracoes de Rules/Functions nesta fase.

## Escopo

### 1. Preparacao da beta

Criar um pacote de beta interna com:

```text
documento de roteiro para tester
checklist de fluxos obrigatorios
checklist de bugs
template de feedback
criterios de aprovacao/reprovacao
estado das plataformas suportadas
limitacoes conhecidas
```

Documentos sugeridos:

```text
docs/M2_11_BETA_INTERNA_STATUS.md
docs/BETA_INTERNAL_TEST_SCRIPT.md
docs/BETA_FEEDBACK_TEMPLATE.md
```

### 2. Contas e roles de teste

Definir como o tester deve usar Cliente e Prestador:

```text
Cliente teste
Prestador teste
troca de role pela UI, sem editar URL
separacao entre dados de teste e dados reais
identificacao clara de dados criados pela beta
```

Requisito obrigatorio da beta: o tester deve conseguir alternar entre Cliente e
Prestador dentro da app. A URL `?role=cliente` / `?role=prestador` pode
continuar como override de desenvolvimento e automacao, mas nao pode ser a unica
forma de testar os dois modos.

Se forem necessarias credenciais reais, elas nao devem ser commitadas. A spec
deve orientar a usar instrucoes locais ou variaveis seguras, nunca segredos no
repositorio.

### 3. Builds

Validar e documentar os builds usados na beta:

```text
Web build local ou hospedado de forma controlada
Windows build local quando viavel
Android fisico continua fora do escopo da M2.11
```

Comandos esperados para validacao tecnica antes de entregar beta:

```cmd
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter build windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Se `flutter build windows` exigir configuracao local indisponivel, isso deve ser
documentado como bloqueio ambiental, nao escondido.

### 4. Roteiro Cliente

O tester Cliente deve validar:

```text
abrir app como Cliente
trocar para modo Prestador pela Conta/Perfil quando necessario
entender Home e categorias
pesquisar/selecionar servico
criar pedido
ver pedido na lista
abrir detalhe do pedido
acompanhar status
usar mensagens/chat quando disponivel
aceitar proposta/orcamento quando aplicavel
confirmar valor final quando aplicavel
cancelar pedido quando o fluxo permitir
consultar pedidos concluidos/cancelados
ver Conta/Perfil
reportar qualquer texto confuso, botao sem acao ou estado sem orientacao
```

### 5. Roteiro Prestador

O tester Prestador deve validar:

```text
abrir app como Prestador
trocar para modo Cliente pela Conta/Perfil quando necessario
entender estado online/offline
ver categorias/servicos configurados
ver pedidos disponiveis
aceitar pedido
ignorar pedido quando aplicavel
abrir detalhe do pedido
iniciar servico
enviar orcamento/faixa quando aplicavel
enviar valor final
usar mensagens/chat
ver pedidos em curso
ver pedidos concluidos/cancelados
ver Conta/Perfil
reportar qualquer acao ambigua, estado travado ou botao sem feedback
```

### 6. Roteiro de mensagens

Validar Mensagens em ambos os roles:

```text
lista de conversas carrega
conversa abre corretamente
mensagens enviadas aparecem
mensagens recebidas ficam compreensiveis
contador de nao lidas quando existir
pesquisa/filtro nao quebram a tela
input nao fica tapado em mobile/Web estreito
```

Nao criar funcionalidade nova de chat nesta fase. Apenas validar o que ja existe.

### 7. Roteiro de Conta/Perfil

Validar:

```text
cartao de perfil
papel Cliente/Prestador
estado online/verificado quando existir
editar perfil quando ja existir
definicoes
notificacoes/documentos/ajuda quando ja existirem
terminar sessao
```

Nao implementar KYC real, documentos reais ou pagamentos reais.

### 8. Diferencas Web e Windows

A beta deve documentar as diferencas observadas:

```text
layout desktop largo
scroll
sidebar
bottom navigation quando viewport estreito
renderizacao de SVGs
inputs e foco
atalhos/teclado quando relevante
performance percebida
```

Windows nao substitui Android fisico. A M2.6 continua pendente.

### 9. Checklist de bugs

Cada bug deve ser registado com:

```text
id curto
titulo
plataforma: Web, Windows ou ambos
role: Cliente, Prestador ou ambos
fluxo
passos para reproduzir
resultado esperado
resultado observado
screenshot/video quando possivel
severidade: bloqueador, alto, medio, baixo
tipo: funcional, visual, texto, performance, dados, ambiente
status: novo, confirmado, corrigido, nao reproduzido, futuro
```

### 10. Triagem

Prioridade de triagem:

```text
P0 bloqueador: impede concluir fluxo Cliente/Prestador
P1 alto: quebra acao importante, dados errados ou estado incoerente
P2 medio: confusao de UX, visual quebrado, mensagem ruim, workaround existe
P3 baixo: polish, copy, ajuste visual sem impacto forte
```

Politica de correcao:

```text
P0/P1 devem ser corrigidos antes de aprovar beta.
P2 podem ser agrupados numa fase de ajustes se forem muitos.
P3 podem ficar documentados para backlog visual/produto.
```

## Fora do Escopo

```text
pagamentos reais
Play Store
Android fisico real
fechar M2.6
backend novo
Firestore Rules novas
Storage Rules novas
Cloud Functions novas
deploy real sem necessidade
smoke real em producao sem necessidade
cleanup real
health real
novas funcionalidades grandes
KYC real
documentos reais
CI/CD de deploy automatico
```

## Criterios de Aceitacao

A M2.11 fica pronta para avancar quando:

```text
spec da beta interna existe e esta aprovada
roteiro Cliente/Prestador esta claro
contas/roles de teste estao definidos sem segredos no repositorio
checklist de bugs esta definido
template de feedback esta definido
criterios de aprovacao/reprovacao estao claros
build Web esta validado ou bloqueio documentado
build Windows esta validado ou bloqueio documentado
M2.6 continua marcada como pendente de Android fisico
fora do escopo foi respeitado
```

A beta interna so deve ser considerada aprovada se:

```text
fluxo Cliente principal conclui sem bloqueador
fluxo Prestador principal conclui sem bloqueador
mensagens funcionam no fluxo testado
pedido criado aparece em lista/detalhe
estados de pedido sao compreensiveis
Conta/Perfil nao bloqueia uso basico
nao ha P0/P1 abertos
P2/P3 restantes estao documentados
```

## Resultado Esperado

Ao final da M2.11, o ChegaJa deve ter uma beta interna executavel e auditavel:

```text
tester sabe exatamente o que testar
equipa sabe como classificar bugs
resultados ficam documentados
decisao de avancar, corrigir ou bloquear fica baseada em evidencia
M2.6 continua honesta: Android fisico ainda pendente
```
