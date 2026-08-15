import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';
import 'package:olcerim/features/evaluations/presentation/views/grading_session_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/student_result_view.dart';

class AssessmentResultsView extends ConsumerWidget {
  const AssessmentResultsView({required this.assessmentId, super.key});
  final int assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(assessmentResultsProvider(assessmentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Değerlendirme sonuçları')),
      body: results.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(assessmentResultsProvider(assessmentId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (data.incompleteCount > 0)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded),
                    title: Text('${data.incompleteCount} öğrenci henüz tamamlanmadı.'),
                    trailing: TextButton(onPressed: () => _openGrading(context), child: const Text('Eksikleri aç')),
                  ),
                ),
              const SizedBox(height: 12),
              _SummaryGrid(data: data),
              const SizedBox(height: 24),
              Text('Kriter ortalamaları', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...data.criteria.map((criterion) => _CriterionAverage(criterion: criterion)),
              const SizedBox(height: 24),
              Row(children: [Expanded(child: Text('Öğrenciler', style: Theme.of(context).textTheme.titleLarge)), FilledButton.tonal(onPressed: () => _openGrading(context), child: const Text('Değerlendirmeye dön'))]),
              const SizedBox(height: 8),
              ...data.students.map((student) => Card(child: ListTile(
                    leading: _StatusIcon(status: student.status),
                    title: Text(student.student.fullName),
                    subtitle: student.student.schoolNumber == null ? null : Text('No: ${student.student.schoolNumber}'),
                    trailing: Text('${_score(student.total)} / ${_score(data.maxTotal)}'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentResultView(results: data, student: student))),
                  ))),
              const SizedBox(height: 16),
              if (data.incompleteCount == 0 && data.assessment.status != AssessmentStatus.completed.storageValue)
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(assessmentRepositoryProvider).setStatus(assessmentId, AssessmentStatus.completed);
                    ref.invalidate(assessmentResultsProvider(assessmentId));
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Değerlendirmeyi tamamla'),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Sonuçlar yüklenemedi.')),
      ),
    );
  }

  void _openGrading(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => GradingSessionView(assessmentId: assessmentId)));
  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});
  final AssessmentResults data;
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Sınıf ortalaması', _score(data.classAverage)),
      ('Tamamlanan', '${data.completedCount} / ${data.students.length}'),
      ('En güçlü kriter', data.strongestCriterion?.title ?? '—'),
      ('Gelişim alanı', data.growthCriterion?.title ?? '—'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final count = constraints.maxWidth >= 900 ? 4 : 2;
      return GridView.count(
        crossAxisCount: count,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: count == 4 ? 1.8 : 1.5,
        children: items.map((item) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(item.$1, style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center), const SizedBox(height: 8), Text(item.$2, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center)])))).toList(),
      );
    });
  }
  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

class _CriterionAverage extends StatelessWidget {
  const _CriterionAverage({required this.criterion});
  final CriterionResult criterion;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [Expanded(child: Text(criterion.title)), Text('${_score(criterion.average)} / ${_score(criterion.maxScore)}')]),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: criterion.ratio),
        ]),
      );
  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final String status;
  @override Widget build(BuildContext context) => Icon(switch (status) { 'completed' => Icons.check_circle, 'incomplete' => Icons.warning_amber_rounded, _ => Icons.radio_button_unchecked }, semanticLabel: switch (status) { 'completed' => 'Tamamlandı', 'incomplete' => 'Eksik', _ => 'Değerlendirilmedi' });
}
