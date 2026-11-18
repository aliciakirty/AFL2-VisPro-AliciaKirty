import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/todo.dart';

typedef TodoFormResult = ({String title, String description});

class TodoFormDialog extends StatefulWidget {
  final Todo? initial;

  const TodoFormDialog({super.key, this.initial});

  @override
  State<TodoFormDialog> createState() => _TodoFormDialogState();
}

class _TodoFormDialogState extends State<TodoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController =
  TextEditingController(text: widget.initial?.title ?? '');
  late final TextEditingController _descriptionController =
  TextEditingController(text: widget.initial?.description ?? '');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop<TodoFormResult>(context, (
    title: _titleController.text.trim(),
    description: _descriptionController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initial == null ? 'Tambah Tugas' : 'Edit Tugas',
        style: const TextStyle(
          color: AppColors.darkBlue,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Judul tugas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tugas tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}