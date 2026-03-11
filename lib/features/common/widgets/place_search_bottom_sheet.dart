import 'dart:async';

import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/google_places_service.dart';
import 'package:chegaja_v2/core/services/location_data_service.dart';

class PlaceSearchBottomSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final List<String> localItems;
  final PlaceSearchType type;
  final String? countryCode;
  final int maxLocal;
  final int maxOnline;

  const PlaceSearchBottomSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.localItems,
    required this.type,
    this.countryCode,
    this.maxLocal = 200,
    this.maxOnline = 20,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String hintText,
    required List<String> localItems,
    required PlaceSearchType type,
    String? countryCode,
    int maxLocal = 200,
    int maxOnline = 20,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return PlaceSearchBottomSheet(
          title: title,
          hintText: hintText,
          localItems: localItems,
          type: type,
          countryCode: countryCode,
          maxLocal: maxLocal,
          maxOnline: maxOnline,
        );
      },
    );
  }

  @override
  State<PlaceSearchBottomSheet> createState() => _PlaceSearchBottomSheetState();
}

class _PlaceSearchBottomSheetState extends State<PlaceSearchBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _online = const [];
  bool _loadingOnline = false;
  late final String _sessionToken;

  @override
  void initState() {
    super.initState();
    _sessionToken = GooglePlacesService.createSessionToken();
    _searchCtrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchCtrl.text.trim();
    _debounce?.cancel();
    if (!GooglePlacesService.isAvailable || query.length < 2) {
      if (_online.isNotEmpty || _loadingOnline) {
        setState(() {
          _online = const [];
          _loadingOnline = false;
        });
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loadingOnline = true);
      final results = await GooglePlacesService.autocomplete(
        query: query,
        type: widget.type,
        countryCode: widget.countryCode,
        sessionToken: _sessionToken,
      );
      if (!mounted) return;
      setState(() {
        _online = results;
        _loadingOnline = false;
      });
    });
  }

  List<_SearchItem> _buildItems() {
    final q = LocationDataService.normalize(_searchCtrl.text);
    final seen = <String>{};
    final items = <_SearchItem>[];

    final locals = widget.localItems;
    for (final item in locals) {
      if (items.length >= widget.maxLocal) break;
      final norm = LocationDataService.normalize(item);
      if (q.isNotEmpty && !norm.contains(q)) continue;
      if (norm.isEmpty || seen.contains(norm)) continue;
      seen.add(norm);
      items.add(_SearchItem(
        value: item,
        label: item,
        isOnline: false,
      ),);
    }

    for (final suggestion in _online) {
      if (items.length >= widget.maxLocal + widget.maxOnline) break;
      final norm = LocationDataService.normalize(suggestion.mainText);
      if (norm.isEmpty || seen.contains(norm)) continue;
      seen.add(norm);
      items.add(_SearchItem(
        value: suggestion.mainText,
        label: suggestion.label,
        subtitle: suggestion.secondaryText,
        isOnline: true,
      ),);
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: widget.hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _loadingOnline
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return ListTile(
                        leading: item.isOnline
                            ? const Icon(Icons.cloud_outlined, size: 20)
                            : const Icon(Icons.place_outlined, size: 20),
                        title: Text(item.label),
                        subtitle:
                            item.subtitle != null ? Text(item.subtitle!) : null,
                        onTap: () => Navigator.of(ctx).pop(item.value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchItem {
  final String value;
  final String label;
  final String? subtitle;
  final bool isOnline;

  _SearchItem({
    required this.value,
    required this.label,
    required this.isOnline,
    this.subtitle,
  });
}
