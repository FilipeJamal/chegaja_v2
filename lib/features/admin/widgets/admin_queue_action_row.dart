import 'package:flutter/material.dart';

class AdminQueueAction {
  const AdminQueueAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool destructive;
}

class AdminQueueActionRow extends StatelessWidget {
  const AdminQueueActionRow({
    super.key,
    required this.actions,
  });

  final List<AdminQueueAction> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in actions)
          if (action.primary)
            FilledButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: Text(action.label),
            )
          else
            OutlinedButton.icon(
              onPressed: action.onPressed,
              style: action.destructive
                  ? OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    )
                  : null,
              icon: Icon(action.icon),
              label: Text(action.label),
            ),
      ],
    );
  }
}
