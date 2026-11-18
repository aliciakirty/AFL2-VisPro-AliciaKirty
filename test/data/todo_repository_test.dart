import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:afl_2/data/datasources/todo_local_datasource.dart';
import 'package:afl_2/data/repositories/todo_repository_impl.dart';
import 'package:afl_2/domain/failures/todo_failure.dart';

import '../helpers/fake_todo_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(SharedPreferences, TodoRepositoryImpl)> open(
      Map<String, Object> initial,
      ) async {
    SharedPreferences.setMockInitialValues(initial);
    final preferences = await SharedPreferences.getInstance();
    return (
    preferences,
    TodoRepositoryImpl(TodoLocalDataSourceImpl(preferences)),
    );
  }

  test('returns an empty list when nothing is stored', () async {
    final (_, repository) = await open({});

    expect(await repository.getTodos(), isEmpty);
  });

  test('creates todos with their own id and keeps newest first', () async {
    final (_, repository) = await open({});

    final first = await repository.createTodo(title: 'Satu', description: '');
    final second =
    await repository.createTodo(title: 'Dua', description: 'desk');

    expect(first.id, isNot(second.id));
    final todos = await repository.getTodos();
    expect(todos.map((t) => t.title), ['Dua', 'Satu']);
    expect(todos.first.description, 'desk');
  });

  test('uses the injected clock for createdAt', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = TodoRepositoryImpl(
      TodoLocalDataSourceImpl(preferences),
      clock: () => DateTime(2026, 5, 5),
    );

    final created = await repository.createTodo(title: 'A', description: '');

    expect(created.createdAt, DateTime(2026, 5, 5));
  });

  test('data written before a cold restart is present after it', () async {
    final (preferences, repository) = await open({});
    final created =
    await repository.createTodo(title: 'Bertahan', description: '');
    await repository.updateTodo(created.copyWith(isCompleted: true));

    // Simulasi "aplikasi dimatikan lalu dibuka lagi": hanya isi disk yang
    // tersisa; SharedPreferences dan repository dibuat ulang.
    final onDisk = preferences.getString(TodoLocalDataSourceImpl.storageKey)!;
    final (_, reopened) =
    await open({TodoLocalDataSourceImpl.storageKey: onDisk});

    final todos = await reopened.getTodos();
    expect(todos, hasLength(1));
    expect(todos.single.title, 'Bertahan');
    expect(todos.single.isCompleted, isTrue);
  });

  test('reads data saved in the original storage format', () async {
    const legacy = '[{"id":"1","title":"Lama","description":"",'
        '"isCompleted":true,"createdAt":"2026-01-01T00:00:00.000"}]';
    final (_, repository) =
    await open({TodoLocalDataSourceImpl.storageKey: legacy});

    final todo = (await repository.getTodos()).single;

    // Dibandingkan per field: TodoModel (data) bukan Todo (domain) menurut
    // Equatable, karena runtimeType-nya berbeda.
    expect(todo.id, '1');
    expect(todo.title, 'Lama');
    expect(todo.isCompleted, isTrue);
    expect(todo.createdAt, DateTime(2026, 1, 1));
  });

  test('updates a todo in place and returns it', () async {
    final (_, repository) = await open({});
    final created = await repository.createTodo(title: 'A', description: '');

    final saved = await repository.updateTodo(created.copyWith(title: 'B'));

    expect(saved.title, 'B');
    expect((await repository.getTodos()).single.title, 'B');
  });

  test('updating a missing todo throws NotFoundFailure', () async {
    final (_, repository) = await open({});

    await expectLater(
      repository.updateTodo(makeTodo('missing')),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('deletes a todo and ignores unknown ids', () async {
    final (_, repository) = await open({});
    final created = await repository.createTodo(title: 'A', description: '');

    await repository.deleteTodo('unknown');
    expect(await repository.getTodos(), hasLength(1));

    await repository.deleteTodo(created.id);
    expect(await repository.getTodos(), isEmpty);
  });

  test('corrupted JSON becomes a StorageFailure', () async {
    final (_, repository) =
    await open({TodoLocalDataSourceImpl.storageKey: 'bukan json'});

    await expectLater(repository.getTodos(), throwsA(isA<StorageFailure>()));
  });

  test('JSON that is not a list becomes a StorageFailure', () async {
    final (_, repository) =
    await open({TodoLocalDataSourceImpl.storageKey: '{"a":1}'});

    await expectLater(repository.getTodos(), throwsA(isA<StorageFailure>()));
  });
}