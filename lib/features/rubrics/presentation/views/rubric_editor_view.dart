import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/features/rubrics/domain/rubric_draft.dart';
import 'package:olcerim/features/rubrics/presentation/controllers/rubric_providers.dart';

class RubricEditorView extends ConsumerStatefulWidget {
  const RubricEditorView({this.rubricId, super.key}); final int? rubricId;
  @override ConsumerState<RubricEditorView> createState() => _RubricEditorViewState();
}

class _RubricEditorViewState extends ConsumerState<RubricEditorView> {
  RubricDraft draft = RubricDraft(criteria: [CriterionDraft(title: 'Kriter 1', maxScore: 10)]);
  bool loaded = false; bool advanced = false; bool saving = false;
  final title = TextEditingController(); final description = TextEditingController();

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }
  Future<void> _load() async {
    if (loaded) return; loaded = true;
    if (widget.rubricId != null) {
      final value = await ref.read(rubricRepositoryProvider).load(widget.rubricId!);
      if (value != null && mounted) setState(() { draft = value; title.text = value.title; description.text = value.description; advanced = value.hasLevels; });
    }
  }
  @override void dispose() { title.dispose(); description.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    draft.title = title.text; draft.description = description.text;
    return Scaffold(
      appBar: AppBar(title: Text(widget.rubricId == null ? 'Yeni rubrik' : 'Rubriği düzenle'), actions: [Padding(padding: const EdgeInsets.only(right: 12), child: Chip(label: Text('Toplam: ${_score(draft.totalScore)} puan')))]),
      body: Align(alignment: Alignment.topCenter, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: AppConstants.readingMaxWidth), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Rubrik adı'), onChanged: (_) => setState(() {})), const SizedBox(height: 12),
        TextField(controller: description, decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'), minLines: 2, maxLines: 4, onChanged: (_) => setState(() {})), const SizedBox(height: 16),
        SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Basit')), ButtonSegment(value: true, label: Text('Gelişmiş'))], selected: {advanced}, onSelectionChanged: (values) => setState(() => advanced = values.first)), const SizedBox(height: 20),
        ...List.generate(draft.criteria.length, (index) => _CriterionEditor(index: index, criterion: draft.criteria[index], advanced: advanced, onChanged: () => setState(() {}), onMoveUp: index == 0 ? null : () => setState(() { final item = draft.criteria.removeAt(index); draft.criteria.insert(index - 1, item); }), onMoveDown: index == draft.criteria.length - 1 ? null : () => setState(() { final item = draft.criteria.removeAt(index); draft.criteria.insert(index + 1, item); }), onRemove: draft.criteria.length == 1 ? null : () => setState(() => draft.criteria.removeAt(index)))),
        FilledButton.tonalIcon(onPressed: () => setState(() => draft.criteria.add(CriterionDraft(title: 'Yeni kriter', maxScore: 10))), icon: const Icon(Icons.add), label: const Text('Kriter ekle')),
      ])))),
      bottomNavigationBar: SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('İptal')), const SizedBox(width: 8), FilledButton(onPressed: saving ? null : _save, child: Text(saving ? 'Kaydediliyor…' : 'Rubriği kaydet'))]))),
    );
  }

  Future<void> _save() async {
    draft.title = title.text; draft.description = description.text;
    setState(() => saving = true);
    try { await ref.read(rubricRepositoryProvider).save(draft); if (mounted) Navigator.pop(context); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error is ArgumentError ? error.message?.toString() ?? 'Rubrik geçerli değil.' : 'Rubrik kaydedilemedi.'))); }
    finally { if (mounted) setState(() => saving = false); }
  }
  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

class _CriterionEditor extends StatelessWidget {
  const _CriterionEditor({required this.index, required this.criterion, required this.advanced, required this.onChanged, this.onMoveUp, this.onMoveDown, this.onRemove});
  final int index; final CriterionDraft criterion; final bool advanced; final VoidCallback onChanged; final VoidCallback? onMoveUp; final VoidCallback? onMoveDown; final VoidCallback? onRemove;
  @override Widget build(BuildContext context) {
    final name = TextEditingController(text: criterion.title); final desc = TextEditingController(text: criterion.description); final max = TextEditingController(text: criterion.maxScore.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), ''));
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Text('${index + 1}.', style: Theme.of(context).textTheme.titleMedium), const Spacer(), IconButton(tooltip: 'Yukarı taşı', onPressed: onMoveUp, icon: const Icon(Icons.arrow_upward)), IconButton(tooltip: 'Aşağı taşı', onPressed: onMoveDown, icon: const Icon(Icons.arrow_downward)), IconButton(tooltip: 'Kriteri kaldır', onPressed: onRemove, icon: const Icon(Icons.remove_circle_outline))]),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Kriter adı'), onChanged: (v) { criterion.title = v; onChanged(); }), const SizedBox(height: 10),
      TextField(controller: max, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Maksimum puan'), onChanged: (v) { final parsed = double.tryParse(v.replaceAll(',', '.')); if (parsed != null) criterion.maxScore = parsed; onChanged(); }), const SizedBox(height: 10),
      TextField(controller: desc, decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'), onChanged: (v) { criterion.description = v; onChanged(); }),
      if (advanced) ...[const SizedBox(height: 14), Text('Performans seviyeleri', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), ...List.generate(criterion.levels.length, (i) => _LevelEditor(level: criterion.levels[i], onChanged: onChanged, onRemove: () { criterion.levels.removeAt(i); onChanged(); })), FilledButton.tonalIcon(onPressed: () { final nextScore = criterion.levels.isEmpty ? criterion.maxScore : (criterion.maxScore - criterion.levels.length).clamp(0, criterion.maxScore).toDouble(); criterion.levels.add(LevelDraft(label: 'Seviye ${criterion.levels.length + 1}', score: nextScore)); onChanged(); }, icon: const Icon(Icons.add), label: const Text('Seviye ekle'))],
    ])));
  }
}

class _LevelEditor extends StatelessWidget {
  const _LevelEditor({required this.level, required this.onChanged, required this.onRemove}); final LevelDraft level; final VoidCallback onChanged; final VoidCallback onRemove;
  @override Widget build(BuildContext context) {
    final label = TextEditingController(text: level.label); final desc = TextEditingController(text: level.description); final score = TextEditingController(text: level.score.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), ''));
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 2, child: TextField(controller: label, decoration: const InputDecoration(labelText: 'Seviye'), onChanged: (v) { level.label = v; onChanged(); })), const SizedBox(width: 8), Expanded(child: TextField(controller: score, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Puan'), onChanged: (v) { final parsed = double.tryParse(v.replaceAll(',', '.')); if (parsed != null) level.score = parsed; onChanged(); })), const SizedBox(width: 8), Expanded(flex: 3, child: TextField(controller: desc, decoration: const InputDecoration(labelText: 'Açıklama'), onChanged: (v) { level.description = v; onChanged(); })), IconButton(tooltip: 'Seviyeyi kaldır', onPressed: onRemove, icon: const Icon(Icons.close))]));
  }
}
