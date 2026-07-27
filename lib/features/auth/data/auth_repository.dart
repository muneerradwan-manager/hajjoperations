import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../notifications/data/push_service.dart';

/// Domain-level auth error carrying a user-presentable message.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps Supabase Auth. Supabase is the sole identity provider; Google is used
/// only to obtain an ID token that we hand to Supabase.
class AuthRepository {
  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  /// GoogleSignIn.initialize() may be called only once per process.
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized(String webClientId) async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: webClientId);
    _googleInitialized = true;
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signUp(email: email.trim(), password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signInWithGoogle() async {
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    if (webClientId == null || webClientId.isEmpty) {
      throw AuthFailure('Google client id is not configured');
    }

    try {
      await _ensureGoogleInitialized(webClientId);

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthFailure('No ID token returned from Google');
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthFailure('cancelled');
      }
      throw AuthFailure(e.description ?? 'Google sign-in failed');
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      // Surface any other error (e.g. platform/config issues) instead of
      // leaving the UI stuck in a submitting state.
      throw AuthFailure('Google sign-in failed: $e');
    }
  }

  /// Updates the signed-in user's own password.
  Future<void> updatePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  /// Signs out, dropping this device's push subscriptions first: FCM topics
  /// outlive a session, and the next person to use the phone must not receive
  /// the last one's files.
  Future<void> signOut() async {
    await PushService.instance.forgetTopics();
    await supabase.auth.signOut();
  }
}
