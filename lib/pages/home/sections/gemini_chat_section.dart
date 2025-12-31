import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GeminiChatSection extends StatefulWidget {
  final bool isFrench;

  const GeminiChatSection({
    super.key,
    this.isFrench = true,
  });

  @override
  State<GeminiChatSection> createState() => _GeminiChatSectionState();
}

class _GeminiChatSectionState extends State<GeminiChatSection> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // ⚠️ Mets ta clé ici pour la démo, mais évite de la commiter !
  static const String _apiKey = 'AIzaSyDBw-zWsbosyMD2R-G7uYo0ALLj15ZIa20';

  // Endpoint Gemini (chat)
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final systemPrompt = widget.isFrench
          ? 'Tu es un assistant IA serviable et amical.'
          : 'You are a helpful and friendly AI assistant.';

      final uri = Uri.parse('$_apiUrl?key=$_apiKey');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': '$systemPrompt\n\nUtilisateur : $userMessage',
                },
              ],
            },
          ],
        }),
      );

      debugPrint('Gemini status: ${response.statusCode}');
      debugPrint('Gemini body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        String aiResponse;

        if (candidates != null && candidates.isNotEmpty) {
          final content =
          candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          aiResponse = (parts != null &&
              parts.isNotEmpty &&
              parts[0]['text'] is String)
              ? parts[0]['text'] as String
              : (widget.isFrench
              ? "Aucune réponse générée."
              : "No response generated.");
        } else {
          aiResponse = widget.isFrench
              ? "Aucune réponse générée."
              : "No response generated.";
        }

        setState(() {
          _messages.add(ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      } else {
        // Erreur côté API Gemini
        setState(() {
          _messages.add(ChatMessage(
            text: widget.isFrench
                ? 'Erreur API ${response.statusCode} : ${response.body}'
                : 'API error ${response.statusCode}: ${response.body}',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      // Erreur réseau / autre
      setState(() {
        _messages.add(ChatMessage(
          text: widget.isFrench
              ? 'Erreur: Impossible de contacter le serveur.'
              : 'Error: Unable to contact the server.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleText =
    widget.isFrench ? "Chat Gemini AI" : "Gemini AI Chat";

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.withOpacity(0.2),
                        Colors.blue.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: Colors.deepPurple,
                    size: 36,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (_messages.isNotEmpty)
                  IconButton(
                    onPressed: _clearChat,
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: widget.isFrench
                        ? 'Effacer la conversation'
                        : 'Clear conversation',
                    color: theme.colorScheme.error,
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Zone de chat
            Container(
              height: 500,
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                children: [
                  // Messages
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.isFrench
                                ? 'Commencez une conversation'
                                : 'Start a conversation',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _MessageBubble(
                          message: _messages[index],
                          theme: theme,
                        );
                      },
                    ),
                  ),

                  // Indicateur de chargement
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.isFrench
                                ? 'Gemini réfléchit...'
                                : 'Gemini is thinking...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Zone de saisie
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surface.withOpacity(0.3)
                          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: widget.isFrench
                                  ? 'Écrivez votre message...'
                                  : 'Type your message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            enabled: !_isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _isLoading ? null : _sendMessage,
                            icon: const Icon(Icons.send_rounded),
                            color: Colors.white,
                            disabledColor: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isFrench
                      ? 'Propulsé par Gemini API'
                      : 'Powered by Gemini API',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                    theme.colorScheme.onSurface.withOpacity(0.5),
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

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ThemeData theme;

  const _MessageBubble({
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: message.isError
                    ? Colors.red.withOpacity(0.1)
                    : Colors.deepPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isError
                    ? Icons.error_outline
                    : Icons.smart_toy_rounded,
                color: message.isError ? Colors.red : Colors.deepPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? theme.colorScheme.primary
                    : message.isError
                    ? Colors.red.withOpacity(0.1)
                    : isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surfaceVariant
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(16).copyWith(
                  topLeft: message.isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  topRight: message.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: message.isError
                    ? Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: message.isUser
                          ? Colors.white
                          : message.isError
                          ? Colors.red
                          : theme.colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
