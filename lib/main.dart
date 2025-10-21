import 'package:flutter/material.dart';
import 'ollama_client.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const JyotishiApp());

class JyotishiApp extends StatelessWidget {
  const JyotishiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0B132B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF5BC0BE),
        secondary: Color(0xFFFFD700),
        background: Color(0xFF0B132B),
        surface: Color(0xFF1C2541),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
      ),
    );

    return MaterialApp(
      title: 'Jyotishi — Your AI Astrologer',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
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
If the user hasn't given their date, time, or place of birth, politely ask.
Provide thoughtful, positive guidance with clear and concise response.
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
  final size = MediaQuery.of(context).size;

  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2541)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF5BC0BE), Color(0xFFFFD700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Jyotishi — Your AI Astrologer',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  tooltip: 'Reset Chat',
                  onPressed: () => setState(() => _chat.clear()),
                ),
              ],
            ),

     // --- CHAT LIST ---
Expanded(
  child: LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth * 0.8;

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _chat.length,
        itemBuilder: (context, index) {
          final msg = _chat[index];
          final isUser = msg["role"] == "user";

          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFF5BC0BE).withOpacity(0.2)
                      : const Color(0xFFFFD700).withOpacity(0.1),
                  border: Border.all(
                    color: isUser
                        ? const Color(0xFF5BC0BE).withOpacity(0.4)
                        : const Color(0xFFFFD700).withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isUser ? 14 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 14),
                  ),
                ),
                child: Text(
                  msg["content"] ?? '',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  ),
),

const Divider(height: 1, color: Colors.white24),

// --- INPUT BAR ---
SafeArea(
  top: false,
  child: Container(
    color: const Color(0xFF1C2541),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'Ask about your stars...',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
              ),
              border: InputBorder.none,
            ),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        IconButton(
          icon: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white),
          onPressed: _loading ? null : _send,
        ),
      ],
    ),
  ),
),

SizedBox(height: size.height * 0.01),

          ],
        ),
      ),
    ),
  );
}
}