import 'dart:async';

import 'package:afl_2/domain/entities/todo.dart';
import 'package:afl_2/domain/failures/todo_failure.dart';
import 'package:afl_2/domain/repositories/todo_repository.dart';
import 'package:afl_2/domain/usecases/add_todo.dart';
import 'package:afl_2/domain/usecases/delete_todo.dart';
import 'package:afl_2/domain/usecases/get_todos.dart';
import 'package:afl_2/domain/usecases/update_todo.dart';
import 'package:afl_2/presentation/viewmodels/todo_viewmodel.dart';

Todo makeTodo(
    String id, {
      String title = 'Tugas',
      String description = '',
      bool isCompleted = false,
    }) {
  return Todo(
    id: id,
    title: title,
    description: description,
    isCompleted: isCompleted,
    createdAt: DateTime(2026, 1, 1),
  );
}

TodoViewModel buildViewModel(TodoRepository repository) {
  return TodoViewModel(
    getTodosUseCase: GetTodos(repository),
    addTodoUseCase: AddTodo(repository),
    updateTodoUseCase: UpdateTodo(repository),
    deleteTodoUseCase: DeleteTodo(repository),
  );
}

/// Repository palsu: bisa dipaksa gagal ([failure]) atau ditahan ([gate])
/// supaya keadaan "sedang berjalan" bisa diperiksa.
class FakeTodoRepository implements TodoRepository {
  FakeTodoRepository({List<Todo> seed = const []}) : todos = List.of(seed);

  List<Todo> todos;
  TodoFailure? failure;
  Completer<void>? gate;
  int _nextId = 1;

  Future<void> _enter() async {
    final pending = gate;
    if (pending != null) await pending.future;
    final error = failure;
    if (error != null) throw error;
  }

  @override
  Future<List<Todo>> getTodos() async {
    await _enter();
    return List.of(todos);
  }

  @override
  Future<Todo> createTodo({
    required String title,
    required String description,
  }) async {
    await _enter();
    final created = makeTodo(
      'new-${_nextId++}',
      title: title,
      description: description,
    );
    todos.insert(0, created);
    return created;
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    await _enter();
    final index = todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) throw const NotFoundFailure();
    todos[index] = todo;
    return todo;
  }

  @override
  Future<void> deleteTodo(String id) async {
    await _enter();
    todos.removeWhere((item) => item.id == id);
  }
}