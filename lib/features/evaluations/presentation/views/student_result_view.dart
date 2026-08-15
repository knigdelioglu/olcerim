import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';
import 'package:olcerim/features/reports/presentation/controllers/report_providers.dart';
import 'package:olcerim/features/reports/presentation/views/generated_pdf_view.dart';

class StudentResultView extends ConsumerWidget {
  const StudentResultView({required this.results, required this.student, super.key});
  final AssessmentResults results; final StudentResult student;
  @override Widget build(BuildContext context, WidgetRef ref) => Scaffold(appBar: AppBar(title: const Text('Öğrenci sonucu'), actions: [TextButton.icon(onPressed: () async { final bytes = await ref.read(reportRepositoryProvider).studentPdf(results, student); if (!context.mounted) return; Navigator.push(context, MaterialPageRoute(builder: (_) => GeneratedPdfView(title: 'Öğrenci formu', bytes: bytes, fileName: 'ogrenci-degerlendirme.pdf'))); }, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF'))]), body: Align(alignment: Alignment.topCenter, child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [Text(student.student.fullName, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 4), Text('${results.classroom.name} · ${results.assessment.title}'), const SizedBox(height: 16), Text('${_score(student.total)} / ${_score(results.maxTotal)}', style: Theme.of(context).textTheme.displaySmall), const SizedBox(height: 24), ...results.criteria.map((criterion) { final matches = student.entries.where((item) => item.criterionId == criterion.criterionId); final entry = matches.isEmpty ? null : matches.first; return ListTile(contentPadding: EdgeInsets.zero, title: Text(criterion.title), trailing: Text(entry == null ? '— / ${_score(criterion.maxScore)}' : '${_score(entry.score)} / ${_score(criterion.maxScore)}')); }), if (student.note?.isNotEmpty == true) ...[const Divider(height: 32), Text('Öğretmen notu', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text(student.note!)] ])));
  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}
