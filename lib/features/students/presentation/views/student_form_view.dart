import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olcerim/core/constants/app_constants.dart';
import 'package:olcerim/core/database/app_database.dart';
import 'package:olcerim/features/classrooms/presentation/controllers/classroom_providers.dart';
import 'package:olcerim/features/students/presentation/controllers/student_providers.dart';

class StudentFormView extends ConsumerStatefulWidget {
  const StudentFormView({required this.classroomId, this.student, super.key});

  final int classroomId;
  final Student? student;

  bool get isEditing => student != null;

  @override
  ConsumerState<StudentFormView> createState() => _StudentFormViewState();
}

class _StudentFormViewState extends ConsumerState<StudentFormView> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final number = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name.text = widget.student?.fullName ?? '';
    number.text = widget.student?.schoolNumber ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classroom = ref.watch(classroomDetailProvider(widget.classroomId)).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Öğrenciyi düzenle' : 'Öğrenci ekle')),
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
                  if (classroom != null)
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Sınıf'),
                      child: Text('${classroom.classroom.name} · ${classroom.course.name}'),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: number,
                    decoration: const InputDecoration(labelText: 'Okul numarası (opsiyonel)'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    autofocus: !widget.isEditing,
                    decoration: const InputDecoration(labelText: 'Ad soyad'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ad soyad zorunludur.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: saving ? null : _save,
                    child: Text(
                      saving
                          ? 'Kaydediliyor…'
                          : widget.isEditing
                              ? 'Değişiklikleri kaydet'
                              : 'Öğrenciyi ekle',
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

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      await ref.read(studentRepositoryProvider).saveStudent(
            id: widget.student?.id,
            classroomId: widget.classroomId,
            schoolNumber: number.text,
            fullName: name.text,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu okul numarası bu sınıfta zaten kullanılıyor olabilir.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
