import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final bool isFrench;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const SettingsSection({
    super.key,
    required this.isFrench,
    required this.isDark,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final titleTextStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : Colors.blueGrey.shade800,
    );

    final sectionTitle = isFrench ? 'Paramètres' : 'Settings';
    final sectionSubtitle = isFrench
        ? 'Personnalisez votre expérience dans l’application.'
        : 'Customize your experience in the app.';

    return Scaffold(
      backgroundColor:
      isDarkMode ? const Color(0xFF121212) : const Color(0xFFF1F3F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------------
              // HEADER
              // ----------------------------------------------------------
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 28,
                      color: Colors.deepPurple.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sectionTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sectionSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ----------------------------------------------------------
              // SECTION APPARENCE (Thème + Langue)
              // ----------------------------------------------------------
              _buildSectionCard(
                context: context,
                title: isFrench ? 'Apparence' : 'Appearance',
                icon: Icons.color_lens_outlined,
                children: [
                  // Thème
                  SwitchListTile.adaptive(
                    value: isDark,
                    onChanged: (_) => onToggleTheme(),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: Colors.deepPurple.shade300,
                    ),
                    title: Text(
                      isFrench ? 'Mode sombre' : 'Dark mode',
                      style: titleTextStyle,
                    ),
                    subtitle: Text(
                      isDark
                          ? (isFrench ? 'Activé' : 'Enabled')
                          : (isFrench ? 'Désactivé' : 'Disabled'),
                    ),
                  ),
                  const Divider(height: 0),
                  // Langue
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: Colors.deepPurple.shade300,
                    ),
                    title: Text(
                      isFrench ? 'Langue' : 'Language',
                      style: titleTextStyle,
                    ),
                    subtitle: Text(
                      isFrench
                          ? 'Français / Anglais'
                          : 'French / English',
                    ),
                    trailing: OutlinedButton.icon(
                      onPressed: onToggleLanguage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(
                        isFrench ? 'Basculer' : 'Switch',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------------
              // SECTION NOTIFICATIONS
              // ----------------------------------------------------------
              _buildSectionCard(
                context: context,
                title: isFrench ? 'Notifications' : 'Notifications',
                icon: Icons.notifications_active_outlined,
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_none),
                    title: Text(
                      isFrench
                          ? 'Notifications générales'
                          : 'General notifications',
                      style: titleTextStyle,
                    ),
                    subtitle: Text(
                      isFrench
                          ? 'Recevoir des alertes importantes et mises à jour.'
                          : 'Receive important alerts and updates.',
                    ),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // TODO: connecter à ta logique de notification
                      },
                    ),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(
                      isFrench
                          ? 'Notifications par email'
                          : 'Email notifications',
                      style: titleTextStyle,
                    ),
                    subtitle: Text(
                      isFrench
                          ? 'Résumé des activités, changements importants.'
                          : 'Activity summaries, important changes.',
                    ),
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        // TODO: connecter à Firestore / backend plus tard
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------------
              // SECTION CONFIDENTIALITÉ & SÉCURITÉ
              // ----------------------------------------------------------
              _buildSectionCard(
                context: context,
                title: isFrench
                    ? 'Confidentialité & sécurité'
                    : 'Privacy & security',
                icon: Icons.lock_outline,
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_person_outlined),
                    title: Text(
                      isFrench
                          ? 'Gestion de la sécurité'
                          : 'Security management',
                      style: titleTextStyle,
                    ),
                    subtitle: Text(
                      isFrench
                          ? 'Paramètres du compte, mots de passe, PIN.'
                          : 'Account settings, passwords, PIN.',
                    ),
                    onTap: () {
                      // Tu peux naviguer vers ton écran Profil > Sécurité
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFrench
                                ? 'Accédez à l’onglet Profil pour modifier la sécurité.'
                                : 'Go to the Profile tab to manage security.',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(
                      isFrench
                          ? 'Politique de confidentialité'
                          : 'Privacy policy',
                      style: titleTextStyle,
                    ),
                    subtitle: Text(
                      isFrench
                          ? 'Comprendre comment vos données sont utilisées.'
                          : 'Understand how your data is used.',
                    ),
                    onTap: () {
                      // TODO: ouvrir une page / lien vers politique
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ----------------------------------------------------------
              // SECTION À PROPOS
              // ----------------------------------------------------------
              _buildSectionCard(
                context: context,
                title: isFrench ? 'À propos de l’application' : 'About app',
                icon: Icons.info_outline,
                children: [
                  ListTile(
                    leading: const Icon(Icons.rocket_launch_outlined),
                    title: Text(
                      isFrench ? 'Version de l’application' : 'App version',
                      style: titleTextStyle,
                    ),
                    subtitle: const Text('v1.0.0'),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: Text(
                      isFrench ? 'Support & aide' : 'Support & help',
                      style: titleTextStyle,
                    ),
                    subtitle: Text(
                      isFrench
                          ? 'Besoin d’aide ? Contactez le support.'
                          : 'Need help? Contact support.',
                    ),
                    onTap: () {
                      // TODO: ouvrir mail, page contact, etc.
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // WIDGET UTILITAIRE POUR CHAQUE “CARTE DE SECTION”
  // ------------------------------------------------------------------
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDarkMode ? 2 : 4,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          // En-tête de la section (icone + titre)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              color: isDarkMode
                  ? Colors.deepPurple.withOpacity(0.12)
                  : Colors.deepPurple.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.deepPurple.shade400),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          // Contenu de la section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: children,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
