import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

class AdminStoriesSection extends StatelessWidget {
  const AdminStoriesSection({
    super.key,
    required this.stories,
    required this.onDeleteStory,
    this.error,
  });

  final List<Map<String, dynamic>> stories;
  final Future<void> Function(String storyId) onDeleteStory;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Moderacao de historias',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (error != null && error!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              AdminSectionError(message: error!),
            ],
            const SizedBox(height: 12),
            if (stories.isEmpty)
              const AdminSectionEmptyState(message: 'Sem historias ativas.')
            else
              for (final story in stories)
                ListTile(
                  leading: _StoryThumb(url: '${story['mediaUrl'] ?? ''}'),
                  title: Text('${story['prestadorNome'] ?? '-'}'),
                  subtitle: Text(
                    '${story['descricao'] ?? ''}\n'
                    'Expira: ${adminFormatMs(story['expiresAt'])}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Remover historia',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDeleteStory('${story['id'] ?? ''}'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _StoryThumb extends StatelessWidget {
  const _StoryThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return const Icon(Icons.image_outlined);
    }
    return Image.network(
      url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }
}
