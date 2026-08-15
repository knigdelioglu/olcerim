import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/database_provider.dart';
import 'package:olcerim/core/services/backup_restore_service.dart';
import 'package:olcerim/features/backup/data/backup_repository.dart';

final backupRepositoryProvider = Provider<BackupRepository>((ref) => BackupRepository(ref.watch(databaseProvider), BackupRestoreService()));
final lastBackupAtProvider = FutureProvider<DateTime?>((ref) => ref.watch(backupRepositoryProvider).lastBackupAt());
