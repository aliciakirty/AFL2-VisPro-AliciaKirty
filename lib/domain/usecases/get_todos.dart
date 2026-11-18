import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class GetTodos {
  final TodoRepository repository;
  const GetTodos(this.repository);
  Future<List<Todo>> call() => repository.getTodos();
}