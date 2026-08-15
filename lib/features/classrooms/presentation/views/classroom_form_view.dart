import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';

class ClassroomFormView extends ConsumerStatefulWidget {
  const ClassroomFormView({
    required this.initialSchoolYearId,
    this.classroomId,
    this.initialName,
    this.initialCourseName,
    this.initialDescription,
    super.key,
  });

  final int initialSchoolYearId;
  final int? classroomId;
  final String? initialName;
  final String? initialCourseName;
  final String? initialDescription;

  bool get isEditing => classroomId != null;

  @override
  ConsumerState<ClassroomFormView> createState() => _ClassroomFormViewState();
}

class _ClassroomFormViewState extends ConsumerState<ClassroomFormView> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final courseController = TextEditingController();
  final descriptionController = TextEditingController();
  late int schoolYearId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    schoolYearId = widget.initialSchoolYearId;
    nameController.text = widget.initialName ?? '';
    courseController.text = widget.initialCourseName ?? '';
    descriptionController.text = widget.initialDescription ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    courseController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final years = ref.watch(schoolYearsProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Sınıfı düzenle' : 'Yeni sınıf')),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppConstants.formMaxWidth),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: schoolYearId,
                    decoration: const InputDecoration(labelText: 'Eğitim yılı'),
                    items: years
                        .map((year) => DropdownMenuItem(value: year.id, child: Text(year.label)))
                        .toList(),
                    onChanged: (value) => schoolYearId = value ?? schoolYearId,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Sınıf adı', hintText: '10/A'),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: courseController,
                    decoration: const InputDecoration(
                      labelText: 'Ders',
                      hintText: 'Türk Dili ve Edebiyatı',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: saving ? null : _save,
                    child: Text(
                      saving
                          ? 'Kaydediliyor…'
                          : widget.isEditing
                              ? 'Değişiklikleri kaydet'
                              : 'Sınıfı oluştur',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bu alan zorunludur.' : null;

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      final repository = ref.read(classroomRepositoryProvider);
      if (widget.classroomId == null) {
        await repository.createClassroom(
          schoolYearId: schoolYearId,
          name: nameController.text,
          courseName: courseController.text,
          description: descriptionController.text,
        );
      } else {
        await repository.updateClassroom(
          id: widget.classroomId!,
          schoolYearId: schoolYearId,
          name: nameController.text,
          courseName: courseController.text,
          description: descriptionController.text,
        );
        ref.invalidate(classroomDetailProvider(widget.classroomId!));
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sınıf kaydedilemedi. Aynı eğitim yılı, sınıf ve ders kaydı zaten var olabilir.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
