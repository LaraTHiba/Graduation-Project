import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIPage extends StatefulWidget {
  const AIPage({Key? key}) : super(key: key);

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final TextEditingController _controller = TextEditingController();
  final Color _primaryColor = const Color(0xFF006C5F);
  List<_Message> _messages = [];
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _messages = [
        _Message(
          text:
              'Welcome to **Gang App**!\nWe\'re glad to have you here, **$_username**.\n\nStay tuned - a smart assistant is coming soon to make your experience even better!\n\nThanks for joining the **Gang**!',
          isSent: false,
        ),
      ];
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(_Message(text: text, isSent: true));
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _primaryColor.withOpacity(0.1),
              child: Icon(Icons.smart_toy_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Assistant',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.call, color: Colors.grey),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.videocam, color: Colors.grey),
              onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _MessageBubble(msg: msg, primaryColor: _primaryColor);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Your messages',
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _primaryColor,
                  radius: 24,
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
  final String? text;
  final bool isSent;
  final bool isVoice;
  final String? duration;
  final String? time;
  _Message(
      {this.text,
      required this.isSent,
      this.isVoice = false,
      this.duration,
      this.time});
}

class _MessageBubble extends StatelessWidget {
  final _Message msg;
  final Color primaryColor;
  const _MessageBubble({required this.msg, required this.primaryColor});

  List<InlineSpan> _parseBoldText(String text, TextStyle style) {
    final regex = RegExp(r'\*\*(.*?)\*\*');
    final spans = <InlineSpan>[];
    int start = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(
            TextSpan(text: text.substring(start, match.start), style: style));
      }
      spans.add(TextSpan(
          text: match.group(1),
          style: style.copyWith(fontWeight: FontWeight.bold)));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isSent = msg.isSent;
    final align = isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isSent ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight:
          isSent ? const Radius.circular(4) : const Radius.circular(18),
    );
    final bubbleColor = isSent ? primaryColor : Colors.grey[200];
    final textColor = isSent ? Colors.white : Colors.black87;
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisAlignment:
              isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isSent)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.smart_toy_rounded,
                      color: primaryColor, size: 20),
                ),
              ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: msg.isVoice
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: radius,
                ),
                child: msg.isVoice
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow,
                              color: isSent ? Colors.white : primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color:
                                    isSent ? Colors.white54 : Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(msg.duration ?? '',
                              style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    : RichText(
                        text: TextSpan(
                          children: _parseBoldText(msg.text ?? '',
                              TextStyle(color: textColor, fontSize: 16)),
                        ),
                      ),
              ),
            ),
            if (isSent)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: primaryColor, size: 20),
                ),
              ),
          ],
        ),
        if (msg.time != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 8, right: 8),
            child: Text(
              msg.time!,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
