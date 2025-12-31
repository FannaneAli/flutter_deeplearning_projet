import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../config/ui_config.dart';

/// Page d'inscription (même thème que LoginPage)
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmpasswordController =
  TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _validateEmail(String? value) {
    if ((value == null) || value.isEmpty) {
      return UIConfig.isFrench
          ? 'Veuillez saisir votre email'
          : 'Please enter your email';
    }
    final emailPattern = r'^[^@]+@[^@]+\.[^@]+$';
    final regex = RegExp(emailPattern);
    if (!regex.hasMatch(value)) {
      return UIConfig.isFrench
          ? 'Adresse email invalide'
          : 'Invalid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value == null) || value.isEmpty) {
      return UIConfig.isFrench
          ? 'Veuillez saisir un mot de passe'
          : 'Please enter a password';
    }
    if (value.length < 6) {
      return UIConfig.isFrench
          ? 'Au moins 6 caractères'
          : 'At least 6 characters';
    }
    final strongPattern = RegExp(r'^(?=.*[A-Z])(?=.*[0-9]).{6,}$');
    if (!strongPattern.hasMatch(value)) {
      return UIConfig.isFrench
          ? 'Au moins 1 majuscule et 1 chiffre'
          : 'Must contain at least 1 uppercase letter and 1 digit';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value == null) || value.isEmpty) {
      return UIConfig.isFrench
          ? 'Veuillez confirmer le mot de passe'
          : 'Please confirm password';
    }
    if (value != _passController.text) {
      return UIConfig.isFrench
          ? 'Les mots de passe ne correspondent pas'
          : 'Passwords do not match';
    }
    return null;
  }

  Future<void> signUp() async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      if (userCredential.user != null) {
        Fluttertoast.showToast(
          msg: UIConfig.isFrench
              ? 'Compte créé avec succès ✅'
              : 'Account created successfully ✅',
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      final fr = UIConfig.isFrench;
      if (e.code.contains("weak-password")) {
        Fluttertoast.showToast(
          msg: fr
              ? 'Mot de passe trop faible (min 6 caractères).'
              : 'Weak password (min 6 characters).',
        );
      } else if (e.code.contains("invalid-email")) {
        Fluttertoast.showToast(
          msg: fr ? 'Format d’email invalide.' : 'Invalid email format.',
        );
      } else if (e.code.contains("email-already-in-use")) {
        Fluttertoast.showToast(
          msg: fr
              ? 'Cette adresse email est déjà utilisée.'
              : 'This email is already in use.',
        );
      } else {
        Fluttertoast.showToast(
          msg: fr ? 'Erreur : ${e.code}' : 'Error: ${e.code}',
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmpasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = UIConfig.isDarkMode;
    final isFr = UIConfig.isFrench;

    // mêmes couleurs de fond que Login
    final bgColors = isDark
        ? [const Color(0xFF121212), const Color(0xFF1F2933)]
        : [Colors.white, Colors.grey.shade200];

    // même couleur de carte que Login
    final cardColor = isDark ? const Color(0xFFF5EFFD) : Colors.white;

    // couleur du lien / accent (comme Login)
    final linkColor = Colors.deepPurple;

    // style du bouton principal (comme "Se connecter" dans Login)
    final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.deepPurple,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              color: cardColor,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // mêmes boutons thème/langue que Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: isDark
                                ? (isFr ? 'Mode clair' : 'Light mode')
                                : (isFr ? 'Mode sombre' : 'Dark mode'),
                            icon: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                UIConfig.isDarkMode = !UIConfig.isDarkMode;
                              });
                            },
                          ),
                          IconButton(
                            tooltip: isFr
                                ? 'Passer en anglais'
                                : 'Passer en français',
                            icon: const Icon(Icons.language, size: 20),
                            onPressed: () {
                              setState(() {
                                UIConfig.isFrench = !UIConfig.isFrench;
                              });
                            },
                          ),
                        ],
                      ),

                      Text(
                        isFr ? 'Inscription' : 'Sign up',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isFr
                            ? 'Crée ton compte pour continuer'
                            : 'Create your account to continue',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // 👇 NOUVELLE IMAGE REGISTER
                      Center(
                        child: Image.asset(
                          'images/register.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person_add, size: 48),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: isFr ? 'Email' : 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _passController,
                        decoration: InputDecoration(
                          labelText: isFr ? 'Mot de passe' : 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.password),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                        obscureText: !_passwordVisible,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _confirmpasswordController,
                        decoration: InputDecoration(
                          labelText: isFr
                              ? 'Confirmer le mot de passe'
                              : 'Confirm password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.password),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _confirmPasswordVisible =
                                !_confirmPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _confirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: _validateConfirmPassword,
                        obscureText: !_confirmPasswordVisible,
                      ),

                      const SizedBox(height: 30),

                      // 🔵 Bouton principal – même style que Login
                      ElevatedButton(
                        style: primaryButtonStyle,
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFr
                                      ? 'Création du compte...'
                                      : 'Creating account...',
                                ),
                              ),
                            );
                            await signUp();
                          }
                        },
                        child: Text(
                          isFr ? 'S’inscrire' : 'Register',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔵 Lien retour Login – même style que le lien de Login
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          isFr
                              ? 'Vous avez déjà un compte ? Connectez-vous'
                              : 'Already have an account? Log in',
                          style: TextStyle(
                            color: linkColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
