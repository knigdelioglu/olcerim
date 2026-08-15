import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';

void main() {
  test('criterion ratio max puana göre normalize edilir', () {
    const result = CriterionResult(criterionId: 1, title: 'İçerik', maxScore: 20, average: 15, scoredCount: 3);
    expect(result.ratio, 0.75);
  });

  test('criterion ratio 1 üzerinde taşmaz', () {
    const result = CriterionResult(criterionId: 1, title: 'İçerik', maxScore: 20, average: 25, scoredCount: 3);
    expect(result.ratio, 1);
  });
}
