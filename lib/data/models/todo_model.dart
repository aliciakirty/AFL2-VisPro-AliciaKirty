import '../../domain/entities/todo.dart';

class TodoModel extends Todo {
  const TodoModel({required super.id, required super.title, super.description = '', super.isCompleted = false, required super.createdAt});
  factory TodoModel.fromJson(Map<String, dynamic> json) => TodoModel(
    id: json['id'] as String, title: json['title'] as String,
    description: (json['description'] as String?) ?? '',
    isCompleted: (json['isCompleted'] as bool?) ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
  factory TodoModel.fromEntity(Todo todo) => TodoModel(
    id: todo.id, title: todo.title, description: todo.description,
    isCompleted: todo.isCompleted, createdAt: todo.createdAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description,
    'isCompleted': isCompleted, 'createdAt': createdAt.toIso8601String(),
  };
}