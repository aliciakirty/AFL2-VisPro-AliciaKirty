import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../states/todo_state.dart';

class EmptyView extends StatelessWidget {
  final TodoFilter filter;

  const EmptyView({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      TodoFilter.all => 'Belum ada tugas. Tambahkan tugas pertamamu!',
      TodoFilter.active => 'Tidak ada tugas aktif.',
      TodoFilter.completed => 'Belum ada tugas yang selesai.',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42),
      child: Column(
        children: [
          const Icon(
            Icons.checklist_rounded,
            size: 48,
            color: AppColors.accentBlue,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}