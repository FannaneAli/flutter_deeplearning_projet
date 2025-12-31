import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_deeplearning_projet/pages/home/sections/chatbot_section.dart';

import '../../config/ui_config.dart';
import '../../config/firestore_service.dart';
import '../home/app_drawer.dart';
import 'sections/profile_section.dart';
import 'sections/settings_section.dart';
import 'sections/dashboard_section.dart';
import 'sections/covid_section.dart';
import 'sections/gemini_chat_section.dart';



/// ============================================================================
/// PAGE D'ACCUEIL PRINCIPALE (HomePage)
/// ============================================================================
/// - Affichée après connexion réussie
/// - Gère :
///   * thème sombre / clair
///   * langue FR / EN
///   * navigation interne via Drawer (dashboard, profil, settings, chatbot, covid)
///   * synchro avec Firestore pour le profil utilisateur
/// ============================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isFrench = UIConfig.isFrench;
  bool _isDarkMode = UIConfig.isDarkMode;

  // ⚠️ On utilise l'enum HomeSection défini dans app_drawer.dart
  HomeSection _currentSection = HomeSection.dashboard;

  @override
  void initState() {
    super.initState();
    _isFrench = UIConfig.isFrench;
    _isDarkMode = UIConfig.isDarkMode;

    // On s'assure que le document Firestore existe
    UserFirestoreService().createUserIfNotExists();
  }

  // ---------------------------------------------------------------------------
  // TOGGLES LANGUE / THÈME
  // ---------------------------------------------------------------------------
  void _toggleLanguage() {
    setState(() {
      _isFrench = !_isFrench;
      UIConfig.isFrench = _isFrench;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      UIConfig.isDarkMode = _isDarkMode;
    });
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // APPBAR
  // ---------------------------------------------------------------------------
  AppBar _buildAppBar() {
    final title = _isFrench ? "Accueil" : "Home";

    final Color bgColor =
    _isDarkMode ? Colors.grey.shade900 : Colors.deepPurple;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 4,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Bouton langue
        IconButton(
          tooltip: _isFrench ? 'Changer la langue' : 'Change language',
          onPressed: _toggleLanguage,
          icon: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: Text(
              _isFrench ? 'FR' : 'EN',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Bouton thème
        IconButton(
          tooltip: _isFrench ? 'Changer de thème' : 'Toggle theme',
          onPressed: _toggleTheme,
          icon: Icon(
            _isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENU PRINCIPAL (SELON LA SECTION)
  // ---------------------------------------------------------------------------
  Widget _buildBody() {
    final user = _auth.currentUser;

    switch (_currentSection) {
      case HomeSection.dashboard:
        return DashboardSection(
          isFrench: _isFrench,
        ); // 👈 on utilise ton nouveau widget
      case HomeSection.profile:
        return ProfileSection(
          isFrench: _isFrench,
          user: user,
        );
      case HomeSection.deepSeek:
        return GeminiChatSection(
          isFrench: _isFrench,
        );
      case HomeSection.settings:
        return _buildSettingsContent();
      case HomeSection.chatbot:
        return _buildChatbotContent();
      case HomeSection.covid:
        return CovidSection(
          isFrench: _isFrench,
        );

    }
  }

  Widget _buildDashboardContent() {
    final Color bg =
    _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final Color cardBg =
    _isDarkMode ? Colors.grey.shade800 : Colors.white;
    final Color titleColor =
    _isDarkMode ? Colors.white : const Color(0xFF455A64);
    final Color textColor =
    _isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

    return Container(
      color: bg,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text(
            _isFrench
                ? "Bienvenue dans votre application Flutter DeepLearning"
                : "Welcome to your Flutter DeepLearning app",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isFrench
                ? "Utilisez le menu latéral pour accéder à votre profil, vos paramètres, le chatbot, etc."
                : "Use the side menu to access your profile, settings, chatbot, and more.",
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: cardBg,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.deepPurple.shade700
                          : Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      size: 36,
                      color: _isDarkMode
                          ? Colors.white
                          : Colors.deepPurple.shade400,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isFrench
                              ? "Espace Dashboard"
                              : "Dashboard Area",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isFrench
                              ? "Ici tu pourras afficher les stats, graphiques ou résultats de tes modèles IA."
                              : "Here you can show stats, charts, or your AI model results.",
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------------------------------------------------------------------------
  /// CONTENU DES PARAMÈTRES : SettingsSection
  /// ---------------------------------------------------------------------------
  Widget _buildSettingsContent() {
    return SettingsSection(
      isFrench: _isFrench,
      isDark: _isDarkMode,
      onToggleTheme: _toggleTheme,
      onToggleLanguage: _toggleLanguage,
    );
  }

  Widget _buildChatbotContent() {
    return ChatbotSection(
      isFrench: _isFrench,
      isDark: _isDarkMode,
    );
  }

  Widget _buildCovidContent() {
    final Color bg =
    _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final Color cardBg =
    _isDarkMode ? Colors.grey.shade800 : Colors.white;
    final Color textColor =
    _isDarkMode ? Colors.grey.shade200 : Colors.grey.shade700;

    return Container(
      color: bg,
      padding: const EdgeInsets.all(16),
      child: Card(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _isFrench
                ? "Espace Covid (placeholder).\nTu peux y mettre des infos, stats, etc."
                : "Covid area (placeholder).\nYou can put stats or info here.",
            style: TextStyle(color: textColor),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final Color bg =
    _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;

    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(),
        drawer: AppDrawer(
          isDark: _isDarkMode,
          isFrench: _isFrench,
          currentSection: _currentSection,
          onSectionSelected: (section) {
            setState(() => _currentSection = section);
          },
          onLogout: _logout,
        ),
        body: _buildBody(),
      ),
    );
  }
}
