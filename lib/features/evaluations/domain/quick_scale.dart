class QuickScalePreset {
  const QuickScalePreset({
    required this.id,
    required this.label,
    required this.description,
    required this.levels,
  });

  final String id;
  final String label;
  final String description;
  final List<QuickScaleLevelDefinition> levels;

  double get maxScore => levels.fold<double>(0, (max, level) => level.score > max ? level.score : max);

  static const numericFive = QuickScalePreset(
    id: 'numeric-5',
    label: '1–5',
    description: 'Beş basamaklı hızlı puanlama. 1 en düşük, 5 en yüksek düzeydir.',
    levels: [
      QuickScaleLevelDefinition(label: '1', score: 1),
      QuickScaleLevelDefinition(label: '2', score: 2),
      QuickScaleLevelDefinition(label: '3', score: 3),
      QuickScaleLevelDefinition(label: '4', score: 4),
      QuickScaleLevelDefinition(label: '5', score: 5),
    ],
  );

  static const descriptiveFour = QuickScalePreset(
    id: 'descriptive-4',
    label: 'Yetersiz → Çok iyi',
    description: 'Dört düzeyli sözel ölçek; ders sırasında tek dokunuşla derecelendirme için uygundur.',
    levels: [
      QuickScaleLevelDefinition(label: 'Yetersiz', score: 1),
      QuickScaleLevelDefinition(label: 'Geliştirilmeli', score: 2),
      QuickScaleLevelDefinition(label: 'İyi', score: 3),
      QuickScaleLevelDefinition(label: 'Çok iyi', score: 4),
    ],
  );

  static const progressThree = QuickScalePreset(
    id: 'progress-3',
    label: 'Başlangıç → Yetkin',
    description: 'Üç düzeyli gelişim ölçeği: Başlangıç, Gelişiyor ve Yetkin.',
    levels: [
      QuickScaleLevelDefinition(label: 'Başlangıç', score: 1),
      QuickScaleLevelDefinition(label: 'Gelişiyor', score: 2),
      QuickScaleLevelDefinition(label: 'Yetkin', score: 3),
    ],
  );

  static const values = [numericFive, descriptiveFour, progressThree];

  static QuickScalePreset byId(String id) => values.firstWhere(
        (preset) => preset.id == id,
        orElse: () => descriptiveFour,
      );
}

class QuickScaleLevelDefinition {
  const QuickScaleLevelDefinition({required this.label, required this.score});

  final String label;
  final double score;
}
