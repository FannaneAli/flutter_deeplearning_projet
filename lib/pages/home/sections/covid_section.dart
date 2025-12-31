import 'package:flutter/material.dart';

class CovidSection extends StatelessWidget {
  final bool isFrench;

  const CovidSection({
    super.key,
    this.isFrench = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleText = isFrench ? "Section Covid-19" : "Covid-19 Section";

    return Center(
      child: SingleChildScrollView(
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
                        Colors.redAccent.withOpacity(0.2),
                        Colors.orangeAccent.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.coronavirus_rounded,
                    color: Colors.redAccent,
                    size: 36,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              titleText,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFrench
                  ? "Cette section ne donne pas un diagnostic médical, mais des idées pour se protéger et savoir comment réagir."
                  : "This section does not give a medical diagnosis, but ideas on how to stay safe and how to react.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 28),

            // 1) Prévention – comment éviter de tomber malade
            _InfoCard(
              isDark: isDark,
              color: Colors.green,
              icon: Icons.health_and_safety_rounded,
              title: isFrench
                  ? "Comment éviter de tomber malade ?"
                  : "How to reduce your risk?",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFrench
                        ? "Ces bonnes pratiques réduisent le risque de contamination au Covid-19 et à d'autres infections respiratoires :"
                        : "These habits help reduce the risk of Covid-19 and other respiratory infections:",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TipChip(
                        icon: Icons.soap_rounded,
                        label: isFrench
                            ? "Se laver les mains souvent (eau + savon ou gel hydroalcoolique)."
                            : "Wash your hands regularly (soap or hand sanitizer).",
                        theme: theme,
                      ),
                      _TipChip(
                        icon: Icons.masks_rounded,
                        label: isFrench
                            ? "Porter un masque dans les lieux fermés et très fréquentés si nécessaire."
                            : "Wear a mask in crowded indoor areas when needed.",
                        theme: theme,
                      ),
                      _TipChip(
                        icon: Icons.social_distance_rounded,
                        label: isFrench
                            ? "Éviter les contacts rapprochés avec des personnes malades."
                            : "Avoid close contact with people who are sick.",
                        theme: theme,
                      ),
                      _TipChip(
                        icon: Icons.air_rounded,
                        label: isFrench
                            ? "Aérer régulièrement les pièces (ouvrir les fenêtres)."
                            : "Ventilate rooms regularly (open windows).",
                        theme: theme,
                      ),
                      _TipChip(
                        icon: Icons.vaccines_rounded,
                        label: isFrench
                            ? "Suivre les recommandations de vaccination de votre pays."
                            : "Follow your local vaccination recommendations.",
                        theme: theme,
                      ),
                      _TipChip(
                        icon: Icons.bed_rounded,
                        label: isFrench
                            ? "Bien dormir, manger équilibré et faire un peu d'activité physique."
                            : "Sleep well, eat balanced meals and stay physically active.",
                        theme: theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2) Reconnaître des symptômes possibles
            _InfoCard(
              isDark: isDark,
              color: Colors.orange,
              icon: Icons.sick_rounded,
              title: isFrench
                  ? "Comment savoir si je suis peut-être malade ?"
                  : "How to know if you might be sick?",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFrench
                        ? "Certains symptômes peuvent faire penser au Covid-19, mais ils peuvent aussi être liés à d'autres maladies (grippe, rhume, etc.)."
                        : "Some symptoms may suggest Covid-19, but they can also be caused by other illnesses (flu, cold, etc.).",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _Bullet(
                    text: isFrench
                        ? "Fièvre ou sensation de fièvre (frissons)."
                        : "Fever or feeling feverish (chills).",
                    theme: theme,
                  ),
                  _Bullet(
                    text: isFrench
                        ? "Toux, gorge irritée, nez bouché ou qui coule."
                        : "Cough, sore throat, runny or stuffy nose.",
                    theme: theme,
                  ),
                  _Bullet(
                    text: isFrench
                        ? "Fatigue inhabituelle, maux de tête, douleurs musculaires."
                        : "Unusual fatigue, headache, muscle aches.",
                    theme: theme,
                  ),
                  _Bullet(
                    text: isFrench
                        ? "Perte ou changement du goût et/ou de l’odorat."
                        : "Loss or change of taste or smell.",
                    theme: theme,
                  ),
                  _Bullet(
                    text: isFrench
                        ? "Difficulté à respirer ou douleur dans la poitrine (symptômes plus sérieux)."
                        : "Difficulty breathing or chest pain (more serious symptoms).",
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFrench
                        ? "⚠️ Seul un test (antigénique ou PCR) et l’avis d’un professionnel de santé peuvent confirmer si c’est vraiment le Covid-19."
                        : "⚠️ Only a test (antigen or PCR) and a healthcare professional can confirm if it is really Covid-19.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3) Que faire si tu penses être malade
            _InfoCard(
              isDark: isDark,
              color: Colors.red,
              icon: Icons.medical_services_rounded,
              title: isFrench
                  ? "Que faire si tu penses avoir le Covid ?"
                  : "What to do if you think you have Covid?",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Bullet(
                    text: isFrench
                        ? "Reste à la maison si possible et évite les contacts rapprochés avec les autres."
                        : "Stay at home if possible and avoid close contact with others.",
                    theme: theme,
                  ),
                  _Bullet(
                    text: isFrench
                        ? "Porte un masque si tu dois être proche d’autres personnes."
                        : "Wear a mask if you need to be near other people.",
                    theme: theme,
                  ),
                  _Bullet(
                    text: isFrench
                        ? "Hydrate-toi bien, repose-toi et surveille l’évolution de tes symptômes."
                        : "Drink plenty of fluids, rest and monitor your symptoms.",
                    theme: theme,
                  ),
                  _Bullet(
                    text: isFrench
                        ? "Contacte un médecin ou les services de santé de ton pays pour savoir s’il faut faire un test et quelles consignes suivre."
                        : "Contact a doctor or your local health service to know if you should get tested and what to do.",
                    theme: theme,
                  ),
                  _Bullet(
                    text: isFrench
                        ? "En cas de signes graves (difficulté à respirer, douleur intense dans la poitrine, confusion, lèvres ou visage bleutés), appelle immédiatement les services d’urgence."
                        : "If you have severe signs (trouble breathing, intense chest pain, confusion, bluish lips or face), call emergency services immediately.",
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFrench
                        ? "Ces conseils sont généraux : toujours suivre les recommandations officielles de ton pays et l’avis d’un professionnel de santé."
                        : "These tips are general: always follow the official recommendations in your country and the advice of a healthcare professional.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte générique pour les blocs d'information
class _InfoCard extends StatelessWidget {
  final bool isDark;
  final Color color;
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.isDark,
    required this.color,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Puce de conseil courte (prévention)
class _TipChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _TipChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
        isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit bullet point texte
class _Bullet extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _Bullet({
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  "),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
