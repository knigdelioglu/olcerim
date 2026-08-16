import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/database/daos/student_dao.dart';
import 'package:olcerim/core/services/excel_service.dart';
import 'package:olcerim/features/students/presentation/controllers/student_providers.dart';

class StudentImportView extends ConsumerStatefulWidget {
  const StudentImportView({this.classroomId, super.key});

  final int? classroomId;

  @override
  ConsumerState<StudentImportView> createState() => _StudentImportViewState();
}

class _StudentImportViewState extends ConsumerState<StudentImportView> {
  final service = ExcelService();
  StudentFilePreview? preview;
  StudentPreviewValidation? validation;
  List<StudentImportConflict> databaseConflicts = const [];
  int? nameColumn;
  int? numberColumn;
  String? fileName;
  String? preflightError;
  bool busy = false;
  bool checkingConflicts = false;
  int validationRevision = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.classroomId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Öğrenci içe aktarmak için önce bir sınıf açın.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Öğrenci içe aktar')),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Excel veya CSV sınıf listenizi seçin',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dosya yalnız cihazınızda okunur. İçe aktarmadan önce '
                  'kolonları ve hatalı satırları kontrol edebilirsiniz.',
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: busy ? null : _pickFile,
                  icon: const Icon(Icons.file_open),
                  label: Text(fileName ?? 'Dosya seç'),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
                if (preview case final data?) ...[
                  const SizedBox(height: 24),
                  _columnSelector(data),
                  const SizedBox(height: 16),
                  _previewTable(data),
                  if (validation case final result?) ...[
                    const SizedBox(height: 16),
                    if (result.errors.isNotEmpty) _localErrorCard(result),
                    if (checkingConflicts) ...[
                      const SizedBox(height: 16),
                      const Card(
                        child: ListTile(
                          leading: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          title: Text('Sınıftaki mevcut okul numaraları kontrol ediliyor…'),
                        ),
                      ),
                    ],
                    if (preflightError case final message?) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.error_outline),
                          title: const Text('Mevcut sınıf kontrol edilemedi'),
                          subtitle: Text(message),
                          trailing: TextButton(
                            onPressed: checkingConflicts ? null : _validate,
                            child: const Text('Tekrar dene'),
                          ),
                        ),
                      ),
                    ],
                    if (databaseConflicts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _databaseConflictCard(),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _canImport(result) ? _import : null,
                      child: Text('${result.validRows.length} öğrenciyi içe aktar'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _columnSelector(StudentFilePreview data) {
    List<DropdownMenuItem<int>> items() => List.generate(
          data.headers.length,
          (index) => DropdownMenuItem<int>(
            value: index,
            child: Text(
              data.headers[index].isEmpty ? 'Kolon ${index + 1}' : data.headers[index],
            ),
          ),
        );

    return Wrap(
      runSpacing: 12,
      spacing: 12,
      children: [
        SizedBox(
          width: 320,
          child: DropdownButtonFormField<int>(
            initialValue: nameColumn,
            decoration: const InputDecoration(labelText: 'Ad soyad kolonu'),
            items: items(),
            onChanged: (value) {
              setState(() => nameColumn = value);
              _validate();
            },
          ),
        ),
        SizedBox(
          width: 320,
          child: DropdownButtonFormField<int?>(
            initialValue: numberColumn,
            decoration: const InputDecoration(labelText: 'Okul no kolonu (opsiyonel)'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Yok')),
              ...items().map(
                (item) => DropdownMenuItem<int?>(
                  value: item.value,
                  child: item.child,
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => numberColumn = value);
              _validate();
            },
          ),
        ),
      ],
    );
  }

  Widget _previewTable(StudentFilePreview data) {
    final columns = data.headers
        .map((header) => DataColumn(label: Text(header.isEmpty ? 'Kolon' : header)))
        .toList();
    final rows = data.rows
        .take(8)
        .map(
          (row) => DataRow(
            cells: List.generate(
              columns.length,
              (index) => DataCell(Text(index < row.length ? row[index] : '')),
            ),
          ),
        )
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: columns, rows: rows),
    );
  }

  Widget _localErrorCard(StudentPreviewValidation result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.errors.length} satırda dosya sorunu bulundu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...result.errors.take(8).map(Text.new),
            if (result.errors.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${result.errors.length - 8} sorun daha var.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _databaseConflictCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${databaseConflicts.length} öğrenci mevcut sınıfla çakışıyor',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Bu kayıtlar sessizce değiştirilmez. Okul numarasını dosyada '
              'düzeltin veya mevcut/arşivlenmiş öğrenci kaydını yönetin.',
            ),
            const SizedBox(height: 8),
            ...databaseConflicts.take(8).map(
                  (conflict) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(conflict.userMessage),
                  ),
                ),
            if (databaseConflicts.length > 8)
              Text('${databaseConflicts.length - 8} çakışma daha var.'),
          ],
        ),
      ),
    );
  }

  bool _canImport(StudentPreviewValidation result) {
    return result.isValid &&
        databaseConflicts.isEmpty &&
        preflightError == null &&
        !checkingConflicts &&
        !busy;
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv'],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    validationRevision++;
    setState(() {
      busy = true;
      fileName = file.name;
      preview = null;
      validation = null;
      databaseConflicts = const [];
      preflightError = null;
      checkingConflicts = false;
    });

    try {
      final parsed = await service.parseStudentList(bytes, file.extension ?? '');
      if (!mounted) return;
      setState(() {
        preview = parsed;
        nameColumn = parsed.suggestedNameColumn;
        numberColumn = parsed.suggestedNumberColumn;
        busy = false;
      });
      await _validate();
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dosya okunamadı. Dosya biçimini kontrol edip tekrar deneyin.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _validate() async {
    final revision = ++validationRevision;
    final data = preview;
    final name = nameColumn;
    if (data == null || name == null) {
      if (mounted) {
        setState(() {
          validation = null;
          databaseConflicts = const [];
          preflightError = null;
          checkingConflicts = false;
        });
      }
      return;
    }

    final localResult = service.validate(
      data,
      nameColumn: name,
      numberColumn: numberColumn,
    );
    if (!mounted || revision != validationRevision) return;

    final records = _importRecords(localResult);
    final needsDatabaseCheck = localResult.isValid &&
        records.any((record) => record.schoolNumber?.isNotEmpty == true);
    setState(() {
      validation = localResult;
      databaseConflicts = const [];
      preflightError = null;
      checkingConflicts = needsDatabaseCheck;
    });

    if (!needsDatabaseCheck) return;

    try {
      final conflicts = await ref
          .read(studentRepositoryProvider)
          .findImportConflicts(widget.classroomId!, records);
      if (!mounted || revision != validationRevision) return;
      setState(() {
        databaseConflicts = conflicts;
        checkingConflicts = false;
      });
    } catch (_) {
      if (!mounted || revision != validationRevision) return;
      setState(() {
        checkingConflicts = false;
        preflightError =
            'İçe aktarmadan önce sınıftaki okul numaraları doğrulanamadı. '
            'Bağlantıyı değil yerel veritabanını kontrol eden bu adım '
            'başarılı olmadan içe aktarma yapılmayacak.';
      });
    }
  }

  List<StudentImportRecord> _importRecords(StudentPreviewValidation result) {
    return result.validRows
        .map(
          (row) => StudentImportRecord(
            fullName: row.fullName,
            schoolNumber: row.schoolNumber,
            sourceRow: row.sourceRow,
          ),
        )
        .toList();
  }

  Future<void> _import() async {
    final result = validation;
    if (result == null || !_canImport(result)) return;

    setState(() => busy = true);
    try {
      await ref.read(studentRepositoryProvider).importStudents(
            widget.classroomId!,
            _importRecords(result),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.validRows.length} öğrenci içe aktarıldı.')),
      );
      Navigator.pop(context);
    } on StudentImportConflictException catch (error) {
      if (!mounted) return;
      setState(() {
        databaseConflicts = error.conflicts;
        preflightError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sınıf listesi önizlemeden sonra değişti. Yeni çakışmaları '
            'kontrol edip tekrar deneyin.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Öğrenciler içe aktarılamadı. Verileri kontrol edip tekrar deneyin.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
