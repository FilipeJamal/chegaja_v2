import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chegaja_v2/core/services/favorites_service.dart';
import 'package:chegaja_v2/features/common/perfil_publico_screen.dart';
// Idealmente usar o modelo Prestador
// Mas como SelecionarPrestadorScreen usa _PrestadorItem local, vou fazer algo similar ou melhor:
// Vou buscar os dados brutos e construir a UI.

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  List<Map<String, dynamic>> _favoritos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoritos();
  }

  Future<void> _loadFavoritos() async {
    setState(() => _loading = true);
    try {
      final favIds = await FavoritesService.instance.getFavorites();

      if (favIds.isEmpty) {
        if (mounted) {
          setState(() {
            _favoritos = [];
            _loading = false;
          });
        }
        return;
      }

      // Firestore whereIn limita a 10. Se tivermos mais, precisamos de chunks ou fetch individual.
      // Para simplificar, vou fazer fetch individual em paralelo (até uns 20 não é critico).
      // Se escalar muito, mudar para chunks.

      final futures = favIds.map(
        (id) =>
            FirebaseFirestore.instance.collection('prestadores').doc(id).get(),
      );

      final snaps = await Future.wait(futures);
      final validDocs = snaps.where((doc) => doc.exists).map((doc) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _favoritos = validDocs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar favoritos: $e')),
        );
      }
    }
  }

  String _ratingLabel(dynamic avg, dynamic count) {
    if (avg == null || count == null || count == 0) return 'Sem avaliações';
    final nAvg = (avg as num).toDouble();
    final nCount = (count as num).toInt();
    return '${nAvg.toStringAsFixed(1)} ($nCount)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Favoritos'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favoritos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Ainda não tens favoritos.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoritos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final item = _favoritos[i];
                    final nome =
                        item['nome'] ?? item['displayName'] ?? 'Prestador';
                    final photoUrl = item['photoUrl'] ?? item['fotoUrl'];
                    final ratingAvg = item['ratingAvg'];
                    final ratingCount = item['ratingCount'];
                    final city = item['city'] ?? item['cidade'];

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage:
                              photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? Text(nome[0].toString().toUpperCase())
                              : null,
                        ),
                        title: Text(
                          nome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _ratingLabel(ratingAvg, ratingCount),
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (city != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                city,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () async {
                            await FavoritesService.instance
                                .toggleFavorite(item['id']);
                            await _loadFavoritos(); // Reload list
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PublicProfileScreen(
                                userId: item['id'],
                                role: 'prestador',
                                initialName: nome,
                                initialPhotoUrl: photoUrl,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
