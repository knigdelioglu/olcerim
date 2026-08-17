import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/evaluations/domain/quick_scale.dart';
import 'package:olcerim/features/evaluations/presentation/views/grading_session_view.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<({int assessmentId, int firstEvaluationId, int criterionId})> fixture() async {
    final year = await db.schoolDao.activeSchoolYear();
    final classroomId = await db.schoolDao.saveClassroom(
      schoolYearId: year!.id,
      name: '10/A',
      courseName: 'Türk Dili ve Edebiyatı',
    );
    await db.studentDao.saveStudent(
      classroomId: classroomId,
      schoolNumber: '101',
      fullName: 'Ada Öğrenci',
    );
    await db.studentDao.saveStudent(
      classroomId: classroomId,
      schoolNumber: '102',
      fullName: 'Bora Öğrenci',
    );
    final assessmentId = await db.assessmentDao.createQuickScaleAssessment(
      classroomId: classroomId,
      preset: QuickScalePreset.numericFive,
      title: 'Ders içi hızlı değerlendirme',
      assessmentDate: DateTime(2026, 8, 16),
    );
    final evaluationsList = await (db.select(db.evaluations)
          ..where((row) => row.assessmentId.equals(assessmentId)))
        .get();
    final criterion = (await db.evaluationDao.criteriaForAssessment(assessmentId)).single;
    return (
      assessmentId: assessmentId,
      firstEvaluationId: evaluationsList.first.id,
      criterionId: criterion.id,
    );
  }

  Future<void> pumpSession(
    WidgetTester tester, {
    required Size size,
    required int assessmentId,
    required ProviderContainer container,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: GradingSessionView(assessmentId: assessmentId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone renders sequential compact grading flow', (tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });

    final data = await fixture();
    await pumpSession(
      tester,
      size: const Size(390, 844),
      assessmentId: data.assessmentId,
      container: container,
    );

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Ada Öğrenci'), findsOneWidget);
    expect(find.text('Önceki'), findsOneWidget);
    expect(find.text('Sonraki'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey(
          'gradebook-score-${data.firstEvaluationId}-${data.criterionId}',
        ),
      ),
      findsNothing,
    );
  });

  testWidgets('tablet and desktop widths render the gradebook', (tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });

    final data = await fixture();
    await pumpSession(
      tester,
      size: const Size(800, 1000),
      assessmentId: data.assessmentId,
      container: container,
    );

    expect(find.text('2 öğrenci'), findsOneWidget);
    expect(find.text('Öğrenci'), findsOneWidget);
    expect(find.text('Genel değerlendirme'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_alt_outlined), findsOneWidget);
    expect(
      find.byKey(
        ValueKey(
          'gradebook-score-${data.firstEvaluationId}-${data.criterionId}',
        ),
      ),
      findsOneWidget,
    );

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpAndSettle();

    expect(find.text('2 öğrenci'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_alt_outlined), findsOneWidget);
    expect(
      find.byKey(
        ValueKey(
          'gradebook-score-${data.firstEvaluationId}-${data.criterionId}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('resizing from phone to wide layout switches to gradebook without data loss',
      (tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await tester.pump(const Duration(milliseconds: 100));
    });

    final data = await fixture();
    await pumpSession(
      tester,
      size: const Size(390, 844),
      assessmentId: data.assessmentId,
      container: container,
    );

    expect(find.text('Ada Öğrenci'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1024, 900));
    await tester.pumpAndSettle();

    expect(find.text('2 öğrenci'), findsOneWidget);
    expect(find.text('Ada Öğrenci'), findsOneWidget);
    expect(find.text('Bora Öğrenci'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey(
          'gradebook-score-${data.firstEvaluationId}-${data.criterionId}',
        ),
      ),
      findsOneWidget,
    );
  });
}
