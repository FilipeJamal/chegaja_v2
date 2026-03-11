import 'package:flutter/material.dart';
import 'package:chegaja_v2/core/models/story.dart';
import 'package:chegaja_v2/core/repositories/stories_repo.dart';
import 'package:chegaja_v2/core/services/user_country_service.dart';
import 'package:chegaja_v2/features/common/perfil_publico_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

class StoriesCarouselWidget extends StatelessWidget {
  const StoriesCarouselWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserCountryService.instance,
      builder: (context, _) {
        final countryCode = UserCountryService.instance.countryCode;
        return StreamBuilder<List<Story>>(
          stream: StoriesRepo.streamActiveStories(countryCode: countryCode),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final stories = snapshot.data!;
            if (stories.isEmpty) return const SizedBox.shrink();

        // Agrupar stories por prestador
        final Map<String, List<Story>> grouped = {};
        for (var s in stories) {
          grouped.putIfAbsent(s.prestadorId, () => []).add(s);
        }

        final prestadoresIds = grouped.keys.toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Stories Recentes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: prestadoresIds.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final pid = prestadoresIds[index];
                      final sList = grouped[pid]!;
                      final first = sList.first;

                      return GestureDetector(
                        onTap: () {
                          _showStoryViewer(context, sList);
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.purple, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(first.mediaUrl),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 70,
                              child: Text(
                                first.prestadorNome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  void _showStoryViewer(BuildContext context, List<Story> stories) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StoryViewerScreen(stories: stories),
      ),
    );
  }
}

class _StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;

  const _StoryViewerScreen({required this.stories});

  @override
  State<_StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<_StoryViewerScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Imagem (expandida)
            Positioned.fill(
              child: Image.network(
                story.mediaUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),

            // Barra de progresso (dummy, só indicador de contagem)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: widget.stories.asMap().entries.map((entry) {
                  final idx = entry.key;
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      color: idx == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Info Prestador
            Positioned(
              top: 24,
              left: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: story.prestadorFoto != null
                        ? NetworkImage(story.prestadorFoto!)
                        : null,
                    child: story.prestadorFoto == null
                        ? Text(story.prestadorNome[0])
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    story.prestadorNome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeAgo(story.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Controles de toque
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex > 0) {
                        setState(() => _currentIndex--);
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentIndex < widget.stories.length - 1) {
                        setState(() => _currentIndex++);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),

            // Botão Fechar
            Positioned(
              top: 24,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (story.descricao != null && story.descricao!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        story.descricao!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          shadows: [
                            Shadow(offset: Offset(0, 1), blurRadius: 3.0),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(
                            userId: story.prestadorId,
                            role: 'prestador',
                            initialName: story.prestadorNome,
                            initialPhotoUrl: story.prestadorFoto,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person),
                    label: Text(l10n.chatViewProviderProfileAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'agora';
  }
}





