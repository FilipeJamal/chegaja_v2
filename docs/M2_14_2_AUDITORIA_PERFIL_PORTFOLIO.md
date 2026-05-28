# M2.14.2 - Auditoria Perfil, Portfolio e Confianca do Prestador

Data: 2026-05-28

## 1. Estado Executivo

```text
M2.14.1: concluida
M2.14.2: concluida como auditoria tecnica/produto
M2.14.3: proximo passo recomendado - melhorar perfil publico do prestador
Bloco F: ativo
Bloco R: pausado por falta de tester humano real
Bloco M: pausado por falta de Android fisico real
R1: nao fechado
M2.6: nao fechada
Tester externo: nao executado
Android fisico: nao executado
```

Conclusao curta:

```text
O ChegaJa ja tem base real para perfil publico, perfil editavel e portfolio do
prestador. A M2.14 nao deve recriar isto do zero. O proximo passo deve evoluir
PublicProfileScreen com layout premium, badges leves e testes, preservando os
fluxos atuais.
```

## 2. Mapa de Ficheiros Analisados

| Ficheiro | Responsabilidade | Estado | Risco | Acao recomendada |
| --- | --- | --- | --- | --- |
| `docs/M2_14_PERFIL_PORTFOLIO_PRESTADOR_SPEC.md` | Spec da M2.14 | Boa base; status inicial precisava atualizacao | Baixo | Atualizada para M2.14.1 concluida, M2.14.2 concluida e M2.14.3 proximo |
| `docs/ROADMAP_A_T_CHEGAJA.md` | Roadmap A-T oficial | M2.14 ja ativo; precisava passar M2.14.3 para proximo | Baixo | Atualizado |
| `docs/M2_13_BETA_EXTERNA_STATUS.md` | Status da beta externa/tester | R ja pausado corretamente | Baixo | Sem alteracao necessaria nesta auditoria |
| `docs/ANDROID_MOBILE_REAL_STATUS.md` | Status Android fisico/M2.6 | M ja pausado corretamente | Baixo | Sem alteracao necessaria nesta auditoria |
| `lib/features/common/perfil_publico_screen.dart` | Perfil publico Cliente/Prestador | Funcional, mas simples | Medio | Evoluir em M2.14.3 sem duplicar tela |
| `lib/features/prestador/prestador_perfil_screen.dart` | Perfil editavel do prestador | Funcional, com foto, localizacao, raio e portfolio | Medio | Melhorar UX do portfolio em M2.14.4 |
| `storage.rules` | Regras para ficheiros/imagens | Ja cobre portfolio publico com escrita dono/admin | Baixo | Nao alterar agora |
| `firestore.rules` | Regras para perfis prestadores | Leitura publica e update controlado ja existem | Baixo | Nao alterar agora |
| `lib/features/common/mensagens/chat_thread_screen.dart` | Chat e menu de conversa | Ja abre perfil do outro participante | Baixo | Preservar |
| `lib/features/cliente/selecionar_prestador_screen.dart` | Selecao/convite de prestador | Ja tem botao Ver perfil | Baixo | Preservar e melhorar visual depois |
| `lib/features/cliente/favoritos_screen.dart` | Lista de favoritos do Cliente | Ja abre perfil por tap no item | Baixo | Preservar |
| `lib/features/common/widgets/stories_carousel_widget.dart` | Stories/atalho de prestador | Ja abre perfil a partir de story | Baixo | Preservar |
| `test/features/common/widgets/account_profile_components_test.dart` | Testes de AccountProfileSummary | Existe, mas nao cobre perfil publico | Medio | Criar testes dedicados em M2.14.3 |

## 3. Perfil Publico Atual

Ficheiro:

```text
lib/features/common/perfil_publico_screen.dart
```

### Dados que le

`PublicProfileScreen` escolhe a colecao pelo papel:

```text
role == prestador -> prestadores/{userId}
outros roles      -> users/{userId}
```

Campos resolvidos:

| Area | Campos usados |
| --- | --- |
| Nome | `nome`, `displayName`, `name`, `initialName` |
| Foto | `photoUrl`, `fotoUrl`, `avatarUrl`, `initialPhotoUrl` |
| Bio | `bio`, `descricao` |
| Localizacao | `city`, `cidade`, `state`, `province`, `region`, `country`, `pais` |
| Contacto | `phoneE164`, `phoneNumber`, `phone`, `phoneRaw` |
| Servicos | `servicosNomes` |
| Portfolio | `portfolioUrls`, `portfolioImages` |

### O que mostra

```text
cabecalho simples com CircleAvatar e nome
bio quando existe
localizacao quando existe
telefone quando existe
chips de servicos quando existem
grid de portfolio quando existem imagens
```

### Foto

Pontos fortes:

```text
usa NetworkImage quando a URL e valida
usa inicial como fallback quando nao ha foto
aceita initialPhotoUrl para abrir rapido a tela com dados ja conhecidos
```

Limitacoes:

```text
nao ha composicao premium de header
nao ha badge "Foto adicionada"
nao ha estado visual forte para perfil sem foto
```

### Bio

Pontos fortes:

```text
le bio e descricao
so mostra secao se existir texto
```

Limitacoes:

```text
nao mostra estado vazio amigavel
nao limita/expande texto longo com intencao visual
nao cria hierarquia suficiente para perfil publico premium
```

### Localizacao

Pontos fortes:

```text
combina cidade, estado/regiao e pais
aceita nomes alternativos de campos
```

Limitacoes:

```text
nao mostra radiusKm/area atendida
nao diferencia "cidade do perfil" de "area de atendimento"
```

### Servicos

Pontos fortes:

```text
usa servicosNomes como chips
usa surfaceContainerHighest do tema
```

Limitacoes:

```text
nao mostra estado vazio
nao destaca categoria principal
nao usa icones visuais do catalogo expandido
```

### Portfolio

Pontos fortes:

```text
suporta portfolioUrls e portfolioImages legado
usa GridView 3 colunas
abre MediaViewerScreen no tap
tem errorBuilder para imagem quebrada
```

Limitacoes:

```text
nao tem estado vazio premium
nao tem loadingBuilder
nao limita visualmente grande quantidade de imagens
nao tem layout responsivo para desktop/tablet
nao tem legendas
nao tem contagem/indicador de quantidade
```

## 4. Perfil Editavel do Prestador

Ficheiro:

```text
lib/features/prestador/prestador_perfil_screen.dart
```

### Campos que permite editar

```text
nome
bio
cidade
pais
countryCode
radiusKm
photoUrl
portfolioUrls
```

### Como guarda no Firestore

Usa:

```text
prestadores/{uid}
doc.set(..., SetOptions(merge: true))
updatedAt: FieldValue.serverTimestamp()
```

Campos guardados:

```text
nome
bio
city
country
countryCode
radiusKm
photoUrl
portfolioUrls
updatedAt
```

### Upload da foto

Fluxo atual:

```text
ImagePicker.pickImage(source: gallery, imageQuality: 85)
Storage path: prestadores/{uid}/profile_{timestamp}.jpg
contentType: image/jpeg
doc.set({ photoUrl, updatedAt }, merge: true)
```

Pontos fortes:

```text
usa path por prestador
nao depende de backend novo
salva URL no perfil
```

Limitacoes:

```text
nao ha etapa de crop/preview
nao ha orientacao visual clara de formato ideal
nao ha tratamento granular para permissao negada no picker nativo
```

### Upload do portfolio

Fluxo atual:

```text
ImagePicker.pickMultiImage(imageQuality: 85)
Storage path: prestadores/{uid}/portfolio/item_{timestamp}_{x.name}.jpg
doc.set({ portfolioUrls, updatedAt }, merge: true)
```

Pontos fortes:

```text
suporta multiplas imagens
usa caminho correto em prestadores/{uid}/portfolio
abre imagens em tela cheia
tem estado vazio simples
tem loading/error por imagem
remove item e tenta apagar do Storage
```

Limitacoes:

```text
remocao nao pede confirmacao
nao ha limite visual/contagem explicita
nao ha aviso de tamanho/quantidade
nao ha reordenacao
nao ha legenda
nao ha teste dedicado
```

### Pais/cidade

Pontos fortes:

```text
usa LocationDataService
usa country_state_city
tem autocomplete para pais e cidade
salva countryCode
usa UserCountryService quando pais e definido
```

Limitacoes:

```text
ha textos com mojibake/encoding em alguns literais ja existentes
autocomplete pode precisar de QA visual em mobile/desktop
```

### Raio

Pontos fortes:

```text
radiusKm existe
slider de 1 a 50 km
metric card mostra raio no resumo
```

Limitacoes:

```text
perfil publico ainda nao usa radiusKm para explicar area atendida
```

## 5. Storage e Firestore

### Storage

Caminhos relevantes:

```text
prestadores/{prestadorId}/{fileName}
prestadores/{prestadorId}/portfolio/{fileName}
portfolio/{userId}/{fileName}
```

Regras confirmadas:

```text
leitura publica permitida para portfolio e imagens de prestador
create/update apenas se auth.uid == prestadorId ou admin
delete apenas se auth.uid == prestadorId ou admin
validImageUpload com limite de 10 MB
```

Decisao:

```text
Nao alterar Storage Rules agora.
As regras atuais sao suficientes para a M2.14.3/M2.14.4, desde que a UI
continue a usar prestadores/{uid}/portfolio/... e nao crie novos caminhos.
```

### Firestore

Regras confirmadas:

```text
prestadores/{prestadorId}
  read: true
  create: proprio prestador ou admin
  update: admin, proprio prestador sem auto-editar rating aggregates,
          ou outros utilizadores apenas para ratingCount/ratingSum/ratingAvg/updatedAt
```

Decisao:

```text
Nao alterar Firestore Rules agora.
Badges leves devem ser calculados a partir dos campos existentes.
Se uma fase futura criar campo novo, deve vir com teste de Rules especifico.
```

## 6. Pontos de Abertura do Perfil

| Ponto | Estado | Evidencia | Observacao |
| --- | --- | --- | --- |
| Chat | FEITO | `chat_thread_screen.dart` abre `_openProfile()` via menu `perfil` | Preservar |
| Selecao de prestador | FEITO | `selecionar_prestador_screen.dart` tem botao `Ver perfil` | Bom ponto para validar o novo perfil |
| Favoritos | FEITO | `favoritos_screen.dart` abre `PublicProfileScreen` no tap do item | Preservar |
| Stories | FEITO | `stories_carousel_widget.dart` abre perfil do prestador do story | Preservar |
| Detalhe do pedido Cliente | FALTA/PARCIAL | Nao foi encontrado `PublicProfileScreen` no detalhe | Recomendar integracao em M2.14.6 |
| Detalhe do pedido Prestador | NAO APLICAVEL/PARCIAL | Prestador normalmente precisa ver Cliente, nao prestador | Auditar depois se deve abrir perfil Cliente |
| Cards/listas de pedido | FALTA/PARCIAL | Nao foi encontrado atalho direto de perfil nos cards | Recomendar apenas quando houver prestador associado |
| PedidoChatPreview | PARCIAL | Busca perfil/foto do outro user, mas nao abre perfil publico | Pode ganhar atalho em fase futura se fizer sentido |

## 7. Badges Leves Possiveis

| Badge | Dados necessarios | Dados existem? | Risco | Recomendacao |
| --- | --- | --- | --- | --- |
| Perfil ativo | nome + pelo menos um de bio/foto/servicos/localizacao | Sim, com campos atuais | Baixo | Pode ser calculado localmente |
| Prestador disponivel | estado online/disponibilidade real | Parcial, depende de dados de disponibilidade fora desta auditoria | Medio | So mostrar se houver campo real confirmado na M2.14.3 |
| Portfolio adicionado | `portfolioUrls` ou `portfolioImages` nao vazio | Sim | Baixo | Pode ser calculado |
| Servicos concluidos | contagem real de pedidos concluidos | Parcial/incerto | Medio | So mostrar se dado real existir; nao inventar numero |
| Area definida | `city`/`country` e/ou `radiusKm` | Sim | Baixo | Pode ser calculado |
| Foto adicionada | `photoUrl`/`fotoUrl`/`avatarUrl` valido | Sim | Baixo | Pode ser calculado |

Badges recomendados para M2.14.3:

```text
Foto adicionada
Area definida
Portfolio adicionado
Perfil ativo
```

Badges a adiar ate confirmacao de dados:

```text
Prestador disponivel
Servicos concluidos
```

## 8. Badges Proibidos

Continuam proibidos nesta fase:

```text
Identidade verificada
Documento verificado
Prestador certificado
Pagamento seguro
Profissional aprovado oficialmente
```

Motivo:

```text
A app ainda nao tem KYC real, validacao documental, moderacao oficial,
pagamentos reais ou processo formal de certificacao.
```

## 9. Testes Existentes e Testes em Falta

| Teste | Existe? | Ficheiro | Recomendacao |
| --- | --- | --- | --- |
| AccountProfileSummary renderiza nome/role/metrica | Sim | `test/features/common/widgets/account_profile_components_test.dart` | Preservar |
| PublicProfileScreen renderiza nome/foto/bio/localizacao | Nao encontrado | - | Criar em M2.14.3 |
| PublicProfileScreen renderiza portfolio vazio | Nao encontrado | - | Criar em M2.14.3 |
| PublicProfileScreen renderiza portfolio com imagens | Nao encontrado | - | Criar em M2.14.3 |
| PublicProfileScreen mostra badges permitidos | Nao encontrado | - | Criar quando badges forem implementados |
| PublicProfileScreen impede badges proibidos | Nao encontrado | - | Criar quando badges forem implementados |
| PublicProfileScreen dark mode | Nao encontrado | - | Criar em M2.14.3 ou M2.14.7 |
| Perfil editavel mostra portfolio vazio | Nao encontrado | - | Criar em M2.14.4 |
| Perfil editavel confirma remocao de imagem | Nao existe feature/teste | - | Criar em M2.14.4 se a feature entrar |
| Abertura de perfil a partir do chat | Nao encontrado como widget test | - | Avaliar custo; talvez cobrir com smoke/widget isolado |
| Abertura de perfil a partir da selecao de prestador | Nao encontrado como widget test | - | Criar se houver harness simples |
| Abertura de perfil a partir de favoritos | Nao encontrado como widget test | - | Criar se houver harness simples |

## 10. Riscos Tecnicos

```text
1. Imagens quebradas ou URLs antigos no portfolio.
2. Perfil publico sem dados suficientes parecer vazio/fraco.
3. Badges transmitirem confianca acima do que a app prova.
4. Portfolio com muitas imagens deixar a tela pesada.
5. Dark mode voltar a ficar ilegivel em areas novas.
6. Layout mobile quebrar por nome/bio/servicos longos.
7. Telefone/contacto ficar exposto sem contexto claro.
8. Alterar Firestore/Storage Rules sem necessidade real.
9. Criar uma tela nova duplicada em vez de evoluir PublicProfileScreen.
10. Confundir progresso da M2.14 com fecho indevido de R, M ou M2.6.
```

Mitigacoes:

```text
usar dados reais e campos existentes
badges leves e factuais
limitar/renderizar portfolio de forma responsiva
testar dark mode desde M2.14.3
nao alterar rules sem teste RED claro
reaproveitar PublicProfileScreen
manter R/M explicitamente pausados
```

## 11. Plano Recomendado para M2.14.3

Fase:

```text
M2.14.3 - Melhorar perfil publico do prestador
```

Objetivo:

```text
Evoluir PublicProfileScreen para uma pagina publica premium do prestador,
sem criar tela duplicada e sem alterar Firestore/Storage Rules.
```

Ficheiros provaveis:

```text
lib/features/common/perfil_publico_screen.dart
test/features/common/perfil_publico_screen_test.dart
docs/M2_14_PERFIL_PORTFOLIO_PRESTADOR_SPEC.md
docs/ROADMAP_A_T_CHEGAJA.md
docs/M2_14_2_AUDITORIA_PERFIL_PORTFOLIO.md
```

Componentes a considerar:

```text
ProviderPublicProfileHeader
ProviderTrustBadgeStrip
ProviderPortfolioPreviewGrid
ProviderServiceChips
ProviderServiceAreaCard
```

Campos a reaproveitar:

```text
nome/displayName/name
photoUrl/fotoUrl/avatarUrl
bio/descricao
city/cidade
state/province/region
country/pais
servicosNomes
portfolioUrls/portfolioImages
radiusKm
ratingAvg/ratingCount apenas se houver cuidado de copy
```

Badges iniciais recomendados:

```text
Foto adicionada
Area definida
Portfolio adicionado
Perfil ativo
```

Testes a criar:

```text
PublicProfileScreen renderiza dados principais do prestador.
PublicProfileScreen mostra estado vazio de portfolio.
PublicProfileScreen mostra portfolio com imagens.
PublicProfileScreen mostra badges leves permitidos.
PublicProfileScreen nao mostra badges proibidos.
PublicProfileScreen usa contraste adequado em dark mode.
```

Fora do escopo da M2.14.3:

```text
gestao de portfolio no perfil editavel
reordenacao/legendas de portfolio
KYC
reviews completas
pagamentos
rules
functions
deploy
Android fisico
tester externo
```

Criterios de conclusao da M2.14.3:

```text
perfil publico visualmente mais forte
sem duplicar tela
sem fields/rules novos
testes de PublicProfileScreen criados
dark mode validado por teste ou screenshot local
flutter test --no-pub passando
npm.cmd run test:scripts passando
roadmap/status atualizado
```

## 12. Criterio de Saida da M2.14.2

```text
Auditoria criada: sim
Spec/roadmap coerentes: sim
R continua pausado: sim
M continua pausado: sim
M2.14.3 definido: sim
Feature grande implementada: nao
Flutter code alterado: nao
Rules/Functions alteradas: nao
Deploy executado: nao
```
