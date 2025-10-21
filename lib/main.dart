import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ollama_client.dart';

void main() => runApp(const JyotishiApp());

class JyotishiApp extends StatefulWidget {
  const JyotishiApp({super.key});
  @override
  State<JyotishiApp> createState() => _JyotishiAppState();
}

class _JyotishiAppState extends State<JyotishiApp> {
  bool _dark = true;

  // Brand colors
  static const _mystic = Color(0xFF6C63FF);
  static const _gold = Color(0xFFFFD700);
  static const _darkBgStart = Color(0xFF0B0C10);
  static const _darkBgEnd = Color(0xFF1A1B2F);
  static const _lightBgStart = Color(0xFFF4F3FF);
  static const _lightBgEnd = Color(0xFFFFFFFF);

  ThemeData _darkTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: _mystic,
          secondary: _gold,
          background: _darkBgStart,
          surface: _darkBgEnd,
        ),
        scaffoldBackgroundColor: _darkBgStart,
        textTheme: TextTheme(
          titleLarge: GoogleFonts.cinzelDecorative(
              fontSize: 20, fontWeight: FontWeight.w600, color: _gold),
          bodyMedium: GoogleFonts.nunitoSans(
              fontSize: 16, height: 1.5, color: Colors.white.withOpacity(0.9)),
        ),
      );

  ThemeData _lightTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: _gold,
          secondary: _mystic,
          background: _lightBgEnd,
          surface: _lightBgStart,
        ),
        scaffoldBackgroundColor: _lightBgEnd,
        textTheme: TextTheme(
          titleLarge: GoogleFonts.prata(
              fontSize: 20, fontWeight: FontWeight.w600, color: _mystic),
          bodyMedium: GoogleFonts.poppins(
              fontSize: 16, height: 1.5, color: Colors.black87),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jyotishi — Your AI Astrologer',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      darkTheme: _darkTheme(),
      theme: _lightTheme(),
      home: ChatScreen(
        darkMode: _dark,
        toggleTheme: () => setState(() => _dark = !_dark),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final bool darkMode;
  final VoidCallback toggleTheme;
  const ChatScreen({super.key, required this.darkMode, required this.toggleTheme});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = OllamaClient();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _chat = [];
  bool _loading = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chat.add({"role": "user", "content": text});
      _controller.clear();
      _loading = true;
    });

    final conversation = _chat.map((m) => "${m['role']}: ${m['content']}").join("\n\n");
    final prompt = '''
You are Jyotishi — a calm, kind, insightful AI Vedic Astrologer.
If the user hasn’t provided date, time, or place of birth, ask politely.
Always end with:
"✨ Astrology is for guidance, not a substitute for professional advice."

Conversation so far:
$conversation

assistant:
''';

    try {
      final reply = await _client.generate(prompt);
      setState(() => _chat.add({"role": "assistant", "content": reply}));
    } catch (e) {
      setState(() => _chat.add({"role": "assistant", "content": "⚠️ $e"}));
    } finally {
      setState(() => _loading = false);
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    }
  }

  void _resetChat() => setState(() => _chat.clear());

  void _downloadChat() {
    if (_chat.isEmpty) return;
    final content = _chat
        .map((e) => "${e['role']?.toUpperCase()}: ${e['content']}")
        .join("\n\n");
    final blob = html.Blob([utf8.encode(content)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "jyotishi_chat.txt")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [_JyotishiAppState._darkBgStart, _JyotishiAppState._darkBgEnd]
                : const [_JyotishiAppState._lightBgStart, _JyotishiAppState._lightBgEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                isDark: isDark,
                onToggleTheme: widget.toggleTheme,
                onReset: _resetChat,
                onDownload: _downloadChat,
              ),
              Expanded(child: _buildChatList(context)),
              _InputBar(
                controller: _controller,
                loading: _loading,
                onSend: _send,
                dark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        controller: _scroll,
        itemCount: _chat.length,
        itemBuilder: (context, i) {
          final msg = _chat[i];
          final isUser = msg['role'] == 'user';
          return ChatBubble(text: msg['content'] ?? '', isUser: isUser);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isDark,
    required this.onToggleTheme,
    required this.onReset,
    required this.onDownload,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onReset;
  final VoidCallback onDownload;

  static const _gold = Color(0xFFFFD700);
  static const _mystic = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge!;
    final bgColor = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFEDEAFF); // inverted tone
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bgColor, border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark ? const [_mystic, _gold] : const [_gold, _mystic],
              ),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Jyotishi — Your AI Astrologer', style: titleStyle)),
          IconButton(
            tooltip: 'Reset Chat',
            icon: Icon(Icons.restart_alt_rounded,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: onReset,
          ),
          IconButton(
            tooltip: 'Download Chat',
            icon: Icon(Icons.download_rounded,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: onDownload,
          ),
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: onToggleTheme,
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.text, required this.isUser});
  final String text;
  final bool isUser;

  static const _gold = Color(0xFFFFD700);
  static const _mystic = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxW = MediaQuery.of(context).size.width * 0.8;

    final borderColor = isUser
        ? (isDark ? _mystic : _gold)
        : (isDark ? _gold : _mystic);

    final bg = isUser
        ? (isDark
            ? _mystic.withOpacity(0.18)
            : _gold.withOpacity(0.15))
        : (isDark
            ? Colors.white.withOpacity(0.9)
            : const Color(0xFF201C3B).withOpacity(0.08));

    final textColor =
        isDark ? (isUser ? Colors.white : Colors.black87) : (isUser ? Colors.black87 : Colors.black);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isUser ? 14 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 14),
            ),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            text,
            style: GoogleFonts.nunitoSans(
                fontSize: 15, height: 1.45, color: textColor),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.loading,
    required this.onSend,
    required this.dark,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);
    final iconColor = dark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: dark ? Colors.white10 : Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Ask Jyotishi about your stars...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 15,
                  color: dark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.4),
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 4),
          loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: Icon(Icons.send_rounded, color: iconColor),
                  onPressed: onSend,
                ),
        ],
      ),
    );
  }
}
