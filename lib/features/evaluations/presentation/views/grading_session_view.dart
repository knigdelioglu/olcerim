import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/app/layout/app_breakpoints.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/evaluation_dao.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';
import 'package:olcerim/features/evaluations/presentation/gradebook_keyboard_navigation.dart';
import 'package:olcerim/features/evaluations/presentation/views/assessment_results_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/evaluation_notes_sheet.dart';
import 'package:olcerim/features/evaluations/presentation/views/score_picker.dart';

class GradingSessionView extends ConsumerStatefulWidget {
  const GradingSessionView({required this.assessmentId, super.key});
  final int assessmentId;

  @override
  ConsumerState<GradingSessionView> createState() => _GradingSessionViewState();
}

class _GradingSessionViewState extends ConsumerState<GradingSessionView> {
  int selectedIndex = 0;
  String filter = 'all';
  bool saving = false;
  Timer? noteDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(assessmentRepositoryProvider).setStatus(widget.assessmentId, AssessmentStatus.active),
    );
  }

  @override
  void dispose() {
    noteDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(assessmentDetailProvider(widget.assessmentId));
    final students = ref.watch(assessmentStudentsProvider(widget.assessmentId));
    final criteria = ref.watch(assessmentCriteriaProvider(widget.assessmentId));
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.valueOrNull?.assessment.title ?? 'Değerlendirme'),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                saving ? 'Kaydediliyor…' : 'Kaydedildi',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: students.when(
        data: (allStudents) {
          final visible = _filter(allStudents);
          if (visible.isEmpty) return const Center(child: Text('Bu filtrede öğrenci yok.'));
          if (selectedIndex >= visible.length) selectedIndex = visible.length - 1;
          final criteriaItems = criteria.valueOrNull ?? const <RubricCriterion>[];
          return LayoutBuilder(
            builder: (context, constraints) {
              final layout = AppBreakpoints.ofWidth(constraints.maxWidth);
              return layout == AppLayoutClass.compact
                  ? _CompactGrading(
                      assessmentId: widget.assessmentId,
                      students: visible,
                      criteria: criteriaItems,
                      selectedIndex: selectedIndex,
                      filter: filter,
                      onFilter: (value) => setState(() {
                        filter = value;
                        selectedIndex = 0;
                      }),
                      onIndex: (value) => setState(() => selectedIndex = value),
                      onSaving: _setSaving,
                      onNoteChanged: _saveNoteDebounced,
                    )
                  : _Gradebook(
                      students: visible,
                      criteria: criteriaItems,
                      filter: filter,
                      onFilter: (value) => setState(() => filter = value),
                      onSaving: _setSaving,
                    );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Değerlendirme oturumu yüklenemedi.')),
      ),
    );
  }

  List<EvaluationStudentRow> _filter(List<EvaluationStudentRow> rows) =>
      filter == 'all' ? rows : rows.where((row) => row.evaluation.status == filter).toList();

  void _setSaving(bool value) {
    if (mounted) setState(() => saving = value);
  }

  void _saveNoteDebounced(int evaluationId, String value) {
    noteDebounce?.cancel();
    noteDebounce = Timer(const Duration(milliseconds: 550), () async {
      _setSaving(true);
      try {
        await ref.read(evaluationRepositoryProvider).saveStudentNote(evaluationId, value);
      } finally {
        _setSaving(false);
      }
    });
  }
}

class _CompactGrading extends ConsumerWidget {
  const _CompactGrading({
    required this.assessmentId,
    required this.students,
    required this.criteria,
    required this.selectedIndex,
    required this.filter,
    required this.onFilter,
    required this.onIndex,
    required this.onSaving,
    required this.onNoteChanged,
  });
  final int assessmentId;
  final List<EvaluationStudentRow> students;
  final List<RubricCriterion> criteria;
  final int selectedIndex;
  final String filter;
  final ValueChanged<String> onFilter;
  final ValueChanged<int> onIndex;
  final ValueChanged<bool> onSaving;
  final void Function(int, String) onNoteChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = students[selectedIndex];
    final entries = ref.watch(evaluationEntriesProvider(row.evaluation.id)).valueOrNull ??
        const <EvaluationEntry>[];
    final byCriterion = {for (final entry in entries) entry.criterionId: entry};
    return Column(
      children: [
        LinearProgressIndicator(
          value: students.isEmpty ? 0 : (selectedIndex + 1) / students.length,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(child: Text('${selectedIndex + 1} / ${students.length}')),
              _FilterMenu(value: filter, onChanged: onFilter),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.student.schoolNumber ?? '—', style: Theme.of(context).textTheme.bodyMedium),
                        Text(row.student.fullName, style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _EvaluationStatusChip(status: row.evaluation.status),
                      TextButton.icon(
                        onPressed: () => showObservationNotesSheet(context, row.evaluation.id),
                        icon: const Icon(Icons.notes, size: 18),
                        label: const Text('Gözlemler'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...criteria.map((criterion) {
                final entry = byCriterion[criterion.id];
                final levels = ref.watch(criterionLevelsProvider(criterion.id)).valueOrNull ??
                    const <RubricLevel>[];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _CriterionCard(
                    criterion: criterion,
                    levels: levels,
                    score: entry?.score,
                    note: entry?.note,
                    onNote: entry == null
                        ? null
                        : () => showCriterionNoteDialog(
                              context: context,
                              ref: ref,
                              evaluationId: row.evaluation.id,
                              criterionId: criterion.id,
                              currentNote: entry.note,
                            ),
                    onScore: (score) async {
                      onSaving(true);
                      try {
                        await ref.read(evaluationRepositoryProvider).score(
                              evaluationId: row.evaluation.id,
                              criterionId: criterion.id,
                              score: score,
                            );
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Puan kaydedilemedi. Tekrar deneyin.')),
                          );
                        }
                      } finally {
                        onSaving(false);
                      }
                    },
                  ),
                );
              }),
              TextField(
                key: ValueKey(row.evaluation.id),
                controller: TextEditingController(text: row.evaluation.note ?? ''),
                decoration: const InputDecoration(labelText: 'Öğretmen notu'),
                minLines: 3,
                maxLines: 6,
                onChanged: (value) => onNoteChanged(row.evaluation.id, value),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedIndex == 0 ? null : () => onIndex(selectedIndex - 1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Önceki'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: selectedIndex >= students.length - 1
                        ? null
                        : () => onIndex(selectedIndex + 1),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Sonraki'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CriterionCard extends StatelessWidget {
  const _CriterionCard({
    required this.criterion,
    required this.levels,
    required this.score,
    required this.note,
    required this.onScore,
    required this.onNote,
  });
  final RubricCriterion criterion;
  final List<RubricLevel> levels;
  final double? score;
  final String? note;
  final ValueChanged<double> onScore;
  final VoidCallback? onNote;

  @override
  Widget build(BuildContext context) {
    final value = score?.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '') ?? '—';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(criterion.title, style: Theme.of(context).textTheme.titleMedium)),
                Text('$value / ${criterion.maxScore.toStringAsFixed(1).replaceFirst('.0', '')}'),
              ],
            ),
            if (criterion.description != null) ...[
              const SizedBox(height: 4),
              Text(criterion.description!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            if (levels.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: levels
                    .map(
                      (level) => ChoiceChip(
                        selected: score == level.score,
                        label: Text(level.label),
                        onSelected: (_) => onScore(level.score),
                      ),
                    )
                    .toList(),
              )
            else
              FilledButton.tonal(
                onPressed: () async {
                  final picked = await showModalBottomSheet<double>(
                    context: context,
                    showDragHandle: true,
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: ScorePicker(
                        criterion: criterion,
                        levels: levels,
                        currentScore: score,
                      ),
                    ),
                  );
                  if (picked != null) onScore(picked);
                },
                child: Text(score == null ? 'Puan ver' : 'Puanı değiştir'),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onNote,
              icon: Icon(note == null || note!.isEmpty ? Icons.note_add_outlined : Icons.sticky_note_2_outlined),
              label: Text(note == null || note!.isEmpty ? 'Kriter notu ekle' : 'Kriter notunu düzenle'),
            ),
            if (note != null && note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(note!, style: Theme.of(context).textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}

class _Gradebook extends ConsumerStatefulWidget {
  const _Gradebook({
    required this.students,
    required this.criteria,
    required this.filter,
    required this.onFilter,
    required this.onSaving,
  });

  final List<EvaluationStudentRow> students;
  final List<RubricCriterion> criteria;
  final String filter;
  final ValueChanged<String> onFilter;
  final ValueChanged<bool> onSaving;

  @override
  ConsumerState<_Gradebook> createState() => _GradebookState();
}

class _GradebookState extends ConsumerState<_Gradebook> {
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void didUpdateWidget(covariant _Gradebook oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pruneFocusNodes();
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  String _cellKey(int rowIndex, int columnIndex) =>
      '${widget.students[rowIndex].evaluation.id}:${widget.criteria[columnIndex].id}';

  FocusNode _focusNodeFor(int rowIndex, int columnIndex) {
    final key = _cellKey(rowIndex, columnIndex);
    return _focusNodes.putIfAbsent(
      key,
      () => FocusNode(debugLabel: 'gradebook-score-$key'),
    );
  }

  void _pruneFocusNodes() {
    final validKeys = <String>{
      for (var row = 0; row < widget.students.length; row++)
        for (var column = 0; column < widget.criteria.length; column++) _cellKey(row, column),
    };
    final staleKeys = _focusNodes.keys.where((key) => !validKeys.contains(key)).toList();
    for (final key in staleKeys) {
      _focusNodes.remove(key)?.dispose();
    }
  }

  void _handleNavigation(
    GradebookCellPosition current,
    GradebookKeyboardCommand command,
  ) {
    final next = moveGradebookCell(
      current: current,
      command: command,
      rowCount: widget.students.length,
      columnCount: widget.criteria.length,
    );
    if (next == current) return;

    final node = _focusNodeFor(next.row, next.column);
    node.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = node.context;
      if (targetContext == null) return;
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 120),
          alignment: 0.5,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const nameWidth = 280.0;
    const cellWidth = 148.0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.students.length} öğrenci',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.criteria.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message:
                        'Klavye: Tab ile puan hücresine geçin; ok tuşlarıyla hareket edin; '
                        'Home/End ile satırın başına/sonuna gidin; Enter veya Space ile puanlayın.',
                    child: const Semantics(
                      label: 'Klavye kısayolları bilgisi',
                      child: Icon(Icons.keyboard_alt_outlined),
                    ),
                  ),
                ),
              _FilterMenu(value: widget.filter, onChanged: widget.onFilter),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: nameWidth,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 52,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Align(alignment: Alignment.centerLeft, child: Text('Öğrenci')),
                        ),
                      ),
                      ...widget.students.map((row) => _StudentNameCell(row: row)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 52,
                          child: Row(
                            children: [
                              ...widget.criteria.map(
                                (criterion) => SizedBox(
                                  width: cellWidth,
                                  child: Center(
                                    child: Text(criterion.title, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 100, child: Center(child: Text('Toplam'))),
                            ],
                          ),
                        ),
                        ...widget.students.asMap().entries.map(
                              (studentEntry) => _ScoreRow(
                                rowIndex: studentEntry.key,
                                row: studentEntry.value,
                                criteria: widget.criteria,
                                cellWidth: cellWidth,
                                focusNodeFor: (columnIndex) =>
                                    _focusNodeFor(studentEntry.key, columnIndex),
                                onKeyboardCommand: (columnIndex, command) => _handleNavigation(
                                  GradebookCellPosition(
                                    row: studentEntry.key,
                                    column: columnIndex,
                                  ),
                                  command,
                                ),
                                onSaving: widget.onSaving,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentNameCell extends StatelessWidget {
  const _StudentNameCell({required this.row});
  final EvaluationStudentRow row;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            children: [
              SizedBox(width: 24, child: _StatusIcon(status: row.evaluation.status)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.student.fullName, overflow: TextOverflow.ellipsis),
                    if (row.student.schoolNumber != null)
                      Text(row.student.schoolNumber!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Gözlem notları',
                onPressed: () => showObservationNotesSheet(context, row.evaluation.id),
                icon: const Icon(Icons.notes, size: 19),
              ),
            ],
          ),
        ),
      );
}

class _ScoreRow extends ConsumerWidget {
  const _ScoreRow({
    required this.rowIndex,
    required this.row,
    required this.criteria,
    required this.cellWidth,
    required this.focusNodeFor,
    required this.onKeyboardCommand,
    required this.onSaving,
  });

  final int rowIndex;
  final EvaluationStudentRow row;
  final List<RubricCriterion> criteria;
  final double cellWidth;
  final FocusNode Function(int columnIndex) focusNodeFor;
  final void Function(int columnIndex, GradebookKeyboardCommand command) onKeyboardCommand;
  final ValueChanged<bool> onSaving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(evaluationEntriesProvider(row.evaluation.id)).valueOrNull ??
        const <EvaluationEntry>[];
    final byCriterion = {for (final entry in entries) entry.criterionId: entry};
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.score);

    Future<void> editScore(RubricCriterion criterion, double? score) async {
      final levels = await ref.read(evaluationRepositoryProvider).levels(criterion.id);
      if (!context.mounted) return;
      final picked = await showDialog<double>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(criterion.title),
          content: SizedBox(
            width: 420,
            child: ScorePicker(
              criterion: criterion,
              levels: levels,
              currentScore: score,
            ),
          ),
        ),
      );
      if (picked == null) return;
      onSaving(true);
      try {
        await ref.read(evaluationRepositoryProvider).score(
              evaluationId: row.evaluation.id,
              criterionId: criterion.id,
              score: picked,
            );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Puan kaydedilemedi. Tekrar deneyin.')),
          );
        }
      } finally {
        onSaving(false);
      }
    }

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          ...criteria.asMap().entries.map((criterionEntry) {
            final columnIndex = criterionEntry.key;
            final criterion = criterionEntry.value;
            final entry = byCriterion[criterion.id];
            final score = entry?.score;
            final scoreText =
                score?.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '') ?? '—';
            return SizedBox(
              width: cellWidth,
              child: Row(
                children: [
                  Expanded(
                    child: _KeyboardScoreCell(
                      key: ValueKey(
                        'gradebook-score-${row.evaluation.id}-${criterion.id}',
                      ),
                      focusNode: focusNodeFor(columnIndex),
                      semanticLabel:
                          '${row.student.fullName}, ${criterion.title}, puan $scoreText. '
                          'Ok tuşlarıyla hareket edin; Enter veya Space ile puanlayın.',
                      scoreText: scoreText,
                      onActivate: () => editScore(criterion, score),
                      onCommand: (command) => onKeyboardCommand(columnIndex, command),
                    ),
                  ),
                  if (entry != null)
                    IconButton(
                      tooltip: 'Kriter notu',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => showCriterionNoteDialog(
                        context: context,
                        ref: ref,
                        evaluationId: row.evaluation.id,
                        criterionId: criterion.id,
                        currentNote: entry.note,
                      ),
                      icon: Icon(
                        entry.note == null || entry.note!.isEmpty
                            ? Icons.note_add_outlined
                            : Icons.sticky_note_2,
                        size: 18,
                      ),
                    ),
                ],
              ),
            );
          }),
          SizedBox(
            width: 100,
            child: Center(
              child: Text(total.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardScoreCell extends StatelessWidget {
  const _KeyboardScoreCell({
    required this.focusNode,
    required this.semanticLabel,
    required this.scoreText,
    required this.onActivate,
    required this.onCommand,
    super.key,
  });

  final FocusNode focusNode;
  final String semanticLabel;
  final String scoreText;
  final Future<void> Function() onActivate;
  final ValueChanged<GradebookKeyboardCommand> onCommand;

  @override
  Widget build(BuildContext context) => Focus(
        focusNode: focusNode,
        onKeyEvent: (_, event) {
          final command = gradebookCommandForKeyEvent(event);
          if (command == GradebookKeyboardCommand.none) {
            return KeyEventResult.ignored;
          }
          if (command == GradebookKeyboardCommand.activate) {
            unawaited(onActivate());
          } else {
            onCommand(command);
          }
          return KeyEventResult.handled;
        },
        child: Builder(
          builder: (context) {
            final focused = Focus.of(context).hasFocus;
            final colorScheme = Theme.of(context).colorScheme;
            return Semantics(
              button: true,
              focusable: true,
              focused: focused,
              label: semanticLabel,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: focused ? colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  canRequestFocus: false,
                  onTap: () => unawaited(onActivate()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Center(child: Text(scoreText)),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        initialValue: value,
        tooltip: 'Öğrenci filtresi',
        onSelected: onChanged,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'all', child: Text('Tümü')),
          PopupMenuItem(value: 'notStarted', child: Text('Değerlendirilmedi')),
          PopupMenuItem(value: 'incomplete', child: Text('Eksik')),
          PopupMenuItem(value: 'completed', child: Text('Tamamlandı')),
        ],
        child: const Chip(avatar: Icon(Icons.filter_list, size: 18), label: Text('Filtre')),
      );
}

class _EvaluationStatusChip extends StatelessWidget {
  const _EvaluationStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(
          switch (status) {
            'completed' => 'Tamamlandı',
            'incomplete' => 'Eksik',
            _ => 'Değerlendirilmedi',
          },
        ),
      );
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Icon(
        switch (status) {
          'completed' => Icons.check_circle,
          'incomplete' => Icons.warning_amber_rounded,
          _ => Icons.radio_button_unchecked,
        },
        size: 19,
        semanticLabel: switch (status) {
          'completed' => 'Tamamlandı',
          'incomplete' => 'Eksik',
          _ => 'Değerlendirilmedi',
        },
      );
}
