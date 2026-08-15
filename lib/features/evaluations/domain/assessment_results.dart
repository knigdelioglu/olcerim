import 'package:olcerim/core/database/app_database.dart';

class AssessmentResults {
  const AssessmentResults({
    required this.assessment,
    required this.classroom,
    required this.criteria,
    required this.students,
  });

  final Assessment assessment;
  final Classroom classroom;
  final List<CriterionResult> criteria;
  final List<StudentResult> students;

  int get completedCount => students.where((item) => item.status == 'completed').length;
  int get incompleteCount => students.length - completedCount;
  double get maxTotal => criteria.fold(0, (sum, item) => sum + item.maxScore);

  double get classAverage {
    final scored = students.where((item) => item.hasScore).toList();
    if (scored.isEmpty) return 0;
    return scored.fold<double>(0, (sum, item) => sum + item.total) / scored.length;
  }

  CriterionResult? get strongestCriterion {
    final scored = criteria.where((item) => item.scoredCount > 0 && item.maxScore > 0).toList();
    if (scored.isEmpty) return null;
    scored.sort((a, b) => b.ratio.compareTo(a.ratio));
    return scored.first;
  }

  CriterionResult? get growthCriterion {
    final scored = criteria.where((item) => item.scoredCount > 0 && item.maxScore > 0).toList();
    if (scored.isEmpty) return null;
    scored.sort((a, b) => a.ratio.compareTo(b.ratio));
    return scored.first;
  }
}

class CriterionResult {
  const CriterionResult({
    required this.criterionId,
    required this.title,
    required this.maxScore,
    required this.average,
    required this.scoredCount,
  });

  final int criterionId;
  final String title;
  final double maxScore;
  final double average;
  final int scoredCount;
  double get ratio => maxScore <= 0 ? 0 : (average / maxScore).clamp(0, 1);
}

class StudentResult {
  const StudentResult({
    required this.evaluationId,
    required this.student,
    required this.status,
    required this.note,
    required this.entries,
    required this.observations,
  });

  final int evaluationId;
  final Student student;
  final String status;
  final String? note;
  final List<StudentCriterionResult> entries;
  final List<ObservationNote> observations;

  bool get hasScore => entries.isNotEmpty;
  double get total => entries.fold(0, (sum, item) => sum + item.score);
  int get criterionNoteCount => entries.where((item) => item.note?.isNotEmpty == true).length;
}

class StudentCriterionResult {
  const StudentCriterionResult({
    required this.criterionId,
    required this.title,
    required this.score,
    required this.maxScore,
    required this.note,
  });

  final int criterionId;
  final String title;
  final double score;
  final double maxScore;
  final String? note;
}
