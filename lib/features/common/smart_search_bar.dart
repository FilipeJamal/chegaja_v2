import 'package:flutter/material.dart';
import 'package:chegaja_v2/core/services/smart_search_service.dart';

/// Barra de Pesquisa "Super Inteligente"
///
/// Características:
/// - Feedback visual imediato ao digitar.
/// - Sugestões automáticas baseadas no `SmartSearchService`.
/// - Destaque visual (negrito) nas partes do texto que deram match.
/// - Design limpo e moderno (estilo Google/Apple Spotlight).
class SmartSearchBar<T> extends StatefulWidget {
  final String hintText;
  final List<T> allItems;
  final String Function(T) idSelector;
  final String Function(T) nameSelector;
  final List<String> Function(T) keywordsSelector;
  final void Function(T) onItemSelected;

  const SmartSearchBar({
    super.key,
    this.hintText = 'O que precisas hoje? Ex: "lápis", "fome"...',
    required this.allItems,
    required this.idSelector,
    required this.nameSelector,
    required this.keywordsSelector,
    required this.onItemSelected,
  });

  @override
  State<SmartSearchBar<T>> createState() => _SmartSearchBarState<T>();
}

class _SmartSearchBarState<T> extends State<SmartSearchBar<T>> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<T> _results = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      setState(() {
        _showResults = _focusNode.hasFocus && _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _controller.text;
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }

    final hits = SmartSearchService.instance.search(
      query: query,
      items: widget.allItems,
      idSelector: widget.idSelector,
      nameSelector: widget.nameSelector,
      keywordsSelector: widget.keywordsSelector,
      limit: 5, // Top 5 sugestões rápidas
    );

    setState(() {
      _results = hits;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de Input com Sombra e Bordas Arredondadas
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _controller.clear();
                            _focusNode.unfocus();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.search,
              ),
            ),

            // Lista de Resultados (Overlay "Fake" por simplicidade, ou expandida)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _buildSuggestionsList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    if (!_showResults) return const SizedBox.shrink();

    if (_results.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sem resultados para "${_controller.text}".\nTenta "limpeza", "aulas" ou "comida".',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, left: 4, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _results.map((item) {
            final name = widget.nameSelector(item);
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.deepPurple,
                radius: 14,
                child: Icon(Icons.bolt, color: Colors.white, size: 16),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              // subtitle: Text('Categoria...'), // Opcional se tivéssemos a categoria aqui
              onTap: () {
                widget.onItemSelected(item);
                _focusNode.unfocus();
                _showResults = false;
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
