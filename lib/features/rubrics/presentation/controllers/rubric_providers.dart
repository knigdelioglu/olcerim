import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/daos/rubric_dao.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/rubrics/data/rubric_repository.dart';
import 'package:olcerim/features/rubrics/domain/rubric_draft.dart';

final rubricRepositoryProvider = Provider<RubricRepository>((ref) => RubricRepository(ref.watch(databaseProvider)));
final rubricTemplatesProvider = StreamProvider<List<RubricSummaryRow>>((ref) => ref.watch(rubricRepositoryProvider).watchTemplates());
final rubricDraftProvider = FutureProvider.family<RubricDraft?, int>((ref, id) => ref.watch(rubricRepositoryProvider).load(id));
