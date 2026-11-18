import '../repositories/todo_repository.dart';

class DeleteTodo {
  final TodoRepository repository;
  const DeleteTodo(this.repository);
  Future<void> call(String id) => repository.deleteTodo(id);
}