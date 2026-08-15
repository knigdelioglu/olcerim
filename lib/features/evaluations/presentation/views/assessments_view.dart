import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olcerim/core/database/daos/assessment_dao.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';
import 'package:olcerim/features/evaluations/presentation/views/assessment_results_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/create_assessment_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/grading_session_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/quick_scale_grading_view.dart';

class AssessmentsView extends ConsumerStatefulWidget {
  const AssessmentsView({super.key});

  @override
  ConsumerState<AssessmentsView> createState() => _AssessmentsViewState();
}

class _AssessmentsViewState extends ConsumerState<AssessmentsView> {
  String? status;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(assessmentsByStatusProvider(status));
    return Scaffold(
      appBar: AppBar(title: const Text('Değerlendirmeler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateAssessmentView()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Değerlendirme'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _filterChip(null, 'Tümü'),
                const SizedBox(width: 8),
                _filterChip(AssessmentStatus.draft.storageValue, AssessmentStatus.draft.label),
                const SizedBox(width: 8),
                _filterChip(AssessmentStatus.active.storageValue, AssessmentStatus.active.label),
                const SizedBox(width: 8),
                _filterChip(AssessmentStatus.completed.storageValue, AssessmentStatus.completed.label),
              ],
            ),
          ),
          Expanded(
            child: items.when(
              data: (rows) => rows.isEmpty
                  ? _EmptyAssessments(filtered: status != null)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _AssessmentCard(row: rows[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Değerlendirmeler yüklenemedi.')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? value, String label) => ChoiceChip(
        selected: status == value,
        label: Text(label),
        onSelected: (_) => setState(() => status = value),
      );
}

class _AssessmentCard extends ConsumerWidget {
  const _AssessmentCard({required this.row});
  final AssessmentSummaryRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = row.totalCount == 0 ? 0.0 : row.completedCount / row.totalCount;
    final type = AssessmentType.fromStorage(row.assessment.type);
    final description = row.assessment.description?.trim();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, type),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(type == AssessmentType.quickScale ? Icons.speed : Icons.rule),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(row.assessment.title, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Chip(
                    label: Text(
                      switch (row.assessment.status) {
                        'completed' => 'Tamamlandı',
                        'active' => 'Devam ediyor',
                        _ => 'Taslak',
                      },
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Değerlendirme işlemleri',
                    onSelected: (value) async {
                      if (value == 'open') {
                        _open(context, type);
                        return;
                      }
                      if (value != 'archive') return;
                      await ref.read(assessmentRepositoryProvider).setArchived(row.assessment.id, true);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${row.assessment.title} arşivlendi'),
                          action: SnackBarAction(
                            label: 'Geri al',
                            onPressed: () => ref
                                .read(assessmentRepositoryProvider)
                                .setArchived(row.assessment.id, false),
                          ),
                        ),
                      );
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'open', child: Text('Aç')),
                      PopupMenuItem(value: 'archive', child: Text('Arşivle')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${row.classroom.name} · ${DateFormat('d MMM y', 'tr').format(row.assessment.assessmentDate)} · ${type.label}',
              ),
              if (description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(description!, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 16),
              Text('${row.completedCount} / ${row.totalCount} tamamlandı'),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, AssessmentType type) {
    final completed = row.assessment.status == AssessmentStatus.completed.storageValue;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => completed
            ? AssessmentResultsView(assessmentId: row.assessment.id)
            : type == AssessmentType.quickScale
                ? QuickScaleGradingView(assessmentId: row.assessment.id)
                : GradingSessionView(assessmentId: row.assessment.id),
      ),
    );
  }
}

class _EmptyAssessments extends StatelessWidget {
  const _EmptyAssessments({required this.filtered});
  final bool filtered;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fact_check_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                filtered ? 'Bu durumda değerlendirme yok' : 'Henüz değerlendirme yok',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                filtered
                    ? 'Başka bir durum filtresi seçebilirsiniz.'
                    : 'Bir sınıf seçip Rubrik veya Hızlı Derecelendirme ile ilk değerlendirmeyi oluşturun.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
