import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchBar extends StatefulWidget {
  final Function(String) onQueryChanged;
  final Color color;

  const SearchBar({
    required this.onQueryChanged,
    required this.color,
    super.key,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _suggestions = ['#', '=', '#='];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _controller.text.isEmpty) {
        _showSuggestions();
      } else {
        _hideSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _hideSuggestions();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showSuggestions() {
    if (_overlayEntry != null) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 5,
          width: size.width,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.blueAccent,
                    ),
                  ),
                  title: Text(
                    suggestion == '#'
                        ? 'Search users'
                        : suggestion == '='
                            ? 'Search posts'
                            : 'Search community',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _onSuggestionSelected(suggestion),
                );
              },
            ).animate().fadeIn(duration: 300.ms).moveY(
                  begin: 10,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOut,
                ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onSuggestionSelected(String suggestion) {
    _controller.text = suggestion;
    widget.onQueryChanged(suggestion);
    _hideSuggestions();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: 'Search...',
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: widget.color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white70),
      onChanged: (query) {
        widget.onQueryChanged(query);
        if (query.isEmpty && _focusNode.hasFocus) {
          _showSuggestions();
        } else {
          _hideSuggestions();
        }
      },
    );
  }
}
