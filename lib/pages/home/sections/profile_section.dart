import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../config/firestore_service.dart';

/// ============================================================================
/// SECTION PROFIL UTILISATEUR (dans HomePage)
/// ============================================================================
/// - Firestore : name, email, phone, city, bio, dob, photoUrl, pinHash
/// - Cloudinary : stockage photo
/// - PIN :
///   * obligatoire au premier login (tous les comptes)
///   * modifiable ensuite
///   * utilisé comme option pour suppression de compte
/// ============================================================================

class ProfileSection extends StatefulWidget {
  final bool isFrench;
  final User? user;

  const ProfileSection({
    super.key,
    required this.isFrench,
    required this.user,
  });

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  // ================================================================
  // SERVICES, VARIABLES ET CONTRÔLEURS
  // ================================================================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserFirestoreService _userService = UserFirestoreService();
  String? _currentPinHash;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _needsPinSetup = false;

  String? _photoUrl;

  // 🔹 CONFIG CLOUDINARY
  static const String _cloudinaryCloudName = 'dpky9tbbn';
  static const String _cloudinaryUploadPreset = 'flutter_unsigned';

  bool get isGoogleUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  @override
  void initState() {
    super.initState();

    _nameController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadUserData();
  }

  // ----------------------------------------------------------------
  // CHARGEMENT DES DONNÉES
  // ----------------------------------------------------------------
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      await _userService.createUserIfNotExists();
      final data = await _userService.getUserProfile();

      if (data != null) {
        _nameController.text = data['name'] ?? _defaultName();
        _emailController.text = data['email'] ?? (widget.user?.email ?? '');
        _phoneController.text = data['phone'] ?? '';
        _cityController.text = data['city'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _dobController.text = data['dob'] ?? '';
        _photoUrl = data['photoUrl'] ?? widget.user?.photoURL;

        _currentPinHash = data['pinHash'] as String?;
        _needsPinSetup =
        (_currentPinHash == null || _currentPinHash!.isEmpty);
      } else {
        _nameController.text = _defaultName();
        _emailController.text = widget.user?.email ?? '';
        _phoneController.text = '';
        _cityController.text = '';
        _bioController.text = '';
        _dobController.text = '';
        _photoUrl = widget.user?.photoURL;
        _currentPinHash = null;
        _needsPinSetup = true;
      }
    } catch (e) {
      _showSnackBar(
        widget.isFrench
            ? 'Erreur lors du chargement du profil: $e'
            : 'Error while loading profile: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _defaultName() {
    return widget.user?.displayName ??
        (widget.isFrench ? 'Utilisateur' : 'User');
  }

  // ----------------------------------------------------------------
  // SAUVEGARDE DU PROFIL
  // ----------------------------------------------------------------
  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);

      await _userService.updateUserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        bio: _bioController.text.trim(),
        dob: _dobController.text.trim(),
      );

      _showSnackBar(
        widget.isFrench
            ? "Profil mis à jour avec succès ✅"
            : "Profile successfully updated ✅",
      );

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      _showSnackBar(
        widget.isFrench
            ? "Erreur lors de la mise à jour: $e"
            : "Error while updating profile: $e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ----------------------------------------------------------------
  // CLOUDINARY
  // ----------------------------------------------------------------
  Future<String?> _uploadImageToCloudinary(String filePath) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _cloudinaryUploadPreset
        ..files.add(
          await http.MultipartFile.fromPath('file', filePath),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
        jsonDecode(responseBody) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary error: $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('Erreur upload Cloudinary: $e');
      return null;
    }
  }

  Future<void> _changeProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final imageUrl = await _uploadImageToCloudinary(pickedFile.path);

      if (imageUrl == null) {
        _showSnackBar(
          widget.isFrench
              ? "Erreur lors de l'upload de la photo."
              : "Error while uploading image.",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      await _userService.updateUserPhoto(imageUrl);

      setState(() {
        _photoUrl = imageUrl;
        _isLoading = false;
      });

      _showSnackBar(
        widget.isFrench
            ? "Photo de profil mise à jour ✅"
            : "Profile picture updated ✅",
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        widget.isFrench
            ? "Erreur lors du changement de photo: $e"
            : "Error while changing photo: $e",
        isError: true,
      );
    }
  }

  // ----------------------------------------------------------------
  // AUTH & RE-AUTH
  // ----------------------------------------------------------------
  Future<bool> _reauthenticateUser(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      _showSnackBar(
        widget.isFrench
            ? "Utilisateur non authentifié."
            : "User is not authenticated.",
        isError: true,
      );
      return false;
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showSnackBar(
          widget.isFrench
              ? "Ancien mot de passe incorrect."
              : "Old password is incorrect.",
          isError: true,
        );
      } else {
        _showSnackBar(
          widget.isFrench
              ? "Erreur d'authentification: ${e.code}"
              : "Re-authentication error: ${e.code}",
          isError: true,
        );
      }
      return false;
    } catch (e) {
      _showSnackBar(
        widget.isFrench
            ? "Erreur d'authentification: $e"
            : "Authentication error: $e",
        isError: true,
      );
      return false;
    }
  }

  Future<bool> _reauthenticateWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final googleProvider = GoogleAuthProvider();
      await user.reauthenticateWithProvider(googleProvider);
      return true;
    } catch (e) {
      _showSnackBar(
        widget.isFrench
            ? "Erreur de ré-authentification Google."
            : "Google re-authentication failed.",
        isError: true,
      );
      return false;
    }
  }

  // ----------------------------------------------------------------
  // GESTION DU PIN
  // ----------------------------------------------------------------
  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  bool _isPinFormatValid(String pin) {
    final reg = RegExp(r'^\d{4,6}$'); // 4 à 6 chiffres
    return reg.hasMatch(pin);
  }

  Future<bool> _isPinCorrect(String pin) async {
    final data = await _userService.getUserProfile();
    final stored = data?['pinHash'] as String?;
    if (stored == null || stored.isEmpty) {
      _showSnackBar(
        widget.isFrench
            ? "Aucun code PIN enregistré."
            : "No PIN is registered.",
        isError: true,
      );
      return false;
    }
    if (_hashPin(pin) != stored) {
      _showSnackBar(
        widget.isFrench ? "Code PIN incorrect." : "Incorrect PIN code.",
        isError: true,
      );
      return false;
    }
    return true;
  }

  Future<void> _createOrUpdatePin(String pin) async {
    final hash = _hashPin(pin);
    await _userService.updateUserPinHash(hash);
    _currentPinHash = hash;
  }

  void _showPinDialog({required bool force}) {
    final TextEditingController pin1 = TextEditingController();
    final TextEditingController pin2 = TextEditingController();

    final title = widget.isFrench
        ? (force ? "Créer un code PIN" : "Modifier le code PIN")
        : (force ? "Create PIN code" : "Change PIN code");
    final msg = widget.isFrench
        ? "Le code PIN sera utilisé pour sécuriser les actions sensibles (suppression de compte, etc.)."
        : "The PIN code will secure sensitive actions (account deletion, etc.).";
    final pinLabel =
    widget.isFrench ? "Code PIN (4–6 chiffres)" : "PIN code (4–6 digits)";
    final confirmLabel =
    widget.isFrench ? "Confirmer le code PIN" : "Confirm PIN code";
    final cancel = widget.isFrench ? "Annuler" : "Cancel";
    final save = widget.isFrench ? "Enregistrer" : "Save";

    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg),
            const SizedBox(height: 16),
            TextField(
              controller: pin1,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: pinLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pin2,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: confirmLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(cancel),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            onPressed: () async {
              final p1 = pin1.text.trim();
              final p2 = pin2.text.trim();

              if (!_isPinFormatValid(p1)) {
                _showSnackBar(
                  widget.isFrench
                      ? "Le PIN doit contenir 4 à 6 chiffres."
                      : "PIN must be 4–6 digits.",
                  isError: true,
                );
                return;
              }
              if (p1 != p2) {
                _showSnackBar(
                  widget.isFrench
                      ? "Les deux PIN ne correspondent pas."
                      : "PIN and confirmation do not match.",
                  isError: true,
                );
                return;
              }

              Navigator.pop(ctx);
              await _createOrUpdatePin(p1);
              _showSnackBar(
                widget.isFrench
                    ? "Code PIN enregistré ✅"
                    : "PIN code saved ✅",
              );
            },
            child: Text(
              save,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // CHANGEMENT DE MDP
  // ----------------------------------------------------------------
  Future<void> _changePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (isGoogleUser) {
      _showSnackBar(
        widget.isFrench
            ? "Ce compte est lié à Google, il n'a pas de mot de passe local."
            : "This account is linked to Google, it has no local password.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ok = await _reauthenticateUser(oldPassword);
      if (!ok) {
        setState(() => _isLoading = false);
        return;
      }

      await user.updatePassword(newPassword);

      _showSnackBar(
        widget.isFrench
            ? "Mot de passe mis à jour ✅"
            : "Password updated successfully ✅",
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'weak-password') {
        msg = widget.isFrench
            ? "Le nouveau mot de passe est trop faible (min. 6 caractères, avec majuscule et chiffre)."
            : "New password is too weak (min 6 chars, with uppercase and number).";
      } else if (e.code == 'requires-recent-login') {
        msg = widget.isFrench
            ? "Veuillez vous reconnecter puis réessayer."
            : "Please log in again and try.";
      } else {
        msg = widget.isFrench
            ? "Erreur lors du changement de mot de passe: ${e.code}"
            : "Error while changing password: ${e.code}";
      }
      _showSnackBar(msg, isError: true);
    } catch (e) {
      _showSnackBar(
        widget.isFrench
            ? "Erreur lors du changement de mot de passe: $e"
            : "Error while changing password: $e",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ----------------------------------------------------------------
  // SUPPRESSION DU COMPTE (PIN ou MDP)
  // ----------------------------------------------------------------
  Future<void> _deleteAccount({String? password, String? pin}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1) Vérif PIN si demandé
      if (pin != null) {
        final okPin = await _isPinCorrect(pin);
        if (!okPin) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2) Re-auth Firebase
      bool okAuth = true;
      if (isGoogleUser) {
        okAuth = await _reauthenticateWithGoogle();
      } else if (password != null) {
        okAuth = await _reauthenticateUser(password);
      }

      if (!okAuth) {
        setState(() => _isLoading = false);
        return;
      }

      // 3) Supprimer Firestore + Auth
      await _userService.deleteUserDocument();
      await user.delete();

      _showSnackBar(
        widget.isFrench
            ? "Compte supprimé avec succès."
            : "Account deleted successfully.",
      );

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'requires-recent-login') {
        msg = widget.isFrench
            ? "Veuillez vous reconnecter puis réessayer de supprimer le compte."
            : "Please log in again before deleting your account.";
      } else {
        msg = widget.isFrench
            ? "Erreur lors de la suppression du compte: ${e.code}"
            : "Error while deleting account: ${e.code}";
      }
      _showSnackBar(msg, isError: true);
    } catch (e) {
      _showSnackBar(
        widget.isFrench
            ? "Erreur lors de la suppression du compte: $e"
            : "Error while deleting account: $e",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // ====================================================================
  // BUILD
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    if (_needsPinSetup && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPinDialog(force: true);
      });
      _needsPinSetup = false;
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          _buildInfoSection(),
          const SizedBox(height: 24),
          _buildSecuritySection(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // HEADER AVEC AVATAR + ICÔNE CAMÉRA
  // ----------------------------------------------------------------
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _photoUrl != null
                      ? NetworkImage(_photoUrl!)
                      : const AssetImage("images/Profile.png")
                  as ImageProvider,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: GestureDetector(
                  onTap: _changeProfilePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nameController.text.isEmpty
                ? _defaultName()
                : _nameController.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // INFO PERSONNELLES + STYLO EN HAUT
  // ----------------------------------------------------------------
  Widget _buildInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = widget.isFrench
        ? "Informations personnelles"
        : "Personal information";

    final labelName = widget.isFrench ? "Nom complet" : "Full name";
    const labelEmail = "Email";
    final labelPhone = widget.isFrench ? "Téléphone" : "Phone";
    final labelCity = widget.isFrench ? "Ville" : "City";
    final labelBio =
    widget.isFrench ? "Bio / À propos de moi" : "Bio / About me";
    final labelDob =
    widget.isFrench ? "Date de naissance" : "Date of birth";
    final labelMemberSince =
    widget.isFrench ? "Membre depuis" : "Member since";
    final emailHintInfo = widget.isFrench
        ? "L'email ne peut pas être modifié ici"
        : "Email cannot be changed here";

    final saveTooltip =
    widget.isFrench ? "Sauvegarder les changements" : "Save changes";
    final editTooltip =
    widget.isFrench ? "Modifier le profil" : "Edit profile";

    final Color cardBg =
    isDark ? const Color(0xFF1C1926) : Colors.white;
    final Color textPrimary =
    isDark ? Colors.white : Colors.black87;
    final Color textSecondary =
    isDark ? Colors.white70 : Colors.grey.shade700;
    final Color fieldFill =
    isDark ? const Color(0xFF262335) : Colors.grey.shade100;

    InputDecoration _fieldDecoration({
      required String label,
      IconData? icon,
      bool enabled = true,
      Widget? suffix,
      bool alignLabelWithHint = false,
    }) {
      return InputDecoration(
        labelText: label,
        alignLabelWithHint: alignLabelWithHint,
        prefixIcon: icon != null ? Icon(icon) : null,
        prefixIconColor: isDark ? Colors.white70 : Colors.grey.shade700,
        suffixIcon: suffix,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey.shade700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white24
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.deepPurple,
            width: 1.8,
          ),
        ),
        filled: true,
        fillColor: enabled ? fieldFill : (isDark
            ? const Color(0xFF201D2B)
            : Colors.grey.shade100),
      );
    }

    return Card(
      elevation: 4,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.deepPurple.shade300,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                Tooltip(
                  message: _isEditing ? saveTooltip : editTooltip,
                  child: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      if (_isEditing) {
                        _saveProfile();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
                    icon: Icon(
                      _isEditing ? Icons.check_circle : Icons.edit,
                      color:
                      _isEditing ? Colors.green : Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nom
            TextField(
              controller: _nameController,
              enabled: _isEditing,
              style: TextStyle(color: textPrimary),
              decoration: _fieldDecoration(
                label: labelName,
                icon: Icons.person_outline,
                enabled: _isEditing,
              ),
            ),
            const SizedBox(height: 16),

            // Email
            TextField(
              controller: _emailController,
              enabled: false,
              style: TextStyle(color: textSecondary),
              decoration: _fieldDecoration(
                label: labelEmail,
                icon: Icons.email_outlined,
                enabled: false,
                suffix: Tooltip(
                  message: emailHintInfo,
                  child: const Icon(Icons.lock_outline, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Téléphone
            TextField(
              controller: _phoneController,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: textPrimary),
              decoration: _fieldDecoration(
                label: labelPhone,
                icon: Icons.phone,
                enabled: _isEditing,
              ),
            ),
            const SizedBox(height: 16),

            // Ville
            TextField(
              controller: _cityController,
              enabled: _isEditing,
              style: TextStyle(color: textPrimary),
              decoration: _fieldDecoration(
                label: labelCity,
                icon: Icons.location_city,
                enabled: _isEditing,
              ),
            ),
            const SizedBox(height: 16),

            // Date de naissance
            TextField(
              controller: _dobController,
              enabled: _isEditing,
              readOnly: true,
              style: TextStyle(color: textPrimary),
              onTap: _isEditing
                  ? () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                  DateTime(now.year - 18, now.month, now.day),
                  firstDate: DateTime(1900),
                  lastDate: now,
                );
                if (picked != null) {
                  _dobController.text =
                  "${picked.day.toString().padLeft(2, '0')}/"
                      "${picked.month.toString().padLeft(2, '0')}/"
                      "${picked.year}";
                }
              }
                  : null,
              decoration: _fieldDecoration(
                label: labelDob,
                icon: Icons.cake_outlined,
                enabled: _isEditing,
              ),
            ),
            const SizedBox(height: 16),

            // Bio
            TextField(
              controller: _bioController,
              enabled: _isEditing,
              maxLines: 3,
              style: TextStyle(color: textPrimary),
              decoration: _fieldDecoration(
                label: labelBio,
                icon: Icons.info_outline,
                enabled: _isEditing,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  labelMemberSince,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(_auth.currentUser?.metadata.creationTime),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return widget.isFrench ? "Non disponible" : "Not available";
    }
    return "${date.day}/${date.month}/${date.year}";
  }

  // ----------------------------------------------------------------
  // SECTION SÉCURITÉ : PIN + MDP + SUPPRESSION
  // ----------------------------------------------------------------
  Widget _buildSecuritySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title =
    widget.isFrench ? "Sécurité du compte" : "Account security";
    final changePwd =
    widget.isFrench ? "Changer le mot de passe" : "Change password";
    final changePin =
    widget.isFrench ? "Modifier le code PIN" : "Change PIN code";
    final deleteAccount =
    widget.isFrench ? "Supprimer le compte" : "Delete account";

    final Color cardBg =
    isDark ? const Color(0xFF1C1926) : Colors.white;
    final Color textPrimary =
    isDark ? Colors.white : Colors.black87;

    return Card(
      elevation: 4,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, color: Colors.deepPurple.shade300),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // PIN
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                _isLoading ? null : _showChangePinDialog,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.deepPurple.shade300,
                  ),
                ),
                icon: Icon(
                  Icons.pin,
                  color: Colors.deepPurple.shade300,
                ),
                label: Text(
                  changePin,
                  style: TextStyle(
                    color: Colors.deepPurple.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Changer mot de passe (email/password uniquement)
            if (!isGoogleUser)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                  _isLoading ? null : _showChangePasswordDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.password, color: Colors.white),
                  label: Text(
                    changePwd,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (!isGoogleUser) const SizedBox(height: 12),

            // Supprimer compte (MDP ou PIN)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                _isLoading ? null : _showDeleteAccountDialog,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(
                  deleteAccount,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // DIALOGUES
  // ----------------------------------------------------------------
  void _showChangePasswordDialog() {
    final TextEditingController oldPasswordController =
    TextEditingController();
    final TextEditingController newPasswordController =
    TextEditingController();
    final TextEditingController confirmPasswordController =
    TextEditingController();

    final title = widget.isFrench
        ? "Changer le mot de passe"
        : "Change password";
    final oldLabel =
    widget.isFrench ? "Ancien mot de passe" : "Old password";
    final newLabel =
    widget.isFrench ? "Nouveau mot de passe" : "New password";
    final confirmLabel = widget.isFrench
        ? "Confirmer le nouveau mot de passe"
        : "Confirm new password";
    final cancel = widget.isFrench ? "Annuler" : "Cancel";
    final confirm = widget.isFrench ? "Confirmer" : "Confirm";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool obscureOld = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ancien mot de passe
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: oldLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          obscureOld = !obscureOld;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nouveau mot de passe
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: newLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmation
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: confirmLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final oldPwd = oldPasswordController.text.trim();
                  final newPwd = newPasswordController.text.trim();
                  final confirmPwd =
                  confirmPasswordController.text.trim();

                  // 1) Champs obligatoires
                  if (oldPwd.isEmpty ||
                      newPwd.isEmpty ||
                      confirmPwd.isEmpty) {
                    _showSnackBar(
                      widget.isFrench
                          ? "Veuillez remplir tous les champs."
                          : "Please fill in all fields.",
                      isError: true,
                    );
                    return;
                  }

                  // 2) Règles de complexité
                  final hasUpper = newPwd.contains(RegExp(r'[A-Z]'));
                  final hasDigit = newPwd.contains(RegExp(r'\d'));
                  if (newPwd.length < 6 || !hasUpper || !hasDigit) {
                    _showSnackBar(
                      widget.isFrench
                          ? "Le mot de passe doit contenir au moins 6 caractères, une majuscule et un chiffre."
                          : "Password must have at least 6 characters, one uppercase letter and one digit.",
                      isError: true,
                    );
                    return;
                  }

                  // 3) Confirmation = nouveau
                  if (newPwd != confirmPwd) {
                    _showSnackBar(
                      widget.isFrench
                          ? "Les deux nouveaux mots de passe ne correspondent pas."
                          : "New password and confirmation do not match.",
                      isError: true,
                    );
                    return;
                  }

                  // 4) Vérifier l'ancien mot de passe AVANT de fermer la popup
                  final ok = await _reauthenticateUser(oldPwd);
                  if (!ok) {
                    // _reauthenticateUser affiche déjà :
                    // "Ancien mot de passe incorrect." en rouge
                    // ⚠️ On NE ferme PAS la popup.
                    return;
                  }

                  // 5) Tout est bon → on ferme la popup puis on change le mot de passe
                  Navigator.pop(ctx);
                  await _changePassword(oldPwd, newPwd);
                },
                child: Text(confirm),
              ),
            ],
          ),
        );
      },
    );
  }



  void _showChangePinDialog() {
    final TextEditingController oldPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    final title =
    widget.isFrench ? "Modifier le code PIN" : "Change PIN code";
    final desc = widget.isFrench
        ? "Le code PIN sera utilisé pour sécuriser les actions sensibles (suppression de compte, etc.)."
        : "The PIN code will secure sensitive actions (account deletion, etc.).";
    final cancel = widget.isFrench ? "Annuler" : "Cancel";
    final save = widget.isFrench ? "Enregistrer" : "Save";

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool obscureOld = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  desc,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Ancien PIN
                TextField(
                  controller: oldPinController,
                  keyboardType: TextInputType.number,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: widget.isFrench
                        ? 'Ancien code PIN'
                        : 'Current PIN',
                    hintText:
                    widget.isFrench ? 'PIN actuel' : 'Current PIN',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          obscureOld = !obscureOld;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nouveau PIN
                TextField(
                  controller: newPinController,
                  keyboardType: TextInputType.number,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: widget.isFrench
                        ? 'Nouveau code PIN'
                        : 'New PIN',
                    hintText: widget.isFrench
                        ? 'Code PIN (4–6 chiffres)'
                        : 'PIN (4–6 digits)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirmation
                TextField(
                  controller: confirmPinController,
                  keyboardType: TextInputType.number,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: widget.isFrench
                        ? 'Confirmer le code PIN'
                        : 'Confirm PIN',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: isDark ? 2 : 0,
                ),
                onPressed: () async {
                  final oldPin = oldPinController.text.trim();
                  final newPin = newPinController.text.trim();
                  final confirmPin = confirmPinController.text.trim();

                  // 1) Champs obligatoires
                  if (oldPin.isEmpty ||
                      newPin.isEmpty ||
                      confirmPin.isEmpty) {
                    _showSnackBar(
                      widget.isFrench
                          ? 'Tous les champs sont obligatoires'
                          : 'All fields are required',
                      isError: true,
                    );
                    return;
                  }

                  // 2) Nouveau PIN : 4–6 chiffres
                  if (!_isPinFormatValid(newPin)) {
                    _showSnackBar(
                      widget.isFrench
                          ? 'Le PIN doit contenir 4 à 6 chiffres uniquement'
                          : 'PIN must be 4–6 digits',
                      isError: true,
                    );
                    return;
                  }

                  // 3) Confirmation = nouveau
                  if (newPin != confirmPin) {
                    _showSnackBar(
                      widget.isFrench
                          ? 'Les deux nouveaux PIN ne correspondent pas'
                          : 'The two PIN codes do not match',
                      isError: true,
                    );
                    return;
                  }

                  // 4) Vérifier qu’un PIN existe
                  if (_currentPinHash == null ||
                      _currentPinHash!.isEmpty) {
                    _showSnackBar(
                      widget.isFrench
                          ? 'Aucun PIN défini pour ce compte'
                          : 'No PIN defined for this account',
                      isError: true,
                    );
                    return;
                  }

                  // 5) Vérifier l'ancien PIN (sha256)
                  final oldHash = _hashPin(oldPin);
                  if (oldHash != _currentPinHash) {
                    _showSnackBar(
                      widget.isFrench
                          ? 'Ancien PIN incorrect'
                          : 'Incorrect current PIN',
                      isError: true,
                    );
                    // ❌ On ne ferme pas la popup
                    return;
                  }

                  // 6) Enregistrer le nouveau PIN
                  await _createOrUpdatePin(newPin);

                  if (mounted) {
                    Navigator.pop(ctx);
                    _showSnackBar(
                      widget.isFrench
                          ? 'Code PIN mis à jour avec succès'
                          : 'PIN updated successfully',
                    );
                  }
                },
                child: Text(save),
              ),
            ],
          ),
        );
      },
    );
  }



  void _showDeleteAccountDialog() {
    final TextEditingController passwordController =
    TextEditingController();
    final TextEditingController pinController = TextEditingController();

    Method method = isGoogleUser ? Method.pin : Method.password;

    final title = widget.isFrench ? "Attention !" : "Warning!";
    final baseMessage = widget.isFrench
        ? "Êtes-vous sûr de vouloir supprimer définitivement votre compte ?"
        : "Are you sure you want to permanently delete your account?";
    final cancel = widget.isFrench ? "Annuler" : "Cancel";
    final delete = widget.isFrench ? "Supprimer" : "Delete";
    final pwdLabel = widget.isFrench ? "Mot de passe" : "Password";
    final pinLabel = widget.isFrench ? "Code PIN" : "PIN code";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(baseMessage),
              const SizedBox(height: 16),
              if (!isGoogleUser) ...[
                RadioListTile<Method>(
                  value: Method.password,
                  groupValue: method,
                  onChanged: (m) {
                    if (m != null) {
                      setStateDialog(() => method = m);
                    }
                  },
                  title: Text(
                    widget.isFrench
                        ? "Confirmer avec mot de passe"
                        : "Confirm with password",
                  ),
                ),
                RadioListTile<Method>(
                  value: Method.pin,
                  groupValue: method,
                  onChanged: (m) {
                    if (m != null) {
                      setStateDialog(() => method = m);
                    }
                  },
                  title: Text(
                    widget.isFrench
                        ? "Confirmer avec code PIN"
                        : "Confirm with PIN",
                  ),
                ),
              ] else
                Text(
                  widget.isFrench
                      ? "Ce compte Google peut être confirmé avec votre code PIN."
                      : "This Google account can be confirmed with your PIN.",
                ),
              const SizedBox(height: 12),
              if (method == Method.password && !isGoogleUser)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: pwdLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              else
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: pinLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                if (method == Method.password && !isGoogleUser) {
                  final pwd = passwordController.text.trim();
                  if (pwd.isEmpty) {
                    _showSnackBar(
                      widget.isFrench
                          ? "Veuillez saisir votre mot de passe."
                          : "Please enter your password.",
                      isError: true,
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await _deleteAccount(password: pwd);
                } else {
                  final pin = pinController.text.trim();
                  if (!_isPinFormatValid(pin)) {
                    _showSnackBar(
                      widget.isFrench
                          ? "Veuillez saisir un code PIN valide."
                          : "Please enter a valid PIN.",
                      isError: true,
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await _deleteAccount(pin: pin);
                }
              },
              child: Text(
                delete,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum Method { password, pin }
