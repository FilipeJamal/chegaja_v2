# M2.13 - Beta Externa / Tester Real

Data: 2026-05-23

## Contexto

A M2.12 avancou o Bloco Q do roadmap A-T e preparou o pacote de entrega beta Web/Windows para tester real.

Commit base:

```text
6239f70 Avancar M2.12 pacote entrega beta
```

Estado herdado:

```text
M2.10: fechada como Visual Product System
M2.11: fechada como beta interna Web/Windows
M2.12: pacote de entrega beta Web/Windows preparado
M2.6: continua pendente de Android fisico real
```

Pacote local preparado:

```text
C:\Users\Jamal\Downloads\ChegaJa_Beta_M2_12
```

Conteudo do pacote:

```text
web_beta_debug
windows_beta_debug
BETA_TESTER_GUIA_RAPIDO.md
BETA_TESTER_ROTEIRO_SIMPLIFICADO.md
BETA_TESTER_FEEDBACK_FORM.md
BETA_TESTER_BUG_REPORT.md
BETA_TESTER_CHECKLIST_ENTREGA.md
BETA_TESTER_BUILD_INSTRUCTIONS.md
BETA_TESTER_MANIFEST_ENTREGA.md
```

## Ligacao ao Roadmap A-T

Esta fase corresponde ao Bloco R:

```text
R - Beta externa / tester real
```

Subfases:

```text
R1 - Entregar app ao tester
R2 - Tester executa roteiro
R3 - Recolher bugs reais
R4 - Classificar bugs
R5 - Corrigir bloqueadores
R6 - Decidir se beta externa passa
```

## Objetivo

Executar uma beta externa controlada com uma pessoa real a testar o ChegaJa em Web/Windows, usando o pacote M2.12, e transformar o feedback em decisoes objetivas de aprovacao, reprovacao ou correcao.

## Principio da Fase

A M2.13 nao e uma fase de novas funcionalidades.

O objetivo e observar uso real:

```text
abrir app
entender guia
executar roteiro
usar Cliente e Prestador
testar pedidos, mensagens e conta
reportar bugs com evidencia
classificar problemas
decidir o proximo passo com base em dados reais
```

## Escopo

### 1. Preparar entrega ao tester

Definir e documentar:

```text
quem vai testar
qual plataforma vai testar primeiro: Web, Windows ou ambas
como vai receber o pacote
qual roteiro deve executar
como deve devolver feedback e bugs
prazo esperado da primeira rodada
```

### 2. Entregar pacote

Entregar ao tester:

```text
guia rapido
roteiro simplificado
template de feedback
template de bug
build Web ou Windows
lista de limitacoes conhecidas
```

### 3. Acompanhar execucao do roteiro

O tester deve cobrir:

```text
abrir app
trocar entre Cliente e Prestador pela UI
criar pedido
prestador aceitar/iniciar pedido
orcamento/valor final quando aplicavel
mensagens/chat
conta/perfil
cancelamento ou no-show quando aplicavel
percecao visual geral
```

### 4. Recolher bugs reais

Cada bug deve conter:

```text
papel usado: Cliente ou Prestador
plataforma: Web ou Windows
passos executados
resultado esperado
resultado obtido
severidade
frequencia
screenshot/video quando possivel
```

### 5. Classificar resultados

Classificar cada item como:

```text
bloqueador
alto
medio
baixo
observacao
melhoria futura
```

### 6. Decidir aprovacao/reprovacao

A beta externa pode passar se:

```text
tester consegue abrir a app
tester entende como usar Cliente/Prestador
fluxo principal Cliente/Prestador passa sem bloqueio
mensagens funcionam no uso real
pedido/orcamento/valor final funcionam no uso real
nao ha bug bloqueador
bugs medios/baixos ficam documentados
```

A beta externa reprova se:

```text
tester nao consegue abrir a app
tester nao consegue criar pedido
prestador nao consegue aceitar/iniciar pedido
mensagens impedem fluxo principal
troca Cliente/Prestador nao funciona
crash ou erro visual impede uso
ha bug de permissao/seguranca evidente
```

## Fora do Escopo

```text
backend novo
Firestore Rules novas sem bug real comprovado
Storage Rules novas
Cloud Functions novas
deploy real
smoke real
cleanup real
health real
Android fisico real
pagamentos reais
Play Store
package id final
HTTPS App Links
fechar M2.6
novas funcionalidades grandes
redesign visual amplo
```

## Artefatos Esperados

```text
docs/M2_13_BETA_EXTERNA_STATUS.md
docs/BETA_EXTERNA_REGISTO_ENTREGA.md
docs/BETA_EXTERNA_BUGS_REPORTADOS.md
docs/BETA_EXTERNA_DECISAO.md
```

## Validacoes

Antes de entregar novo pacote ao tester:

```text
git diff --check
```

Se qualquer codigo for alterado para corrigir bug:

```text
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Se a correcao tocar fluxos Web:

```text
npm.cmd run e2e:ui:dual
npm.cmd run e2e:ui:orcamento
```

Se a correcao tocar build:

```text
flutter build web --debug --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter build windows --debug
```

## Criterios de Aceitacao desta Spec

```text
Bloco R iniciado oficialmente
objetivo da beta externa definido
escopo e fora do escopo claros
criterios de aprovacao/reprovacao definidos
artefatos de acompanhamento definidos
M2.6 permanece explicitamente pendente de Android fisico real
```
