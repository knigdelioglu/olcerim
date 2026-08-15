enum AssessmentType {
  rubric('rubric', 'Rubrik'),
  quickScale('quickScale', 'Hızlı derecelendirme');

  const AssessmentType(this.storageValue, this.label);
  final String storageValue;
  final String label;

  static AssessmentType fromStorage(String value) {
    return values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => AssessmentType.rubric,
    );
  }
}

enum AssessmentStatus {
  draft('draft', 'Taslak'),
  active('active', 'Devam ediyor'),
  completed('completed', 'Tamamlandı');

  const AssessmentStatus(this.storageValue, this.label);
  final String storageValue;
  final String label;
}

enum EvaluationStatus {
  notStarted('notStarted', 'Değerlendirilmedi'),
  incomplete('incomplete', 'Eksik'),
  completed('completed', 'Tamamlandı');

  const EvaluationStatus(this.storageValue, this.label);
  final String storageValue;
  final String label;
}
