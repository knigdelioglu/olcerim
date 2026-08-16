import 'package:flutter/material.dart';
import 'package:olcerim/app/layout/app_breakpoints.dart';

/// Adaptive top-level navigation shell shared by phone, tablet and desktop.
///
/// The shell is intentionally controlled: [selectedIndex] is owned by the
/// caller so navigation state remains explicit and testable. Page widgets are
/// kept alive in an [IndexedStack] while switching destinations.
class AdaptiveAppShell extends StatelessWidget {
  const AdaptiveAppShell({
    required this.selectedIndex,
    required this.destinations,
    required this.pages,
    required this.onDestinationSelected,
    this.brandLabel = 'Ölçerim',
    super.key,
  }) : assert(destinations.length == pages.length),
       assert(selectedIndex >= 0),
       assert(selectedIndex < pages.length);

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final List<Widget> pages;
  final ValueChanged<int> onDestinationSelected;
  final String brandLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppBreakpoints.ofWidth(constraints.maxWidth);
        if (layout == AppLayoutClass.compact) {
          return Scaffold(
            body: SafeArea(
              child: IndexedStack(index: selectedIndex, children: pages),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ),
          );
        }

        final extended = layout == AppLayoutClass.expanded;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  minExtendedWidth: 248,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      brandLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  destinations: destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(index: selectedIndex, children: pages),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
