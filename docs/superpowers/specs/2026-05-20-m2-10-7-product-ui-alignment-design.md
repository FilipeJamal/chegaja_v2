# M2.10.7 - Product UI Alignment

Data: 2026-05-20

## Contexto

A M2.10 ja melhorou a base visual do ChegaJa:

```text
M2.10.2: design system foundation
M2.10.3: Home Cliente redesign
M2.10.4: Home Prestador redesign
M2.10.5: pedido, listas e detalhe polish
M2.10.6: responsividade e QA visual
```

Depois da QA visual, ficou claro que a app saiu do prototipo cru, mas ainda
precisa de alinhar telas-chave ao modelo visual de produto real apresentado nas
referencias do utilizador.

As referencias visuais aprovadas apontam para:

```text
mobile premium
fundo claro
cards brancos com sombra suave
hierarquia tipografica forte
marca visivel no topo
avatar e notificacoes no header
bottom navigation elegante
azul como CTA principal
verde como sucesso/online
chips de estado compactos
listas densas mas arejadas
desktop com sidebar e dashboard leve
```

Esta fase nao deve copiar marcas externas. Deve adaptar os principios ao
ChegaJa.

## Problema

Mesmo com a M2.10 avancada, ainda ha superficies que podem parecer menos
premium ou incompletas quando comparadas com a direcao desejada:

```text
Mensagens ainda precisam parecer uma inbox real.
Pedidos precisam parecer uma area operacional forte, nao apenas lista.
Conta/Perfil precisa parecer produto acabado.
Navegacao global precisa ficar mais consistente entre mobile, Web e Windows.
O desktop precisa manter dashboard/sidebar, enquanto mobile deve parecer app nativa premium.
```

## Objetivo

Alinhar as telas principais restantes ao visual de produto real definido pelas
referencias:

```text
Mensagens
Pedidos
Conta/Perfil
navegacao global
header/avatar/notificacoes
cards/list items/chips/segmented controls
```

O objetivo e transformar o ChegaJa de "app funcional com UI melhorada" para
"produto visualmente consistente e pronto para beta visual".

## Direcao Visual

### Mobile

Mobile deve ser tratado como experiencia principal:

```text
header com logo ChegaJa, sino e avatar
titulo grande por tela
subtitulo curto e humano
search bar elevada com botao de filtro quando fizer sentido
cards altos, respirados, com avatar/foto quando houver pessoa
chips coloridos para status/servico
bottom navigation com icones grandes e label selecionada
safe area respeitada
sem elementos debug tapando navegacao
```

### Desktop/Web/Windows

Desktop nao deve ser mobile esticado:

```text
sidebar fixa ou rail lateral
conteudo central com largura util
cards/tabelas mais densos
colunas para resumo, atividade e detalhe
acoes principais alinhadas a direita
menos altura desperdicada
mais informacao escaneavel
```

### Cores e tom

```text
azul: acao principal, tabs selecionadas, links fortes
verde: online, sucesso, concluido, confirmacao
laranja/amarelo: orcamento, pendente, atencao leve
vermelho: erro, cancelado, acao destrutiva
roxo: uso pontual para categorias/variedade, nao dominante
cinza/azul escuro: texto, bordas e informacao secundaria
```

## Escopo

### 1. Navegacao Global

Alinhar a estrutura global com as referencias:

```text
App header com marca, notificacoes e avatar quando apropriado.
Bottom navigation mobile mais premium.
Navigation rail/sidebar desktop consistente.
Estados selecionados mais claros.
Espacamento e safe area revisados.
```

Nao criar novas rotas obrigatorias. Preservar fluxos existentes.

### 2. Mensagens

Redesenhar lista de conversas Cliente e Prestador:

```text
titulo grande "Mensagens"
subtitulo por role
search bar
botao de filtro visual, mesmo que inicialmente preserve comportamento simples
cards de conversa com avatar
online indicator
ultimo texto
hora/data
contador de nao lidas
chip de servico/status
estado vazio mais premium
```

Se a conversa aberta ja existir, alinhar visualmente apenas o que for seguro:

```text
header de conversa com avatar/nome/status
baloes mais refinados
input mais limpo
sem alterar modelo de chat
```

### 3. Pedidos

Redesenhar a experiencia de Pedidos para Cliente e Prestador:

```text
titulo grande "Pedidos"
segmented control/tabs com contadores quando os dados existirem
cards de pedido com avatar/prestador/cliente quando houver
servico, local, horario/ETA, valor e status em blocos claros
CTA principal "Abrir" ou "Ver detalhes"
Prestador: secao "Novos pedidos perto de ti", "Pedidos em curso", "Concluidos"
Cliente: ativos, agendados, concluidos/cancelados
```

Preservar keys e callbacks de aceitar, ignorar, abrir detalhe e orcamento.

### 4. Conta/Perfil

Dar aspeto de produto acabado:

```text
cartao de perfil com avatar, nome, role, online/status
metricas principais quando ja existirem
lista de definicoes com icones coloridos
acao de editar perfil clara
logout/destrutivo separado e visualmente controlado
```

Nao implementar KYC, pagamentos reais ou novas features. Apenas organizar e
apresentar melhor o que ja existe.

### 5. Componentes Reutilizaveis

Criar ou evoluir componentes visuais sem duplicar estilos:

```text
AppProductHeader
AppPremiumSearchBar
AppFilterButton
AppSegmentedTabs
AppAvatar
AppUnreadBadge
ConversationListCard
OrderOperationalCard
AccountProfileSummary
SettingsListTile
```

Estes nomes sao sugestivos; a implementacao deve seguir a estrutura real do
codigo.

## Fora do Escopo

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
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
mudancas de schema
mudancas de regra de negocio
```

## Guardrails

```text
Preservar keys existentes usadas por testes.
Preservar fluxos Cliente/Prestador.
Nao esconder acoes existentes.
Nao criar botoes falsos que prometem feature inexistente.
Nao usar imagens remotas obrigatorias para UI critica.
Nao introduzir paleta dominada por roxo.
Nao criar cards dentro de cards.
Nao deixar desktop como mobile esticado.
Nao quebrar Android/mobile por causa de layout desktop.
```

## Criterios de Aceitacao

```text
Spec define direcao visual baseada nas referencias aprovadas.
M2.10.7 fica focada em alinhamento visual/produto.
Mensagens, Pedidos, Conta e navegacao global entram no escopo.
Backend e producao continuam fora do escopo.
Proxima etapa deve ser plano de implementacao, nao codigo direto.
M2.10 nao fecha antes desta passada de alinhamento visual.
```

## Validacoes Esperadas Apos Implementacao

```text
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
qa visual com screenshots mobile/desktop das telas tocadas
```

## Commit Recomendado

```text
Iniciar M2.10.7 product UI alignment
```
