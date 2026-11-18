import '../entities/todo.dart';
import '../failures/todo_failure.dart';
import '../repositories/todo_repository.dart';

class AddTodo {
  final TodoRepository repository;
  const AddTodo(this.repository);

  Future<Todo> call({required String title, String description = ''}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) throw const EmptyTitleFailure();

    return repository.createTodo(
      title: cleanTitle,
      description: description.trim(),
    );
  }
}