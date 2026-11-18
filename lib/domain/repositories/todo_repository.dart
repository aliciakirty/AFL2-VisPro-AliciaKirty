import '../entities/todo.dart';
abstract interface class TodoRepository {
  Future<List<Todo>> getTodos();

  Future<Todo> createTodo({
    required String title,
    required String description,
  });

  Future<Todo> updateTodo(Todo todo);
  Future<void> deleteTodo(String id);
}