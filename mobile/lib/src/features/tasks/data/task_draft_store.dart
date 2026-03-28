import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/task.dart';

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.dueDateIso,
    required this.statusLabel,
    required this.blockedById,
  });

  final String title;
  final String description;
  final String? dueDateIso;
  final String statusLabel;
  final int? blockedById;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'dueDateIso': dueDateIso,
        'statusLabel': statusLabel,
        'blockedById': blockedById,
      };

  static TaskDraft fromJson(Map<String, dynamic> json) {
    return TaskDraft(
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      dueDateIso: json['dueDateIso'] as String?,
      statusLabel: (json['statusLabel'] as String?) ?? TaskStatus.todo.label,
      blockedById: json['blockedById'] as int?,
    );
  }
}

class TaskDraftStore {
  static const _key = 'draft_task_create_v1';

  Future<TaskDraft?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return TaskDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(TaskDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

