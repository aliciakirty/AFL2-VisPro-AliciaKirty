
import '../entities/todo.dart';
import '../failures/todo_failure.dart';
import '../repositories/todo_repository.dart';

class UpdateTodo {
  final TodoRepository repository;

  const UpdateTodo(this.repository);

  Future<Todo> call(Todo todo) async {
    final cleanTitle = todo.title.trim();

    if (cleanTitle.isEmpty) {
      throw const EmptyTitleFailure();
    }

    final normalizedTodo = todo.copyWith(
      title: cleanTitle,
      description: todo.description.trim(),
    );

    return await repository.updateTodo(normalizedTodo);
  }
}