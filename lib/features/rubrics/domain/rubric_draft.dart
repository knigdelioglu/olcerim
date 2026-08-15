class RubricDraft {
  RubricDraft({this.id, this.title = '', this.description = '', List<CriterionDraft>? criteria})
      : criteria = criteria ?? [];
  int? id;
  String title;
  String description;
  List<CriterionDraft> criteria;

  double get totalScore => criteria.fold(0, (sum, item) => sum + item.maxScore);
  bool get hasLevels => criteria.any((item) => item.levels.isNotEmpty);
}

class CriterionDraft {
  CriterionDraft({this.id, this.title = '', this.description = '', this.maxScore = 10, List<LevelDraft>? levels})
      : levels = levels ?? [];
  int? id;
  String title;
  String description;
  double maxScore;
  List<LevelDraft> levels;
}

class LevelDraft {
  LevelDraft({this.id, this.label = '', this.description = '', this.score = 0});
  int? id;
  String label;
  String description;
  double score;
}
