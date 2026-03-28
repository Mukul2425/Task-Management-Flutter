import 'package:flutter/material.dart';

import '../domain/task.dart';
import 'task_text_highlight.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.allTasks,
    required this.searchQuery,
    required this.onTap,
  });

  final Task task;
  final List<Task> allTasks;
  final String searchQuery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final blocker = task.blockedById == null
        ? null
        : allTasks.where((t) => t.id == task.blockedById).cast<Task?>().firstOrNull;
    final isBlocked = blocker != null && blocker.status != TaskStatus.done;

    final baseStyle = theme.textTheme.titleMedium!;
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: cs.primaryContainer,
      color: cs.onPrimaryContainer,
      fontWeight: FontWeight.w700,
    );

    final cardColor = isBlocked ? cs.surfaceContainerHighest : cs.surface;
    final borderSide = isBlocked ? BorderSide(color: cs.outlineVariant) : BorderSide.none;

    return Opacity(
      opacity: isBlocked ? 0.65 : 1,
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: borderSide,
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: highlightOccurrences(
                          text: task.title,
                          query: searchQuery,
                          baseStyle: baseStyle,
                          highlightStyle: highlightStyle,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusChip(status: task.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.event, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      task.dueDateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (isBlocked) ...[
                      const Spacer(),
                      Icon(Icons.lock, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Blocked by ${blocker.title}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (status) {
      TaskStatus.todo => (cs.secondaryContainer, cs.onSecondaryContainer, Icons.list_alt),
      TaskStatus.inProgress =>
        (cs.tertiaryContainer, cs.onTertiaryContainer, Icons.timelapse),
      TaskStatus.done => (cs.primaryContainer, cs.onPrimaryContainer, Icons.check_circle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

