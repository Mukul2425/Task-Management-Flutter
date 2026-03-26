import 'package:flutter/material.dart';

import 'features/tasks/task_list_screen.dart';

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
    );

    return MaterialApp(
      title: 'Tasks',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        cardTheme: const CardTheme(
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: const TaskListScreen(),
    );
  }
}

