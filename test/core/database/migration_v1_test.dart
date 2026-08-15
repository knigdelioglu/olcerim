import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('v1 veritabanı güncel şemaya yükselirken öğrenci ve puan korunur', () async {
    final directory = await Directory.systemTemp.createTemp('olcerim-migration-');
    final file = File('${directory.path}/v1.sqlite');
    final raw = sqlite3.open(file.path);
    raw.execute('PRAGMA foreign_keys = OFF');
    raw.execute('CREATE TABLE students (id INTEGER PRIMARY KEY AUTOINCREMENT, school_number TEXT, full_name TEXT NOT NULL, class_name TEXT NOT NULL, archived INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL)');
    raw.execute('CREATE TABLE rubrics (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)');
    raw.execute('CREATE TABLE rubric_criteria (id INTEGER PRIMARY KEY AUTOINCREMENT, rubric_id INTEGER NOT NULL, title TEXT NOT NULL, description TEXT, max_score REAL NOT NULL, sort_order INTEGER NOT NULL DEFAULT 0)');
    raw.execute('CREATE TABLE evaluation_entries (id INTEGER PRIMARY KEY AUTOINCREMENT, student_id INTEGER NOT NULL, criterion_id INTEGER NOT NULL, score REAL NOT NULL, note TEXT, evaluated_at INTEGER NOT NULL)');
    raw.execute("INSERT INTO students VALUES (1, '101', 'Sentetik Öğrenci', '10/Test', 0, 1700000000)");
    raw.execute("INSERT INTO rubrics VALUES (1, 'Sentetik Rubrik', NULL, 1700000000, 1700000000)");
    raw.execute("INSERT INTO rubric_criteria VALUES (1, 1, 'İçerik', NULL, 20, 0)");
    raw.execute("INSERT INTO evaluation_entries VALUES (1, 1, 1, 17, NULL, 1700000000)");
    raw.execute('PRAGMA user_version = 1');
    raw.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    expect((await db.studentDao.studentsForClassroom(1)).single.fullName, 'Sentetik Öğrenci');
    final assessments = await db.assessmentDao.watchAssessments().first;
    expect(assessments, isNotEmpty);
    final results = await db.evaluationDao.loadResults(assessments.first.assessment.id);
    expect(results.students.single.total, 17);
    await db.close();
    await directory.delete(recursive: true);
  });
}
