sealed class Failure implements Exception {
  const Failure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class ImportFailure extends Failure {
  const ImportFailure(super.message, [super.cause]);
}

final class ExportFailure extends Failure {
  const ExportFailure(super.message, [super.cause]);
}

final class BackupFailure extends Failure {
  const BackupFailure(super.message, [super.cause]);
}
