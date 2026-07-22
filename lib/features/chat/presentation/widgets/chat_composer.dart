import 'package:flutter/material.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({super.key, required this.enabled, required this.onSend});
  final bool enabled;
  final ValueChanged<String> onSend;
  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  int get _length => _controller.text.trim().runes.length;
  bool get _valid => widget.enabled && _length >= 1 && _length <= 2000;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('chat-composer-field'),
              controller: _controller,
              enabled: widget.enabled,
              minLines: 1,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.enabled
                    ? 'Message the outing'
                    : 'Chat is read-only',
                counterText: '$_length/2000',
              ),
            ),
          ),
          IconButton.filled(
            tooltip: 'Send message',
            onPressed: _valid
                ? () {
                    final text = _controller.text;
                    _controller.clear();
                    setState(() {});
                    widget.onSend(text);
                  }
                : null,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}
