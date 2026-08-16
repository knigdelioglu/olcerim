import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';
import 'package:olcerim/features/students/data/student_repository.dart';

void main() {
  late AppDatabase db;
  late StudentRepository repository;
  late int classroomId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = StudentRepository(db);
    final year = await db.schoolDao.activeSchoolYear();
    classroomId = await db.schoolDao.saveClassroom(
      schoolYearId: year!.id,
      name: '10/Test',
      courseName: 'Türk Dili ve Edebiyatı',
    );
  });

  tearDown(() => db.close());

  test('preflight aktif öğrencideki okul numarası çakışmasını satırıyla döndürür', () async {
    await repository.saveStudent(
      classroomId: classroomId,
      schoolNumber: '101',
      fullName: 'Mevcut Öğrenci',
    );

    final conflicts = await repository.findImportConflicts(
      classroomId,
      const [
        StudentImportRecord(
          fullName: 'Yeni Öğrenci',
          schoolNumber: ' 101 ',
          sourceRow: 7,
        ),
        StudentImportRecord(
          fullName: 'Çakışmayan Öğrenci',
          schoolNumber: '102',
          sourceRow: 8,
        ),
      ],
    );

    expect(conflicts, hasLength(1));
    final conflict = conflicts.single;
    expect(conflict.sourceRow, 7);
    expect(conflict.schoolNumber, '101');
    expect(conflict.incomingFullName, 'Yeni Öğrenci');
    expect(conflict.existingFullName, 'Mevcut Öğrenci');
    expect(conflict.existingArchived, isFalse);
    expect(
      conflict.userMessage,
      '7. satır: 101 okul numarası mevcut Mevcut Öğrenci öğrencisinde kayıtlı.',
    );
  });

  test('arşivlenmiş öğrenci de UNIQUE invariantı nedeniyle conflict sayılır', () async {
    final studentId = await repository.saveStudent(
      classroomId: classroomId,
      schoolNumber: '201',
      fullName: 'Arşivdeki Öğrenci',
    );
    await repository.setArchived(studentId, true);

    final conflicts = await repository.findImportConflicts(
      classroomId,
      const [
        StudentImportRecord(
          fullName: 'Yeni 201',
          schoolNumber: '201',
          sourceRow: 3,
        ),
      ],
    );

    expect(conflicts, hasLength(1));
    expect(conflicts.single.existingArchived, isTrue);
    expect(conflicts.single.userMessage, contains('arşivdeki Arşivdeki Öğrenci'));
  });

  test('school number olmayan kayıtlar preflight tarafından engellenmez', () async {
    final conflicts = await repository.findImportConflicts(
      classroomId,
      const [
        StudentImportRecord(fullName: 'Numarasız A', sourceRow: 2),
        StudentImportRecord(fullName: 'Numarasız B', schoolNumber: '   ', sourceRow: 3),
      ],
    );

    expect(conflicts, isEmpty);
    await repository.importStudents(
      classroomId,
      const [
        StudentImportRecord(fullName: 'Numarasız A', sourceRow: 2),
        StudentImportRecord(fullName: 'Numarasız B', schoolNumber: '   ', sourceRow: 3),
      ],
    );
    expect(await repository.studentsForClassroom(classroomId), hasLength(2));
  });

  test('write transaction stale preview conflictinde hiçbir yeni satır yazmaz', () async {
    await repository.saveStudent(
      classroomId: classroomId,
      schoolNumber: '301',
      fullName: 'Önceden Kayıtlı',
    );

    await expectLater(
      repository.importStudents(
        classroomId,
        const [
          StudentImportRecord(
            fullName: 'Önce Yazılmaması Gereken',
            schoolNumber: '300',
            sourceRow: 2,
          ),
          StudentImportRecord(
            fullName: 'Conflict Satırı',
            schoolNumber: '301',
            sourceRow: 3,
          ),
        ],
      ),
      throwsA(
        isA<StudentImportConflictException>().having(
          (error) => error.conflicts.single.sourceRow,
          'sourceRow',
          3,
        ),
      ),
    );

    final students = await db.studentDao.studentsForClassroom(classroomId);
    expect(students, hasLength(1));
    expect(students.single.fullName, 'Önceden Kayıtlı');
    expect(students.map((student) => student.schoolNumber), isNot(contains('300')));
  });

  test('aynı okul numarası başka sınıfta ise importu engellemez', () async {
    final year = await db.schoolDao.activeSchoolYear();
    final otherClassroomId = await db.schoolDao.saveClassroom(
      schoolYearId: year!.id,
      name: '11/Test',
      courseName: 'Türk Dili ve Edebiyatı',
    );
    await repository.saveStudent(
      classroomId: otherClassroomId,
      schoolNumber: '401',
      fullName: 'Başka Sınıftaki Öğrenci',
    );

    final conflicts = await repository.findImportConflicts(
      classroomId,
      const [
        StudentImportRecord(
          fullName: 'Bu Sınıfa Gelebilir',
          schoolNumber: '401',
          sourceRow: 2,
        ),
      ],
    );

    expect(conflicts, isEmpty);
    await repository.importStudents(
      classroomId,
      const [
        StudentImportRecord(
          fullName: 'Bu Sınıfa Gelebilir',
          schoolNumber: '401',
          sourceRow: 2,
        ),
      ],
    );
    expect(await repository.studentsForClassroom(classroomId), hasLength(1));
  });
}
