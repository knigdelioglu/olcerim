import 'dart:typed_data';

import 'package:olcerim/core/services/pdf_export_service.dart';
import 'package:olcerim/core/services/tabular_export_service.dart';
import 'package:olcerim/features/evaluations/data/evaluation_repository.dart';
import 'package:olcerim/features/evaluations/domain/assessment_results.dart';

class ReportRepository {
  ReportRepository(this._evaluationRepository, this._pdf, this._tabular);
  final EvaluationRepository _evaluationRepository;
  final PdfExportService _pdf;
  final TabularExportService _tabular;

  Future<AssessmentResults> results(int assessmentId) => _evaluationRepository.loadResults(assessmentId);
  Future<Uint8List> classPdf(AssessmentResults results) => _pdf.classAssessment(results);
  Future<Uint8List> studentPdf(AssessmentResults results, StudentResult student) => _pdf.studentAssessment(results, student);
  Uint8List csv(AssessmentResults results) => _tabular.csvBytes(results);
  Uint8List xlsx(AssessmentResults results) => _tabular.xlsxBytes(results);
}
