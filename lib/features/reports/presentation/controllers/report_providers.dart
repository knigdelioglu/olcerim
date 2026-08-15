import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/services/pdf_export_service.dart';
import 'package:olcerim/core/services/tabular_export_service.dart';
import 'package:olcerim/features/evaluations/presentation/controllers/evaluation_providers.dart';
import 'package:olcerim/features/reports/data/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository(ref.watch(evaluationRepositoryProvider), PdfExportService(), TabularExportService()));
