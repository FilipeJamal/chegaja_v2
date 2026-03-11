import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/location_service.dart';
import 'package:chegaja_v2/core/services/favorites_service.dart';
import 'package:chegaja_v2/features/common/perfil_publico_screen.dart';

class PrestadorSelecionado {
  final String id;
  final String nome;
  final String? photoUrl;
  final double? ratingAvg;
  final int ratingCount;
  final double? distanciaKm;
  final String? city;
  final String? state;
  final String? country;

  const PrestadorSelecionado({
    required this.id,
    required this.nome,
    this.photoUrl,
    this.ratingAvg,
    this.ratingCount = 0,
    this.distanciaKm,
    this.city,
    this.state,
    this.country,
  });
}

enum _OrdenacaoPrestador { balanceado, proximidade, avaliacao }

class SelecionarPrestadorScreen extends StatefulWidget {
  final String? servicoId;
  final String? servicoNome;
  final double? latitude;
  final double? longitude;

  const SelecionarPrestadorScreen({
    super.key,
    this.servicoId,
    this.servicoNome,
    this.latitude,
    this.longitude,
  });

  @override
  State<SelecionarPrestadorScreen> createState() =>
      _SelecionarPrestadorScreenState();
}

class _SelecionarPrestadorScreenState extends State<SelecionarPrestadorScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _erro;
  String _query = '';
  _OrdenacaoPrestador _ordenacao = _OrdenacaoPrestador.balanceado;
  List<_PrestadorItem> _todos = [];
  List<_PrestadorItem> _visiveis = [];

  List<String> _favoritosIds = [];
  StreamSubscription? _favSub;

  @override
  void initState() {
    super.initState();
    _carregarPrestadores();
    _favSub = FavoritesService.instance.getFavoritesStream().listen((ids) {
      if (mounted) {
        setState(() => _favoritosIds = ids);
      }
    });

    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next == _query) return;
      setState(() {
        _query = next;
        _aplicarFiltro();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _favSub?.cancel();
    super.dispose();
  }

  Future<void> _carregarPrestadores() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final categoriaId = (widget.servicoId ?? '').trim();
      final categoriaNome = (widget.servicoNome ?? '').trim();

      Query<Map<String, dynamic>> query =
          FirebaseFirestore.instance.collection('prestadores');

      final filtro = categoriaId.isNotEmpty
          ? categoriaId
          : (categoriaNome.isNotEmpty ? categoriaNome : '');
      if (filtro.isNotEmpty) {
        query = query.where('categories', arrayContains: filtro);
      }

      final snapshot = await query.limit(50).get();
      final items = snapshot.docs.map(_mapPrestador).toList();

      if (mounted) {
        setState(() {
          _todos = items;
          _aplicarFiltro();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _loading = false;
        });
      }
    }
  }

  _PrestadorItem _mapPrestador(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final nome = (data['nome'] ??
            data['displayName'] ??
            data['name'] ??
            'Prestador')
        .toString();
    final photoUrl = (data['photoUrl'] ??
            data['fotoUrl'] ??
            data['avatarUrl'] ??
            data['photoURL'])
        ?.toString();

    final ratingAvg = (data['ratingAvg'] as num?)?.toDouble();
    final ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;

    final city = (data['city'] ?? data['cidade'])?.toString();
    final state = (data['state'] ?? data['estado'])?.toString();
    final country = (data['country'] ?? data['pais'])?.toString();

    final distanciaKm = _calcularDistanciaKm(data);

    return _PrestadorItem(
      id: doc.id,
      nome: nome,
      photoUrl: photoUrl,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      distanciaKm: distanciaKm,
      city: city,
      state: state,
      country: country,
    );
  }

  double? _calcularDistanciaKm(Map<String, dynamic> data) {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) return null;

    final coords = _extrairLatLng(data);
    if (coords == null) return null;

    return LocationService.instance.distanceKm(
      lat1: lat,
      lng1: lng,
      lat2: coords.lat,
      lng2: coords.lng,
    );
  }

  ({double lat, double lng})? _extrairLatLng(Map<String, dynamic> data) {
    final geo = data['geo'];
    if (geo is Map) {
      final geoPoint = geo['geopoint'];
      if (geoPoint is GeoPoint) {
        return (lat: geoPoint.latitude, lng: geoPoint.longitude);
      }
    }

    final lastLocation = data['lastLocation'];
    if (lastLocation is GeoPoint) {
      return (lat: lastLocation.latitude, lng: lastLocation.longitude);
    }
    if (lastLocation is Map) {
      final lat = lastLocation['lat'] ?? lastLocation['latitude'];
      final lng = lastLocation['lng'] ?? lastLocation['longitude'];
      if (lat is num && lng is num) {
        return (lat: lat.toDouble(), lng: lng.toDouble());
      }
    }

    final lat = data['latitude'] ?? data['lat'];
    final lng = data['longitude'] ?? data['lng'];
    if (lat is num && lng is num) {
      return (lat: lat.toDouble(), lng: lng.toDouble());
    }

    return null;
  }

  void _aplicarFiltro() {
    final q = _query.toLowerCase();
    _visiveis = _todos.where((p) {
      if (q.isEmpty) return true;
      final nome = p.nome.toLowerCase();
      final city = (p.city ?? '').toLowerCase();
      final state = (p.state ?? '').toLowerCase();
      final country = (p.country ?? '').toLowerCase();
      return nome.contains(q) ||
          city.contains(q) ||
          state.contains(q) ||
          country.contains(q);
    }).toList();

    _visiveis.sort(_comparePrestadores);
  }

  int _comparePrestadores(_PrestadorItem a, _PrestadorItem b) {
    switch (_ordenacao) {
      case _OrdenacaoPrestador.proximidade:
        return _compareDoubleNullable(a.distanciaKm, b.distanciaKm);
      case _OrdenacaoPrestador.avaliacao:
        final byAvg = (b.ratingAvg ?? 0).compareTo(a.ratingAvg ?? 0);
        if (byAvg != 0) return byAvg;
        return (b.ratingCount).compareTo(a.ratingCount);
      case _OrdenacaoPrestador.balanceado:
        final scoreA = (a.distanciaKm ?? 9999) - (a.ratingAvg ?? 0);
        final scoreB = (b.distanciaKm ?? 9999) - (b.ratingAvg ?? 0);
        return scoreA.compareTo(scoreB);
    }
  }

  int _compareDoubleNullable(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  String _ratingLabel(double? avg, int count) {
    if (avg == null || count == 0) return 'Sem avaliacao';
    return '${avg.toStringAsFixed(1)} ($count)';
  }

  String _distanciaLabel(double? km) {
    if (km == null) return 'Distancia indisponivel';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  String _localLabel(_PrestadorItem item) {
    final parts = [item.city, item.state, item.country]
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .toList();
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar prestador'),
        actions: [
          PopupMenuButton<_OrdenacaoPrestador>(
            onSelected: (value) {
              setState(() {
                _ordenacao = value;
                _aplicarFiltro();
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _OrdenacaoPrestador.balanceado,
                child: Text('Ordenar: balanceado'),
              ),
              PopupMenuItem(
                value: _OrdenacaoPrestador.proximidade,
                child: Text('Ordenar: proximidade'),
              ),
              PopupMenuItem(
                value: _OrdenacaoPrestador.avaliacao,
                child: Text('Ordenar: avaliacao'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Pesquisar prestador',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_erro != null)
                    ? const Center(child: Text('Erro ao carregar prestadores'))
                    : _visiveis.isEmpty
                        ? const Center(child: Text('Sem prestadores'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _visiveis.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _visiveis[index];
                              final local = _localLabel(item);
                              final isFav = _favoritosIds.contains(item.id);

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundImage: item.photoUrl != null
                                              ? NetworkImage(item.photoUrl!)
                                              : null,
                                          child: item.photoUrl == null
                                              ? Text(
                                                  item.nome.isNotEmpty
                                                      ? item.nome[0].toUpperCase()
                                                      : '?',
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.nome,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () async {
                                                      await FavoritesService.instance
                                                          .toggleFavorite(item.id);
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(4),
                                                      child: Icon(
                                                        isFav
                                                            ? Icons.favorite
                                                            : Icons.favorite_border,
                                                        size: 20,
                                                        color: isFav
                                                            ? Colors.red
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    size: 16,
                                                    color: Colors.orange,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _ratingLabel(
                                                      item.ratingAvg,
                                                      item.ratingCount,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Icon(
                                                    Icons.place,
                                                    size: 16,
                                                    color: Colors.black45,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _distanciaLabel(
                                                      item.distanciaKm,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (local.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  local,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => PublicProfileScreen(
                                                  userId: item.id,
                                                  role: 'prestador',
                                                  initialName: item.nome,
                                                  initialPhotoUrl: item.photoUrl,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Ver perfil'),
                                        ),
                                        const Spacer(),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(
                                              PrestadorSelecionado(
                                                id: item.id,
                                                nome: item.nome,
                                                photoUrl: item.photoUrl,
                                                ratingAvg: item.ratingAvg,
                                                ratingCount: item.ratingCount,
                                                distanciaKm: item.distanciaKm,
                                                city: item.city,
                                                state: item.state,
                                                country: item.country,
                                              ),
                                            );
                                          },
                                          child: const Text('Selecionar'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _PrestadorItem {
  final String id;
  final String nome;
  final String? photoUrl;
  final double? ratingAvg;
  final int ratingCount;
  final double? distanciaKm;
  final String? city;
  final String? state;
  final String? country;

  const _PrestadorItem({
    required this.id,
    required this.nome,
    required this.photoUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.distanciaKm,
    required this.city,
    required this.state,
    required this.country,
  });
}
