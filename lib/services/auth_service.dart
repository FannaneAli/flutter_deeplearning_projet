// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service centralisé pour gérer TOUTE l'authentification Firebase.
///
/// Fonctions disponibles :
/// - Stream d'état de connexion
/// - Email / Mot de passe (signup + login + reset password)
/// - Email link (passwordless)
/// - Google Sign-In
/// - Déconnexion
class AuthService {
  // -------- Singleton --------

  AuthService._internal();

  static final AuthService _instance = AuthService._internal();

  /// Utiliser `AuthService.instance` partout dans l'app.
  static AuthService get instance => _instance;

  // -------- Firebase Auth --------

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Utilisateur courant (ou null si déconnecté).
  User? get currentUser => _auth.currentUser;

  /// Stream pour écouter automatiquement les changements de connexion.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================
  // 1) EMAIL / MOT DE PASSE
  // ============================================================

  /// Création de compte avec email / mot de passe.
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  /// Connexion avec email / mot de passe.
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  /// Envoi d'un email de réinitialisation de mot de passe.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ============================================================
  // 2) EMAIL LINK (PASSWORDLESS SIGN-IN)
  // ============================================================

  /// Envoie un lien de connexion par email (passwordless sign-in).

  Future<void> sendSignInLinkToEmail(String email) async {
    final trimmedEmail = email.trim();

    final actionCodeSettings = ActionCodeSettings(
      url: 'https://flutter-deeplearning-projet.firebaseapp.com',
      handleCodeInApp: true,
      androidPackageName: 'com.example.flutter_deeplearning_projet',
      androidInstallApp: true,
      androidMinimumVersion: '21',
    );

    await _auth.sendSignInLinkToEmail(
      email: trimmedEmail,
      actionCodeSettings: actionCodeSettings,
    );

    if (kDebugMode) {
      debugPrint('✅ Email link sent to $trimmedEmail');
    }
  }

  /// Connexion via un email link reçu dans la boîte mail.
  ///
  /// `emailLink` = lien complet (deep link) cliqué par l'utilisateur.
  Future<User?> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final trimmedEmail = email.trim();

    final bool isValidLink = _auth.isSignInWithEmailLink(emailLink);
    if (!isValidLink) {
      throw FirebaseAuthException(
        code: 'invalid-email-link',
        message: 'Le lien fourni n\'est pas un lien de connexion valide.',
      );
    }

    final credential = await _auth.signInWithEmailLink(
      email: trimmedEmail,
      emailLink: emailLink,
    );

    return credential.user;
  }

  // ============================================================
  // 3) GOOGLE SIGN-IN
  // ============================================================

  /// Connexion avec Google.
  ///
  /// - Sur Web : utilise signInWithPopup.
  /// - Sur Android / iOS : utilise le plugin google_sign_in.
  // auth_service.dart

  Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
      // Web : la popup affiche déjà le sélecteur de compte
      final googleProvider = GoogleAuthProvider();
      final userCredential = await _auth.signInWithPopup(googleProvider);
      return userCredential.user;
    } else {
      /// Mobile (Android / iOS)
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 👉 Très important : on se déconnecte AVANT pour forcer le choix du compte
      try {
        await googleSignIn.signOut();
        // ou: await googleSignIn.disconnect();  (les deux fonctionnent)
      } catch (_) {
        // ignore, si jamais aucun compte connecté
      }

      // Ouvre le sélecteur de comptes Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // L'utilisateur a annulé
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _auth.signInWithCredential(credential);

      return userCredential.user;
    }
  }


  // ============================================================
  // 4) DÉCONNEXION
  // ============================================================

  /// Déconnecte l'utilisateur de Firebase + Google si nécessaire.
  Future<void> signOut() async {
    if (!kIsWeb) {
      // Important pour bien se déconnecter du compte Google choisi
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }
}
