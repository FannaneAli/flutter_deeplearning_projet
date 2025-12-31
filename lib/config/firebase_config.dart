// lib/config/firebase_config.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Classe utilitaire pour initialiser Firebase au démarrage de l'application.
class FirebaseConfig {
  /// À appeler dans main() avant runApp().
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (kDebugMode) {
        debugPrint('✅ Firebase initialized successfully');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing Firebase: $e');
        debugPrint(stack.toString());
      }
      rethrow;
    }
  }
}
