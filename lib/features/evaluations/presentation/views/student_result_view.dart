import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';
import 'package:olcerim/features/reports/presentation/controllers/report_providers.dart';
import 'package:olcerim/features/reports/presentation/views/generated_pdf_view.dart';

class StudentResultView extends ConsumerWidget {
  const StudentResultView({required this.results, required this.student, super.key});

  final AssessmentResults results;
  final StudentResult student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenci sonucu'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final bytes = await ref.read(reportRepositoryProvider).studentPdf(results, student);
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GeneratedPdfView(
                    title: 'Öğrenci formu',
                    bytes: bytes,
                    fileName: 'ogrenci-degerlendirme.pdf',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(student.student.fullName, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text('${results.classroom.name} · ${results.assessment.title}'),
              const SizedBox(height: 16),
              Text(
                '${_score(student.total)} / ${_score(results.maxTotal)}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              Text('Puanlama ayrıntıları', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...results.criteria.map((criterion) {
                final matches = student.entries.where((item) => item.criterionId == criterion.criterionId);
                final entry = matches.isEmpty ? null : matches.first;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(criterion.title, style: Theme.of(context).textTheme.titleMedium)),
                            Text(
                              entry == null
                                  ? '— / ${_score(criterion.maxScore)}'
                                  : '${_score(entry.score)} / ${_score(criterion.maxScore)}',
                            ),
                          ],
                        ),
                        if (entry?.note?.isNotEmpty == true) ...[
                          const SizedBox(height: 10),
                          Text('Kriter notu', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text(entry!.note!),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              if (student.note?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                Text('Öğretmen notu', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(student.note!),
              ],
              if (student.observations.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Gözlem notları', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...student.observations.map(
                  (observation) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notes),
                    title: Text(observation.content),
                    subtitle: Text(
                      DateFormat('d MMM y, HH:mm', 'tr').format(observation.createdAt.toLocal()),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}
