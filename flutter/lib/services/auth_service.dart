import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserProfile> register({
    required String email,
    required String password,
    required String pseudo,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final profile = UserProfile(
      uid: cred.user!.uid,
      email: email,
      pseudo: pseudo,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(cred.user!.uid).set(profile.toFirestore());
    return profile;
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _anonymizeUserData(uid);
    await _db.collection('users').doc(uid).delete();
    await _auth.currentUser?.delete();
  }

  Future<void> _anonymizeUserData(String uid) async {
    final remedies = await _db
        .collection('remedies')
        .where('authorId', isEqualTo: uid)
        .get();
    for (final doc in remedies.docs) {
      await doc.reference.update({'authorName': 'Utilisateur supprimé', 'authorId': 'deleted'});
    }
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> updatePseudo(String uid, String pseudo) async {
    await _db.collection('users').doc(uid).update({'pseudo': pseudo});
  }
}
