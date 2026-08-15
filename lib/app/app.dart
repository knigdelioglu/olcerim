import 'package:flutter/material.dart';
import 'package:olcerim/app/router/app_router.dart';
import 'package:olcerim/app/theme/app_theme.dart';
import 'package:olcerim/features/backup/presentation/views/backup_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/grading_table_view.dart';
import 'package:olcerim/features/reports/presentation/views/report_preview_view.dart';
import 'package:olcerim/features/rubrics/presentation/views/rubric_editor_view.dart';
import 'package:olcerim/features/students/presentation/views/student_import_view.dart';

class OlcerimApp extends StatelessWidget {
  const OlcerimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ölçerim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  AppSection section = AppSection.students;

  static const views = <Widget>[
    StudentImportView(),
    RubricEditorView(),
    GradingTableView(),
    ReportPreviewView(),
    BackupView(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = AppSection.values.indexOf(section);

    return Scaffold(
      appBar: AppBar(title: const Text('Ölçerim')),
      body: SafeArea(child: views[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => section = AppSection.values[value]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'Öğrenciler'),
          NavigationDestination(icon: Icon(Icons.rule_outlined), label: 'Rubrikler'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Değerlendir'),
          NavigationDestination(icon: Icon(Icons.picture_as_pdf_outlined), label: 'Raporlar'),
          NavigationDestination(icon: Icon(Icons.backup_outlined), label: 'Yedek'),
        ],
      ),
    );
  }
}
