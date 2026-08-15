import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/features/demo/data/demo_repository.dart';

final demoRepositoryProvider = Provider<DemoRepository>((ref) => DemoRepository(ref.watch(databaseProvider)));
