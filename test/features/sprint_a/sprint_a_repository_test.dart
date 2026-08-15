import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/features/classrooms/data/classroom_repository.dart';
import 'package:olcerim/features/onboarding/data/onboarding_repository.dart';
import 'package:olcerim/features/students/data/student_repository.dart';

void main() {
  late AppDatabase db;
  late ClassroomRepository classrooms;
  late StudentRepository students;
  late OnboardingRepository onboarding;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    classrooms = ClassroomRepository(db);
    students = StudentRepository(db);
    onboarding = OnboardingRepository(db);
  });

  tearDown(() => db.close());

  test('fresh install remains in onboarding until setup is completed', () async {
    expect(await onboarding.hasCompleted(), isFalse);
  });

  test('archiving the last classroom never reopens onboarding', () async {
    final year = await classrooms.activeSchoolYear();
    final classroomId = await classrooms.createClassroom(
      schoolYearId: year!.id,
      name: '10/A',
      courseName: 'Türk Dili ve Edebiyatı',
    );

    // Existing installs without the new persistent flag are migrated lazily.
    expect(await onboarding.hasCompleted(), isTrue);
    expect(await db.getSetting(OnboardingRepository.completedKey), 'true');

    await classrooms.setArchived(classroomId, true);
    expect(await classrooms.watchClassrooms().first, isEmpty);
    expect(await onboarding.hasCompleted(), isTrue);
  });

  test('education year can be created and made canonical active year', () async {
    final id = await classrooms.createSchoolYear(
      label: '2027–2028',
      startsAt: DateTime(2027, 9, 1),
      endsAt: DateTime(2028, 8, 31),
      makeActive: true,
    );

    final active = await classrooms.activeSchoolYear();
    expect(active?.id, id);
    expect(active?.label, '2027–2028');
  });

  test('classroom can be edited after creation', () async {
    final year = await classrooms.activeSchoolYear();
    final id = await classrooms.createClassroom(
      schoolYearId: year!.id,
      name: '10/A',
      courseName: 'Türk Dili ve Edebiyatı',
      description: 'İlk açıklama',
    );

    await classrooms.updateClassroom(
      id: id,
      schoolYearId: year.id,
      name: '10/B',
      courseName: 'Seçmeli Türk Dili ve Edebiyatı',
      description: 'Güncel açıklama',
    );

    final detail = await classrooms.classroomDetail(id);
    expect(detail?.classroom.name, '10/B');
    expect(detail?.classroom.description, 'Güncel açıklama');
    expect(detail?.course.name, 'Seçmeli Türk Dili ve Edebiyatı');
  });

  test('student name and school number can be edited', () async {
    final year = await classrooms.activeSchoolYear();
    final classroomId = await classrooms.createClassroom(
      schoolYearId: year!.id,
      name: '11/A',
      courseName: 'Türk Dili ve Edebiyatı',
    );
    final studentId = await students.saveStudent(
      classroomId: classroomId,
      schoolNumber: '101',
      fullName: 'Ada Öğrenci',
    );

    await students.saveStudent(
      id: studentId,
      classroomId: classroomId,
      schoolNumber: '202',
      fullName: 'Ada Düzeltilmiş',
    );

    final student = (await students.studentsForClassroom(classroomId)).single;
    expect(student.id, studentId);
    expect(student.schoolNumber, '202');
    expect(student.fullName, 'Ada Düzeltilmiş');
  });
}
