import 'dart:typed_data';

class ImportedStudent {
  const ImportedStudent({
    required this.fullName,
    required this.className,
    this.schoolNumber,
  });

  final String fullName;
  final String className;
  final String? schoolNumber;
}

abstract interface class ExcelService {
  /// Parses workbook bytes outside the UI isolate in the concrete implementation.
  Future<List<ImportedStudent>> parseStudentList(Uint8List workbookBytes);
}
