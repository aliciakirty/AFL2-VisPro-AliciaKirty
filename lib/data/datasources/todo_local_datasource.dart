import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';

abstract interface class TodoLocalDataSource {
  Future<List<TodoModel>> getTodos();
  Future<void> saveTodos(List<TodoModel> todos);
}

class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  static const storageKey = 'blue_task_todos';
  final SharedPreferences preferences;
  TodoLocalDataSourceImpl(this.preferences);

  @override
  Future<List<TodoModel>> getTodos() async {
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Stored todos are not a JSON list.');
    }
    return decoded
        .map((item) => TodoModel.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  @override
  Future<void> saveTodos(List<TodoModel> todos) async {
    final encoded = jsonEncode(todos.map((todo) => todo.toJson()).toList());
    final saved = await preferences.setString(storageKey, encoded);
    if (!saved) throw StateError('SharedPreferences refused to write.');
  }
}