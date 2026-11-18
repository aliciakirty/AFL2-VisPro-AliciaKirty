import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afl_2/core/di/injection.dart';
import 'package:afl_2/main.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('To Do page loads and displays app title', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dependencies = await AppDependencies.create();
    await tester.pumpWidget(ToDoApp(viewModel: dependencies.todoViewModel));
    await tester.pumpAndSettle();
    expect(find.text('To Do'), findsOneWidget);
  });
}