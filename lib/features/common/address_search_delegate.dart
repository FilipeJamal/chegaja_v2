import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chegaja_v2/core/services/address_autocomplete_service.dart';

class AddressSearchDelegate extends SearchDelegate<AddressResult?> {
  final AddressAutocompleteService _service = AddressAutocompleteService.instance;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Se o utilizador confirmar a pesquisa (Enter), forçamos uma busca imediata
    // ou apenas mostramos a mesma UI de sugestões (que já lida com a busca).
    return _DebouncedSuggestions(
      query: query,
      service: _service,
      onSelected: (result) => close(context, result),
      immediate: true, // Forçar busca imediata se for 'Resultados'
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _DebouncedSuggestions(
      query: query,
      service: _service,
      onSelected: (result) => close(context, result),
    );
  }
}

class _DebouncedSuggestions extends StatefulWidget {
  final String query;
  final AddressAutocompleteService service;
  final ValueChanged<AddressResult> onSelected;
  final bool immediate;

  const _DebouncedSuggestions({
    required this.query,
    required this.service,
    required this.onSelected,
    this.immediate = false,
  });

  @override
  State<_DebouncedSuggestions> createState() => _DebouncedSuggestionsState();
}

class _DebouncedSuggestionsState extends State<_DebouncedSuggestions> {
  Timer? _debounce;
  List<AddressResult> _results = [];
  bool _isLoading = false;
  String? _error;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    _onQueryChanged();
  }

  @override
  void didUpdateWidget(covariant _DebouncedSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query || widget.immediate != oldWidget.immediate) {
      _onQueryChanged();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged() {
    // Se a query for curta, limpamos tudo
    if (widget.query.trim().length < 3) {
      _debounce?.cancel();
      setState(() {
        _results = [];
        _isLoading = false;
        _error = null;
        _lastQuery = widget.query;
      });
      return;
    }

    // Se já buscamos esta exata query com sucesso, não fazemos nada (cache simples local)
    // Mas se for 'immediate' (enter pressionado), podemos querer forçar.
    if (_lastQuery == widget.query && !_isLoading && _error == null && !widget.immediate) {
      return;
    }

    // Cancelar timer anterior
    _debounce?.cancel();

    if (widget.immediate) {
      _performSearch();
    } else {
      _debounce = Timer(const Duration(milliseconds: 700), () {
        _performSearch();
      });
    }
  }

  Future<void> _performSearch() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await widget.service.search(widget.query);
      if (!mounted) return;
      
      setState(() {
        _results = results;
        _isLoading = false;
        _lastQuery = widget.query;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao buscar endereços.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.query.trim().length < 3) {
      return Center(
        child: Text(
          'Digita pelo menos 3 letras...',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: LinearProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_results.isEmpty) {
      return const Center(child: Text('Nenhum endereço encontrado.'));
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _results[index];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(item.label),
          subtitle: Text(
            '${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () {
            widget.onSelected(item);
          },
        );
      },
    );
  }
}
