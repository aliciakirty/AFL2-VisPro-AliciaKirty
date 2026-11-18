import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:afl_2/domain/entities/todo.dart';
import 'package:afl_2/domain/failures/todo_failure.dart';
import 'package:afl_2/presentation/states/command_result.dart';
import 'package:afl_2/presentation/states/todo_state.dart';
import 'package:afl_2/presentation/viewmodels/todo_viewmodel.dart';

import '../helpers/fake_todo_repository.dart';

void main() {
  late FakeTodoRepository repository;
  late TodoViewModel viewModel;

  Future<void> loadedWith(List<Todo> seed) async {
    repository = FakeTodoRepository(seed: seed);
    viewModel = buildViewModel(repository);
    await viewModel.loadTodos();
  }

  TodoSuccess loaded() => viewModel.state as TodoSuccess;

  group('loadTodos', () {
    test('emits Loading then Success with the stored todos', () async {
      repository = FakeTodoRepository(seed: [makeTodo('a')]);
      viewModel = buildViewModel(repository);
      final states = <TodoState>[];
      viewModel.addListener(() => states.add(viewModel.state));

      await viewModel.loadTodos();

      expect(states, [
        const TodoLoading(),
        TodoSuccess(todos: [makeTodo('a')]),
      ]);
    });

    test('emits Error with a user-facing message on failure', () async {
      repository = FakeTodoRepository()..failure = const StorageFailure();
      viewModel = buildViewModel(repository);

      await viewModel.loadTodos();

      expect(
        viewModel.state,
        const TodoError('Daftar tugas gagal dimuat. Silakan coba lagi.'),
      );
    });

    test('explains network failures differently from storage failures',
            () async {
          repository = FakeTodoRepository()..failure = const NetworkFailure();
          viewModel = buildViewModel(repository);

          await viewModel.loadTodos();

          expect(
            viewModel.state,
            const TodoError(
              'Tidak ada koneksi internet. Periksa koneksimu lalu coba lagi.',
            ),
          );
        });

    test('recovers on retry once the source works again', () async {
      repository = FakeTodoRepository(seed: [makeTodo('a')])
        ..failure = const StorageFailure();
      viewModel = buildViewModel(repository);
      await viewModel.loadTodos();

      repository.failure = null;
      await viewModel.retry();

      expect(loaded().todos, [makeTodo('a')]);
    });
  });

  group('addTodo', () {
    test('puts the new todo first and reports success', () async {
      await loadedWith([makeTodo('a')]);

      final result = await viewModel.addTodo(title: 'Baru', description: 'x');

      expect(result, const CommandResult.success('Tugas berhasil ditambahkan.'));
      expect(loaded().todos.map((t) => t.title), ['Baru', 'Tugas']);
      expect(loaded().isBusy, isFalse);
    });

    test('rejects a blank title and leaves the screen state intact', () async {
      await loadedWith([makeTodo('a')]);
      final before = viewModel.state;

      final result = await viewModel.addTodo(title: '   ');

      expect(
        result,
        const CommandResult.failure('Judul tugas tidak boleh kosong.'),
      );
      expect(viewModel.state, before);
      expect(repository.todos, hasLength(1));
    });

    test('keeps the visible list when the source fails', () async {
      await loadedWith([makeTodo('a')]);
      repository.failure = const StorageFailure();

      final result = await viewModel.addTodo(title: 'Baru');

      expect(
        result,
        const CommandResult.failure(
          'Tugas gagal ditambahkan. Silakan coba lagi.',
        ),
      );
      expect(loaded().todos, [makeTodo('a')]);
      expect(loaded().isBusy, isFalse);
    });
  });

  group('toggleTodo', () {
    test('completes an active todo', () async {
      await loadedWith([makeTodo('a')]);

      final result = await viewModel.toggleTodo(makeTodo('a'));

      expect(
        result,
        const CommandResult.success('Tugas berhasil diselesaikan.'),
      );
      expect(loaded().todos.single.isCompleted, isTrue);
    });

    test('reopens a completed todo', () async {
      await loadedWith([makeTodo('a', isCompleted: true)]);

      final result =
      await viewModel.toggleTodo(makeTodo('a', isCompleted: true));

      expect(
        result,
        const CommandResult.success('Tugas ditandai belum selesai.'),
      );
      expect(loaded().todos.single.isCompleted, isFalse);
    });

    test('reports failure and leaves the todo unchanged', () async {
      await loadedWith([makeTodo('a')]);
      repository.failure = const StorageFailure();

      final result = await viewModel.toggleTodo(makeTodo('a'));

      expect(result.isSuccess, isFalse);
      expect(loaded().todos.single.isCompleted, isFalse);
    });
  });

  group('updateTodo and deleteTodo', () {
    test('updates only the matching todo', () async {
      await loadedWith([makeTodo('a'), makeTodo('b', title: 'B')]);

      await viewModel.updateTodo(makeTodo('b', title: ' B2 '));

      expect(loaded().todos.map((t) => t.title), ['Tugas', 'B2']);
    });

    test('says the todo is missing when it no longer exists', () async {
      await loadedWith([makeTodo('a')]);
      repository.todos.clear();

      final result = await viewModel.updateTodo(makeTodo('a', title: 'X'));

      expect(
        result,
        const CommandResult.failure(
          'Tugas tidak ditemukan. Mungkin sudah dihapus.',
        ),
      );
      expect(loaded().todos, [makeTodo('a')]);
    });

    test('deletes the todo', () async {
      await loadedWith([makeTodo('a'), makeTodo('b')]);

      final result = await viewModel.deleteTodo('a');

      expect(result, const CommandResult.success('Tugas berhasil dihapus.'));
      expect(loaded().todos.map((t) => t.id), ['b']);
    });

    test('keeps the list when deleting fails', () async {
      await loadedWith([makeTodo('a')]);
      repository.failure = const StorageFailure();

      final result = await viewModel.deleteTodo('a');

      expect(result.isSuccess, isFalse);
      expect(loaded().todos, [makeTodo('a')]);
    });
  });

  group('filter', () {
    test('shows only matching todos', () async {
      await loadedWith([makeTodo('a'), makeTodo('b', isCompleted: true)]);

      viewModel.setFilter(TodoFilter.active);
      expect(loaded().visibleTodos.map((t) => t.id), ['a']);

      viewModel.setFilter(TodoFilter.completed);
      expect(loaded().visibleTodos.map((t) => t.id), ['b']);
    });

    test('survives add, toggle and delete', () async {
      await loadedWith([makeTodo('a'), makeTodo('b')]);
      viewModel.setFilter(TodoFilter.active);

      await viewModel.addTodo(title: 'Baru');
      expect(loaded().filter, TodoFilter.active);

      await viewModel.toggleTodo(makeTodo('a'));
      expect(loaded().filter, TodoFilter.active);

      await viewModel.deleteTodo('b');
      expect(loaded().filter, TodoFilter.active);
    });
  });

  group('lifecycle', () {
    test('marks busy while running and refuses a second command', () async {
      await loadedWith([makeTodo('a')]);
      repository.gate = Completer<void>();

      final first = viewModel.addTodo(title: 'Satu');
      expect(loaded().isBusy, isTrue);

      final second = await viewModel.addTodo(title: 'Dua');
      expect(second.isSuccess, isFalse);

      repository.gate!.complete();
      expect((await first).isSuccess, isTrue);
      expect(loaded().isBusy, isFalse);
      expect(loaded().todos.map((t) => t.title), ['Satu', 'Tugas']);
    });

    test('does not notify after dispose', () async {
      await loadedWith([makeTodo('a')]);
      repository.gate = Completer<void>();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      final pending = viewModel.toggleTodo(makeTodo('a'));
      final countBeforeDispose = notifications;
      viewModel.dispose();
      repository.gate!.complete();
      await pending;

      expect(notifications, countBeforeDispose);
    });

    test('pull-to-refresh keeps the list when it fails', () async {
      await loadedWith([makeTodo('a')]);
      repository.failure = const NetworkFailure();

      final result = await viewModel.refresh();

      expect(result.isSuccess, isFalse);
      expect(loaded().todos, [makeTodo('a')]);
    });
  });
}