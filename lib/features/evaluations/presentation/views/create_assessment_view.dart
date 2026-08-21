import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/school_dao.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';
import 'package:olcerim/features/evaluations/domain/assessment_type.dart';
import 'package:olcerim/features/evaluations/domain/quick_scale.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';
import 'package:olcerim/features/evaluations/presentation/views/grading_session_view.dart';
import 'package:olcerim/features/evaluations/presentation/views/quick_scale_grading_view.dart';
import 'package:olcerim/features/rubrics/presentation/controllers/rubric_providers.dart';
import 'package:olcerim/features/rubrics/presentation/views/rubric_editor_view.dart';

final availableRubricsProvider = StreamProvider<List<Rubric>>(
  (ref) => ref.watch(rubricRepositoryProvider).watchAllRubrics(),
);

class CreateAssessmentView extends ConsumerStatefulWidget {
  const CreateAssessmentView({this.initialClassroomId, super.key});
  final int? initialClassroomId;

  @override
  ConsumerState<CreateAssessmentView> createState() => _CreateAssessmentViewState();
}

class _CreateAssessmentViewState extends ConsumerState<CreateAssessmentView> {
  int step = 0;
  int? classroomId;
  int? rubricId;
  String quickScalePresetId = QuickScalePreset.descriptiveFour.id;
  AssessmentType type = AssessmentType.rubric;
  final title = TextEditingController();
  final description = TextEditingController();
  DateTime date = DateTime.now();
  bool saving = false;
  bool showPastYears = false;

  @override
  void initState() {
    super.initState();
    classroomId = widget.initialClassroomId;
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allClassrooms = ref.watch(classroomsProvider(null)).valueOrNull ?? const <ClassroomSummaryRow>[];
    final activeYear = ref.watch(activeSchoolYearProvider).valueOrNull;
    final rubrics = ref.watch(availableRubricsProvider).valueOrNull ?? const <Rubric>[];
    final selectedClassroom = _findClassroom(allClassrooms, classroomId);
    final selectedIsOutsideActiveYear = activeYear != null &&
        selectedClassroom != null &&
        selectedClassroom.schoolYear.id != activeYear.id;
    final useAllYears = showPastYears || selectedIsOutsideActiveYear || activeYear == null;
    final classrooms = useAllYears
        ? allClassrooms
        : allClassrooms.where((item) => item.schoolYear.id == activeYear.id).toList();
    final hasPastYears = activeYear != null &&
        allClassrooms.any((item) => item.schoolYear.id != activeYear.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni değerlendirme')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Stepper(
            currentStep: step,
            onStepContinue: () => step == 3 ? _save() : setState(() => step++),
            onStepCancel: step == 0 ? null : () => setState(() => step--),
            controlsBuilder: (context, details) => Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: saving || !_canContinue ? null : details.onStepContinue,
                    child: Text(step == 3 ? 'Oluştur ve puanlamaya başla' : 'Devam'),
                  ),
                  if (step > 0) ...[
                    const SizedBox(width: 8),
                    TextButton(onPressed: details.onStepCancel, child: const Text('Geri')),
                  ],
                ],
              ),
            ),
            steps: [
              Step(
                title: const Text('Sınıf'),
                isActive: step >= 0,
                content: _classrooms(
                  classrooms: classrooms,
                  activeYear: activeYear,
                  hasPastYears: hasPastYears,
                ),
              ),
              Step(
                title: const Text('Değerlendirme tipi'),
                isActive: step >= 1,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<AssessmentType>(
                      segments: AssessmentType.values
                          .map(
                            (item) => ButtonSegment(
                              value: item,
                              label: Text(item.label),
                              icon: Icon(item == AssessmentType.rubric ? Icons.rule : Icons.speed),
                            ),
                          )
                          .toList(),
                      selected: {type},
                      onSelectionChanged: (values) => setState(() {
                        type = values.first;
                        if (type == AssessmentType.quickScale) rubricId = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      type == AssessmentType.rubric
                          ? 'Birden fazla kriteri ayrı ayrı puanlamak için Rubrik kullanın.'
                          : 'Her öğrenciye tek bir genel puan veya düzey vermek için Hızlı Derecelendirme kullanın.',
                    ),
                  ],
                ),
              ),
              Step(
                title: Text(type == AssessmentType.rubric ? 'Rubrik' : 'Hızlı ölçek'),
                isActive: step >= 2,
                content: type == AssessmentType.rubric
                    ? _rubrics(context, rubrics)
                    : _quickScales(),
              ),
              Step(title: const Text('Detay'), isActive: step >= 3, content: _details()),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canContinue => switch (step) {
        0 => classroomId != null,
        1 => true,
        2 => type == AssessmentType.rubric ? rubricId != null : quickScalePresetId.isNotEmpty,
        _ => title.text.trim().isNotEmpty,
      };

  Widget _classrooms({
    required List<ClassroomSummaryRow> classrooms,
    required SchoolYear? activeYear,
    required bool hasPastYears,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeYear != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Aktif eğitim yılı: ${activeYear.label}'),
          ),
        if (classrooms.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Bu eğitim yılında değerlendirilecek aktif sınıf bulunmuyor.'),
          ),
        RadioGroup<int>(
          groupValue: classroomId,
          onChanged: (value) => setState(() => classroomId = value),
          child: Column(
            children: classrooms
                .map(
                  (item) => RadioListTile<int>(
                    value: item.classroom.id,
                    title: Text(item.classroom.name),
                    subtitle: Text('${item.course.name} · ${item.schoolYear.label}'),
                    secondary: item.schoolYear.isActive
                        ? const Tooltip(message: 'Aktif eğitim yılı', child: Icon(Icons.check_circle_outline))
                        : null,
                  ),
                )
                .toList(),
          ),
        ),
        if (hasPastYears)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: showPastYears,
            onChanged: (value) => setState(() => showPastYears = value ?? false),
            title: const Text('Geçmiş eğitim yıllarındaki sınıfları da göster'),
          ),
      ],
    );
  }

  Widget _rubrics(BuildContext context, List<Rubric> items) => RadioGroup<int>(
        groupValue: rubricId,
        onChanged: (value) => setState(() => rubricId = value),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Henüz rubrik yok. Önce bir rubrik oluşturun.'),
              ),
            ...items.map(
              (item) => RadioListTile<int>(
                value: item.id,
                title: Text(item.title),
                subtitle: item.description == null ? null : Text(item.description!),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RubricEditorView()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni rubrik oluştur'),
              ),
            ),
          ],
        ),
      );

  Widget _quickScales() => RadioGroup<String>(
        groupValue: quickScalePresetId,
        onChanged: (value) => setState(() {
          if (value != null) quickScalePresetId = value;
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: QuickScalePreset.values
              .map(
                (preset) => Card(
                  child: RadioListTile<String>(
                    value: preset.id,
                    title: Text(preset.label),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(preset.description),
                          const SizedBox(height: 8),
                          if (preset.usesNumericInput)
                            Chip(label: Text('0–${_scoreLabel(preset.maxScore)} puan'))
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: preset.levels
                                  .map((level) => Chip(label: Text(level.label)))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );

  Widget _details() => Column(
        children: [
          TextField(
            controller: title,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Değerlendirme adı'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Tarih'),
            subtitle: Text('${date.day}.${date.month}.${date.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
        ],
      );

  ClassroomSummaryRow? _findClassroom(List<ClassroomSummaryRow> items, int? id) {
    if (id == null) return null;
    for (final item in items) {
      if (item.classroom.id == id) return item;
    }
    return null;
  }

  String _scoreLabel(double value) =>
      value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (selected != null) setState(() => date = selected);
  }

  Future<void> _save() async {
    if (!_canContinue || classroomId == null) return;
    setState(() => saving = true);
    try {
      final repository = ref.read(assessmentRepositoryProvider);
      final id = type == AssessmentType.quickScale
          ? await repository.createQuickScale(
              classroomId: classroomId!,
              preset: QuickScalePreset.byId(quickScalePresetId),
              title: title.text,
              description: description.text,
              assessmentDate: date,
            )
          : await repository.create(
              classroomId: classroomId!,
              rubricId: rubricId!,
              type: AssessmentType.rubric,
              title: title.text,
              description: description.text,
              assessmentDate: date,
            );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => type == AssessmentType.quickScale
              ? QuickScaleGradingView(assessmentId: id)
              : GradingSessionView(assessmentId: id),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Değerlendirme oluşturulamadı.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
