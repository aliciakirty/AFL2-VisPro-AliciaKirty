import 'package:flutter/foundation.dart';
import '../../domain/entities/todo.dart';
import '../../domain/failures/todo_failure.dart';
import '../../domain/usecases/add_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/get_todos.dart';
import '../../domain/usecases/update_todo.dart';
import '../states/command_result.dart';
import '../states/todo_state.dart';
import 'failure_messages.dart';

class TodoViewModel extends ChangeNotifier {
  final GetTodos _getTodos;
  final AddTodo _addTodo;
  final UpdateTodo _updateTodo;
  final DeleteTodo _deleteTodo;

  TodoViewModel({
    required GetTodos getTodosUseCase,
    required AddTodo addTodoUseCase,
    required UpdateTodo updateTodoUseCase,
    required DeleteTodo deleteTodoUseCase,
  })  : _getTodos = getTodosUseCase,
        _addTodo = addTodoUseCase,
        _updateTodo = updateTodoUseCase,
        _deleteTodo = deleteTodoUseCase;

  TodoState _state = const TodoInitial();
  TodoState get state => _state;

  bool _disposed = false;

  static const String _busy = 'Sedang memproses. Coba lagi sebentar.';

  void _emit(TodoState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  TodoFailure _asFailure(Object error) {
    return error is TodoFailure ? error : UnknownFailure(error);
  }

  Future<void> loadTodos() async {
    if (_disposed) return;
    _emit(const TodoLoading());
    try {
      final todos = await _getTodos();
      if (_disposed) return;
      _emit(TodoSuccess(todos: todos));
    } catch (error) {
      if (_disposed) return;
      _emit(
        TodoError(
          describeFailure(
            _asFailure(error),
            fallback: 'Daftar tugas gagal dimuat.',
          ),
        ),
      );
    }
  }

  Future<void> retry() => loadTodos();

  Future<CommandResult> refresh() {
    return _runCommand(
      failureFallback: 'Daftar tugas gagal dimuat.',
      successMessage: '',
      action: (_) => _getTodos(),
    );
  }

  Future<CommandResult> addTodo({
    required String title,
    String description = '',
  }) {
    return _runCommand(
      failureFallback: 'Tugas gagal ditambahkan.',
      successMessage: 'Tugas berhasil ditambahkan.',
      action: (todos) async {
        final created = await _addTodo(title: title, description: description);
        return [created, ...todos];
      },
    );
  }

  Future<CommandResult> updateTodo(Todo todo) {
    return _save(todo, successMessage: 'Tugas berhasil diperbarui.');
  }

  Future<CommandResult> toggleTodo(Todo todo) {
    return _save(
      todo.copyWith(isCompleted: !todo.isCompleted),
      successMessage: todo.isCompleted
          ? 'Tugas ditandai belum selesai.'
          : 'Tugas berhasil diselesaikan.',
    );
  }

  Future<CommandResult> deleteTodo(String id) {
    return _runCommand(
      failureFallback: 'Tugas gagal dihapus.',
      successMessage: 'Tugas berhasil dihapus.',
      action: (todos) async {
        await _deleteTodo(id);
        return todos.where((todo) => todo.id != id).toList();
      },
    );
  }

  void setFilter(TodoFilter filter) {
    final current = _state;
    if (current is TodoSuccess) {
      _emit(current.copyWith(filter: filter));
    }
  }

  Future<CommandResult> _save(Todo todo, {required String successMessage}) {
    return _runCommand(
      failureFallback: 'Tugas gagal diperbarui.',
      successMessage: successMessage,
      action: (todos) async {
        final saved = await _updateTodo(todo);
        return [for (final item in todos) item.id == saved.id ? saved : item];
      },
    );
  }

  Future<CommandResult> _runCommand({
    required String failureFallback,
    required String successMessage,
    required Future<List<Todo>> Function(List<Todo> current) action,
  }) async {
    final current = _state;
    if (current is! TodoSuccess || current.isBusy) {
      return const CommandResult.failure(_busy);
    }

    _emit(current.copyWith(isBusy: true));

    try {
      final updatedTodos = await action(current.todos);
      if (_disposed) return CommandResult.success(successMessage);

      final latest = _state;
      if (latest is TodoSuccess) {
        _emit(latest.copyWith(todos: updatedTodos, isBusy: false));
      }
      return CommandResult.success(successMessage);
    } catch (error) {
      final message = describeFailure(
        _asFailure(error),
        fallback: failureFallback,
      );
      if (_disposed) return CommandResult.failure(message);

      final latest = _state;
      if (latest is TodoSuccess) {
        _emit(latest.copyWith(isBusy: false));
      }
      return CommandResult.failure(message);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}