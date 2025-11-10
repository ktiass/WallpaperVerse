import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/constants.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

part 'auth_service.g.dart';

@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return FirebaseAuth.instance.authStateChanges();
}

@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateChangesProvider).value;
}

@riverpod
Stream<UserModel?> userProfile(UserProfileRef ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
  });
}

@riverpod
int userCredits(UserCreditsRef ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.credits ?? 0;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _updateLastActive(credential.user!.uid);
      return credential;
    } catch (e) {
      AppLogger.error('Sign in error', error: e);
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update profile
      await credential.user!.updateDisplayName(displayName);

      // Create user document
      await _createUserDocument(credential.user!);

      return credential;
    } catch (e) {
      AppLogger.error('Sign up error', error: e);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      AppLogger.error('Sign out error', error: e);
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      AppLogger.error('Reset password error', error: e);
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore.collection(AppConstants.usersCollection).doc(user.uid);

    final exists = await userDoc.get();
    if (exists.exists) return;

    final now = DateTime.now();
    await userDoc.set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'credits': 0,
      'createdAt': Timestamp.fromDate(now),
      'lastActiveAt': Timestamp.fromDate(now),
    });
  }

  // Update last active timestamp
  Future<void> _updateLastActive(String uid) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user signed in');

      // Delete user document
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).delete();

      // Delete auth account
      await user.delete();
    } catch (e) {
      AppLogger.error('Delete account error', error: e);
      rethrow;
    }
  }
}

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}
