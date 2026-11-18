
import 'package:uuid/uuid.dart';

import '../../domain/entities/todo.dart';
import '../../domain/failures/todo_failure.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_local_datasource.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDataSource dataSource;
  final Uuid _uuid;
  final DateTime Function() _clock;

  TodoRepositoryImpl(
      this.dataSource, {
        Uuid? uuid,
        DateTime Function()? clock,
      })  : _uuid = uuid ?? const Uuid(),
        _clock = clock ?? DateTime.now;

  @override
  Future<List<Todo>> getTodos() {
    return _guard(() => dataSource.getTodos());
  }

  @override
  Future<Todo> createTodo({
    required String title,
    required String description,
  }) {
    return _guard(() async {
      final created = TodoModel(
        id: _uuid.v4(),
        title: title,
        description: description,
        createdAt: _clock(),
      );

      final todos = await dataSource.getTodos();

      todos.insert(0, created);

      await dataSource.saveTodos(todos);

      return created;
    });
  }

  @override
  Future<Todo> updateTodo(Todo todo) {
    return _guard(() async {
      final todos = await dataSource.getTodos();

      final index = todos.indexWhere(
            (item) => item.id == todo.id,
      );

      if (index < 0) {
        throw const NotFoundFailure();
      }

      final updated = TodoModel.fromEntity(todo);

      todos[index] = updated;

      await dataSource.saveTodos(todos);

      return updated;
    });
  }

  @override
  Future<void> deleteTodo(String id) {
    return _guard(() async {
      final todos = await dataSource.getTodos();

      final oldLength = todos.length;

      todos.removeWhere((item) => item.id == id);

      if (todos.length == oldLength) {
        return;
      }

      await dataSource.saveTodos(todos);
    });
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on TodoFailure {
      rethrow;
    } catch (error) {
      throw StorageFailure(error);
    }
  }
}