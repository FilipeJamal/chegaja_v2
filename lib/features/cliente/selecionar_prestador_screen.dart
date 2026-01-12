import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/location_service.dart';
import 'package:chegaja_v2/core/services/location_data_service.dart';
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
  String _query = '';
  _OrdenacaoPrestador _ordenacao = _OrdenacaoPrestador.balanceado;
  List<_PrestadorItem> _todos = [];
  List<_PrestadorItem> _visiveis = [];

  @override
  void initState() {
    super.initState();
    _carregarPrestadores();
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
    super.dispose();
  }

  Future<void> _carregarPrestadores() async {
    setState(() => _loading = true);

    try {
      final collection = FirebaseFirestore.instance.collection('prestadores');
      final servicoId = widget.servicoId?.trim();
      final servicoNome = widget.servicoNome?.trim();

      QuerySnapshot<Map<String, dynamic>>? snapById;
      QuerySnapshot<Map<String, dynamic>>? snapByName;

      if (servicoId != null && servicoId.isNotEmpty) {
        snapById = await collection
            .where('servicos', arrayContains: servicoId)
            .get();
      }

      if ((snapById == null || snapById.docs.isEmpty) &&
          servicoNome != null &&
          servicoNome.isNotEmpty) {
        snapByName = await collection
            .where('servicosNomes', arrayContains: servicoNome)
            .get();
      }

      final Map<String, _PrestadorItem> merged = {};
      void addDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
        for (final doc in docs) {
          if (merged.containsKey(doc.id)) continue;
          final data = doc.data();
          final isOnline = (data['isOnline'] as bool?) ?? false;
          if (!isOnline) continue;

          final nome = (data['nome'] ??
                  data['displayName'] ??
                  data['name'] ??
                  'Prestador')
              .toString()
              .trim();
          final photoUrl = (data['photoUrl'] ?? data['fotoUrl'])
              ?.toString()
              .trim();

          final ratingAvg = (data['ratingAvg'] as num?)?.toDouble();
          final ratingCount = (data['ratingCount'] as num?)?.toInt() ?? 0;

          final lastLoc = data['lastLocation'] as Map<String, dynamic>?;
          final lat = (lastLoc?['lat'] as num?)?.toDouble();
          final lng = (lastLoc?['lng'] as num?)?.toDouble();
          double? distanciaKm;

          if (widget.latitude != null &&
              widget.longitude != null &&
              lat != null &&
              lng != null) {
            distanciaKm = LocationService.instance.distanceKm(
              lat1: widget.latitude!,
              lng1: widget.longitude!,
              lat2: lat,
              lng2: lng,
            );
          }

          final radiusKm = (data['radiusKm'] as num?)?.toDouble();
          if (radiusKm != null &&
              distanciaKm != null &&
              distanciaKm > radiusKm) {
            continue;
          }

          merged[doc.id] = _PrestadorItem(
            id: doc.id,
            nome: nome,
            photoUrl: photoUrl?.isEmpty ?? true ? null : photoUrl,
            ratingAvg: ratingAvg,
            ratingCount: ratingCount,
            distanciaKm: distanciaKm,
            city: (data['city'] ?? data['cidade'])?.toString().trim(),
            state: (data['state'] ?? data['province'])?.toString().trim(),
            country: (data['country'] ?? data['pais'])?.toString().trim(),
          );
        }
      }

      if (snapById != null) {
        addDocs(snapById.docs);
      }
      if (snapByName != null) {
        addDocs(snapByName.docs);
      }

      setState(() {
        _todos = merged.values.toList();
        _aplicarFiltro();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar prestadores: $e')),
      );
    }
  }

  void _aplicarFiltro() {
    final q = LocationDataService.normalize(_query);
    var lista = _todos.where((item) {
      if (q.isEmpty) return true;
      final parts = <String>[
        item.nome,
        if (item.city != null) item.city!,
        if (item.state != null) item.state!,
        if (item.country != null) item.country!,
      ];
      final haystack = LocationDataService.normalize(parts.join(' '));
      return haystack.contains(q);
    }).toList();

    int compareDist(_PrestadorItem a, _PrestadorItem b) {
      final da = a.distanciaKm;
      final db = b.distanciaKm;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    }

    int compareRating(_PrestadorItem a, _PrestadorItem b) {
      final ra = a.ratingAvg ?? 0.0;
      final rb = b.ratingAvg ?? 0.0;
      if (ra != rb) return rb.compareTo(ra);
      return b.ratingCount.compareTo(a.ratingCount);
    }

    lista.sort((a, b) {
      switch (_ordenacao) {
        case _OrdenacaoPrestador.proximidade:
          final dist = compareDist(a, b);
          if (dist != 0) return dist;
          return compareRating(a, b);
        case _OrdenacaoPrestador.avaliacao:
          final rating = compareRating(a, b);
          if (rating != 0) return rating;
          return compareDist(a, b);
        case _OrdenacaoPrestador.balanceado:
          final dist = compareDist(a, b);
          if (dist != 0) return dist;
          return compareRating(a, b);
      }
    });

    _visiveis = lista;
  }

  String _distanciaLabel(double? km) {
    if (km == null) return 'Distancia indisponivel';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  String _ratingLabel(double? avg, int count) {
    if (avg == null || count == 0) return 'Sem avaliacoes';
    return '${avg.toStringAsFixed(1)} ($count)';
  }

  @override
  Widget build(BuildContext context) {
    final categoriaRaw = (widget.servicoNome ?? '').trim();
    final categoriaLabel =
        categoriaRaw.isNotEmpty ? categoriaRaw : 'Categoria nao definida';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar prestador'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Text('Categoria:'),
                const SizedBox(width: 8),
                Chip(label: Text(categoriaLabel)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Pesquisar por nome',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Text('Ordenar por:'),
                const SizedBox(width: 12),
                DropdownButton<_OrdenacaoPrestador>(
                  value: _ordenacao,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _ordenacao = value;
                      _aplicarFiltro();
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: _OrdenacaoPrestador.balanceado,
                      child: Text('Proximidade + avaliacao'),
                    ),
                    DropdownMenuItem(
                      value: _OrdenacaoPrestador.proximidade,
                      child: Text('Proximidade'),
                    ),
                    DropdownMenuItem(
                      value: _OrdenacaoPrestador.avaliacao,
                      child: Text('Avaliacao'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _visiveis.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum prestador disponivel para este servico.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _visiveis.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _visiveis[index];
                          final local = [
                            item.city,
                            item.state,
                            item.country,
                          ]
                              .whereType<String>()
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .join(', ');

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
                                          Text(
                                            item.nome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
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
