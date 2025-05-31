import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../languages/language.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';

const Color kPrimaryColor = Color(0xFF006C5F);
const Color kSecondaryColor = Color(0xFF757575);

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
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Add the default welcome message
    _messages.add(_Message(
        text:
            "Welcome to Gang App! 🎉\nWe're glad to have you here.\n\nDeepSeek assistant here to make your experience even better! 🤖\n\nThanks for joining the Gang",
        isSent: false));
  }

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
      final response = await _apiService.searchCVs(text);
      print('Raw AI reply: $reply');
      print(response);

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : null,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 8),
            Text(language.get('ai')),
          ],
        ),
        backgroundColor: kPrimaryColor,
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
              child: CircularProgressIndicator(color: kPrimaryColor),
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
                        borderSide: const BorderSide(color: kPrimaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            const BorderSide(color: kPrimaryColor, width: 2),
                      ),
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                      filled: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: message.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              message.isSent ? kPrimaryColor : kPrimaryColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (message.isSent)
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isDarkMode && !message.isSent
                ? Colors.white
                : (message.isSent ? Colors.white : kPrimaryColor),
            fontWeight: message.isSent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
