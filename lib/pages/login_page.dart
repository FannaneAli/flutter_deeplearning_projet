import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../config/ui_config.dart';
import '../services/auth_service.dart';

/// Page de connexion (email / mot de passe + Google)
/// avec gestion des erreurs + switch thème + switch langue.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService.instance;

  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return UIConfig.isFrench ? 'Veuillez saisir un email' : 'Please enter your email';
    }
    if (!value.contains('@')) {
      return UIConfig.isFrench ? 'Email invalide' : 'Invalid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return UIConfig.isFrench ? 'Veuillez saisir un mot de passe' : 'Please enter your password';
    }
    if (value.length < 6) {
      return UIConfig.isFrench ? 'Au moins 6 caractères' : 'At least 6 characters';
    }
    return null;
  }

  String _mapFirebaseLoginError(Object error) {
    final fr = UIConfig.isFrench;
    final s = error.toString();
    if (s.contains('user-not-found')) {
      return fr ? 'Aucun utilisateur trouvé pour cet email.' : 'No user found for this email.';
    }
    if (s.contains('wrong-password')) {
      return fr ? 'Mot de passe incorrect.' : 'Incorrect password.';
    }
    if (s.contains('invalid-email')) {
      return fr ? 'Format d’email invalide.' : 'Invalid email format.';
    }
    if (s.contains('too-many-requests')) {
      return fr ? 'Trop de tentatives. Réessayez plus tard.' : 'Too many attempts. Try again later.';
    }
    if (s.contains('network-request-failed')) {
      return fr ? 'Problème de connexion réseau.' : 'Network error.';
    }
    return fr ? 'Erreur de connexion. Veuillez réessayer.' : 'Login error. Please try again.';
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      Fluttertoast.showToast(
        msg: UIConfig.isFrench ? 'Connexion réussie ✅' : 'Login successful ✅',
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      final msg = _mapFirebaseLoginError(e);
      Fluttertoast.showToast(msg: msg, toastLength: Toast.LENGTH_LONG);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user == null) {
        Fluttertoast.showToast(
          msg: UIConfig.isFrench ? 'Connexion Google annulée' : 'Google sign-in cancelled',
        );
      } else {
        Fluttertoast.showToast(
          msg: UIConfig.isFrench ? 'Connecté avec Google ✅' : 'Signed in with Google ✅',
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: (UIConfig.isFrench ? 'Erreur Google : ' : 'Google error: ') + e.toString(),
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = UIConfig.isDarkMode;
    final isFr = UIConfig.isFrench;

    final bgColors = isDark
        ? [const Color(0xFF121212), const Color(0xFF1F2933)]
        : [Colors.white, Colors.grey.shade200];

    final cardColor = isDark ? const Color(0xFFF5EFFD) : Colors.white;
    final linkColor = Colors.deepPurple;

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
                      // Ligne avec switch thème + langue
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


                      const SizedBox(height: 8),
                      Center(
                        child: Image.asset(
                          'images/user-login.jpg',
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        isFr ? 'Connexion' : 'Login',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isFr
                            ? 'Connecte-toi avec ton email ou ton compte Google'
                            : 'Sign in with your email or Google account',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: isFr ? 'Email' : 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: isFr ? 'Mot de passe' : 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
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
                        obscureText: !_passwordVisible,
                        validator: _validatePassword,
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _loginWithEmail,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(
                            isFr ? 'Se connecter' : 'Sign in',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text('ou'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _loginWithGoogle,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: Text(
                            isFr
                                ? 'Continuer avec Google'
                                : 'Continue with Google',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔵 Lien vers Register – style réutilisable
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          isFr
                              ? 'Pas de compte ? Inscris-toi'
                              : "Don't have an account? Sign up",
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
