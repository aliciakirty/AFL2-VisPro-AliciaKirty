
import 'package:uuid/uuid.dart';

import '../../domain/entities/todo.dart';
import '../../domain/failures/todo_failure.dart';
import '../../domain/repositories/todo_repository.dart';

class InMemoryTodoRepository implements TodoRepository {
  InMemoryTodoRepository({
    List<Todo> seed = const [],
  }) : _todos = List<Todo>.of(seed);

  final List<Todo> _todos;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Todo>> getTodos() async {
    return List<Todo>.of(_todos);
  }

  @override
  Future<Todo> createTodo({
    required String title,
    required String description,
  }) async {
    final created = Todo(
      id: _uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );

    _todos.insert(0, created);

    return created;
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    final index = _todos.indexWhere(
          (item) => item.id == todo.id,
    );

    if (index < 0) {
      throw const NotFoundFailure();
    }

    _todos[index] = todo;

    return todo;
  }

  @override
  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((item) => item.id == id);
  }
}