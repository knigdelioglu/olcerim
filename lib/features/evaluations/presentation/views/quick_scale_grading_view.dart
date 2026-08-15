import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/assessment_dao.dart';
import 'package:olcerim/core/database/daos/evaluation_dao.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';
import 'package:olcerim/features/evaluations/presentation/views/assessment_results_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/evaluation_notes_sheet.dart';

class QuickScaleGradingView extends ConsumerStatefulWidget {
  const QuickScaleGradingView({required this.assessmentId, super.key});
  final int assessmentId;

  @override
  ConsumerState<QuickScaleGradingView> createState() => _QuickScaleGradingViewState();
}

class _QuickScaleGradingViewState extends ConsumerState<QuickScaleGradingView> {
  String filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(assessmentRepositoryProvider).setStatus(widget.assessmentId, AssessmentStatus.active),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(assessmentDetailProvider(widget.assessmentId));
    final students = ref.watch(assessmentStudentsProvider(widget.assessmentId));
    final criteria = ref.watch(assessmentCriteriaProvider(widget.assessmentId));
    final title = detail.valueOrNull?.assessment.title ?? 'Hızlı derecelendirme';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AssessmentResultsView(assessmentId: widget.assessmentId),
              ),
            ),
            icon: const Icon(Icons.bar_chart),
            label: const Text('Sonuçlar'),
          ),
        ],
      ),
      body: detail.when(
        data: (detailValue) {
          if (detailValue == null) return const Center(child: Text('Değerlendirme bulunamadı.'));
          return criteria.when(
            data: (criterionItems) {
              if (criterionItems.length != 1) {
                return const Center(child: Text('Hızlı derecelendirme ölçeği geçersiz.'));
              }
              final criterion = criterionItems.single;
              final levels = ref.watch(criterionLevelsProvider(criterion.id));
              return levels.when(
                data: (levelItems) => students.when(
                  data: (studentItems) => _content(
                    detail: detailValue,
                    students: studentItems,
                    criterion: criterion,
                    levels: levelItems,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Öğrenciler yüklenemedi.')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Hızlı ölçek yüklenemedi.')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Hızlı ölçek yüklenemedi.')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Değerlendirme yüklenemedi.')),
      ),
    );
  }

  Widget _content({
    required AssessmentDetailRow detail,
    required List<EvaluationStudentRow> students,
    required RubricCriterion criterion,
    required List<RubricLevel> levels,
  }) {
    final visible = filter == 'all'
        ? students
        : students.where((item) => item.evaluation.status == filter).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _QuickScaleHeader(detail: detail, levelCount: levels.length),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filter(null, 'Tümü'),
                const SizedBox(width: 8),
                _filter(EvaluationStatus.notStarted.storageValue, EvaluationStatus.notStarted.label),
                const SizedBox(width: 8),
                _filter(EvaluationStatus.completed.storageValue, EvaluationStatus.completed.label),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: visible.isEmpty
              ? const Center(child: Text('Bu filtrede öğrenci yok.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth >= 900 ? 860.0 : double.infinity;
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, index) => _QuickScaleStudentCard(
                            row: visible[index],
                            criterion: criterion,
                            levels: levels,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filter(String? value, String label) {
    final normalized = value ?? 'all';
    return ChoiceChip(
      selected: filter == normalized,
      label: Text(label),
      onSelected: (_) => setState(() => filter = normalized),
    );
  }
}

class _QuickScaleHeader extends StatelessWidget {
  const _QuickScaleHeader({required this.detail, required this.levelCount});
  final AssessmentDetailRow detail;
  final int levelCount;

  @override
  Widget build(BuildContext context) {
    final description = detail.assessment.description?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Hızlı derecelendirme · ${detail.rubric.title}', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Chip(label: Text('$levelCount düzey')),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${detail.classroom.name} · ${detail.course.name} · ${DateFormat('d MMM y', 'tr').format(detail.assessment.assessmentDate)}',
              ),
              if (description?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(description!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickScaleStudentCard extends ConsumerWidget {
  const _QuickScaleStudentCard({
    required this.row,
    required this.criterion,
    required this.levels,
  });

  final EvaluationStudentRow row;
  final RubricCriterion criterion;
  final List<RubricLevel> levels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(evaluationEntriesProvider(row.evaluation.id)).valueOrNull ?? const <EvaluationEntry>[];
    EvaluationEntry? entry;
    for (final item in entries) {
      if (item.criterionId == criterion.id) {
        entry = item;
        break;
      }
    }
    final currentEntry = entry;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.student.fullName, style: Theme.of(context).textTheme.titleMedium),
                      if (row.student.schoolNumber != null) Text('No: ${row.student.schoolNumber}'),
                    ],
                  ),
                ),
                _QuickStatus(status: row.evaluation.status),
                IconButton(
                  tooltip: 'Öğretmen notu',
                  onPressed: () => _showStudentNote(context, ref),
                  icon: Icon(row.evaluation.note?.isNotEmpty == true ? Icons.comment : Icons.add_comment_outlined),
                ),
                IconButton(
                  tooltip: 'Gözlem notları',
                  onPressed: () => showObservationNotesSheet(context, row.evaluation.id),
                  icon: const Icon(Icons.notes),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: levels
                  .map(
                    (level) => ChoiceChip(
                      selected: currentEntry?.score == level.score,
                      label: Text(level.label),
                      onSelected: (_) async {
                        try {
                          await ref.read(evaluationRepositoryProvider).score(
                                evaluationId: row.evaluation.id,
                                criterionId: criterion.id,
                                score: level.score,
                              );
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Derecelendirme kaydedilemedi.')),
                            );
                          }
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
            if (currentEntry != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => showCriterionNoteDialog(
                    context: context,
                    ref: ref,
                    evaluationId: row.evaluation.id,
                    criterionId: criterion.id,
                    currentNote: currentEntry.note,
                  ),
                  icon: Icon(
                    currentEntry.note?.isNotEmpty == true ? Icons.sticky_note_2_outlined : Icons.note_add_outlined,
                    size: 18,
                  ),
                  label: Text(currentEntry.note?.isNotEmpty == true ? 'Derecelendirme notunu düzenle' : 'Derecelendirme notu ekle'),
                ),
              ),
              if (currentEntry.note?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(currentEntry.note!),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showStudentNote(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: row.evaluation.note ?? '');
    final value = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${row.student.fullName} · Öğretmen notu'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Öğrenciye ilişkin genel not'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Kaydet')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await ref.read(evaluationRepositoryProvider).saveStudentNote(row.evaluation.id, value);
  }
}

class _QuickStatus extends StatelessWidget {
  const _QuickStatus({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Icon(
        status == EvaluationStatus.completed.storageValue ? Icons.check_circle : Icons.radio_button_unchecked,
        semanticLabel: status == EvaluationStatus.completed.storageValue ? 'Tamamlandı' : 'Değerlendirilmedi',
      );
}
