import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'data/task_api.dart';
import 'domain/task.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final taskApiProvider = Provider<TaskApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return TaskApi(client: client);
});

class TasksController extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final api = ref.watch(taskApiProvider);
    return api.listTasks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(taskApiProvider);
      return api.listTasks();
    });
  }

  Future<Task> create({
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskStatus status,
    required int? blockedById,
  }) async {
    final api = ref.read(taskApiProvider);
    final created = await api.createTask(
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      blockedById: blockedById,
    );
    final current = state.valueOrNull ?? const <Task>[];
    state = AsyncData([created, ...current]);
    return created;
  }

  Future<Task> update({
    required int id,
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskStatus status,
    required int? blockedById,
  }) async {
    final api = ref.read(taskApiProvider);
    final updated = await api.updateTask(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      blockedById: blockedById,
    );

    final current = state.valueOrNull ?? const <Task>[];
    state = AsyncData([
      for (final t in current) if (t.id == id) updated else t,
    ]);
    return updated;
  }

  Future<void> delete(int id) async {
    final api = ref.read(taskApiProvider);
    await api.deleteTask(id);
    final current = state.valueOrNull ?? const <Task>[];
    state = AsyncData(current.where((t) => t.id != id).toList());
  }
}

final tasksControllerProvider =
    AsyncNotifierProvider<TasksController, List<Task>>(TasksController.new);

class TaskListQuery {
  const TaskListQuery({
    required this.search,
    required this.statusFilter,
  });

  final String search;
  final TaskStatus? statusFilter;

  TaskListQuery copyWith({String? search, TaskStatus? statusFilter}) {
    return TaskListQuery(
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

final taskListQueryProvider = StateProvider<TaskListQuery>(
  (ref) => const TaskListQuery(search: '', statusFilter: null),
);

final filteredTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksControllerProvider).valueOrNull ?? const <Task>[];
  final query = ref.watch(taskListQueryProvider);
  final search = query.search.trim().toLowerCase();

  var filtered = tasks;
  if (query.statusFilter != null) {
    filtered = filtered.where((t) => t.status == query.statusFilter).toList();
  }
  if (search.isNotEmpty) {
    filtered = filtered
        .where((t) => t.title.toLowerCase().contains(search))
        .toList();
  }

  filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return filtered;
});

