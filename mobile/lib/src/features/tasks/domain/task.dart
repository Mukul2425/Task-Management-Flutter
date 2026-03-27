import 'package:intl/intl.dart';

enum TaskStatus {
  todo('To-Do'),
  inProgress('In Progress'),
  done('Done');

  const TaskStatus(this.label);
  final String label;

  static TaskStatus fromLabel(String label) {
    return TaskStatus.values.firstWhere((s) => s.label == label);
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.blockedById,
  });

  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final int? blockedById;

  String get dueDateLabel => DateFormat.yMMMEd().format(dueDate);

  Map<String, dynamic> toApiJson() => {
        'title': title,
        'description': description,
        'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
        'status': status.label,
        'blocked_by_id': blockedById,
      };

  static Task fromApiJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: TaskStatus.fromLabel(json['status'] as String),
      blockedById: json['blocked_by_id'] as int?,
    );
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    int? blockedById,
    bool blockedByIdToNull = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: blockedByIdToNull ? null : (blockedById ?? this.blockedById),
    );
  }
}

