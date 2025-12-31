// lib/pages/home/sections/chatbot_section.dart

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/ai_fruits_service.dart';

class ChatbotSection extends StatefulWidget {
  final bool isFrench;
  final bool isDark;

  const ChatbotSection({
    super.key,
    required this.isFrench,
    required this.isDark,
  });

  @override
  State<ChatbotSection> createState() => _ChatbotSectionState();
}

class _ChatbotSectionState extends State<ChatbotSection>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FruitsAiService _aiService = FruitsAiService.instance;

  final List<_ChatMessage> _messages = [];

  late final AnimationController _typingController;
  late final Animation<double> _typingAnimation;

  bool _isTyping = false;
  bool _loadingModel = false;

  @override
  void initState() {
    super.initState();

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _typingAnimation =
        Tween<double>(begin: 0.3, end: 1.0).animate(_typingController);

    // Message de bienvenue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(
          _ChatMessage(
            fromUser: false,
            text: widget.isFrench
                ? "👋 Bonjour ! Je suis votre assistant IA pour identifier les fruits. Envoyez-moi une photo !"
                : "👋 Hi! I'm your AI assistant for fruit identification. Send me a photo!",
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ENVOI TEXTE (facultatif, juste pour discuter)
  // ---------------------------------------------------------------------------
  void _handleSendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          fromUser: true,
          text: text,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      final reply = widget.isFrench
          ? "Je suis surtout optimisé pour reconnaître les fruits à partir d’images 🍎🍌🍊.\n"
          "Envoie-moi une photo de fruit pour que je la classe !"
          : "I'm mainly optimized to recognize fruits from images 🍎🍌🍊.\n"
          "Send me a fruit picture and I'll classify it!";
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            fromUser: false,
            text: reply,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  // ---------------------------------------------------------------------------
  // ENVOI IMAGE DE FRUIT + PRÉDICTION
  // ---------------------------------------------------------------------------
  Future<void> _pickFruitImage() async {
    if (_loadingModel) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);

    // Message utilisateur "Analyzing..."
    setState(() {
      _messages.add(
        _ChatMessage(
          fromUser: true,
          text: widget.isFrench
              ? "📸 Analyse de l'image..."
              : "📸 Analyzing image...",
          imageFile: file,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
      _loadingModel = true;
    });

    _scrollToBottom();

    try {
      // Appel au service IA
      final prediction = await _aiService.classifyImage(file);

      setState(() {
        _isTyping = false;
        _loadingModel = false;
      });

      final confidence = (prediction.confidence * 100).toStringAsFixed(1);
      final isHighConfidence = prediction.confidence > 0.7;
      final emoji = _getFruitEmoji(prediction.label);

      final reply = widget.isFrench
          ? "🎯 Résultat : $emoji **${prediction.label}**\n"
          "📊 Confiance : $confidence%\n"
          "${isHighConfidence ? "✅ Je suis très sûr de ma réponse." : "ℹ️ La confiance est un peu faible, vérifiez l'image."}"
          : "🎯 Result: $emoji **${prediction.label}**\n"
          "📊 Confidence: $confidence%\n"
          "${isHighConfidence ? "✅ I'm very confident in this prediction." : "ℹ️ Confidence is a bit low, please double-check the image."}";

      setState(() {
        _messages.add(
          _ChatMessage(
            fromUser: false,
            text: reply,
            timestamp: DateTime.now(),
            prediction: prediction,
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _loadingModel = false;
        _messages.add(
          _ChatMessage(
            fromUser: false,
            text: widget.isFrench
                ? "❌ Erreur : Impossible d'analyser cette image. Vérifiez qu'il s'agit bien d'une photo de fruit."
                : "❌ Error: Unable to analyze this image. Make sure it's a fruit photo.",
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  String _getFruitEmoji(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('apple')) return '🍎';
    if (lowerLabel.contains('banana')) return '🍌';
    if (lowerLabel.contains('orange')) return '🍊';
    if (lowerLabel.contains('grape')) return '🍇';
    if (lowerLabel.contains('strawberry')) return '🍓';
    if (lowerLabel.contains('watermelon')) return '🍉';
    if (lowerLabel.contains('lemon')) return '🍋';
    if (lowerLabel.contains('peach')) return '🍑';
    if (lowerLabel.contains('cherry')) return '🍒';
    return '🥭';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;

    return Column(
      children: [
        // Liste des messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isTyping && index == _messages.length) {
                return _buildTypingIndicator(isDark);
              }
              final message = _messages[index];
              return _buildMessageBubble(message, isDark, primaryColor, accentColor);
            },
          ),
        ),

        // Zone d'input
        _buildInputArea(isDark, primaryColor),
      ],
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FadeTransition(
        opacity: _typingAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('•••'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      _ChatMessage message,
      bool isDark,
      Color primary,
      Color accent,
      ) {
    final isUser = message.fromUser;
    final bgColor = isUser
        ? (isDark ? accent.withOpacity(0.8) : accent)
        : (isDark ? Colors.white12 : Colors.grey.shade200);
    final textColor = isUser
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  message.imageFile!,
                  width: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message.text,
              style: TextStyle(
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildInputArea(bool isDark, Color primaryColor) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _pickFruitImage,
              icon: const Icon(Icons.photo),
              color: primaryColor,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.isFrench
                      ? "Écrivez un message..."
                      : "Type a message...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSendText(),
              ),
            ),
            IconButton(
              onPressed: _handleSendText,
              icon: const Icon(Icons.send),
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final bool fromUser;
  final String text;
  final DateTime timestamp;
  final File? imageFile;
  final FruitsPrediction? prediction;
  final bool isError;

  _ChatMessage({
    required this.fromUser,
    required this.text,
    required this.timestamp,
    this.imageFile,
    this.prediction,
    this.isError = false,
  });
}
