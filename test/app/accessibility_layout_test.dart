import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/app/theme/app_theme.dart';
import 'package:olcerim/features/evaluations/presentation/gradebook_layout_metrics.dart';

void main() {
  test('gradebook keeps base geometry at normal text scale', () {
    const scaler = TextScaler.linear(1);

    expect(
      GradebookLayoutMetrics.headerHeight(scaler),
      GradebookLayoutMetrics.baseHeaderHeight,
    );
    expect(
      GradebookLayoutMetrics.rowHeight(scaler),
      GradebookLayoutMetrics.baseRowHeight,
    );
  });

  test('gradebook rows grow with large accessibility text', () {
    const scaler = TextScaler.linear(2);

    expect(
      GradebookLayoutMetrics.headerHeight(scaler),
      greaterThan(GradebookLayoutMetrics.baseHeaderHeight),
    );
    expect(
      GradebookLayoutMetrics.rowHeight(scaler),
      greaterThan(GradebookLayoutMetrics.baseRowHeight),
    );
  });

  test('light and dark themes enforce padded 48 dp controls', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);

      final iconMinimum = theme.iconButtonTheme.style?.minimumSize?.resolve({});
      final textMinimum = theme.textButtonTheme.style?.minimumSize?.resolve({});
      final filledMinimum = theme.filledButtonTheme.style?.minimumSize?.resolve({});
      final outlinedMinimum = theme.outlinedButtonTheme.style?.minimumSize?.resolve({});

      expect(iconMinimum?.width, greaterThanOrEqualTo(48));
      expect(iconMinimum?.height, greaterThanOrEqualTo(48));
      expect(textMinimum?.width, greaterThanOrEqualTo(48));
      expect(textMinimum?.height, greaterThanOrEqualTo(48));
      expect(filledMinimum?.height, greaterThanOrEqualTo(48));
      expect(outlinedMinimum?.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('large system text does not collapse the primary button target', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () {},
              child: const Text('İlk sınıfımı oluştur'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
  });
}
