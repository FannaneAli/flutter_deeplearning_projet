import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================================
/// SERVICE CENTRALISÉ POUR CLOUD FIRESTORE (GÉNÉRIQUE)
/// ============================================================================
class FirestoreService {
  FirestoreService._internal();

  static final FirestoreService _instance = FirestoreService._internal();

  /// Singleton
  static FirestoreService get instance => _instance;

  /// Instance Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Getter pratique si tu veux Firestore brut
  FirebaseFirestore get db => _db;

  /// Récupérer une collection par son chemin
  CollectionReference<Map<String, dynamic>> collectionRef(String path) {
    return _db.collection(path);
  }

  /// Ajout d'un document dans une collection
  Future<void> addDocument(
      String collectionPath,
      Map<String, dynamic> data,
      ) {
    return _db.collection(collectionPath).add(data);
  }

  /// Écouter en temps réel une collection
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToCollection(
      String collectionPath,
      ) {
    return _db.collection(collectionPath).snapshots();
  }
}

/// ============================================================================
/// SERVICE FIRESTORE SPÉCIALISÉ POUR LES PROFILS UTILISATEURS
/// ============================================================================
/// - Collection : "users"
/// - Document : uid de l'utilisateur connecté
/// ============================================================================
class UserFirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Raccourci vers la collection "users"
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Référence du document de l'utilisateur courant
  DocumentReference<Map<String, dynamic>> _userDoc() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    return _users.doc(user.uid);
  }

  /// Crée un document utilisateur s'il n'existe pas encore
  Future<void> createUserIfNotExists() async {
    final docRef = _userDoc();
    final doc = await docRef.get();

    if (!doc.exists) {
      final user = _auth.currentUser;
      await docRef.set({
        'name': user?.displayName ?? 'Utilisateur',
        'email': user?.email ?? '',
        'phone': '',
        'city': '',
        'bio': '',
        'dob': '',            // nouvelle date de naissance (string)
        'photoUrl': user?.photoURL,
        'pinHash': null,      // PIN pas encore défini
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Récupère le profil utilisateur (Map) ou null
  Future<Map<String, dynamic>?> getUserProfile() async {
    final doc = await _userDoc().get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Stream temps réel du profil (utile pour le Drawer)
  Stream<Map<String, dynamic>?> userProfileStream() {
    return _userDoc().snapshots().map((snap) => snap.data());
  }

  /// Met à jour les infos principales du profil
  Future<void> updateUserProfile({
    required String name,
    required String email,
    required String phone,
    required String city,
    required String bio,
    required String dob,
  }) async {
    final docRef = _userDoc();

    await docRef.set(
      {
        'name': name,
        'email': email,
        'phone': phone,
        'city': city,
        'bio': bio,
        'dob': dob,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Met à jour uniquement la photo de profil
  Future<void> updateUserPhoto(String photoUrl) async {
    final docRef = _userDoc();

    await docRef.set(
      {
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Supprime le document Firestore de l'utilisateur
  Future<void> deleteUserDocument() async {
    final docRef = _userDoc();
    await docRef.delete();
  }

  // ==========================================================
  // PIN de sécurité (pour tous les comptes : Google + Email)
  // ==========================================================
  Future<void> updateUserPinHash(String pinHash) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _users.doc(user.uid).set(
      {
        'pinHash': pinHash,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
