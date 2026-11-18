import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:afl_2/domain/failures/todo_failure.dart';
import 'package:afl_2/main.dart';

import '../helpers/fake_todo_repository.dart';

void main() {
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget appWith(FakeTodoRepository repository) {
    return ToDoApp(viewModel: buildViewModel(repository));
  }

  testWidgets('shows a spinner, then the todos', (tester) async {
    useTallScreen(tester);
    final repository = FakeTodoRepository(
      seed: [makeTodo('a', title: 'Belajar Flutter')],
    );

    await tester.pumpWidget(appWith(repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Belajar Flutter'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an empty message when there are no todos',
          (tester) async {
        useTallScreen(tester);

        await tester.pumpWidget(appWith(FakeTodoRepository()));
        await tester.pumpAndSettle();

        expect(
          find.text('Belum ada tugas. Tambahkan tugas pertamamu!'),
          findsOneWidget,
        );
      });

  testWidgets('shows a readable error and recovers with Coba Lagi',
          (tester) async {
        useTallScreen(tester);
        final repository = FakeTodoRepository(
          seed: [makeTodo('a', title: 'Pulih')],
        )..failure = const StorageFailure();

        await tester.pumpWidget(appWith(repository));
        await tester.pumpAndSettle();
        expect(
          find.text('Daftar tugas gagal dimuat. Silakan coba lagi.'),
          findsOneWidget,
        );

        repository.failure = null;
        await tester.tap(find.text('Coba Lagi'));
        await tester.pumpAndSettle();

        expect(find.text('Pulih'), findsOneWidget);
      });

  testWidgets('adds a todo through the dialog', (tester) async {
    useTallScreen(tester);
    final repository = FakeTodoRepository();

    await tester.pumpWidget(appWith(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Tugas baru');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Tugas baru'), findsOneWidget);
    expect(find.text('Tugas berhasil ditambahkan.'), findsOneWidget);
    expect(repository.todos.single.title, 'Tugas baru');
  });

  testWidgets('keeps the dialog open and explains an empty title',
          (tester) async {
        useTallScreen(tester);

        await tester.pumpWidget(appWith(FakeTodoRepository()));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simpan'));
        await tester.pumpAndSettle();

        expect(find.text('Judul tugas tidak boleh kosong.'), findsOneWidget);
        expect(find.byType(AlertDialog), findsOneWidget);
      });

  testWidgets('a failed toggle shows the error, never a success message',
          (tester) async {
        useTallScreen(tester);
        final repository = FakeTodoRepository(
          seed: [makeTodo('a', title: 'Gagal ditandai')],
        );

        await tester.pumpWidget(appWith(repository));
        await tester.pumpAndSettle();

        repository.failure = const StorageFailure();
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        expect(
          find.text('Tugas gagal diperbarui. Silakan coba lagi.'),
          findsOneWidget,
        );
        expect(find.text('Tugas berhasil diselesaikan.'), findsNothing);
        expect(find.text('Gagal ditandai'), findsOneWidget);
      });
}