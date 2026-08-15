sealed class Failure implements Exception {
  const Failure(this.userMessage, {this.cause});

  final String userMessage;
  final Object? cause;

  @override
  String toString() => userMessage;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.userMessage, {super.cause});
}

final class StorageFailure extends Failure {
  const StorageFailure([
    String userMessage = 'Veriler kaydedilirken bir sorun oluştu.',
  ], {
    Object? cause,
  }) : super(userMessage, cause: cause);
}

final class ImportFailure extends Failure {
  const ImportFailure([
    String userMessage = 'Dosya içe aktarılırken bir sorun oluştu.',
  ], {
    Object? cause,
  }) : super(userMessage, cause: cause);
}

final class ExportFailure extends Failure {
  const ExportFailure([
    String userMessage = 'Dosya oluşturulurken bir sorun oluştu.',
  ], {
    Object? cause,
  }) : super(userMessage, cause: cause);
}

final class BackupFailure extends Failure {
  const BackupFailure([
    String userMessage = 'Yedekleme işlemi tamamlanamadı.',
  ], {
    Object? cause,
  }) : super(userMessage, cause: cause);
}
