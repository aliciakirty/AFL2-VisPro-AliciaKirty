import 'package:equatable/equatable.dart';
import '../../domain/entities/todo.dart';

enum TodoFilter { all, active, completed }

sealed class TodoState extends Equatable {
  const TodoState();
  @override
  List<Object?> get props => const [];
}

final class TodoInitial extends TodoState {
  const TodoInitial();
}

final class TodoLoading extends TodoState {
  const TodoLoading();
}

final class TodoSuccess extends TodoState {
  final List<Todo> todos;
  final TodoFilter filter;
  final bool isBusy;
  const TodoSuccess({
    required this.todos,
    this.filter = TodoFilter.all,
    this.isBusy = false,
  });

  TodoSuccess copyWith({
    List<Todo>? todos,
    TodoFilter? filter,
    bool? isBusy,
  }) {
    return TodoSuccess(
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
      isBusy: isBusy ?? this.isBusy,
    );
  }

  List<Todo> get visibleTodos => switch (filter) {
    TodoFilter.all => todos,
    TodoFilter.active => todos.where((todo) => !todo.isCompleted).toList(),
    TodoFilter.completed =>
        todos.where((todo) => todo.isCompleted).toList(),
  };
  int get completedCount => todos.where((todo) => todo.isCompleted).length;
  int get activeCount => todos.where((todo) => !todo.isCompleted).length;

  @override
  List<Object?> get props => [todos, filter, isBusy];
}

final class TodoError extends TodoState {
  final String message;
  const TodoError(this.message);
  @override
  List<Object?> get props => [message];
}