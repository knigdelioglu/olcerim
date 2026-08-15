import 'package:freezed_annotation/freezed_annotation.dart';

part 'evaluation_summary.freezed.dart';
part 'evaluation_summary.g.dart';

@freezed
abstract class EvaluationSummary with _$EvaluationSummary {
  const factory EvaluationSummary({
    required int studentId,
    required int rubricId,
    required double score,
    required double maxScore,
    required DateTime evaluatedAt,
  }) = _EvaluationSummary;

  factory EvaluationSummary.fromJson(Map<String, Object?> json) =>
      _$EvaluationSummaryFromJson(json);
}
