import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olcerim/core/database/daos/assessment_dao.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';
import 'package:olcerim/features/evaluations/presentation/views/create_assessment_view.dart';

class AssessmentsView extends ConsumerWidget {
  const AssessmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(assessmentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Değerlendirmeler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateAssessmentView())),
        icon: const Icon(Icons.add),
        label: const Text('Değerlendirme'),
      ),
      body: items.when(
        data: (rows) => rows.isEmpty
            ? const _EmptyAssessments()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _AssessmentCard(row: rows[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Değerlendirmeler yüklenemedi.')),
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.row});
  final AssessmentSummaryRow row;

  @override
  Widget build(BuildContext context) {
    final progress = row.totalCount == 0 ? 0.0 : row.completedCount / row.totalCount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [Expanded(child: Text(row.assessment.title, style: Theme.of(context).textTheme.titleLarge)), _StatusChip(status: row.assessment.status)]),
            const SizedBox(height: 4),
            Text('${row.classroom.name} · ${DateFormat('d MMM y', 'tr').format(row.assessment.assessmentDate)}'),
            const SizedBox(height: 16),
            Text('${row.completedCount} / ${row.totalCount} tamamlandı'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final label = switch (status) { 'completed' => 'Tamamlandı', 'active' => 'Devam ediyor', _ => 'Taslak' };
    return Chip(label: Text(label));
  }
}

class _EmptyAssessments extends StatelessWidget {
  const _EmptyAssessments();
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.fact_check_outlined, size: 56),
            const SizedBox(height: 16),
            Text('Henüz değerlendirme yok', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Bir sınıf ve rubrik seçerek ilk değerlendirmeyi oluşturun.', textAlign: TextAlign.center),
          ]),
        ),
      );
}
