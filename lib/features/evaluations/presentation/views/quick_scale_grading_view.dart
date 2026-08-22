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
        _QuickScaleHeader(
          detail: detail,
          levelCount: levels.length,
          maxScore: criterion.maxScore,
        ),
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
  const _QuickScaleHeader({
    required this.detail,
    required this.levelCount,
    required this.maxScore,
  });

  final AssessmentDetailRow detail;
  final int levelCount;
  final double maxScore;

  @override
  Widget build(BuildContext context) {
    final description = detail.assessment.description?.trim();
    final scaleLabel = levelCount == 0
        ? '0–${_formatScore(maxScore)} puan'
        : '$levelCount düzey';
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
                    child: Text(
                      'Hızlı derecelendirme · ${detail.rubric.title}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(label: Text(scaleLabel)),
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

    Future<void> writeScore(double score) => ref.read(evaluationRepositoryProvider).score(
          evaluationId: row.evaluation.id,
          criterionId: criterion.id,
          score: score,
        );

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
            if (levels.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: _NumericScoreField(
                  currentScore: currentEntry?.score,
                  maxScore: criterion.maxScore,
                  onScore: writeScore,
                ),
              )
            else
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
                            await writeScore(level.score);
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
                  label: Text(
                    currentEntry.note?.isNotEmpty == true
                        ? 'Derecelendirme notunu düzenle'
                        : 'Derecelendirme notu ekle',
                  ),
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

class _NumericScoreField extends StatefulWidget {
  const _NumericScoreField({
    required this.currentScore,
    required this.maxScore,
    required this.onScore,
  });

  final double? currentScore;
  final double maxScore;
  final Future<void> Function(double score) onScore;

  @override
  State<_NumericScoreField> createState() => _NumericScoreFieldState();
}

class _NumericScoreFieldState extends State<_NumericScoreField> {
  late final TextEditingController controller;
  late final FocusNode focusNode;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: _formatNullableScore(widget.currentScore));
    focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _NumericScoreField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentScore != widget.currentScore && !focusNode.hasFocus) {
      controller.text = _formatNullableScore(widget.currentScore);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    final normalized = controller.text.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value < 0 || value > widget.maxScore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('0 ile ${_formatScore(widget.maxScore)} arasında bir puan girin.'),
        ),
      );
      return false;
    }

    setState(() => saving = true);
    try {
      await widget.onScore(value);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Puan kaydedilemedi. Tekrar deneyin.')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 220,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Puan',
                  suffixText: '/ ${_formatScore(widget.maxScore)}',
                ),
                onSubmitted: (_) async {
                  final saved = await _save();
                  if (saved && mounted) FocusScope.of(context).nextFocus();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Puanı kaydet',
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
            ),
          ],
        ),
      );
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

String _formatNullableScore(double? value) => value == null ? '' : _formatScore(value);

String _formatScore(double value) =>
    value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
