# M2.14 - Perfil, Portfolio e Confianca do Prestador

Data: 2026-05-28

## Estado

```text
M2.14: bloco ativo
M2.14.1: concluida
M2.14.2: auditoria concluida
M2.14.3: concluida - perfil publico do prestador melhorado
M2.14.4: proximo passo - melhorar gestao do portfolio no perfil do prestador
Bloco F: ativo
Bloco R: pausado por falta de tester humano real
Bloco M: pausado por falta de Android fisico real
M2.6: continua pendente de Android fisico
R1: continua pendente de entrega real a tester humano
```

## Decisao de Roadmap

R e M nao devem bloquear o desenvolvimento do produto, mas tambem nao devem ser
fechados sem prova real.

```text
R - Beta externa/tester real:
Estado: pausado/pendente
Motivo: falta de tester humano real

M - Android release/dispositivo fisico:
Estado: pausado/pendente
Motivo: falta de dispositivo Android fisico real

Proximo bloco ativo:
M2.14 - Perfil, portfolio e confianca do prestador
```

## Objetivo

Transformar o perfil do prestador numa peca real de confianca para o Cliente.
O Cliente deve conseguir entender rapidamente:

```text
quem e o prestador
o que faz
onde atende
se tem portfolio
se parece ativo
se tem historico operacional suficiente
se vale a pena contactar, convidar ou aceitar uma proposta
```

Esta fase nao cria KYC real nem reputacao publica completa. Ela consolida a
base existente e prepara a experiencia para a beta externa futura.

## Base Atual Confirmada

### Perfil Publico

Ficheiro:

```text
lib/features/common/perfil_publico_screen.dart
```

Estado atual:

```text
Ja existe PublicProfileScreen.
Le prestadores/{userId} quando role == prestador.
Le users/{userId} quando role != prestador.
Resolve nome, foto, bio/descricao, cidade, estado/regiao, pais, telefone,
servicos e portfolio.
Mostra portfolioUrls e portfolioImages quando existem.
Abre imagens de portfolio com MediaViewerScreen.
```

Limitacoes atuais:

```text
Layout ainda e simples, em formato de ficha.
Nao ha cartao forte de confianca.
Nao ha badges leves.
Nao ha estado vazio premium para portfolio.
Nao ha composicao rica para desktop/tablet.
Nao ha metricas de confianca bem explicadas.
Nao ha teste dedicado ao perfil publico.
```

### Perfil/Editavel do Prestador

Ficheiro:

```text
lib/features/prestador/prestador_perfil_screen.dart
```

Estado atual:

```text
Permite editar nome, bio, cidade, pais, raio, foto e portfolioUrls.
Usa Firebase Auth, Firestore, Storage e ImagePicker.
Upload da foto vai para prestadores/{uid}/profile_*.jpg.
Upload do portfolio vai para prestadores/{uid}/portfolio/item_*.jpg.
Remove imagem do portfolio e tenta apagar o ficheiro no Storage.
Mostra resumo com AccountProfileSummary.
Mostra metricas simples de raio e numero de imagens no portfolio.
Abre imagens do portfolio em MediaViewerScreen.
```

Limitacoes atuais:

```text
Gestao de portfolio ainda e basica.
Nao ha ordenacao/reordenacao.
Nao ha limite visual claro.
Nao ha legendas.
Nao ha validacao visual de tamanho/quantidade para o utilizador.
Nao ha fluxo de preview/confirmacao antes de remover.
Alguns textos ainda podem precisar de polimento/localizacao.
```

### Storage

Ficheiro:

```text
storage.rules
```

Estado atual:

```text
prestadores/{prestadorId}/portfolio/{fileName}
  read: publico
  create/update: apenas dono ou admin
  delete: apenas dono ou admin
  validImageUpload ate 10 MB

prestadores/{prestadorId}/{fileName}
  read: publico
  create/update/delete: dono ou admin com validacao de imagem
```

Decisao:

```text
Nao alterar Storage Rules na M2.14.1.
So alterar rules numa fase futura se uma validacao tecnica concreta provar
necessidade.
```

### Firestore

Ficheiro:

```text
firestore.rules
```

Estado atual:

```text
prestadores/{prestadorId}
  read: publico
  create: proprio prestador ou admin
  update: proprio prestador, admin, ou outros utilizadores apenas para agregados
          de avaliacao permitidos
  delete: admin/dev
```

Decisao:

```text
Nao alterar Firestore Rules na M2.14.1.
Evitar novos campos sensiveis.
Badges leves devem ser calculados do documento existente sempre que possivel.
```

### Pontos de Abertura do Perfil

Ja existem integracoes:

```text
lib/features/common/mensagens/chat_thread_screen.dart
  abre PublicProfileScreen para o outro participante do chat.

lib/features/cliente/selecionar_prestador_screen.dart
  possui botao "Ver perfil" no card de prestador.

lib/features/cliente/favoritos_screen.dart
  abre PublicProfileScreen para prestadores favoritos.
```

Pontos a auditar nas proximas subfases:

```text
detalhe do pedido Cliente quando ha prestador atribuido
detalhe do pedido Prestador quando precisa ver perfil do Cliente
PedidoChatPreview ou cards de conversa, se fizer sentido
cards/listas onde aparece prestador sem atalho para perfil
```

## Campos Atuais a Reaproveitar

| Campo | Origem | Uso recomendado |
| --- | --- | --- |
| `nome`, `displayName`, `name` | prestadores/users | Nome principal |
| `photoUrl`, `fotoUrl`, `avatarUrl` | prestadores/users | Avatar/foto |
| `bio`, `descricao` | prestadores | Texto "Sobre" |
| `city`, `cidade` | prestadores/users | Localizacao |
| `state`, `province`, `region` | prestadores/users | Localizacao secundaria |
| `country`, `pais` | prestadores/users | Pais |
| `countryCode` | prestadores | Persistencia de pais |
| `phoneE164`, `phoneNumber`, `phone`, `phoneRaw` | prestadores/users | Contacto, quando permitido |
| `servicosNomes` | prestadores | Chips de servicos |
| `portfolioUrls` | prestadores | Portfolio atual |
| `portfolioImages` | prestadores/users legado | Portfolio legado/fallback |
| `radiusKm` | prestadores | Area/raio de atendimento |
| `ratingCount`, `ratingSum`, `ratingAvg` | prestadores | Preparado para reputacao futura; usar com cuidado |
| `updatedAt`, `createdAt` | prestadores | Atividade/antiguidade, se existir |

## Campos Novos Seguros

Na primeira implementacao da M2.14, preferir nao criar campos novos. Quando
necessario, os seguintes campos sao seguros porque nao prometem verificacao
oficial:

```text
portfolioUpdatedAt
profileCompletedAt
serviceAreaLabel
portfolioCaptions
```

Campos que nao devem ser criados nesta fase:

```text
identityVerified
documentVerified
certifiedProvider
paymentVerified
officiallyApproved
```

## Perfil Publico Desejado

O perfil publico do prestador deve evoluir para uma pagina com:

```text
1. Header premium:
   - avatar/foto
   - nome
   - categoria ou papel
   - cidade/pais
   - status leve, se houver dado seguro

2. Cartao de confianca:
   - Perfil ativo
   - Prestador disponivel
   - Portfolio adicionado
   - Area definida
   - Foto adicionada
   - Servicos concluidos, se houver dado real

3. Sobre:
   - bio/descricao
   - texto vazio amigavel quando nao existe bio

4. Servicos:
   - chips por servicos/categorias
   - estado vazio se nao houver servicos

5. Area atendida:
   - cidade/pais
   - raio de atendimento quando existir

6. Portfolio:
   - grid responsiva
   - estado vazio premium
   - preview em tela cheia
   - loading/error de imagem com visual limpo
   - limite visual para nao deixar a pagina pesada

7. Acoes contextuais:
   - voltar ao pedido/chat quando aplicavel
   - contactar apenas quando ja existir fluxo seguro
```

## Gestao de Portfolio Desejada

No perfil editavel do prestador:

```text
1. Mostrar estado vazio mais forte.
2. Mostrar limite/quantidade de imagens.
3. Permitir preview antes/depois de adicionar.
4. Confirmar remocao de imagem.
5. Tratar erro de upload com mensagem humana.
6. Evitar que a grelha quebre em mobile.
7. Evitar que imagens grandes deixem a UI lenta.
8. Manter upload atual via ImagePicker + Firebase Storage.
```

Fora da primeira evolucao:

```text
reordenacao manual
legendas ricas
video
compressao avancada propria
moderacao automatica
```

## Badges Leves Permitidos

Estes badges podem aparecer porque sao inferidos de dados locais e nao prometem
verificacao oficial:

```text
Perfil ativo
Prestador disponivel
Portfolio adicionado
Servicos concluidos
Area definida
Foto adicionada
```

Regras:

```text
"Perfil ativo" pode depender de nome/bio/foto/servicos minimos.
"Prestador disponivel" so pode aparecer se houver dado real de disponibilidade.
"Portfolio adicionado" depende de portfolioUrls/portfolioImages nao vazio.
"Servicos concluidos" so pode aparecer se houver contagem real.
"Area definida" depende de cidade/pais/radiusKm.
"Foto adicionada" depende de photoUrl/fotoUrl/avatarUrl valido.
```

## Badges Proibidos

Nao usar estes textos nesta fase:

```text
Identidade verificada
Documento verificado
Prestador certificado
Pagamento seguro
Profissional aprovado oficialmente
```

Motivo:

```text
Eles indicam validacao oficial, KYC, moderacao ou pagamento real que ainda nao
existem como produto fechado.
```

## Integracao no Fluxo Cliente

O Cliente deve conseguir abrir o perfil do prestador em:

```text
selecao/convite de prestador
chat com prestador
favoritos
detalhe do pedido quando prestador ja existe
cards de pedido/listas quando fizer sentido
```

As integracoes existentes devem ser preservadas. Novas integracoes devem usar
`PublicProfileScreen` em vez de criar uma tela duplicada.

## Subfases M2.14

```text
M2.14.1 - Spec perfil e portfolio do prestador
M2.14.2 - Auditoria da base atual de perfil/portfolio
M2.14.3 - Concluida: melhorar perfil publico do prestador
M2.14.4 - Proximo passo: melhorar gestao do portfolio no perfil do prestador
M2.14.5 - Criar cartao de confianca e badges leves
M2.14.6 - Integrar perfil publico em pontos importantes do fluxo Cliente
M2.14.7 - Testes, QA visual e documentacao
```

## Testes Necessarios

### Widget/Unit

```text
PublicProfileScreen renderiza nome/foto/bio/localizacao/servicos/portfolio. Criado em test/features/common/perfil_publico_screen_test.dart.
PublicProfileScreen mostra estado vazio de portfolio. Criado em test/features/common/perfil_publico_screen_test.dart.
PublicProfileScreen mostra badges leves corretos. Criado em test/features/common/perfil_publico_screen_test.dart.
PublicProfileScreen nao mostra badges proibidos. Criado em test/features/common/perfil_publico_screen_test.dart.
Portfolio grid funciona sem imagem valida. Criado em test/features/common/perfil_publico_screen_test.dart.
PrestadorPerfilScreen mostra portfolio vazio.
PrestadorPerfilScreen confirma remocao de imagem, se implementado.
```

### Regressao Visual

```text
dark mode do perfil publico
dark mode do perfil editavel
mobile 390x844
tablet 768x1024
desktop 1366x768
wide 1920x1080
portfolio com 0, 1, 3, 8+ imagens
bio longa
servicos longos
nome longo
```

### Fluxo

```text
Cliente abre perfil a partir de selecao de prestador.
Cliente abre perfil a partir do chat.
Cliente abre perfil a partir de favoritos.
Cliente abre perfil a partir do detalhe do pedido, se a integracao for criada.
Prestador adiciona/remove imagem de portfolio, se testavel sem Android fisico.
```

## Acessibilidade e Responsividade

Requisitos:

```text
Textos com contraste adequado em light/dark mode.
Cards sem overflow em mobile.
Grid de portfolio responsiva.
Botoes com area de toque confortavel.
Estados vazios com linguagem humana.
Imagens com fallback visual quando falham.
Conteudo scrollavel sem bottom nav tapada.
```

## Fora do Escopo da M2.14

```text
KYC real
verificacao documental
pagamentos reais
Stripe/MB WAY
Play Store
Android fisico
tester externo
reviews publicas completas
moderacao completa
denuncias completas
deploy real
Cloud Functions novas sem necessidade
alteracao grande de Firestore Rules sem motivo tecnico comprovado
fechar R
fechar M
fechar M2.6
```

## Riscos

```text
1. Prometer confianca demais sem KYC real.
2. Introduzir campos novos sem Rules/testes suficientes.
3. Tornar o perfil publico pesado com muitas imagens.
4. Quebrar dark mode em telas que acabaram de ser corrigidas.
5. Duplicar tela em vez de evoluir PublicProfileScreen.
6. Fechar R ou M indevidamente por progresso em M2.14.
```

Mitigacao:

```text
usar badges leves e factuais
preferir campos existentes
criar componentes puros testaveis
validar dark mode desde o primeiro bloco de UI
reaproveitar PublicProfileScreen e PrestadorPerfilScreen
manter R/M explicitamente pausados
```

## Criterios de Aceitacao da M2.14

A M2.14 so deve ser considerada concluida quando:

```text
1. Perfil publico do prestador parecer uma pagina de produto real.
2. Portfolio visual tiver grid, vazio, erro e preview consistentes.
3. Badges leves existirem sem prometer KYC/verificacao oficial.
4. Cliente conseguir abrir perfil em pontos principais do fluxo.
5. Dark mode e responsividade forem validados.
6. Testes relevantes passarem.
7. Roadmap continuar com R e M pausados ate dependencias reais existirem.
```

## Criterio de Conclusao da M2.14.1

```text
Spec criada.
Roadmap atualizado com M2.14 como bloco ativo.
R documentado como pausado por falta de tester humano.
M documentado como pausado por falta de Android fisico.
Nenhum codigo Flutter alterado.
Nenhuma Rule/Function alterada.
Validacoes documentais executadas.
Commit e push realizados.
```
