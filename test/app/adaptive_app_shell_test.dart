import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/app/router/adaptive_app_shell.dart';

void main() {
  Future<void> pumpShellAtSize(
    WidgetTester tester,
    Size size,
  ) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: _ShellHarness()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone uses bottom navigation and switches destinations', (tester) async {
    await pumpShellAtSize(tester, const Size(390, 844));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Sayfa 0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Sayfa 4'), findsOneWidget);
    expect(find.text('Sayfa 0'), findsNothing);
  });

  testWidgets('tablet uses compact navigation rail', (tester) async {
    await pumpShellAtSize(tester, const Size(800, 1000));

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isFalse);

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Sayfa 3'), findsOneWidget);
  });

  testWidgets('desktop uses extended navigation rail', (tester) async {
    await pumpShellAtSize(tester, const Size(1440, 900));

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).extended, isTrue);
    expect(find.text('Ölçerim'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.rule_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Sayfa 2'), findsOneWidget);
  });

  testWidgets('destination switches preserve IndexedStack page state', (tester) async {
    await pumpShellAtSize(tester, const Size(390, 844));

    expect(find.text('Sayaç: 0'), findsOneWidget);
    await tester.tap(find.text('Artır'));
    await tester.pump();
    expect(find.text('Sayaç: 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Sayfa 4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Sayaç: 1'), findsOneWidget);
  });
}

class _ShellHarness extends StatefulWidget {
  const _ShellHarness();

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
  int selectedIndex = 0;

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: 'Sınıflar',
    ),
    NavigationDestination(
      icon: Icon(Icons.fact_check_outlined),
      selectedIcon: Icon(Icons.fact_check),
      label: 'Değerlendirmeler',
    ),
    NavigationDestination(
      icon: Icon(Icons.rule_outlined),
      selectedIcon: Icon(Icons.rule),
      label: 'Rubrikler',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Raporlar',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Ayarlar',
    ),
  ];

  static const pages = <Widget>[
    _CounterPage(),
    Center(child: Text('Sayfa 1')),
    Center(child: Text('Sayfa 2')),
    Center(child: Text('Sayfa 3')),
    Center(child: Text('Sayfa 4')),
  ];

  @override
  Widget build(BuildContext context) => AdaptiveAppShell(
        selectedIndex: selectedIndex,
        destinations: destinations,
        pages: pages,
        onDestinationSelected: (value) => setState(() => selectedIndex = value),
      );
}

class _CounterPage extends StatefulWidget {
  const _CounterPage();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sayfa 0'),
            Text('Sayaç: $count'),
            FilledButton(
              onPressed: () => setState(() => count += 1),
              child: const Text('Artır'),
            ),
          ],
        ),
      );
}
