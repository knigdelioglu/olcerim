import 'dart:typed_data';

abstract interface class PdfExportService {
  Future<Uint8List> buildEvaluationReport({required int rubricId});
}
