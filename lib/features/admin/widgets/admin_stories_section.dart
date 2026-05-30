import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_action_row.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_status_chip.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Moderacao de historias',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Conteudo ativo publicado por prestadores. Remover historia e uma acao destrutiva.',
                ),
              ],
            ),
          ),
        ),
        if (error != null && error!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          AdminSectionError(message: error!),
        ],
        const SizedBox(height: 8),
        if (stories.isEmpty)
          const AdminSectionEmptyState(message: 'Sem historias ativas.')
        else
          for (final story in stories)
            _StoryCard(
              story: story,
              onDeleteStory: onDeleteStory,
            ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.onDeleteStory,
  });

  final Map<String, dynamic> story;
  final Future<void> Function(String storyId) onDeleteStory;

  @override
  Widget build(BuildContext context) {
    final storyId = '${story['id'] ?? ''}'.trim();

    return AdminQueueCard(
      title: storyId.isEmpty ? '' : 'Historia $storyId',
      fallbackTitle: 'Historia sem ID',
      subtitle:
          'Prestador: ${adminTextOrFallback(story['prestadorNome'], fallback: 'Sem dados')}',
      leading: _StoryThumb(url: '${story['mediaUrl'] ?? ''}'),
      meta: [
        AdminQueueStatusChip(
          label: 'Expira',
          value: adminFormatMs(story['expiresAt']),
        ),
      ],
      children: [
        Text(adminTextOrFallback(story['descricao'])),
        const Text('Acao destrutiva'),
      ],
      actions: AdminQueueActionRow(
        actions: [
          AdminQueueAction(
            label: 'Remover',
            icon: Icons.delete_outline,
            destructive: true,
            onPressed: storyId.isEmpty ? null : () => onDeleteStory(storyId),
          ),
        ],
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
