import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/task_draft_store.dart';
import 'domain/task.dart';
import 'task_providers.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen._({
    required this.mode,
    required this.taskId,
    super.key,
  });

  const TaskFormScreen.create({super.key}) : this._(mode: _Mode.create, taskId: null);

  const TaskFormScreen.edit({required int taskId, super.key})
      : this._(mode: _Mode.edit, taskId: taskId);

  final _Mode mode;
  final int? taskId;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

enum _Mode { create, edit }

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  DateTime? _dueDate;
  TaskStatus _status = TaskStatus.todo;
  int? _blockedById;
  bool _saving = false;
  bool _loaded = false;

  final _draftStore = TaskDraftStore();

  @override
  void initState() {
    super.initState();
    _title.addListener(_persistDraftIfCreate);
    _description.addListener(_persistDraftIfCreate);
  }

  @override
  void dispose() {
    _title.removeListener(_persistDraftIfCreate);
    _description.removeListener(_persistDraftIfCreate);
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    if (_loaded) return;
    _loaded = true;

    final tasks = ref.read(tasksControllerProvider).valueOrNull ?? const <Task>[];
    if (widget.mode == _Mode.edit) {
      final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;
      if (task != null) {
        _title.text = task.title;
        _description.text = task.description;
        _dueDate = task.dueDate;
        _status = task.status;
        _blockedById = task.blockedById;
        setState(() {});
        return;
      }
    }

    if (widget.mode == _Mode.create) {
      final draft = await _draftStore.read();
      if (draft != null) {
        _title.text = draft.title;
        _description.text = draft.description;
        _dueDate = draft.dueDateIso == null ? null : DateTime.tryParse(draft.dueDateIso!);
        _status = TaskStatus.fromLabel(draft.statusLabel);
        _blockedById = draft.blockedById;
        setState(() {});
      }
    }
  }

  Future<void> _persistDraftIfCreate() async {
    if (widget.mode != _Mode.create) return;
    await _draftStore.write(
      TaskDraft(
        title: _title.text,
        description: _description.text,
        dueDateIso: _dueDate?.toIso8601String(),
        statusLabel: _status.label,
        blockedById: _blockedById,
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: DateTime(initial.year, initial.month, initial.day),
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
    await _persistDraftIfCreate();
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a due date.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final controller = ref.read(tasksControllerProvider.notifier);
      if (widget.mode == _Mode.create) {
        await controller.create(
          title: _title.text.trim(),
          description: _description.text.trim(),
          dueDate: _dueDate!,
          status: _status,
          blockedById: _blockedById,
        );
        await _draftStore.clear();
      } else {
        await controller.update(
          id: widget.taskId!,
          title: _title.text.trim(),
          description: _description.text.trim(),
          dueDate: _dueDate!,
          status: _status,
          blockedById: _blockedById,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(tasksControllerProvider.notifier).delete(widget.taskId!);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksControllerProvider).valueOrNull ?? const <Task>[];

    return FutureBuilder<void>(
      future: _loadInitial(),
      builder: (context, snap) {
        final canInteract = !_saving;

        final isEdit = widget.mode == _Mode.edit;
        final title = isEdit ? 'Edit Task' : 'New Task';

        final blockerItems = [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('None'),
          ),
          ...tasks
              .where((t) => !isEdit || t.id != widget.taskId)
              .map(
                (t) => DropdownMenuItem<int?>(
                  value: t.id,
                  child: Text(
                    t.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (isEdit)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: canInteract ? _delete : null,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: !canInteract,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _title,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _description,
                          decoration: const InputDecoration(labelText: 'Description'),
                          minLines: 3,
                          maxLines: 6,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Description is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Due Date'),
                                child: Text(
                                  _dueDate == null
                                      ? 'Not set'
                                      : MaterialLocalizations.of(context)
                                          .formatMediumDate(_dueDate!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonalIcon(
                              onPressed: _pickDueDate,
                              icon: const Icon(Icons.event),
                              label: const Text('Pick'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<TaskStatus>(
                          value: _status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
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
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => _status = v);
                            await _persistDraftIfCreate();
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          value: _blockedById,
                          decoration: const InputDecoration(labelText: 'Blocked By'),
                          items: blockerItems,
                          onChanged: (v) async {
                            setState(() => _blockedById = v);
                            await _persistDraftIfCreate();
                          },
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEdit
                              ? 'Updates simulate a 2-second save.'
                              : 'Drafts are preserved if you leave this screen.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

