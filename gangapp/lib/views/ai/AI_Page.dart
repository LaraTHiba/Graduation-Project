import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../languages/language.dart';
import 'package:provider/provider.dart';

class AI_Page extends StatefulWidget {
  const AI_Page({Key? key}) : super(key: key);

  @override
  State<AI_Page> createState() => _AI_PageState();
}

class _AI_PageState extends State<AI_Page> {
  final TextEditingController _controller = TextEditingController();
  final List<_Message> _messages = [];
  final AIService _aiService = AIService();
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text: text, isSent: true));
      _controller.clear();
      _isLoading = true;
    });

    try {
      final reply = await _aiService.sendMessage(text);
      setState(() {
        _messages.add(_Message(text: reply, isSent: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message(text: 'Error: ${e.toString()}', isSent: false));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.read<Language>();
    return Scaffold(
      appBar: AppBar(
        title: Text(language.get('ai')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: language.get('Write a message...'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isSent;

  _Message({required this.text, required this.isSent});
}

class _MessageBubble extends StatelessWidget {
  final _Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isSent
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isSent ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
