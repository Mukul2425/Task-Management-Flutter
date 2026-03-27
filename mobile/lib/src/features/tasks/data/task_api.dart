import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../domain/task.dart';

class TaskApi {
  TaskApi({
    required ApiClient client,
    String? baseUrl,
  })  : _dio = client.dio,
        _baseUrl = baseUrl ?? ApiClient.defaultBaseUrl() {
    _dio.options = _dio.options.copyWith(baseUrl: _baseUrl);
  }

  final Dio _dio;
  final String _baseUrl;

  Future<List<Task>> listTasks() async {
    final res = await _dio.get<List<dynamic>>('/tasks');
    final data = (res.data ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(Task.fromApiJson)
        .toList();
    return data;
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskStatus status,
    required int? blockedById,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/tasks',
      data: {
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String().split('T').first,
        'status': status.label,
        'blocked_by_id': blockedById,
      },
    );
    return Task.fromApiJson(res.data!);
  }

  Future<Task> updateTask({
    required int id,
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskStatus status,
    required int? blockedById,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/tasks/$id',
      data: {
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String().split('T').first,
        'status': status.label,
        'blocked_by_id': blockedById,
      },
    );
    return Task.fromApiJson(res.data!);
  }

  Future<void> deleteTask(int id) async {
    await _dio.delete<void>('/tasks/$id');
  }
}

