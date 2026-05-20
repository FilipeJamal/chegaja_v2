# M2.10 Visual Product System Status

Data: 2026-05-20

## Estado

```text
M2.9: fechado
M2.10: iniciado
M2.10.1: spec visual audit e design direction
M2.10.2: avancado com design system foundation
M2.10.3: avancado com Home Cliente redesign
M2.10.4: avancado com Home Prestador redesign
M2.10.5: avancado com Pedido, listas e detalhe polish
M2.10.6: avancado com responsividade e QA visual
M2.10.7: avancado com componentes globais UI, navegacao global, mensagens premium, pedidos premium e conta/perfil premium
```

## Objetivo da M2.10

Tirar o ChegaJa do aspeto de prototipo e criar uma experiencia visual mais
profissional, organizada e responsiva para Web, Windows e Android.

## M2.10.2

Escopo:

```text
tokens responsivos
AppContentShell
AppPageScaffold
AppSectionHeader
AppStatusPill
AppMetricTile
AppActionPanel
AppResponsiveGrid
testes de componentes
documentacao de uso
```

Fora do escopo:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 76/76 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

## M2.10.3

Escopo:

```text
Home Cliente recomposta com AppPageScaffold e AppContentShell
hero operacional com CTA principal
servicos em tiles responsivos
secao de servicos sem altura fixa baseada no viewport
painel lateral de pendencias, pedidos ativos e mensagens
loading, empty e erro mais humanos
desktop/Web/Windows com composicao de dashboard
mobile preservado em uma coluna direta
```

Componentes criados:

```text
ClienteHomeHero
ClienteServicesSection
ClienteServiceTile
ClienteHomeOperationsPanel
ClienteHomeMessagesPanel
ClienteHomeEmptyServices
```

Fora do escopo mantido:

```text
Home Prestador
detalhe/listas inteiras
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia M2.10.3

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 82/82 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

## M2.10.4

Escopo:

```text
Home Prestador recomposta como painel operacional
disponibilidade online/offline como comando principal
metricas com AppMetricTile
trabalho em destaque com AppActionPanel
categorias como painel operacional
pedidos disponiveis em cards responsivos
desktop/Web/Windows com composicao em coluna principal e lateral
mobile preservado em uma coluna direta
keys Aceitar/Ignorar/orcamento preservadas
```

Componentes criados:

```text
PrestadorAvailabilityPanel
PrestadorMetricStrip
PrestadorNextWorkPanel
PrestadorCategoriesPanel
PrestadorCategoriesChips
PrestadorAvailableOrdersSection
PrestadorAvailableOrderCard
```

Fora do escopo mantido:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia M2.10.4

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 90/90 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

## M2.10.5

Escopo:

```text
PedidoDetailLayout responsivo para detalhe do pedido
rail lateral com status, proxima acao, valor e acoes
PedidoValueSummary para valor, estimativa e confirmacao
PedidoStatusSummary e PedidoNextActionCard alinhados com AppActionPanel
PedidoTimeline mais compacta e premium
acoes Cliente/Prestador agrupadas em AppActionPanel
PedidoListCard alinhado com AppStatusPill
estados finais concluido/cancelado com status pill
loading/erro/not found mais humanos no detalhe
desktop/Web/Windows com duas colunas
mobile preservado em uma coluna limpa
keys Cliente/Prestador preservadas
```

Fora do escopo mantido:

```text
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia M2.10.5

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 102/102 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

## M2.10.6

Escopo:

```text
QA visual e responsividade Web/Windows/Android
matriz mobile/tablet/desktop/wide
Home Cliente e Home Prestador com screenshots controlados
fluxo E2E local de orcamento para lista/detalhe em desktop
banner de emulador sem tapar navegacao nem acoes
correcao pequena de loading na aba Meus trabalhos do Prestador
documentacao de problemas aceites para fase futura
```

Fora do escopo mantido:

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
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Evidencia M2.10.6

| Comando | Resultado |
| --- | --- |
| `flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true` | passou; avisos Wasm dry run de `dart_webrtc` sem bloquear build Web standard |
| `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:63776 --out-dir=%TEMP%\chegaja-m2106-visual-qa-final --wait-ms=12000` | passou; 8 screenshots finais |
| `npm.cmd run e2e:ui:orcamento` | passou contra Auth/Firestore/Storage emulators |
| `flutter test` | passou, 102/102 |
| `npm.cmd run test:scripts` | passou |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | passou, 37/37 |

## M2.10.7

Objetivo:

```text
Alinhar Mensagens, Pedidos, Conta/Perfil e navegacao global ao modelo visual
premium aprovado pelo utilizador: mobile app real, fundo claro, cards fortes,
avatar/header, chips de estado, bottom navigation elegante e desktop em formato
dashboard.
```

Referencias:

```text
mobile: telas de Mensagens, Pedidos e Conta com logo, avatar, sino,
search/filter, cards brancos, chips e CTAs azuis.
desktop: dashboard com sidebar, listas densas, tabelas/cards e areas de detalhe.
```

Fora do escopo mantido:

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
pagamentos
Play Store
package id final
HTTPS App Links
fechar M2.6
```

Plano aprovado para execucao:

```text
docs/superpowers/plans/2026-05-20-m2-10-7-product-ui-alignment.md
```

Ordem tecnica definida:

```text
componentes globais primeiro
navegacao global
Mensagens Cliente/Prestador
Pedidos Cliente/Prestador
Conta/Perfil Cliente/Prestador
responsividade e QA visual
```

Ficheiros-chave auditados:

```text
lib/core/widgets/app_shell_scaffold.dart
lib/core/widgets/app_content_shell.dart
lib/features/common/mensagens/mensagens_tab.dart
lib/features/common/mensagens/chat_thread_screen.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/prestador/widgets/prestador_home_components.dart
lib/features/cliente/cliente_perfil_screen.dart
lib/features/prestador/prestador_perfil_screen.dart
```

Decisao de implementacao:

```text
Nao redesenhar telas de forma isolada.
Criar primeiro os componentes globais reutilizaveis da UI de produto.
Aplicar depois em Mensagens, Pedidos e Conta/Perfil preservando fluxos e keys.
```

## M2.10.7 - Bloco 2 Componentes Globais

Componentes criados:

```text
AppAvatar
AppUnreadBadge
AppProductHeader
AppPremiumSearchBar
AppFilterButton
AppSegmentedTabs
```

Ficheiros criados:

```text
lib/core/widgets/app_avatar.dart
lib/core/widgets/app_unread_badge.dart
lib/core/widgets/app_product_header.dart
lib/core/widgets/app_premium_search_bar.dart
lib/core/widgets/app_filter_button.dart
lib/core/widgets/app_segmented_tabs.dart
test/core/widgets/app_product_ui_components_test.dart
```

Cobertura adicionada:

```text
fallback de avatar por inicial
indicador online no avatar
badge de nao lidas com contador
badge com limite visual 99+
search bar chamando onChanged
botao de filtro chamando onPressed
segmented tabs chamando onChanged
product header com titulo, subtitulo, notificacao e avatar
```

Validacao:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 110/110 |

Proximo bloco recomendado:

```text
M2.10.7 - Bloco 3: navegacao global
```

## M2.10.7 - Bloco 3 Navegacao Global

Melhorias feitas:

```text
AppShellScaffold manteve IndexedStack, selectedIndex e onDestinationSelected.
Mobile bottom navigation passou a ter container dedicado, sombra e safe area.
Mobile manteve labels sempre visiveis para reduzir ambiguidade.
Badge de destino passou a usar AppUnreadBadge em vez de Badge generico.
Desktop passou a ter sidebar/rail com fundo surface, borda e sombra leve.
Desktop passou a mostrar marca ChegaJa no topo do rail.
NavigationRail passou a mostrar labels para leitura mais clara em Web/Windows.
```

Ficheiros alterados:

```text
lib/core/widgets/app_shell_scaffold.dart
test/core/widgets/app_shell_scaffold_test.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Cobertura ajustada:

```text
mobile renderiza bottom navigation com chave dedicada
desktop renderiza sidebar/NavigationRail com marca ChegaJa
troca de aba preserva estado do child
badge aparece quando showBadge=true
testes verificam ausencia de overflow basico via takeException
```

Validacao:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 111/111 |

Proximo bloco recomendado:

```text
M2.10.7 - Bloco 4: Mensagens Cliente/Prestador
```

## M2.10.7 - Bloco 4 Mensagens Cliente/Prestador

Melhorias feitas:

```text
MensagensTab passou a usar AppContentShell e AppProductHeader.
Pesquisa passou a usar AppPremiumSearchBar.
Filtros passaram a usar AppFilterButton e AppSegmentedTabs.
Lista de conversas passou a usar ConversationListCard com avatar, badge,
servico, favorito e hierarquia visual de inbox.
Estados de loading, vazio, erro, filtro sem resultado e pesquisa sem resultado
ficaram em card visual consistente.
ChatThreadScreen recebeu AppAvatar no header, fundo claro, bolhas mais limpas,
separador de dia com token visual e input com borda/sombra suave.
```

Comportamento preservado:

```text
query/stream de chats
pesquisa existente
filtros todas/nao lidas/favoritas/grupos
abrir conversa por tap
favoritar/desfavoritar por long press
contador de nao lidas
ChatThreadScreen com envio de texto, anexos, media, audio e chamadas
ChatService sem alteracao
modelo de dados sem alteracao
```

Ficheiros alterados/criados:

```text
lib/features/common/mensagens/mensagens_tab.dart
lib/features/common/mensagens/chat_thread_screen.dart
lib/features/common/mensagens/widgets/conversation_list_card.dart
test/features/common/mensagens/conversation_list_card_test.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Cobertura adicionada:

```text
ConversationListCard renderiza nome e ultima mensagem
ConversationListCard renderiza badge de nao lidas
ConversationListCard chama onTap e onLongPress
ConversationListCard mostra favorito quando ativo
ConversationListCard funciona sem imagem remota
```

Validacao:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 116/116 |

Proximo bloco recomendado:

```text
M2.10.7 - Bloco 5: Pedidos Cliente/Prestador
```

## M2.10.7 - Bloco 5 Pedidos Cliente/Prestador

Melhorias feitas:

```text
Criado OrderOperationalCard como card operacional comum para pedidos.
PedidoListCard passou a compor OrderOperationalCard mantendo a API publica.
Aba Pedidos do Cliente passou a usar AppContentShell, AppProductHeader e
AppSegmentedTabs com contadores por estado.
Aba Pedidos do Prestador passou a usar AppContentShell, AppProductHeader e
AppSegmentedTabs com contadores por estado.
Listas Cliente/Prestador mantiveram mobile em uma coluna e desktop com largura
de dashboard.
Pedidos disponiveis do Prestador continuam a preservar as keys dinamicas de
Aceitar/Ignorar e os callbacks existentes.
```

Comportamento preservado:

```text
streams de pedidos Cliente/Prestador
abrir detalhe do pedido
PedidoChatPreview quando ja existia
acoes Cliente no detalhe: proposta, duvida e confirmacao de valor
acoes Prestador no detalhe: orcamento, iniciar servico e valor final
aceitar pedido disponivel
ignorar pedido disponivel
cancelar trabalho quando ja existia
services/repositories sem alteracao
schema/regras/functions sem alteracao
```

Keys preservadas:

```text
cliente_rejeitar_proposta_button
cliente_aceitar_proposta_button
cliente_duvida_valor_button
confirmar_valor_button
cliente_home_active_orders_panel
prestador_pedido_card_<pedidoId>
prestador_aceitar_pedido_<pedidoId>
prestador_ignorar_pedido_<pedidoId>
prestador_enviar_orcamento_button
prestador_iniciar_servico_button
valor_final_field
prestador_enviar_valor_final_button
prestador_lancar_valor_final_button
prestador_orcamento_dialog_later_button
prestador_orcamento_dialog_now_button
orcamento_min_field
orcamento_max_field
orcamento_msg_field
orcamento_enviar_button
prestador_home_available_orders_section
```

Ficheiros alterados/criados:

```text
lib/features/common/widgets/order_operational_card.dart
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
test/features/common/widgets/order_operational_card_test.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Cobertura adicionada:

```text
OrderOperationalCard renderiza titulo, servico e status
OrderOperationalCard renderiza CTA principal e chama callback
OrderOperationalCard renderiza acao secundaria
OrderOperationalCard funciona sem avatar ou imagem
OrderOperationalCard suporta valor, local e horario
```

Validacao:

| Comando | Resultado |
| --- | --- |
| `flutter test` | passou, 121/121 |

Proximo bloco recomendado:

```text
M2.10.7 - Bloco 6: Conta/Perfil Cliente/Prestador
```

## M2.10.7 - Bloco 6 Conta/Perfil Cliente/Prestador

Melhorias feitas:

```text
Criado AccountProfileSummary como cartao premium de perfil com avatar,
estado, CTA de editar perfil e metricas opcionais.
Criado SettingsListTile como item visual reutilizavel para definicoes.
Aba Conta do Cliente passou a usar AppContentShell, AppProductHeader,
AccountProfileSummary e SettingsListTile.
Aba Conta do Prestador passou a usar AppContentShell, AppProductHeader,
AccountProfileSummary e SettingsListTile.
Perfil editavel do Cliente passou a usar AccountProfileSummary no topo.
Perfil editavel do Prestador passou a usar AccountProfileSummary no topo com
metricas de raio e portfolio.
```

Comportamento preservado:

```text
navegacao para Perfil Cliente
navegacao para Perfil Prestador
selecao de Pais/Regiao do Cliente
selector de tema
suporte do Cliente
Backoffice Admin em ambiente/admin
pagamentos/configuracoes do Prestador quando ja existiam
upload/alteracao de foto nos perfis editaveis
guardar perfil Cliente/Prestador
autocomplete de pais/cidade/localizacao
portfolio do Prestador
services/repositories sem alteracao
schema/regras/functions sem alteracao
```

Ficheiros alterados/criados:

```text
lib/features/common/widgets/account_profile_summary.dart
lib/features/common/widgets/settings_list_tile.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
lib/features/cliente/cliente_perfil_screen.dart
lib/features/prestador/prestador_perfil_screen.dart
test/features/common/widgets/account_profile_components_test.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Cobertura adicionada:

```text
AccountProfileSummary renderiza nome e papel
AccountProfileSummary chama editar perfil
AccountProfileSummary mostra metrica quando fornecida
SettingsListTile renderiza titulo e subtitulo
SettingsListTile chama onTap
SettingsListTile suporta tom destrutivo
```

Validacao:

| Comando | Resultado |
| --- | --- |
| `flutter test test\features\common\widgets\account_profile_components_test.dart` | passou, 6/6 |
| `flutter test test\features\cliente\cliente_home_redesign_test.dart test\features\prestador\prestador_home_redesign_test.dart` | passou, 2/2 |
| `flutter test` | passou, 127/127 |

Proximo bloco recomendado:

```text
M2.10.7 - Bloco 7: Responsividade e QA visual final
```
