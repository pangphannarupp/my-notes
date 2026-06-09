import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/note_editor_screen.dart';
import 'screens/expense_editor_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/drawing_screen.dart';
import 'models/note_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/note_editor',
      builder: (context, state) => NoteEditorScreen(note: state.extra as NoteModel?),
    ),
    GoRoute(
      path: '/expense_editor',
      builder: (context, state) => const ExpenseEditorScreen(),
    ),
    GoRoute(
      path: '/drawing',
      builder: (context, state) => const DrawingScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
