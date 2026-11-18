import 'package:flutter_test/flutter_test.dart';

import 'package:afl_2/domain/failures/todo_failure.dart';
import 'package:afl_2/domain/usecases/get_todos.dart';
import 'package:afl_2/domain/usecases/add_todo.dart';
import 'package:afl_2/domain/usecases/update_todo.dart';
import 'package:afl_2/domain/usecases/delete_todo.dart';

import '../helpers/fake_todo_repository.dart';

void main() {

  group('GetTodos', () {
    test('mengambil seluruh tugas dari repository', () async {
      final todo = makeTodo('1', title: 'Belajar Flutter');

      final repository = FakeTodoRepository(
        seed: [todo],
      );

      final useCase = GetTodos(repository);

      final result = await useCase();

      expect(result, [todo]);
    });

    test('mengembalikan daftar kosong jika tidak ada tugas', () async {
      final repository = FakeTodoRepository();

      final useCase = GetTodos(repository);

      final result = await useCase();

      expect(result, isEmpty);
    });

    test('meneruskan kegagalan dari repository', () async {
      final repository = FakeTodoRepository()
        ..failure = const StorageFailure();

      final useCase = GetTodos(repository);

      await expectLater(
        useCase(),
        throwsA(isA<StorageFailure>()),
      );
    });
  });

  group('AddTodo', () {
    test('menambahkan tugas dengan judul dan deskripsi yang dirapikan',
            () async {
          final repository = FakeTodoRepository();

          final useCase = AddTodo(repository);

          final result = await useCase(
            title: '  Belajar Flutter  ',
            description: '  Mempelajari MVVM  ',
          );

          expect(result.title, 'Belajar Flutter');
          expect(result.description, 'Mempelajari MVVM');
          expect(repository.todos, hasLength(1));
        });

    test('menolak judul yang kosong', () async {
      final repository = FakeTodoRepository();

      final useCase = AddTodo(repository);

      await expectLater(
        useCase(title: '   '),
        throwsA(isA<EmptyTitleFailure>()),
      );

      expect(repository.todos, isEmpty);
    });

    test('meneruskan kegagalan penyimpanan dari repository', () async {
      final repository = FakeTodoRepository()
        ..failure = const StorageFailure();

      final useCase = AddTodo(repository);

      await expectLater(
        useCase(title: 'Tugas baru'),
        throwsA(isA<StorageFailure>()),
      );
    });
  });

  group('UpdateTodo', () {
    test('memperbarui tugas dan merapikan teks', () async {
      final original = makeTodo(
        '1',
        title: 'Judul lama',
        description: 'Deskripsi lama',
      );

      final repository = FakeTodoRepository(
        seed: [original],
      );

      final useCase = UpdateTodo(repository);

      final result = await useCase(
        original.copyWith(
          title: '  Judul baru  ',
          description: '  Deskripsi baru  ',
        ),
      );

      expect(result.title, 'Judul baru');
      expect(result.description, 'Deskripsi baru');
      expect(repository.todos.single.title, 'Judul baru');
    });

    test('menolak judul kosong saat memperbarui tugas', () async {
      final original = makeTodo('1');

      final repository = FakeTodoRepository(
        seed: [original],
      );

      final useCase = UpdateTodo(repository);

      await expectLater(
        useCase(original.copyWith(title: '   ')),
        throwsA(isA<EmptyTitleFailure>()),
      );

      expect(repository.todos.single.title, original.title);
    });

    test('menghasilkan NotFoundFailure jika tugas tidak ditemukan',
            () async {
          final repository = FakeTodoRepository();

          final useCase = UpdateTodo(repository);

          await expectLater(
            useCase(makeTodo('tidak-ada')),
            throwsA(isA<NotFoundFailure>()),
          );
        });
  });


  group('DeleteTodo', () {
    test('menghapus tugas berdasarkan ID', () async {
      final repository = FakeTodoRepository(
        seed: [
          makeTodo('1', title: 'Tugas pertama'),
          makeTodo('2', title: 'Tugas kedua'),
        ],
      );

      final useCase = DeleteTodo(repository);

      await useCase('1');

      expect(repository.todos, hasLength(1));
      expect(repository.todos.single.id, '2');
    });

    test('tidak mengubah data jika ID tidak ditemukan', () async {
      final repository = FakeTodoRepository(
        seed: [makeTodo('1')],
      );

      final useCase = DeleteTodo(repository);

      await useCase('tidak-ada');

      expect(repository.todos, hasLength(1));
    });

    test('meneruskan kegagalan dari repository', () async {
      final repository = FakeTodoRepository(
        seed: [makeTodo('1')],
      )..failure = const StorageFailure();

      final useCase = DeleteTodo(repository);

      await expectLater(
        useCase('1'),
        throwsA(isA<StorageFailure>()),
      );
    });
  });
}