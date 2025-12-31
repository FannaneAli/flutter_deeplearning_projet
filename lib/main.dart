import 'package:flutter/material.dart';

import 'config/firebase_config.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter DeepLearning',

      // 👉 L'écran qui s'affiche au démarrage
      initialRoute: '/login',

      // 👉 Toutes les routes connues par l'appli
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
