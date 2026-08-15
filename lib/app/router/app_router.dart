import 'package:flutter/material.dart';
import 'package:olcerim/app/layout/app_breakpoints.dart';
import 'package:olcerim/features/backup/presentation/views/backup_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/grading_table_view.dart';
import 'package:olcerim/features/reports/presentation/views/report_preview_view.dart';
import 'package:olcerim/features/rubrics/presentation/views/rubric_editor_view.dart';
import 'package:olcerim/features/students/presentation/views/student_import_view.dart';

enum AppSection { classrooms, assessments, rubrics, reports, settings }

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  var selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Sınıflar'),
    NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Değerlendirmeler'),
    NavigationDestination(icon: Icon(Icons.rule_outlined), selectedIcon: Icon(Icons.rule), label: 'Rubrikler'),
    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Raporlar'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ayarlar'),
  ];

  static const _pages = <Widget>[
    StudentImportView(),
    GradingTableView(),
    RubricEditorView(),
    ReportPreviewView(),
    BackupView(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppBreakpoints.ofWidth(constraints.maxWidth);
        if (layout == AppLayoutClass.compact) {
          return Scaffold(
            body: SafeArea(child: IndexedStack(index: selectedIndex, children: _pages)),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) => setState(() => selectedIndex = value),
              destinations: _destinations,
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
                  onDestinationSelected: (value) => setState(() => selectedIndex = value),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text('Ölçerim', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  destinations: _destinations
                      .map((item) => NavigationRailDestination(
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                            label: Text(item.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: IndexedStack(index: selectedIndex, children: _pages)),
              ],
            ),
          ),
        );
      },
    );
  }
}
