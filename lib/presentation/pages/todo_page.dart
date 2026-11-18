import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/todo.dart';
import '../states/command_result.dart';
import '../states/todo_state.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../widgets/empty_view.dart';
import '../widgets/filter_button.dart';
import '../widgets/summary_card.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_form_dialog.dart';

class TodoPage extends StatelessWidget {
  final TodoViewModel viewModel;

  const TodoPage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return switch (viewModel.state) {
          TodoInitial() || TodoLoading() => const _LoadingView(),
          TodoError(:final message) => _FailureView(
            message: message,
            onRetry: viewModel.retry,
          ),
          final TodoSuccess loaded => _LoadedView(
            state: loaded,
            viewModel: viewModel,
          ),
        };
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
    );
  }
}

class _FailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailureView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('To Do'),
        backgroundColor: AppColors.background,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 44),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final TodoSuccess state;
  final TodoViewModel viewModel;

  const _LoadedView({required this.state, required this.viewModel});

  Future<void> _run(
      BuildContext context,
      Future<CommandResult> Function() command,
      ) async {
    final result = await command();
    if (!context.mounted || result.message.isEmpty) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _add(BuildContext context) async {
    final input = await showDialog<TodoFormResult>(
      context: context,
      builder: (_) => const TodoFormDialog(),
    );
    if (input == null || !context.mounted) return;

    await _run(
      context,
          () => viewModel.addTodo(
        title: input.title,
        description: input.description,
      ),
    );
  }

  Future<void> _edit(BuildContext context, Todo todo) async {
    final input = await showDialog<TodoFormResult>(
      context: context,
      builder: (_) => TodoFormDialog(initial: todo),
    );
    if (input == null || !context.mounted) return;

    await _run(
      context,
          () => viewModel.updateTodo(
        todo.copyWith(title: input.title, description: input.description),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Todo todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('Apakah kamu yakin ingin menghapus "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _run(context, () => viewModel.deleteTodo(todo.id));
  }

  @override
  Widget build(BuildContext context) {
    final idle = !state.isBusy;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.blue),
            SizedBox(width: 9),
            Text(
              'To Do',
              style: TextStyle(
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: state.isBusy
              ? const LinearProgressIndicator(
            minHeight: 3,
            color: AppColors.blue,
          )
              : const SizedBox(height: 3),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: idle ? () => _add(context) : null,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tugas'),
      ),
      body: RefreshIndicator(
        color: AppColors.blue,
        onRefresh: () => _run(context, viewModel.refresh),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            const Text(
              'Atur kegiatanmu, satu per satu.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            SummaryCard(
              total: state.todos.length,
              completed: state.completedCount,
              active: state.activeCount,
            ),
            const SizedBox(height: 26),
            const Text(
              'Daftar Tugas',
              style: TextStyle(
                color: AppColors.darkBlue,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                FilterButton(
                  label: 'Semua',
                  selected: state.filter == TodoFilter.all,
                  onTap: () => viewModel.setFilter(TodoFilter.all),
                ),
                const SizedBox(width: 8),
                FilterButton(
                  label: 'Aktif',
                  selected: state.filter == TodoFilter.active,
                  onTap: () => viewModel.setFilter(TodoFilter.active),
                ),
                const SizedBox(width: 8),
                FilterButton(
                  label: 'Selesai',
                  selected: state.filter == TodoFilter.completed,
                  onTap: () => viewModel.setFilter(TodoFilter.completed),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (state.visibleTodos.isEmpty)
              EmptyView(filter: state.filter)
            else
              for (final todo in state.visibleTodos)
                TodoCard(
                  todo: todo,
                  enabled: idle,
                  onToggle: () => _run(
                    context,
                        () => viewModel.toggleTodo(todo),
                  ),
                  onEdit: () => _edit(context, todo),
                  onDelete: () => _delete(context, todo),
                ),
          ],
        ),
      ),
    );
  }
}