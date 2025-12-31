import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/firestore_service.dart';

/// Sections possibles dans la Home
enum HomeSection {
  dashboard,
  profile,
  deepSeek,
  settings,
  chatbot,
  covid,
}

/// ============================================================================
/// AppDrawer
/// ============================================================================
class AppDrawer extends StatelessWidget {
  final bool isDark;
  final bool isFrench;
  final HomeSection currentSection;
  final ValueChanged<HomeSection> onSectionSelected;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.isDark,
    required this.isFrench,
    required this.currentSection,
    required this.onSectionSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final Color drawerColor = isDark ? Colors.grey.shade900 : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtitleColor =
    isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    final user = FirebaseAuth.instance.currentUser;
    final userService = UserFirestoreService();

    return Drawer(
      backgroundColor: drawerColor,
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: userService.userProfileStream(),
        builder: (context, snapshot) {
          final data = snapshot.data;

          final String userName = (data?['name'] as String?) ??
              user?.displayName ??
              (isFrench ? "Utilisateur" : "User");

          final String userEmail =
              (data?['email'] as String?) ?? user?.email ?? "example@email.com";

          final String? photoUrl = data?['photoUrl'] as String?;

          return Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.deepPurple.shade900, Colors.black87]
                        : [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                  (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                    userName.isNotEmpty
                        ? userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  )
                      : null,
                ),
                accountName: Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                accountEmail: Text(
                  userEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                otherAccountsPictures: [
                  Icon(
                    isDark
                        ? Icons.nights_stay_rounded
                        : Icons.wb_sunny_rounded,
                    color: Colors.white,
                  ),
                ],
              ),

              // -------------------- MENU ITEMS -------------------------
              _buildDrawerItem(
                context: context,
                section: HomeSection.dashboard,
                icon: Icons.home_rounded,
                frenchLabel: "Accueil",
                englishLabel: "Home",
                textColor: textColor,
              ),
              _buildDrawerItem(
                context: context,
                section: HomeSection.profile,
                icon: Icons.person_rounded,
                frenchLabel: "Profil",
                englishLabel: "Profile",
                textColor: textColor,
              ),
              _buildDrawerItem(
                context: context,
                section: HomeSection.chatbot,
                icon: Icons.smart_toy_rounded,
                frenchLabel: "Assistant Fruits IA",
                englishLabel: "Fruit AI Assistant",
                textColor: textColor,
              ),
              // 👉 NOUVEL ITEM DEEPSEEK
              _buildDrawerItem(
                context: context,
                section: HomeSection.deepSeek,
                icon: Icons.psychology_rounded,
                frenchLabel: "Assistant Gemini",
                englishLabel: "Gemini Assistant",
                textColor: textColor,
              ),
              _buildDrawerItem(
                context: context,
                section: HomeSection.covid,
                icon: Icons.coronavirus_rounded,
                frenchLabel: "Covid-19",
                englishLabel: "Covid-19",
                textColor: textColor,
              ),
              _buildDrawerItem(
                context: context,
                section: HomeSection.settings,
                icon: Icons.settings_rounded,
                frenchLabel: "Paramètres",
                englishLabel: "Settings",
                textColor: textColor,
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFrench
                          ? "Connecté en tant que :"
                          : "Logged in as:",
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  isFrench ? "Se déconnecter" : "Sign out",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required HomeSection section,
    required IconData icon,
    required String frenchLabel,
    required String englishLabel,
    required Color textColor,
  }) {
    final bool selected = (section == currentSection);
    final String label = isFrench ? frenchLabel : englishLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? Colors.deepPurpleAccent : textColor,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.deepPurpleAccent : textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: selected,
        selectedTileColor:
        Colors.deepPurple.withOpacity(isDark ? 0.2 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          Navigator.of(context).pop();
          onSectionSelected(section);
        },
      ),
    );
  }
}
