# M2.10.7 Product UI Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Alinhar navegacao global, Mensagens, Pedidos e Conta/Perfil ao modelo visual premium aprovado para o ChegaJa, mantendo os fluxos atuais e sem tocar em backend ou producao.

**Architecture:** Primeiro criar componentes globais reutilizaveis sobre a foundation da M2.10.2, depois aplicar esses componentes nas superficies principais. A implementacao deve preservar `AppShellScaffold`, `AppContentShell`, `AppPageScaffold`, `AppStatusPill`, `AppActionPanel`, `AppMetricTile`, callbacks existentes e keys de testes. Alteracoes de dados, regras, services e Functions ficam fora do escopo.

**Tech Stack:** Flutter/Dart, Material 3, Firebase emulators apenas para testes, `flutter_test`, Playwright QA visual local, `AppShellScaffold`, `AppPageScaffold`, `AppContentShell`, `AppCard`, `AppButton`, `AppStatusPill`, `AppResponsiveGrid`.

---

## Contexto

Spec aprovada:

```txt
docs/superpowers/specs/2026-05-20-m2-10-7-product-ui-alignment-design.md
```

Commit base:

```txt
4cabfd5 Iniciar M2.10.7 product UI alignment
```

Estado visual anterior:

```txt
M2.10.2: design system foundation
M2.10.3: Home Cliente redesign
M2.10.4: Home Prestador redesign
M2.10.5: Pedido, listas e detalhe polish
M2.10.6: responsividade e QA visual
```

Referencia aprovada pelo utilizador:

```txt
mobile premium com logo ChegaJa, sino, avatar, titulo grande, subtitulo curto,
search bar elevada, filtro compacto, cards brancos com sombra suave, chips,
badges, CTAs azuis e bottom navigation elegante.

desktop com sidebar/dashboard, listas densas, areas de detalhe e largura util,
sem parecer mobile esticado.
```

## Auditoria tecnica inicial

Ficheiros principais encontrados:

```txt
lib/core/widgets/app_shell_scaffold.dart
lib/core/widgets/app_content_shell.dart
lib/core/widgets/app_card.dart
lib/core/widgets/app_button.dart
lib/core/widgets/app_status_pill.dart
lib/core/widgets/app_action_panel.dart
lib/core/widgets/app_metric_tile.dart
lib/core/widgets/app_responsive_grid.dart
lib/core/theme/app_tokens.dart

lib/features/common/mensagens/mensagens_tab.dart
lib/features/common/mensagens/chat_thread_screen.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/prestador/widgets/prestador_home_components.dart
lib/features/cliente/cliente_perfil_screen.dart
lib/features/prestador/prestador_perfil_screen.dart
```

Leitura do estado atual:

```txt
AppShellScaffold ja centraliza bottom navigation mobile e NavigationRail desktop.
AppContentShell/AppPageScaffold ja resolvem max-width e padding responsivo.
MensagensTab ainda usa Scaffold, TextField, chips e tiles manuais fora da foundation.
ChatThreadScreen tem header, bubbles e input funcionais, mas visual antigo/WhatsApp-ish.
PedidoListCard ja usa AppCard/AppStatusPill, mas pode ser elevado para card operacional.
PrestadorAvailableOrderCard preserva keys criticas de aceitar/ignorar.
Conta tab de Cliente/Prestador ainda e simples, com listas basicas.
ClientePerfilScreen e PrestadorPerfilScreen usam Scaffold/ListView/ListTile manuais.
```

## Fora do escopo

```txt
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

Nao tocar:

```txt
functions/**
firestore.rules
storage.rules
lib/core/services/pedido_service.dart
lib/core/repositories/pedido_repo.dart
lib/core/services/location_service.dart
lib/core/services/chat_service.dart
android/key.properties
keystore
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
.superpowers/
```

## Keys e fluxos a preservar

Cliente:

```txt
cliente_rejeitar_proposta_button
cliente_aceitar_proposta_button
cliente_duvida_valor_button
confirmar_valor_button
cliente_home_hero
cliente_home_primary_cta
cliente_home_services_section
cliente_home_operations_panel
cliente_home_active_orders_panel
```

Prestador:

```txt
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
prestador_home_availability_panel
prestador_home_metric_strip
prestador_home_next_work_panel
prestador_home_categories_panel
prestador_home_available_orders_section
```

Mensagens:

```txt
abrir conversa por tap
favoritar/desfavoritar por long press
filtros all/unread/favorites/groups
contador de nao lidas
envio de texto/anexo/audio/imagem no ChatThreadScreen
marcacao de mensagens como vistas/entregues
```

## Estrutura de ficheiros prevista

Criar componentes globais:

```txt
lib/core/widgets/app_product_header.dart
lib/core/widgets/app_premium_search_bar.dart
lib/core/widgets/app_filter_button.dart
lib/core/widgets/app_segmented_tabs.dart
lib/core/widgets/app_avatar.dart
lib/core/widgets/app_unread_badge.dart
test/core/widgets/app_product_ui_components_test.dart
```

Criar componentes por dominio visual:

```txt
lib/features/common/mensagens/widgets/conversation_list_card.dart
lib/features/common/widgets/order_operational_card.dart
lib/features/common/widgets/account_profile_summary.dart
lib/features/common/widgets/settings_list_tile.dart
test/features/common/mensagens/conversation_list_card_test.dart
test/features/common/widgets/order_operational_card_test.dart
test/features/common/widgets/account_profile_components_test.dart
```

Modificar telas existentes:

```txt
lib/core/widgets/app_shell_scaffold.dart
lib/features/common/mensagens/mensagens_tab.dart
lib/features/common/mensagens/chat_thread_screen.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/prestador/widgets/prestador_home_components.dart
lib/features/cliente/cliente_perfil_screen.dart
lib/features/prestador/prestador_perfil_screen.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Atualizar testes existentes quando a estrutura visual mudar sem mudar comportamento:

```txt
test/core/widgets/app_shell_scaffold_test.dart
test/features/cliente/cliente_home_redesign_test.dart
test/features/prestador/prestador_home_redesign_test.dart
test/features/cliente/widgets/pedido_list_card_test.dart
test/features/prestador/widgets/prestador_home_components_test.dart
```

## Bloco 1 - Congelar contratos visuais e riscos

- [ ] Confirmar `git status --short` e deixar fora de escopo os `~$*.pptx` e `.superpowers/`.
- [ ] Ler a spec M2.10.7 e este plano antes de editar codigo.
- [ ] Confirmar que `MensagensTab`, `ChatThreadScreen`, `_ClientePedidosTab`, `_PrestadorPedidosTab`, `_ContaTab`, `ClientePerfilScreen` e `PrestadorPerfilScreen` continuam com os mesmos fluxos de dados.
- [ ] Listar no terminal, antes de editar codigo, os ficheiros que serao alterados e as keys que serao preservadas.
- [ ] Nao alterar services, repositorios, rules, schema ou Functions.

## Bloco 2 - Componentes globais primeiro

- [ ] Criar `AppAvatar` com:
  - imagem remota opcional
  - fallback por inicial
  - indicador online opcional
  - tamanhos `sm/md/lg`
  - sem dependencia de rede para o fallback
- [ ] Criar `AppUnreadBadge` com:
  - ponto pequeno para estado simples
  - contador para mensagens nao lidas
  - limite visual para numeros grandes
- [ ] Criar `AppProductHeader` com:
  - logo/texto ChegaJa
  - titulo grande
  - subtitulo opcional
  - acoes de notificacao/avatar opcionais
  - comportamento compacto em mobile
  - alinhamento limpo em desktop
- [ ] Criar `AppPremiumSearchBar` com:
  - icone de pesquisa
  - hint
  - controller opcional
  - `onChanged`
  - altura estavel
  - sombra/borda consistente com referencias
- [ ] Criar `AppFilterButton` com:
  - icone de filtro
  - estado ativo opcional
  - tooltip
  - tamanho minimo de toque
- [ ] Criar `AppSegmentedTabs` com:
  - tabs com label
  - contador opcional
  - selected index
  - layout horizontal scrollable em mobile
  - estilo azul para selecionado
- [ ] Adicionar testes em `test/core/widgets/app_product_ui_components_test.dart` cobrindo tamanhos, badges, search callbacks, tabs e header em mobile/desktop.

## Bloco 3 - Navegacao global

- [ ] Evoluir `AppShellScaffold` sem mudar a API publica obrigatoria.
- [ ] Mobile:
  - bottom navigation com visual mais premium
  - labels legiveis
  - icones selecionados em azul/brand
  - badge nao intrusivo para mensagens
  - safe area preservada
- [ ] Desktop/Web/Windows:
  - NavigationRail com aspeto de sidebar/rail de dashboard
  - marca ChegaJa no topo quando houver espaco
  - item selecionado mais claro
  - conteudo central sem esticar mobile
- [ ] Preservar `IndexedStack`, rotas e `onDestinationSelected`.
- [ ] Atualizar `test/core/widgets/app_shell_scaffold_test.dart` para garantir que:
  - mobile usa bottom navigation
  - desktop usa rail/sidebar
  - trocar aba preserva child
  - badge continua visivel quando `showBadge=true`

## Bloco 4 - Mensagens Cliente/Prestador

- [ ] Criar `ConversationListCard` em `lib/features/common/mensagens/widgets/`.
- [ ] O card deve suportar:
  - `AppAvatar`
  - indicador online quando existir dado
  - nome
  - ultima mensagem
  - hora/data
  - `AppUnreadBadge`
  - chip de servico/status com `AppStatusPill`
  - estado favorito sem dominar o layout
- [ ] Refatorar `MensagensTab` para usar:
  - `AppPageScaffold` ou `AppContentShell`
  - `AppProductHeader`
  - `AppPremiumSearchBar`
  - `AppFilterButton`
  - `AppSegmentedTabs` ou chips alinhados ao novo componente
  - `ConversationListCard`
- [ ] Manter query Firestore, filtros, long press de favorito e navegacao para `ChatThreadScreen`.
- [ ] Melhorar empty/loading/error com texto humano e sem excecao bruta.
- [ ] Fazer polish seguro em `ChatThreadScreen`:
  - header com `AppAvatar`, nome, status e acoes
  - fundo claro, nao wallpaper escuro
  - bubbles mais limpos e alinhados ao design system
  - input com fundo branco, borda suave e botao azul
  - sem alterar envio, anexos, chamadas, presenca ou ChatService
- [ ] Adicionar testes de widget para `ConversationListCard` e testes de smoke visual para `MensagensTab` com dados fake quando possivel.

## Bloco 5 - Pedidos Cliente/Prestador

- [ ] Criar `OrderOperationalCard` como componente compartilhado, ou evoluir `PedidoListCard` para cobrir o mesmo contrato sem duplicacao.
- [ ] O card deve suportar:
  - avatar ou icone de servico
  - titulo/nome
  - categoria/servico
  - local
  - horario/ETA
  - valor/estimativa
  - status pill
  - CTA principal
  - acoes secundarias opcionais
- [ ] Cliente:
  - aplicar visual nas listas da aba Pedidos em `cliente_home_screen.dart`
  - manter abrir detalhe
  - manter `PedidoChatPreview` quando ja existir
  - organizar ativos/agendados/concluidos/cancelados sem criar backend novo
- [ ] Prestador:
  - aplicar visual nos cards de pedidos disponiveis e meus trabalhos em `prestador_home_screen.dart`
  - preservar `PrestadorAvailableOrderCard` ou compor com o novo card
  - preservar exatamente keys de aceitar/ignorar/orcamento
  - manter callbacks de aceitar, ignorar, abrir detalhe, orcamento e chat
- [ ] Se a separacao por tabs/segmentos ja existir, usar `AppSegmentedTabs`; se nao existir, nao inventar fluxo novo obrigatorio.
- [ ] Atualizar testes de `PedidoListCard`, `PrestadorAvailableOrderCard` e homes para validar CTA, keys e layout responsivo.

## Bloco 6 - Conta/Perfil Cliente/Prestador

- [ ] Criar `AccountProfileSummary` em `lib/features/common/widgets/`.
- [ ] Criar `SettingsListTile` em `lib/features/common/widgets/`.
- [ ] Conta tab Cliente:
  - usar `AppPageScaffold`/`AppContentShell`
  - header com `AppProductHeader`
  - card de perfil com avatar, nome/role e CTA "Editar perfil"
  - lista de definicoes com icones coloridos
  - favoritos, regiao, tema, definicoes, suporte e logout/destrutivo controlado quando existir
- [ ] Conta tab Prestador:
  - card de perfil com role Prestador
  - atalhos para Perfil, Pagamentos existentes, Definicoes, Suporte
  - nao prometer Stripe/pagamentos reais alem do que ja existe na app
- [ ] Perfil editavel Cliente/Prestador:
  - aplicar `AppPageScaffold`/`AppCard`
  - header mais premium com avatar e botao alterar foto
  - campos agrupados por secoes
  - manter validacoes, autocomplete, upload e save atuais
- [ ] Nao implementar KYC, documentos reais, ganhos reais novos ou features grandes.
- [ ] Adicionar testes para `AccountProfileSummary` e `SettingsListTile`; se perfil completo for dificil por dependencias Firebase, testar os componentes extraidos.

## Bloco 7 - Responsividade e QA visual

- [ ] Garantir que todos os novos componentes respeitam:
  - mobile 390x844
  - tablet 768x1024
  - desktop 1366x768
  - wide 1920x1080
- [ ] Desktop nao deve parecer mobile esticado:
  - usar `AppContentWidth.dashboard` ou `wide`
  - sidebar/rail visivel
  - listas mais densas e centralizadas
- [ ] Mobile deve permanecer em uma coluna limpa:
  - sem overflow horizontal
  - bottom nav nao tapada
  - botoes com altura estavel
  - cards sem texto a sair do limite
- [ ] Atualizar ou reutilizar `scripts/qa/capture_visual_matrix.js` para capturar rotas tocadas quando o ambiente local estiver disponivel.
- [ ] Guardar evidencias em `%TEMP%` ou documentar paths locais; nao commitar screenshots pesados.
- [ ] Atualizar `docs/M2_10_VISUAL_PRODUCT_STATUS.md` com:
  - componentes criados
  - telas tocadas
  - ficheiros principais
  - validacoes
  - limitacoes restantes
  - proximo passo recomendado

## Validacoes obrigatorias

Executar no fim da implementacao:

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Se houver ajuste em screenshots/QA visual:

```powershell
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:<porta> --out-dir=%TEMP%\chegaja-m2107-visual-qa --wait-ms=12000
```

Nao executar:

```powershell
npm.cmd run smoke:firebase:production
npm.cmd run health:firebase:production
npm.cmd run admin:cleanup:smoke
firebase deploy
```

## Checkpoints de revisao

Depois de cada bloco, verificar:

```txt
Bloco 2: componentes globais testados e sem uso prematuro desorganizado.
Bloco 3: navegacao global mais premium sem quebrar troca de abas.
Bloco 4: Mensagens visualmente alinhada e chat funcional preservado.
Bloco 5: Pedidos Cliente/Prestador com cards consistentes e keys preservadas.
Bloco 6: Conta/Perfil com aspeto de produto e sem feature falsa.
Bloco 7: responsividade e docs atualizadas.
```

## Resultado esperado

```txt
M2.10.7 avancada com alinhamento visual de produto.
Mensagens, Pedidos, Conta/Perfil e navegacao global mais proximos das referencias aprovadas.
Design system aplicado de forma consistente.
Fluxos Cliente/Prestador preservados.
Sem backend, rules, Functions, deploy ou producao.
Testes e docs atualizados.
```

## Commit recomendado

```txt
Avancar M2.10.7 product UI alignment implementation
```
