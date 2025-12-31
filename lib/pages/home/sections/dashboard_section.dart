import 'package:flutter/material.dart';

class DashboardSection extends StatelessWidget {
  final bool isFrench;

  const DashboardSection({
    super.key,
    required this.isFrench,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleText = isFrench
        ? "Bienvenue dans votre espace Deep Learning"
        : "Welcome to your Deep Learning space";

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- En-tête ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              titleText,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 28),

            // ---------- Cartes de fonctionnalités ----------
            _FeatureCard(
              icon: Icons.camera_alt_rounded,
              color: Colors.deepPurple,
              title: isFrench ? "Assistant Fruits IA" : "Fruit AI Assistant",
              description: isFrench
                  ? "Analyse des images de fruits grâce au modèle CNN converti en TFLite."
                  : "Analyze fruit images using the CNN model converted to TFLite.",
            ),
            const SizedBox(height: 16),

            _FeatureCard(
              icon: Icons.local_hospital_rounded,
              color: Colors.teal,
              title: isFrench ? "Section Covid-19" : "Covid-19 Section",
              description: isFrench
                  ? "Module thématique Covid-19 avec conseils de prévention et bonnes pratiques."
                  : "Covid-19 themed module with prevention tips and best practices.",
            ),
            const SizedBox(height: 16),

            _FeatureCard(
              icon: Icons.psychology_rounded,
              color: Colors.indigo,
              title: isFrench ? "Assistant Gemini IA" : "Gemini AI Assistant",
              description: isFrench
                  ? "Assistant conversationnel basé sur l’API Gemini pour poser des questions générales ou techniques."
                  : "Conversational assistant powered by the Gemini API for general or technical questions.",
            ),
            const SizedBox(height: 16),

            _FeatureCard(
              icon: Icons.person_rounded,
              color: Colors.orange,
              title: isFrench ? "Profil & Sécurité" : "Profile & Security",
              description: isFrench
                  ? "Authentification Firebase, connexion Google, gestion du thème et de la langue."
                  : "Firebase authentication, Google sign-in, theme and language management.",
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceVariant.withOpacity(0.4)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.3,
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
