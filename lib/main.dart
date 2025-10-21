import 'package:flutter/material.dart';
import 'ollama_client.dart';

void main() => runApp(const JyotishiApp());

class JyotishiApp extends StatefulWidget {
  const JyotishiApp({super.key});

  @override
  State<JyotishiApp> createState() => _JyotishiAppState();
}

class _JyotishiAppState extends State<JyotishiApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jyotishi — AI Astrology',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFF7F3FF),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 16, height: 1.5),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.amber,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: ChatScreen(toggleTheme: () {
        setState(() => _darkMode = !_darkMode);
      }),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ChatScreen({super.key, required this.toggleTheme});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _client = OllamaClient();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _chat = [];
  bool _loading = false;

  late AnimationController _fadeController;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  Future<void> _send() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      _chat.add({"role": "user", "content": userText});
      _controller.clear();
      _loading = true;
    });

    final conversation = _chat.map((m) => "${m["role"]}: ${m["content"]}").join("\n\n");

    final prompt = '''
You are Jyotishi, a calm and kind Vedic astrologer.
If the user hasn’t given their date, time, or place of birth, ask politely.
Provide positive guidance.
Always end with:
"Astrology is for guidance, not a substitute for professional advice."

Conversation so far:
$conversation

assistant:
''';

    try {
      final reply = await _client.generate(prompt);
      setState(() => _chat.add({"role": "assistant", "content": reply}));
    } catch (e) {
      setState(() => _chat.add({"role": "assistant", "content": e.toString()}));
    } finally {
      setState(() => _loading = false);
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jyotishi — AI Astrology'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Chat',
            onPressed: () => setState(() => _chat.clear()),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle Theme',
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // Background gradient with subtle cosmic pattern
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB993D6),
                    Color(0xFF8CA6DB),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Chat interface
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _chat.length,
                    itemBuilder: (context, index) {
                      final msg = _chat[index];
                      final isUser = msg["role"] == "user";

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.15)
                                : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            msg["content"] ?? '',
                            style: TextStyle(
                              color: isUser
                                  ? Colors.deepPurple.shade900
                                  : Colors.black87,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Input area
                SafeArea(
                  top: false,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
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
          ],
        ),
      ),
    );
  }
}
