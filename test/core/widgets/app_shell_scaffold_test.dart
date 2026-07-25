import 'package:chegaja_v2/core/widgets/app_shell_scaffold.dart';
import 'package:chegaja_v2/core/widgets/app_unread_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses a NavigationBar on compact widths', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScaffold(
          experienceV2Override: true,
          currentIndex: 0,
          onDestinationSelected: (_) {},
          destinations: const [
            AppShellDestination(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              child: SizedBox(),
            ),
            AppShellDestination(
              label: 'Messages',
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );

    expect(
      find.byKey(const Key('app_shell_mobile_navigation')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      navBar.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a premium sidebar on desktop widths', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScaffold(
          experienceV2Override: true,
          currentIndex: 0,
          onDestinationSelected: (_) {},
          destinations: const [
            AppShellDestination(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              child: SizedBox(),
            ),
            AppShellDestination(
              label: 'Messages',
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('app_shell_desktop_sidebar')), findsOneWidget);
    expect(find.byKey(const Key('app_shell_desktop_brand')), findsOneWidget);
    expect(find.text('Servicos perto de ti'), findsOneWidget);
    expect(find.text('Sessao ativa'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses a NavigationRail on tablet widths', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScaffold(
          experienceV2Override: true,
          currentIndex: 0,
          onDestinationSelected: (_) {},
          destinations: _fiveDestinations,
        ),
      ),
    );

    expect(
      find.byKey(const Key('app_shell_tablet_navigation')),
      findsOneWidget,
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.byKey(const Key('app_shell_desktop_sidebar')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'flag off keeps legacy tablet navigation, labels, height and eager pages',
      (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var secondaryInitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScaffold(
          experienceV2Override: false,
          currentIndex: 0,
          onDestinationSelected: (_) {},
          destinations: [
            const AppShellDestination(
              label: 'Primary',
              icon: Icons.home_outlined,
              child: Text('Primary page'),
            ),
            AppShellDestination(
              label: 'Secondary',
              icon: Icons.chat_bubble_outline,
              builder: (_) => _SecondaryCounterPage(
                onInit: () => secondaryInitCount += 1,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(secondaryInitCount, 1);
    final navigationBar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navigationBar.height, 76);
    expect(
      navigationBar.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports five destinations on compact widths', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScaffold(
          experienceV2Override: true,
          currentIndex: 0,
          onDestinationSelected: (_) {},
          destinations: _fiveDestinations,
        ),
      ),
    );

    for (final destination in _fiveDestinations) {
      expect(find.text(destination.label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows only the selected mobile label at large text scale',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: AppShellScaffold(
            experienceV2Override: true,
            currentIndex: 0,
            onDestinationSelected: (_) {},
            destinations: _fiveDestinations,
          ),
        ),
      ),
    );

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      navBar.labelBehavior,
      NavigationDestinationLabelBehavior.onlyShowSelected,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop sidebar selection calls callback', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    int? selectedIndex;

    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScaffold(
          experienceV2Override: true,
          currentIndex: 0,
          onDestinationSelected: (index) => selectedIndex = index,
          destinations: const [
            AppShellDestination(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              child: SizedBox(),
            ),
            AppShellDestination(
              label: 'Messages',
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves tab state when switching destinations',
      (tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: _ShellHarness()));

    await tester.tap(find.byKey(const Key('counter-button')));
    await tester.pump();
    expect(find.text('Count: 1'), findsOneWidget);

    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();
    expect(find.text('Messages page'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Count: 1'), findsOneWidget);
  });

  testWidgets('shows unread badge when mobile destination has badge',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScaffold(
          experienceV2Override: true,
          currentIndex: 0,
          onDestinationSelected: (_) {},
          destinations: const [
            AppShellDestination(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              child: SizedBox(),
            ),
            AppShellDestination(
              label: 'Messages',
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              showBadge: true,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );

    expect(find.byType(AppUnreadBadge), findsOneWidget);
  });

  testWidgets('shows unread badge when desktop destination has badge',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppShellScaffold(
          experienceV2Override: true,
          currentIndex: 0,
          onDestinationSelected: (_) {},
          destinations: const [
            AppShellDestination(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              child: SizedBox(),
            ),
            AppShellDestination(
              label: 'Messages',
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              showBadge: true,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );

    expect(find.byType(AppUnreadBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds destinations lazily and preserves visited state',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var secondaryInitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _LazyShellHarness(
          onSecondaryInit: () => secondaryInitCount += 1,
        ),
      ),
    );

    expect(secondaryInitCount, 0);
    expect(find.text('Secondary count: 0'), findsNothing);

    await tester.tap(find.text('Secondary'));
    await tester.pump();
    expect(secondaryInitCount, 1);
    expect(find.text('Secondary count: 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('secondary-counter-button')));
    await tester.pump();
    expect(find.text('Secondary count: 1'), findsOneWidget);

    await tester.tap(find.text('Primary'));
    await tester.pump();
    await tester.tap(find.text('Secondary'));
    await tester.pump();

    expect(secondaryInitCount, 1);
    expect(find.text('Secondary count: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stable destination ids preserve state after reordering',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: _ReorderShellHarness()));
    await tester.tap(find.text('Secondary'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('secondary-counter-button')));
    await tester.pump();
    expect(find.text('Secondary count: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reorder-shell-button')));
    await tester.pump();

    expect(find.text('Secondary count: 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _fiveDestinations = [
  AppShellDestination(
    id: 'home',
    label: 'Início',
    icon: Icons.home_outlined,
    child: Text('Página inicial'),
  ),
  AppShellDestination(
    id: 'orders',
    label: 'Pedidos',
    icon: Icons.receipt_long_outlined,
    child: Text('Página de pedidos'),
  ),
  AppShellDestination(
    id: 'messages',
    label: 'Mensagens',
    icon: Icons.chat_bubble_outline,
    child: Text('Página de mensagens'),
  ),
  AppShellDestination(
    id: 'saved',
    label: 'Guardados',
    icon: Icons.bookmark_border,
    child: Text('Página de guardados'),
  ),
  AppShellDestination(
    id: 'profile',
    label: 'Perfil',
    icon: Icons.person_outline,
    child: Text('Página de perfil'),
  ),
];

class _ShellHarness extends StatefulWidget {
  const _ShellHarness();

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      experienceV2Override: true,
      currentIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: const [
        AppShellDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          child: _CounterPage(),
        ),
        AppShellDestination(
          label: 'Messages',
          icon: Icons.chat_bubble_outline,
          selectedIcon: Icons.chat_bubble,
          child: Center(child: Text('Messages page')),
        ),
      ],
    );
  }
}

class _LazyShellHarness extends StatefulWidget {
  const _LazyShellHarness({
    required this.onSecondaryInit,
  });

  final VoidCallback onSecondaryInit;

  @override
  State<_LazyShellHarness> createState() => _LazyShellHarnessState();
}

class _LazyShellHarnessState extends State<_LazyShellHarness> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      experienceV2Override: true,
      currentIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: [
        const AppShellDestination(
          id: 'primary',
          label: 'Primary',
          icon: Icons.home_outlined,
          child: Center(child: Text('Primary page')),
        ),
        AppShellDestination(
          id: 'secondary',
          label: 'Secondary',
          icon: Icons.chat_bubble_outline,
          builder: (_) => _SecondaryCounterPage(
            onInit: widget.onSecondaryInit,
          ),
        ),
      ],
    );
  }
}

class _ReorderShellHarness extends StatefulWidget {
  const _ReorderShellHarness();

  @override
  State<_ReorderShellHarness> createState() => _ReorderShellHarnessState();
}

class _ReorderShellHarnessState extends State<_ReorderShellHarness> {
  var _selectedId = 'primary';
  var _reordered = false;

  @override
  Widget build(BuildContext context) {
    final destinations = <AppShellDestination>[
      const AppShellDestination(
        id: 'primary',
        label: 'Primary',
        icon: Icons.home_outlined,
        child: Center(child: Text('Primary page')),
      ),
      AppShellDestination(
        id: 'secondary',
        label: 'Secondary',
        icon: Icons.chat_bubble_outline,
        builder: (_) => const _SecondaryCounterPage(onInit: _noOp),
      ),
    ];
    if (_reordered) {
      destinations.insert(0, destinations.removeAt(1));
    }
    final selectedIndex = destinations.indexWhere(
      (destination) => destination.id == _selectedId,
    );

    return Column(
      children: [
        TextButton(
          key: const Key('reorder-shell-button'),
          onPressed: () => setState(() => _reordered = !_reordered),
          child: const Text('Reorder'),
        ),
        Expanded(
          child: AppShellScaffold(
            experienceV2Override: true,
            currentIndex: selectedIndex,
            onDestinationSelected: (index) => setState(
              () => _selectedId = destinations[index].id!,
            ),
            destinations: destinations,
          ),
        ),
      ],
    );
  }
}

void _noOp() {}

class _SecondaryCounterPage extends StatefulWidget {
  const _SecondaryCounterPage({
    required this.onInit,
  });

  final VoidCallback onInit;

  @override
  State<_SecondaryCounterPage> createState() => _SecondaryCounterPageState();
}

class _SecondaryCounterPageState extends State<_SecondaryCounterPage> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Secondary count: $_count'),
          ElevatedButton(
            key: const Key('secondary-counter-button'),
            onPressed: () => setState(() => _count += 1),
            child: const Text('Increment secondary'),
          ),
        ],
      ),
    );
  }
}

class _CounterPage extends StatefulWidget {
  const _CounterPage();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Count: $_count'),
          ElevatedButton(
            key: const Key('counter-button'),
            onPressed: () => setState(() => _count += 1),
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
