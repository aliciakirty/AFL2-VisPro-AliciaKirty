import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/todo_local_datasource.dart';
import '../../data/repositories/todo_repository_impl.dart';
import '../../data/repositories/in_memory_todo_repository.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/usecases/add_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/get_todos.dart';
import '../../domain/usecases/update_todo.dart';
import '../../presentation/viewmodels/todo_viewmodel.dart';

class AppDependencies {
  final TodoRepository todoRepository;
  final TodoViewModel todoViewModel;

  AppDependencies._(this.todoRepository, this.todoViewModel);

  static Future<AppDependencies> create() async {
    final TodoRepository repository = await createLocalRepository();

    final viewModel = TodoViewModel(
      getTodosUseCase: GetTodos(repository),
      addTodoUseCase: AddTodo(repository),
      updateTodoUseCase: UpdateTodo(repository),
      deleteTodoUseCase: DeleteTodo(repository),
    );

    return AppDependencies._(repository, viewModel);
  }

  static Future<TodoRepository> createLocalRepository() async {
    final preferences = await SharedPreferences.getInstance();
    final dataSource = TodoLocalDataSourceImpl(preferences);

    return TodoRepositoryImpl(dataSource);
  }

  static TodoRepository createInMemoryRepository() {
    return InMemoryTodoRepository();
  }
}