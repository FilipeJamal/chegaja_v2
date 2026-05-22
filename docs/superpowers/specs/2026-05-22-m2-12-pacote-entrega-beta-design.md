# M2.12 - Pacote de Entrega Beta

Data: 2026-05-22

## Contexto

A M2.11 foi fechada formalmente no `main`:

```text
296d4bd Fechar M2.11 beta interna controlada
```

Estado atual:

```text
M2.10: fechada como Visual Product System
M2.11: fechada como beta interna Web/Windows
Beta Web automatizada: aprovada
Windows tecnico: aprovado
M2.6: continua pendente de Android fisico real
```

Evidencia final da M2.11:

```text
flutter test: 152/152 passou
npm.cmd run test:scripts: passou
Firestore/Storage/Functions emulator: 68/68 passou
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true: passou
e2e:ui:dual: FULL MULTI-SCENARIO FLOW OK
e2e:ui:orcamento: ORCAMENTO MIN-MAX FLOW OK
logs finais sem overflow/runtime/assertion relevante
```

## Problema

A app ja passou por uma beta interna automatizada e por validacao tecnica
Web/Windows. O proximo passo nao e continuar a construir funcionalidades por
sensacao. O proximo passo e preparar uma entrega que uma pessoa real consiga
receber, abrir, testar e devolver feedback sem conhecer o ambiente de
desenvolvimento.

Sem um pacote de entrega, a beta externa fica fragil:

```text
tester pode nao saber que build usar
tester pode nao saber como alternar Cliente/Prestador
tester pode nao saber quais fluxos validar
bugs podem chegar sem passos de reproducao
limitacoes conhecidas podem ser confundidas com regressao
M2.6/Android fisico pode ser interpretada como resolvida quando nao esta
```

## Objetivo

Preparar um pacote de entrega beta para tester real, com builds, instrucoes,
roteiro simples e templates de feedback/bug.

A M2.12 nao deve adicionar funcionalidades grandes. O objetivo e operacionalizar
a entrega:

```text
build Web beta
build Windows beta
guia curto para tester
checklist de instalacao/abertura
roteiro simplificado Cliente/Prestador
template de feedback
template de bug
criterios de aprovacao/reprovacao da beta externa
lista de limitacoes conhecidas
```

## Principios

### Entrega clara antes de nova feature

A app ja tem base tecnica e visual suficiente para testar com uma pessoa real.
A M2.12 deve transformar essa base num pacote testavel, nao abrir um novo ciclo
de produto.

### Tester nao e programador

O tester nao deve precisar saber comandos internos, query string `?role=`,
estrutura Firebase ou detalhes de emulador para entender o que testar e como
reportar.

### Evidencia acionavel

Feedback deve chegar com informacao suficiente para triagem:

```text
plataforma
papel usado
passos executados
resultado esperado
resultado obtido
screenshot/video quando houver
severidade
frequencia
```

### Limites honestos

M2.12 nao pode fingir que Android fisico real, pagamentos reais, Play Store,
package id final ou HTTPS App Links foram resolvidos.

## Escopo

### 1. Build Web beta

Definir e documentar como gerar/usar o build Web de beta:

```text
comando de build
local de saida
modo de execucao local/controlada
dependencias de emulador ou configuracao
limitacoes conhecidas
criterios minimos para entregar ao tester
```

### 2. Build Windows beta

Definir e documentar como gerar/usar o build Windows de beta:

```text
comando de build
local esperado do executavel
passos para abrir
dependencias locais
comportamentos diferentes de Web
criterios minimos para entregar ao tester
```

### 3. Guia rapido do tester

Criar um guia curto, escrito para alguem que nao conhece o codigo:

```text
o que e o ChegaJa nesta beta
o que deve ser testado
como abrir a app
como alternar Cliente/Prestador pela UI
como reportar bugs
o que nao esta dentro desta beta
```

### 4. Roteiro simplificado Cliente/Prestador

O roteiro deve cobrir os fluxos essenciais:

```text
Cliente abre a app
Cliente escolhe servico
Cliente cria pedido
Cliente acompanha pedido
Prestador muda para online quando aplicavel
Prestador aceita pedido
Prestador inicia servico
Prestador envia orcamento/estimativa quando aplicavel
Cliente aceita/rejeita proposta quando aplicavel
Prestador envia valor final
Cliente confirma/questiona valor final
Mensagens/chat
Conta/Perfil
Historico de pedidos
Cancelamento/no-show quando fizer sentido
Troca Cliente/Prestador pela UI
```

### 5. Feedback e bug report

Criar templates separados:

```text
feedback geral de experiencia
bug report reproduzivel
```

O bug report deve pedir:

```text
ID ou titulo do teste
papel: Cliente/Prestador
plataforma: Web/Windows
passos executados
resultado esperado
resultado obtido
screenshot/video
severidade: bloqueador/alto/medio/baixo
frequencia: sempre/as vezes/uma vez
observacoes
estado: aberto/em analise/corrigido/adiado
```

### 6. Criterios de aprovacao/reprovacao da beta externa

A beta externa pode ser aprovada se:

```text
tester consegue abrir Web ou Windows sem bloqueio
tester entende como mudar Cliente/Prestador
Cliente consegue criar pedido
Prestador consegue aceitar/iniciar fluxo principal
orcamento/valor final funciona quando testado
mensagens funcionam no fluxo principal
Conta/Perfil nao bloqueia a navegacao
nao existe bug bloqueador
bugs medios/baixos ficam documentados
```

A beta externa deve reprovar se:

```text
app nao abre na plataforma entregue
tester nao consegue alternar Cliente/Prestador
Cliente nao consegue criar pedido
Prestador nao consegue aceitar/iniciar pedido
mensagens quebram o fluxo principal
valor final/orcamento bloqueia conclusao
ha crash em fluxo principal
ha erro visual que impede uso
ha bug evidente de seguranca/permissao
```

### 7. Limitacoes conhecidas

Documentar explicitamente:

```text
Android fisico real continua pendente da M2.6
pagamentos reais fora do escopo
Play Store fora do escopo
package id final fora do escopo
HTTPS App Links fora do escopo
deploy real depende de decisao explicita
smoke real em producao fora do escopo
cleanup real fora do escopo
health real fora do escopo
```

## Documentos Esperados

A M2.12 deve produzir:

```text
docs/M2_12_PACOTE_ENTREGA_BETA_STATUS.md
docs/BETA_TESTER_GUIA_RAPIDO.md
docs/BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
docs/BETA_TESTER_FEEDBACK_FORM.md
docs/BETA_TESTER_BUG_REPORT.md
```

## Fora do Escopo

```text
backend novo
Firestore Rules novas
Storage Rules novas
Cloud Functions novas
deploy real sem decisao explicita
smoke real
cleanup real
health real
pagamentos reais
Play Store
Android fisico real
fechar M2.6
novas funcionalidades grandes
```

## Validacoes

Para a criacao desta spec:

```cmd
git diff --check
```

Para fases de execucao da M2.12, quando houver build ou scripts:

```cmd
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter build windows --debug
```

Os comandos devem ser executados conforme o bloco implementado. Se algum build
nao for executado por limitacao local, isso deve ser documentado como bloqueio
ambiental, nao omitido.

## Criterios de Aceitacao da Spec

```text
spec criada
objetivo da M2.12 claro
documentos de entrega definidos
roteiro Cliente/Prestador definido
templates de feedback e bug definidos
criterios de aprovacao/reprovacao definidos
limitacoes conhecidas explicitas
M2.6 continua pendente de Android fisico real
sem alteracao de codigo
```

## Proxima Etapa

Depois desta spec ser revista, criar o plano de implementacao da M2.12 com
blocos curtos:

```text
1. Documentos do tester
2. Checklist e comandos de build
3. Geracao/validacao de builds Web e Windows
4. Status final e pacote de entrega
```
