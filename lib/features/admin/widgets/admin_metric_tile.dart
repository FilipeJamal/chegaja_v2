import 'package:flutter/material.dart';

class AdminMetricTile extends StatelessWidget {
  const AdminMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.helper,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final helperText = helper?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (helperText != null && helperText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    helperText,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
