import 'package:flutter/material.dart';

class AdminQueueFilterOption {
  const AdminQueueFilterOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class AdminQueueFilterBar extends StatelessWidget {
  const AdminQueueFilterBar({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String description;
  final String value;
  final List<AdminQueueFilterOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedValue = options.any((option) => option.value == value)
        ? value
        : options.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: selectedValue,
              items: [
                for (final option in options)
                  DropdownMenuItem(
                    value: option.value,
                    child: Text(option.label),
                  ),
              ],
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ],
        ),
      ),
    );
  }
}
