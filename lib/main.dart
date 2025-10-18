import 'package:flutter/material.dart';
import 'ollama_client.dart';

void main() => runApp(const JyotishiApp());

class JyotishiApp extends StatelessWidget {
  const JyotishiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jyotishi — AI Astrology',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = OllamaClient();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  /// Holds the entire conversation
  final List<Map<String, String>> _chat = [];

  bool _loading = false;

  Future<void> _send() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    print("✅ Send button pressed: $userText");

    // Add user message to chat
    _chat.add({"role": "user", "content": userText});
    _controller.clear();
    setState(() {
      _loading = true;
    });

    // Build conversation context
    final conversation = _chat.map((m) {
      return "${m["role"]}: ${m["content"]}";
    }).join("\n\n");

    final prompt = '''
You are Jyotishi, a calm and kind Vedic astrologer.
Keep the context of the previous conversation in mind.
If the user hasn’t given their date, time, or place of birth, politely ask.
Provide thoughtful, positive guidance.
Always end with:
"Astrology is for guidance, not a substitute for professional advice."

Conversation so far:
$conversation

assistant:
''';

    try {
      print("📡 Sending contextual request to Ollama...");
      final reply = await _client.generate(prompt);
      print("✅ Got reply: $reply");

      // Add model reply to chat
      _chat.add({"role": "assistant", "content": reply});

      // Scroll to bottom after reply
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      setState(() {});
    } catch (e, st) {
      print("❌ Error: $e");
      print(st);
      setState(() {
        _chat.add({"role": "assistant", "content": "⚠️ Error: $e"});
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E8FF),
      appBar: AppBar(
        title: const Text('Jyotishi — AI Astrology'),
        backgroundColor: Colors.deepPurple.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Chat',
            onPressed: () {
              setState(() {
                _chat.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat window
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _chat.length,
                itemBuilder: (context, index) {
                  final msg = _chat[index];
                  final isUser = msg["role"] == "user";
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.deepPurple.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg["content"] ?? '',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 1),

          // Input field
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask your question...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _loading ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
