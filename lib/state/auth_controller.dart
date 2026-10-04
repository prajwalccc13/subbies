// =============================================================================
// Wraps Firebase Authentication for the rest of the app:
//   - knows the current user (and announces changes)
//   - signs in, creates accounts, resets passwords, signs out
//   - turns Firebase's error codes into human messages
//
// Firebase remembers the signed-in user between app launches, so people
// don't have to sign in every time they open the app.
// =============================================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  AuthController(
    this._auth, {
    this._deleteUserData,
  }) {
    _authChanges = _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  final Future<void> Function(String userId)? _deleteUserData;
  late final StreamSubscription<User?> _authChanges;
  User? _user;

  bool get isSignedIn => _user != null;
  String? get userId => _user?.uid; // A unique id Firebase gives each user
  String? get email => _user?.email;

  // Each action returns null on success, or a friendly error message.
  // Returning the message (instead of throwing) keeps the screen code simple.

  Future<String?> signIn(String email, String password) => _run(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  Future<String?> createAccount(String email, String password) => _run(
        () => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  Future<String?> sendPasswordReset(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> signOut() => _auth.signOut();

  // Runs an action and converts any failure into a message.
  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null; // null = it worked
    } on FirebaseAuthException catch (error) {
      // `on X catch` only catches errors of type X. Firebase's errors
      // carry a `code` that tells us exactly what went wrong.
      return _friendlyMessage(error.code);
    } catch (error) {
      debugPrint('Auth error: $error');
      return 'Something went wrong. Please try again.';
    }
  }

  static String _friendlyMessage(String code) => switch (code) {
        'invalid-email' => "That email address doesn't look right.",
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Email or password is incorrect.',
        'email-already-in-use' =>
          'An account with this email already exists. Try signing in.',
        'weak-password' => 'Choose a password with at least 6 characters.',
        'too-many-requests' =>
          'Too many attempts. Wait a moment and try again.',
        'network-request-failed' => 'No internet connection.',
        _ => 'Something went wrong ($code).',
      };

  Future<String?> deleteAccount(String password) => _run(() async {
        final user = _auth.currentUser;
        if (user == null || user.email == null) return;

        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );

        // 2. Delete their data WHILE still signed in. The security rules
        //    only allow access to signed-in owners, so after step 3 it
        //    would be impossible to remove.
        await _deleteUserData?.call(user.uid);

        // 3. Delete the account itself. This also signs them out, so
        //    AccountSync switches the app back to (empty) phone storage.
        await user.delete();
      });

  @override
  void dispose() {
    _authChanges.cancel();
    super.dispose();
  }
}