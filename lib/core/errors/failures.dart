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
  const StorageFailure(
    [super.userMessage = 'Veriler kaydedilirken bir sorun oluştu.'], {
    super.cause,
  });
}

final class ImportFailure extends Failure {
  const ImportFailure(
    [super.userMessage = 'Dosya içe aktarılırken bir sorun oluştu.'], {
    super.cause,
  });
}

final class ExportFailure extends Failure {
  const ExportFailure(
    [super.userMessage = 'Dosya oluşturulurken bir sorun oluştu.'], {
    super.cause,
  });
}

final class BackupFailure extends Failure {
  const BackupFailure(
    [super.userMessage = 'Yedekleme işlemi tamamlanamadı.'], {
    super.cause,
  });
}
