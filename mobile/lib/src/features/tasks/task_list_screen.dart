import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/task.dart';
import 'presentation/task_card.dart';
import 'task_form_screen.dart';
import 'task_providers.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  Timer? _debounce;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(taskListQueryProvider.notifier).state =
          ref.read(taskListQueryProvider).copyWith(search: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksControllerProvider);
    final filtered = ref.watch(filteredTasksProvider);
    final query = ref.watch(taskListQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(tasksControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TaskFormScreen.create()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search by title',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<TaskStatus?>(
                    value: query.statusFilter,
                    onChanged: (value) {
                      ref.read(taskListQueryProvider.notifier).state =
                          query.copyWith(statusFilter: value);
                    },
                    items: const [
                      DropdownMenuItem<TaskStatus?>(
                        value: null,
                        child: Text('All'),
                      ),
                      DropdownMenuItem(
                        value: TaskStatus.todo,
                        child: Text('To-Do'),
                      ),
                      DropdownMenuItem(
                        value: TaskStatus.inProgress,
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(
                        value: TaskStatus.done,
                        child: Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasksAsync.when(
                data: (_) {
                  if (filtered.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final task = filtered[i];
                      return TaskCard(
                        task: task,
                        allTasks: ref.watch(tasksControllerProvider).valueOrNull ??
                            const <Task>[],
                        searchQuery: query.search,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TaskFormScreen.edit(taskId: task.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(
                  error: e,
                  onRetry: () => ref.read(tasksControllerProvider.notifier).refresh(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: cs.outline),
            const SizedBox(height: 10),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Create a task to get started.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44),
            const SizedBox(height: 10),
            Text(
              'Could not load tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

