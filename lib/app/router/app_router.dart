import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/app/router/adaptive_app_shell.dart';
import 'package:olcerim/features/classrooms/presentation/views/classrooms_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/assessments_view.dart';
import 'package:olcerim/features/onboarding/presentation/controllers/onboarding_provider.dart';
import 'package:olcerim/features/onboarding/presentation/welcome_view.dart';
import 'package:olcerim/features/reports/presentation/views/report_preview_view.dart';
import 'package:olcerim/features/rubrics/presentation/views/rubric_library_view.dart';
import 'package:olcerim/features/settings/presentation/views/settings_view.dart';
import 'package:olcerim/features/templates/presentation/controllers/template_seeder_provider.dart';

enum AppSection { classrooms, assessments, rubrics, reports, settings }

class AppRouter extends ConsumerStatefulWidget {
  const AppRouter({super.key});

  @override
  ConsumerState<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<AppRouter> {
  var selectedIndex = 0;

  static const _destinations = [
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

  static const _pages = <Widget>[
    ClassroomsView(),
    AssessmentsView(),
    RubricLibraryView(),
    ReportPreviewView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(defaultTemplateSeederProvider);
    final onboarding = ref.watch(onboardingCompletedProvider);

    return onboarding.when(
      data: (completed) => completed ? _buildShell() : const WelcomeView(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      // A settings-read failure must never lock the user out of Settings,
      // Archives or Restore. The shell is the safest recovery surface.
      error: (_, __) => _buildShell(),
    );
  }

  Widget _buildShell() => AdaptiveAppShell(
        selectedIndex: selectedIndex,
        destinations: _destinations,
        pages: _pages,
        onDestinationSelected: (value) => setState(() => selectedIndex = value),
      );
}
