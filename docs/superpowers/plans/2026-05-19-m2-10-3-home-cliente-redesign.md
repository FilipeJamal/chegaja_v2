# M2.10.3 Home Cliente Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesenhar a Home Cliente para deixar de parecer prototipo e passar a funcionar como uma tela operacional moderna de servicos on-demand em Web, Windows e Android.

**Architecture:** A implementacao aplica a foundation da M2.10.2 na Home Cliente, extraindo componentes visuais reutilizaveis para `lib/features/cliente/widgets/cliente_home_components.dart` e mantendo streams, navegacao e regras de negocio no fluxo existente de `cliente_home_screen.dart`. O layout deixa de depender de altura fixa do viewport e passa a usar `AppPageScaffold`, `AppContentShell`, `AppResponsiveGrid`, `AppActionPanel`, `AppStatusPill` e tiles responsivos.

**Tech Stack:** Flutter/Dart, Material 3, `flutter_test`, Firebase streams existentes, `AppTokens`, `AppPageScaffold`, `AppContentShell`, `AppResponsiveGrid`, `AppActionPanel`, `AppStatusPill`, `PedidoListCard`.

---

## Contexto

Spec aprovada:

```txt
docs/superpowers/specs/2026-05-19-m2-10-3-home-cliente-redesign-design.md
```

Commit da spec:

```txt
3558fce2460fa033134e6690e77ed1c7d1736bb4
Iniciar M2.10.3 home cliente redesign
```

Foundation disponivel desde M2.10.2:

```txt
AppPageScaffold
AppContentShell
AppSectionHeader
AppActionPanel
AppStatusPill
AppMetricTile
AppResponsiveGrid
tokens responsivos em AppTokens
```

Problema principal da tela atual:

```txt
_ClienteInicioTab ainda parece mobile esticado no desktop
servicos usam SizedBox(height: constraints.maxHeight * 0.62)
servicos aparecem como lista estreita, mesmo em Web/Windows
pendencias e mensagens aparecem como blocos soltos
hero/CTA nao parecem produto real
loading/empty/error ainda nao orientam tao bem a acao
```

## Fora do escopo

```txt
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
pagamentos reais
Play Store
package id final
HTTPS App Links
fechar M2.6
```

## Estrutura de ficheiros

Criar:

```txt
lib/features/cliente/widgets/cliente_home_components.dart
test/features/cliente/widgets/cliente_home_components_test.dart
```

Modificar:

```txt
lib/features/cliente/cliente_home_screen.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Nao tocar:

```txt
firestore.rules
storage.rules
functions/**
android/key.properties
keystore
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
```

## Keys e comportamentos a preservar

Antes de alterar a tela, confirmar que estes fluxos continuam:

```txt
tap num servico abre NovoPedidoScreen com modo e servicoInicial corretos
pesquisa de servicos por SmartSearchBar continua a abrir NovoPedidoScreen
pendencia de pedido abre PedidoDetalheScreen
mensagem nao lida abre MensagensTab/ChatThreadScreen conforme fluxo atual
tabs existentes do Cliente continuam acessiveis
testes E2E que clicam por texto de servico continuam a encontrar os cards
```

Adicionar keys novas sem remover compatibilidade:

```dart
const Key('cliente_home_hero')
const Key('cliente_home_primary_cta')
const Key('cliente_home_services_section')
const Key('cliente_home_service_tile_<service-id>')
const Key('cliente_home_operations_panel')
const Key('cliente_home_messages_panel')
const Key('cliente_home_active_orders_panel')
```

Quando o service id tiver caracteres fora de letras, numeros, `_` ou `-`, normalizar para `_` no sufixo da key.

---

### Task 1: Testes dos componentes visuais da Home Cliente

**Files:**
- Create: `test/features/cliente/widgets/cliente_home_components_test.dart`
- Create later: `lib/features/cliente/widgets/cliente_home_components.dart`

- [ ] **Step 1: Criar teste falhando para hero, tile e paineis**

Criar `test/features/cliente/widgets/cliente_home_components_test.dart`:

```dart
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClienteHomeHero', () {
    testWidgets('mostra promessa operacional e CTA principal', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteHomeHero(
              greeting: 'Ola, Filipe',
              title: 'Que servico precisas?',
              subtitle: 'Escolhe um servico e acompanha tudo num unico lugar.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () => tapped = true,
              onSearch: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('cliente_home_hero')), findsOneWidget);
      expect(find.text('Que servico precisas?'), findsOneWidget);
      expect(find.byKey(const Key('cliente_home_primary_cta')), findsOneWidget);

      await tester.tap(find.byKey(const Key('cliente_home_primary_cta')));
      expect(tapped, isTrue);
    });
  });

  group('ClienteServiceTile', () {
    testWidgets('mostra nome, modo e key estavel por servico', (tester) async {
      var tapped = false;
      const servico = Servico(
        id: 'canalizador-1',
        name: 'Canalizador',
        mode: 'IMEDIATO',
        keywords: ['agua', 'cano'],
        iconKey: 'canalizador',
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteServiceTile(
              servico: servico,
              localeCode: 'pt',
              modeLabel: 'Imediato',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('cliente_home_service_tile_canalizador-1')),
        findsOneWidget,
      );
      expect(find.text('Canalizador'), findsOneWidget);
      expect(find.text('Imediato'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('cliente_home_service_tile_canalizador-1')),
      );
      expect(tapped, isTrue);
    });
  });

  group('ClienteHomeOperationsPanel', () {
    testWidgets('mostra acao pendente com CTA', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteHomeOperationsPanel(
              title: 'Tens algo para decidir',
              message: 'Uma proposta aguarda a tua resposta.',
              actionLabel: 'Ver pedido',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('cliente_home_operations_panel')),
        findsOneWidget,
      );
      expect(find.text('Tens algo para decidir'), findsOneWidget);

      await tester.tap(find.text('Ver pedido'));
      expect(tapped, isTrue);
    });
  });

  group('ClienteHomeEmptyServices', () {
    testWidgets('orienta primeira acao sem parecer erro tecnico', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClienteHomeEmptyServices(),
          ),
        ),
      );

      expect(find.text('Ainda estamos a preparar servicos para ti.'), findsOneWidget);
      expect(
        find.text('Tenta novamente daqui a pouco ou ajusta a pesquisa.'),
        findsOneWidget,
      );
    });
  });
}
```

- [ ] **Step 2: Rodar teste e confirmar falha por ficheiro inexistente**

Run:

```powershell
flutter test test/features/cliente/widgets/cliente_home_components_test.dart
```

Expected:

```txt
Error: Error when reading 'lib/features/cliente/widgets/cliente_home_components.dart'
```

---

### Task 2: Componentes visuais da Home Cliente

**Files:**
- Create: `lib/features/cliente/widgets/cliente_home_components.dart`
- Test: `test/features/cliente/widgets/cliente_home_components_test.dart`

- [ ] **Step 1: Criar componentes base**

Criar `lib/features/cliente/widgets/cliente_home_components.dart`:

```dart
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:flutter/material.dart';

class ClienteHomeHero extends StatelessWidget {
  const ClienteHomeHero({
    super.key,
    required this.greeting,
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.onSearch,
  });

  final String greeting;
  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: const Key('cliente_home_hero'),
      variant: AppCardVariant.elevated,
      size: AppCardSize.large,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useRow = constraints.maxWidth >= 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                key: const Key('cliente_home_primary_cta'),
                label: primaryActionLabel,
                onPressed: onPrimaryAction,
                leadingIcon: Icons.add_rounded,
                trailingIcon: Icons.arrow_forward_rounded,
                size: AppButtonSize.lg,
                expanded: true,
              ),
              const SizedBox(height: AppSpacing.x2),
              AppButton(
                label: 'Pesquisar prestadores',
                onPressed: onSearch,
                leadingIcon: Icons.search_rounded,
                variant: AppButtonVariant.secondary,
                expanded: true,
              ),
            ],
          );

          if (!useRow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: AppSpacing.x5),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: copy),
              const SizedBox(width: AppSpacing.x6),
              SizedBox(width: 280, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class ClienteServicesSection extends StatelessWidget {
  const ClienteServicesSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.search,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Widget search;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('cliente_home_services_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: title,
          subtitle: subtitle,
        ),
        search,
        const SizedBox(height: AppSpacing.x4),
        AppResponsiveGrid(
          minItemWidth: 250,
          spacing: AppSpacing.x3,
          runSpacing: AppSpacing.x3,
          children: children,
        ),
      ],
    );
  }
}

class ClienteServiceTile extends StatelessWidget {
  const ClienteServiceTile({
    super.key,
    required this.servico,
    required this.localeCode,
    required this.modeLabel,
    required this.onTap,
  });

  final Servico servico;
  final String localeCode;
  final String modeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = clienteServiceIconFor(servico.iconKey);
    final key = Key('cliente_home_service_tile_${clienteHomeSafeKey(servico.id)}');

    return AppCard(
      key: key,
      onTap: onTap,
      variant: AppCardVariant.outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  servico.nameForLang(localeCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                AppStatusPill(
                  label: modeLabel,
                  tone: clienteServiceToneFor(servico.mode),
                  size: AppStatusPillSize.sm,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          Icon(
            Icons.arrow_forward_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class ClienteHomeOperationsPanel extends StatelessWidget {
  const ClienteHomeOperationsPanel({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      key: const Key('cliente_home_operations_panel'),
      title: title,
      message: message,
      icon: Icons.notifications_active_outlined,
      tone: AppStatusTone.warning,
      primaryAction: AppActionPanelAction(
        label: actionLabel,
        icon: Icons.arrow_forward_rounded,
        onPressed: onAction,
      ),
    );
  }
}

class ClienteHomeMessagesPanel extends StatelessWidget {
  const ClienteHomeMessagesPanel({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      key: const Key('cliente_home_messages_panel'),
      title: title,
      message: message,
      icon: Icons.chat_bubble_outline_rounded,
      tone: AppStatusTone.info,
      primaryAction: AppActionPanelAction(
        label: actionLabel,
        icon: Icons.open_in_new_rounded,
        onPressed: onAction,
        variant: AppButtonVariant.secondary,
      ),
    );
  }
}

class ClienteHomeEmptyServices extends StatelessWidget {
  const ClienteHomeEmptyServices({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppActionPanel(
      title: 'Ainda estamos a preparar servicos para ti.',
      message: 'Tenta novamente daqui a pouco ou ajusta a pesquisa.',
      icon: Icons.search_off_rounded,
      tone: AppStatusTone.neutral,
    );
  }
}

String clienteHomeSafeKey(String raw) {
  final normalized = raw.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  return normalized.isEmpty ? 'sem_id' : normalized;
}

AppStatusTone clienteServiceToneFor(String? mode) {
  final normalized = (mode ?? '').toUpperCase().trim();
  if (normalized == 'IMEDIATO') return AppStatusTone.success;
  if (normalized == 'AGENDADO') return AppStatusTone.info;
  return AppStatusTone.warning;
}

IconData clienteServiceIconFor(String? iconKey) {
  final normalized = (iconKey ?? '').toLowerCase().trim();
  if (normalized.contains('canal') || normalized.contains('plumb')) {
    return Icons.plumbing_rounded;
  }
  if (normalized.contains('eletric') || normalized.contains('electric')) {
    return Icons.electrical_services_rounded;
  }
  if (normalized.contains('limp') || normalized.contains('clean')) {
    return Icons.cleaning_services_rounded;
  }
  if (normalized.contains('pint')) return Icons.format_paint_rounded;
  if (normalized.contains('jard')) return Icons.yard_rounded;
  if (normalized.contains('mont')) return Icons.handyman_rounded;
  return Icons.home_repair_service_rounded;
}
```

- [ ] **Step 2: Rodar teste focado e confirmar passagem**

Run:

```powershell
flutter test test/features/cliente/widgets/cliente_home_components_test.dart
```

Expected:

```txt
All tests passed!
```

- [ ] **Step 3: Formatar ficheiros novos**

Run:

```powershell
dart format lib/features/cliente/widgets/cliente_home_components.dart test/features/cliente/widgets/cliente_home_components_test.dart
```

Expected:

```txt
Formatted 2 files
```

Se o output disser que nenhum ficheiro mudou, aceitar como OK.

---

### Task 3: Integrar foundation na Home Cliente

**Files:**
- Modify: `lib/features/cliente/cliente_home_screen.dart`
- Test: `test/features/cliente/widgets/cliente_home_components_test.dart`

- [ ] **Step 1: Atualizar imports da Home Cliente**

Em `lib/features/cliente/cliente_home_screen.dart`, adicionar:

```dart
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_content_shell.dart';
import 'package:chegaja_v2/core/widgets/app_responsive_grid.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
```

Remover imports que ficarem sem uso depois da migracao:

```dart
import 'package:chegaja_v2/core/widgets/app_chip.dart';
import 'package:chegaja_v2/core/widgets/app_tab_bar.dart';
```

Manter `AppCard` se ainda for usado por outras partes do mesmo ficheiro.

- [ ] **Step 2: Substituir o shell manual de `_ClienteInicioTab`**

Em `_ClienteInicioTab.build`, remover a combinacao:

```dart
return LayoutBuilder(
  builder: (context, constraints) {
    final double tabHeight = constraints.maxHeight * 0.62;
    final double maxWidth = constraints.maxWidth > AppBreakpoints.tabletMax
        ? AppBreakpoints.contentMaxTwoColumn
        : AppBreakpoints.contentMaxSingleColumn;
```

Substituir por uma estrutura sem `tabHeight`:

```dart
return AppPageScaffold(
  width: AppContentWidth.dashboard,
  child: _ClienteHomeDashboard(
    pedidosStream: pedidosStream,
    servicosStream: servicosStream,
    user: user,
    onSearch: () {
      showSearch(
        context: context,
        delegate: PrestadorSearchDelegate(),
      );
    },
  ),
);
```

Criar `_ClienteHomeDashboard` no mesmo ficheiro abaixo de `_ClienteInicioTab` para manter a reconstrucao legivel.

- [ ] **Step 3: Criar `_ClienteHomeDashboard` com layout responsivo**

Adicionar perto dos helpers da Home Cliente:

```dart
final GlobalKey _clienteServicesAnchorKey = GlobalKey(
  debugLabel: 'cliente_home_services_anchor',
);
```

Adicionar em `cliente_home_screen.dart`:

```dart
class _ClienteHomeDashboard extends StatelessWidget {
  const _ClienteHomeDashboard({
    required this.pedidosStream,
    required this.servicosStream,
    required this.user,
    required this.onSearch,
  });

  final Stream<List<Pedido>>? pedidosStream;
  final Stream<List<Servico>>? servicosStream;
  final User? user;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppBreakpoints.desktopMin;
        final mainColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClienteHomeHero(
              greeting: l10n.homeGreeting,
              title: l10n.homeSubtitle,
              subtitle:
                  'Escolhe um servico, acompanha propostas e fala com o prestador sem perder contexto.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () => _scrollToServices(context),
              onSearch: onSearch,
            ),
            const SizedBox(height: AppSpacing.x5),
            const StoriesCarouselWidget(),
            const SizedBox(height: AppSpacing.x5),
            _ClienteServicesStreamSection(
              user: user,
              servicosStream: servicosStream,
            ),
          ],
        );

        final sideColumn = _ClienteHomeSideColumn(
          user: user,
          pedidosStream: pedidosStream,
        );

        if (!isDesktop) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mainColumn,
              const SizedBox(height: AppSpacing.x5),
              sideColumn,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: mainColumn),
            const SizedBox(width: AppSpacing.x6),
            Expanded(flex: 4, child: sideColumn),
          ],
        );
      },
    );
  }
}
```

Adicionar helper local:

```dart
void _scrollToServices(BuildContext context) {
  final targetContext = _clienteServicesAnchorKey.currentContext;
  if (targetContext == null) return;
  Scrollable.ensureVisible(
    targetContext,
    duration: const Duration(milliseconds: 260),
    curve: Curves.easeOutCubic,
  );
}
```

Se a secao ainda nao estiver montada, o CTA continua seguro sem crash. No Task 4, aplicar esta key no container da secao de servicos.

- [ ] **Step 4: Rodar analyzer para capturar imports/nomes quebrados**

Run:

```powershell
dart analyze lib/features/cliente/cliente_home_screen.dart
```

Expected nesta etapa:

```txt
Erros apenas para classes ainda nao criadas nesta Task: _ClienteServicesStreamSection, _ClienteHomeSideColumn
```

Se aparecer erro em import inexistente ou tipo errado, corrigir antes de continuar.

---

### Task 4: Recriar secao de servicos sem altura fixa

**Files:**
- Modify: `lib/features/cliente/cliente_home_screen.dart`

- [ ] **Step 1: Criar `_ClienteServicesStreamSection`**

Adicionar abaixo de `_ClienteHomeDashboard`:

```dart
class _ClienteServicesStreamSection extends StatelessWidget {
  const _ClienteServicesStreamSection({
    required this.user,
    required this.servicosStream,
  });

  final User? user;
  final Stream<List<Servico>>? servicosStream;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return const AppLoadingView(label: 'A preparar a tua area de cliente...');
    }

    return StreamBuilder<List<Servico>>(
      stream: servicosStream ?? ServicosRepo.streamServicosAtivos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingView(label: 'A carregar servicos disponiveis...');
        }

        if (snapshot.hasError) {
          return AppErrorView(
            message:
                'Nao conseguimos carregar os servicos agora. Verifica a ligacao e tenta novamente.',
          );
        }

        final servicos = snapshot.data ?? const <Servico>[];
        if (servicos.isEmpty) {
          return const ClienteHomeEmptyServices();
        }

        return _ClienteServicesCatalog(
          key: _clienteServicesAnchorKey,
          servicos: servicos,
          title: l10n.availableServicesTitle,
          subtitle:
              'Escolhe uma categoria para iniciar um pedido com mais contexto.',
        );
      },
    );
  }
}
```

Esta etapa remove o uso de:

```dart
SizedBox(height: tabHeight)
DefaultTabController
TabBarView
Expanded dentro da Home
```

- [ ] **Step 2: Criar `_ClienteServicesCatalog`**

Adicionar:

```dart
class _ClienteServicesCatalog extends StatefulWidget {
  const _ClienteServicesCatalog({
    super.key,
    required this.servicos,
    required this.title,
    required this.subtitle,
  });

  final List<Servico> servicos;
  final String title;
  final String subtitle;

  @override
  State<_ClienteServicesCatalog> createState() => _ClienteServicesCatalogState();
}

class _ClienteServicesCatalogState extends State<_ClienteServicesCatalog> {
  String _selectedMode = 'ORCAMENTO';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final modes = <String, String>{
      'ORCAMENTO': l10n.serviceTabQuote,
      'AGENDADO': l10n.serviceTabScheduled,
      'IMEDIATO': l10n.serviceTabImmediate,
    };

    final filtered = widget.servicos
        .where((servico) => _normalizeServicoMode(servico.mode) == _selectedMode)
        .toList();

    return ClienteServicesSection(
      title: widget.title,
      subtitle: widget.subtitle,
      search: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SmartSearchBar<Servico>(
            hintText: l10n.serviceSearchHint,
            allItems: filtered,
            idSelector: (s) => s.id,
            nameSelector: (s) => s.name,
            keywordsSelector: (s) => s.keywords,
            onItemSelected: (servico) => _openNovoPedido(
              context: context,
              modo: _selectedMode,
              servico: servico,
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final entry in modes.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _selectedMode == entry.key,
                  onSelected: (_) => setState(() => _selectedMode = entry.key),
                ),
            ],
          ),
        ],
      ),
      children: [
        if (filtered.isEmpty)
          const ClienteHomeEmptyServices()
        else
          for (final servico in filtered)
            ClienteServiceTile(
              servico: servico,
              localeCode: locale.languageCode,
              modeLabel: modes[_selectedMode] ?? _selectedMode,
              onTap: () => _openNovoPedido(
                context: context,
                modo: _selectedMode,
                servico: servico,
              ),
            ),
      ],
    );
  }

  void _openNovoPedido({
    required BuildContext context,
    required String modo,
    required Servico servico,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NovoPedidoScreen(
          modo: modo,
          servicoInicial: servico,
        ),
      ),
    );
  }
}
```

Racional:

```txt
mantem os tres modos atuais
substitui tabs com altura fixa por chips simples e grid responsivo
preserva SmartSearchBar e navegacao para NovoPedidoScreen
permite desktop usar multiplas colunas
```

- [ ] **Step 3: Remover classes antigas de lista/card de servicos**

Remover do fim do ficheiro:

```dart
class _ListaServicosPorModo extends StatefulWidget
class _ListaServicosPorModoState extends State<_ListaServicosPorModo>
class _ServicoCard extends StatelessWidget
```

Manter helpers usados por outros pontos:

```dart
_normalizeServicoMode
_descricaoModo
_mapIcon
```

Depois da migracao, se `_descricaoModo` ou `_mapIcon` ficarem sem uso, remover apenas esses helpers locais. O mapeamento de icone passa para `clienteServiceIconFor`.

- [ ] **Step 4: Rodar analyzer**

Run:

```powershell
dart analyze lib/features/cliente/cliente_home_screen.dart lib/features/cliente/widgets/cliente_home_components.dart
```

Expected:

```txt
No issues found!
```

Se aparecer aviso de import sem uso, remover import.

---

### Task 5: Painel lateral de pendencias, pedidos ativos e mensagens

**Files:**
- Modify: `lib/features/cliente/cliente_home_screen.dart`

- [ ] **Step 1: Criar `_ClienteHomeSideColumn`**

Adicionar:

```dart
class _ClienteHomeSideColumn extends StatelessWidget {
  const _ClienteHomeSideColumn({
    required this.user,
    required this.pedidosStream,
  });

  final User? user;
  final Stream<List<Pedido>>? pedidosStream;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClientePendingActionPanel(
          clienteId: user!.uid,
          pedidosStream: pedidosStream,
        ),
        const SizedBox(height: AppSpacing.x4),
        _ClienteActiveOrdersPanel(
          clienteId: user!.uid,
          pedidosStream: pedidosStream,
        ),
        const SizedBox(height: AppSpacing.x4),
        _ClienteMensagensBanner(clienteId: user!.uid),
      ],
    );
  }
}
```

- [ ] **Step 2: Criar `_ClientePendingActionPanel` usando componente novo**

Adicionar:

```dart
class _ClientePendingActionPanel extends StatelessWidget {
  const _ClientePendingActionPanel({
    required this.clienteId,
    required this.pedidosStream,
  });

  final String clienteId;
  final Stream<List<Pedido>>? pedidosStream;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Pedido>>(
      stream: pedidosStream ?? PedidosRepo.streamPedidosDoCliente(clienteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final pendentes = (snapshot.data ?? const <Pedido>[])
            .where(_temAcaoPendente)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (pendentes.isEmpty) return const SizedBox.shrink();
        final pedido = pendentes.first;

        return ClienteHomeOperationsPanel(
          title: l10n.homePendingTitle,
          message: _textoAcaoPendente(pedido, l10n),
          actionLabel: l10n.homePendingCta,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: Criar `_ClienteActiveOrdersPanel` com preview compacto**

Adicionar:

```dart
class _ClienteActiveOrdersPanel extends StatelessWidget {
  const _ClienteActiveOrdersPanel({
    required this.clienteId,
    required this.pedidosStream,
  });

  final String clienteId;
  final Stream<List<Pedido>>? pedidosStream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<Pedido>>(
      stream: pedidosStream ?? PedidosRepo.streamPedidosDoCliente(clienteId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final ativos = (snapshot.data ?? const <Pedido>[])
            .where((pedido) => !_pedidoEstaFinalizado(pedido))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (ativos.isEmpty) {
          return AppActionPanel(
            key: const Key('cliente_home_active_orders_panel'),
            title: 'Sem pedidos ativos',
            message: 'Quando criares um pedido, acompanhas aqui o proximo passo.',
            icon: Icons.receipt_long_outlined,
            tone: AppStatusTone.neutral,
          );
        }

        final pedido = ativos.first;
        final cardData = PedidoListPresenter.dataFor(
          pedido,
          role: PedidoListRole.cliente,
        );

        return Column(
          key: const Key('cliente_home_active_orders_panel'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: 'Pedido em curso',
              subtitle: 'Continua de onde paraste.',
              dense: true,
              trailing: ativos.length > 1
                  ? AppStatusPill(
                      label: '${ativos.length} ativos',
                      tone: AppStatusTone.info,
                      size: AppStatusPillSize.sm,
                    )
                  : null,
            ),
            PedidoListCard(
              data: cardData,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id),
                ),
              ),
            ),
            if (ativos.length > 1) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(
                'Ve mais pedidos na aba Pedidos.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
```

Adicionar helper:

```dart
bool _pedidoEstaFinalizado(Pedido pedido) {
  final status = pedido.status.toLowerCase().trim();
  final estado = pedido.estado.toLowerCase().trim();
  return status == 'concluido' ||
      status == 'cancelado' ||
      estado == 'concluido' ||
      estado == 'cancelado';
}
```

- [ ] **Step 4: Adaptar `_ClienteMensagensBanner` para usar `ClienteHomeMessagesPanel`**

Dentro de `_ClienteMensagensBanner.build`, no ramo que hoje retorna `AppCard`, trocar o card por:

```dart
return ClienteHomeMessagesPanel(
  title: l10n.unreadMessagesTitle,
  message: l10n.unreadMessagesCta,
  actionLabel: l10n.unreadMessagesCta,
  onAction: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MensagensTab(role: 'cliente'),
      ),
    );
  },
);
```

Se a assinatura de `MensagensTab` for diferente, manter a navegacao atual e trocar apenas o widget visual por `ClienteHomeMessagesPanel`.

- [ ] **Step 5: Rodar teste focado da Home components**

Run:

```powershell
flutter test test/features/cliente/widgets/cliente_home_components_test.dart
```

Expected:

```txt
All tests passed!
```

---

### Task 6: Teste de composicao da Home Cliente

**Files:**
- Create: `test/features/cliente/cliente_home_redesign_test.dart`
- Modify if needed: `lib/features/cliente/cliente_home_screen.dart`

- [ ] **Step 1: Criar teste de composicao com widgets extraidos**

Criar `test/features/cliente/cliente_home_redesign_test.dart` com um teste de nivel visual que nao dependa de Firebase real:

```dart
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home Cliente foundation compoe hero, operacoes e servicos',
      (tester) async {
    const servicos = [
      Servico(
        id: 'limpeza_1',
        name: 'Limpeza',
        mode: 'IMEDIATO',
        keywords: ['casa'],
        isActive: true,
      ),
      Servico(
        id: 'eletricista_1',
        name: 'Eletricista',
        mode: 'ORCAMENTO',
        keywords: ['luz'],
        isActive: true,
      ),
    ];

    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ClienteHomeHero(
                  greeting: 'Ola',
                  title: 'Que servico precisas?',
                  subtitle: 'Escolhe e acompanha tudo num unico lugar.',
                  primaryActionLabel: 'Escolher servico',
                  onPrimaryAction: () {},
                  onSearch: () {},
                ),
                ClienteHomeOperationsPanel(
                  title: 'Tens algo para decidir',
                  message: 'Uma proposta aguarda resposta.',
                  actionLabel: 'Ver pedido',
                  onAction: () {},
                ),
                ClienteServicesSection(
                  title: 'Servicos disponiveis',
                  subtitle: 'Escolhe uma categoria.',
                  search: const SizedBox.shrink(),
                  children: [
                    for (final servico in servicos)
                      ClienteServiceTile(
                        servico: servico,
                        localeCode: 'pt',
                        modeLabel: servico.mode,
                        onTap: () {},
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('cliente_home_hero')), findsOneWidget);
    expect(find.byKey(const Key('cliente_home_operations_panel')), findsOneWidget);
    expect(find.byKey(const Key('cliente_home_services_section')), findsOneWidget);
    expect(find.text('Limpeza'), findsOneWidget);
    expect(find.text('Eletricista'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar teste de composicao**

Run:

```powershell
flutter test test/features/cliente/cliente_home_redesign_test.dart
```

Expected:

```txt
All tests passed!
```

- [ ] **Step 3: Corrigir imports, overflow ou texto se o teste indicar problema real**

Se o teste acusar overflow, ajustar apenas dimensoes/padding dos componentes visuais criados nesta fase. Nao alterar backend nem fluxo.

---

### Task 7: Refinar loading, empty e erro na Home Cliente

**Files:**
- Modify: `lib/features/cliente/cliente_home_screen.dart`

- [ ] **Step 1: Substituir loading generico por loading contextual**

Na area de servicos, usar:

```dart
const AppLoadingView(label: 'A carregar servicos disponiveis...')
```

Na area de auth/user, usar:

```dart
const AppLoadingView(label: 'A preparar a tua area de cliente...')
```

- [ ] **Step 2: Substituir erro tecnico por mensagem humana**

Trocar:

```dart
AppErrorView(
  message: l10n.servicesLoadError(snapshot.error.toString()),
)
```

por:

```dart
AppErrorView(
  message:
      'Nao conseguimos carregar os servicos agora. Verifica a ligacao e tenta novamente.',
)
```

Nao passar `retryLabel` sem `onRetry`, porque `AppErrorView` so mostra botao se houver acao real.

- [ ] **Step 3: Substituir empty state de servicos por `ClienteHomeEmptyServices`**

Usar:

```dart
return const ClienteHomeEmptyServices();
```

- [ ] **Step 4: Rodar teste completo Flutter**

Run:

```powershell
flutter test
```

Expected:

```txt
All tests passed!
```

---

### Task 8: Responsividade e verificacao visual local

**Files:**
- Modify if needed: `lib/features/cliente/cliente_home_screen.dart`
- Modify if needed: `lib/features/cliente/widgets/cliente_home_components.dart`

- [ ] **Step 1: Verificar layout mobile no teste de surface**

Adicionar ao teste de componentes:

```dart
testWidgets('Hero mantem CTA visivel em largura mobile', (tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ClienteHomeHero(
          greeting: 'Ola',
          title: 'Que servico precisas?',
          subtitle: 'Escolhe um servico e acompanha tudo num unico lugar.',
          primaryActionLabel: 'Escolher servico',
          onPrimaryAction: () {},
          onSearch: () {},
        ),
      ),
    ),
  );

  expect(find.byKey(const Key('cliente_home_primary_cta')), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Rodar testes focados**

Run:

```powershell
flutter test test/features/cliente/widgets/cliente_home_components_test.dart test/features/cliente/cliente_home_redesign_test.dart
```

Expected:

```txt
All tests passed!
```

- [ ] **Step 3: Fazer screenshot manual local se servidor estiver disponivel**

Se houver servidor Web local ja aberto em `127.0.0.1:5173`, abrir a Home Cliente e verificar visualmente:

```txt
desktop usa coluna principal + lateral
mobile nao tem overflow horizontal
CTA principal aparece antes da lista de servicos
servicos aparecem em grid no desktop
pendencias/mensagens ficam na coluna lateral no desktop
```

Nao iniciar deploy, smoke real, health real ou cleanup real nesta etapa.

---

### Task 9: Documentacao de status M2.10

**Files:**
- Modify: `docs/M2_10_VISUAL_PRODUCT_STATUS.md`

- [ ] **Step 1: Atualizar status da M2.10.3**

Adicionar uma secao:

```md
## M2.10.3 - Home Cliente redesign

Estado: avancado quando a implementacao for concluida.

Escopo:
- Home Cliente recomposta com `AppPageScaffold` e `AppContentShell`.
- Hero operacional com CTA principal.
- Servicos em tiles responsivos com `AppResponsiveGrid`.
- Pendencias, pedidos ativos e mensagens com paineis operacionais.
- Loading, empty e erro mais humanos.
- Desktop/Web/Windows deixam de usar layout de mobile esticado.
- Mobile preserva uma coluna direta.

Fora do escopo mantido:
- Home Prestador.
- Backend, Rules, Functions e deploy.
- Pagamentos, Play Store, package id final e HTTPS App Links.
- Android fisico e fecho da M2.6.

Validacoes esperadas:
- `flutter test`
- `npm.cmd run test:scripts`
- `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"`
```

- [ ] **Step 2: Registrar evidencias apos validacoes finais**

Depois dos comandos finais, substituir "Validacoes esperadas" por "Validacoes executadas" com os resultados reais.

---

### Task 10: Validações finais e commit

**Files:**
- All modified files

- [ ] **Step 1: Confirmar working tree e ficheiros fora do escopo**

Run:

```powershell
git status --short
```

Expected:

```txt
 M docs/M2_10_VISUAL_PRODUCT_STATUS.md
 M lib/features/cliente/cliente_home_screen.dart
?? lib/features/cliente/widgets/cliente_home_components.dart
?? test/features/cliente/cliente_home_redesign_test.dart
?? test/features/cliente/widgets/cliente_home_components_test.dart
```

As duas delecoes antigas dos PPTX podem continuar aparecendo como `D`, mas nao devem ser staged no commit.

- [ ] **Step 2: Rodar Flutter tests**

Run:

```powershell
flutter test
```

Expected:

```txt
All tests passed!
```

- [ ] **Step 3: Rodar testes de scripts**

Run:

```powershell
npm.cmd run test:scripts
```

Expected:

```txt
process exit code 0
```

- [ ] **Step 4: Rodar testes Firebase emulator**

Run:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```txt
37 passing
```

Se o numero aumentar por testes novos em Functions, aceitar desde que todos passem. Esta fase nao deve criar ou alterar testes em `functions/`.

- [ ] **Step 5: Verificar diff**

Run:

```powershell
git diff --check
git diff --stat
```

Expected:

```txt
git diff --check sem output
stat limitado a Home Cliente, componentes, testes e docs M2.10
```

- [ ] **Step 6: Stage sem misturar PPTX**

Run:

```powershell
git add -- lib/features/cliente/cliente_home_screen.dart lib/features/cliente/widgets/cliente_home_components.dart test/features/cliente/cliente_home_redesign_test.dart test/features/cliente/widgets/cliente_home_components_test.dart docs/M2_10_VISUAL_PRODUCT_STATUS.md
git status --short
```

Expected:

```txt
M  docs/M2_10_VISUAL_PRODUCT_STATUS.md
M  lib/features/cliente/cliente_home_screen.dart
A  lib/features/cliente/widgets/cliente_home_components.dart
A  test/features/cliente/cliente_home_redesign_test.dart
A  test/features/cliente/widgets/cliente_home_components_test.dart
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
```

As linhas `D artifacts/...` devem ficar sem stage.

- [ ] **Step 7: Commit**

Run:

```powershell
git commit -m "Avancar M2.10.3 home cliente redesign"
```

Expected:

```txt
[main <sha>] Avancar M2.10.3 home cliente redesign
```

---

## Checklist de cobertura da spec

- Auditoria visual da Home atual: Tasks 1, 3 e 4.
- Preservacao de keys e comportamentos: secao "Keys e comportamentos" e Tasks 3, 4, 5, 10.
- Hero operacional compacto: Tasks 1, 2 e 3.
- CTA principal forte: Tasks 1, 2 e 3.
- Servicos/categorias em tiles: Tasks 1, 2 e 4.
- Pedidos ativos/pendencias: Task 5.
- Mensagens/recentes: Task 5.
- Loading/empty/error humanos: Task 7.
- Responsividade Web/Windows/Android: Tasks 3, 4 e 8.
- Testes Flutter: Tasks 1, 2, 6, 8 e 10.
- Docs/status M2.10: Task 9.
- Backend/Rules/Functions/deploy fora do escopo: secao fora do escopo e Task 10.

## Handoff de execucao

Executar em blocos:

```txt
1. Componentes + testes
2. Integracao Home Cliente + servicos responsivos
3. Paineis de operacao + mensagens
4. Loading/empty/error + docs
5. Validacoes finais + commit
```

Commit final recomendado:

```txt
Avancar M2.10.3 home cliente redesign
```
