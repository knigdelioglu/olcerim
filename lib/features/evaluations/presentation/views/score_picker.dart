import 'package:flutter/material.dart';
import 'package:olcerim/core/database/app_database.dart';

class ScorePicker extends StatefulWidget {
  const ScorePicker({required this.criterion, required this.levels, this.currentScore, super.key});
  final RubricCriterion criterion;
  final List<RubricLevel> levels;
  final double? currentScore;

  @override
  State<ScorePicker> createState() => _ScorePickerState();
}

class _ScorePickerState extends State<ScorePicker> {
  late final TextEditingController controller = TextEditingController(text: widget.currentScore?.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '') ?? '');

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.levels.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.levels
            .map((level) => ChoiceChip(
                  selected: widget.currentScore == level.score,
                  label: Text('${level.label} · ${_score(level.score)}'),
                  onSelected: (_) => Navigator.pop(context, level.score),
                ))
            .toList(),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Puan', suffixText: '/ ${_score(widget.criterion.maxScore)}'),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(onPressed: _submit, child: const Text('Uygula')),
      ],
    );
  }

  void _submit() {
    final value = double.tryParse(controller.text.replaceAll(',', '.'));
    if (value == null || value < 0 || value > widget.criterion.maxScore) return;
    Navigator.pop(context, value);
  }

  String _score(double value) => value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}
