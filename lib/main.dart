import 'dart:async';
import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/di/injection.dart';
import 'presentation/pages/todo_page.dart';
import 'presentation/viewmodels/todo_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.create();
  runApp(ToDoApp(viewModel: dependencies.todoViewModel));
}

class ToDoApp extends StatefulWidget {
  final TodoViewModel viewModel;
  const ToDoApp({super.key, required this.viewModel});

  @override
  State<ToDoApp> createState() => _ToDoAppState();
}

class _ToDoAppState extends State<ToDoApp> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.loadTodos());
  }

  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'To Do',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
      ),
      scaffoldBackgroundColor: AppColors.background,
    ),
    home: TodoPage(viewModel: widget.viewModel),
  );
}