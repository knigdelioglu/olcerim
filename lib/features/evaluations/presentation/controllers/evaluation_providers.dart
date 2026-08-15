import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/core/database/daos/assessment_dao.dart';
import 'package:olcerim/core/database/daos/evaluation_dao.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/evaluations/data/assessment_repository.dart';
import 'package:olcerim/features/evaluations/data/evaluation_repository.dart';

final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) => AssessmentRepository(ref.watch(databaseProvider)));
final evaluationRepositoryProvider = Provider<EvaluationRepository>((ref) => EvaluationRepository(ref.watch(databaseProvider)));
final assessmentsProvider = StreamProvider<List<AssessmentSummaryRow>>((ref) => ref.watch(assessmentRepositoryProvider).watchAssessments());
final assessmentDetailProvider = FutureProvider.family<AssessmentDetailRow?, int>((ref, id) => ref.watch(assessmentRepositoryProvider).detail(id));
final assessmentStudentsProvider = StreamProvider.family<List<EvaluationStudentRow>, int>((ref, id) => ref.watch(evaluationRepositoryProvider).watchStudents(id));
final assessmentCriteriaProvider = FutureProvider.family<List<RubricCriterion>, int>((ref, id) => ref.watch(evaluationRepositoryProvider).criteria(id));
final evaluationEntriesProvider = StreamProvider.family<List<EvaluationEntry>, int>((ref, id) => ref.watch(evaluationRepositoryProvider).watchEntries(id));
final criterionLevelsProvider = FutureProvider.family<List<RubricLevel>, int>((ref, id) => ref.watch(evaluationRepositoryProvider).levels(id));
