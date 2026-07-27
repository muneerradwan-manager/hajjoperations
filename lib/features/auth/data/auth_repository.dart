import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_logger.dart';
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
      _logIdTokenAudience(idToken);

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

  /// Prints the `aud` and `iss` of the Google ID token, debug builds only.
  ///
  /// Supabase rejecting this exchange says only "Internal Server Error", which
  /// names nothing. The single fact that identifies the mismatch is the token
  /// AUDIENCE — the client id Google issued it for. It has to appear, exactly,
  /// as the Client ID of the Google provider in Supabase (or in its Authorized
  /// Client IDs). Printing it turns an opaque 500 into a string to compare.
  ///
  /// The claims only, never the token: an id_token is a credential, and a
  /// console log is not a private place.
  void _logIdTokenAudience(String idToken) {
    if (!AppLogger.enabled) return;
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) return;
      final payload = parts[1].padRight((parts[1].length + 3) ~/ 4 * 4, '=');
      final claims =
          jsonDecode(utf8.decode(base64Url.decode(payload)))
              as Map<String, dynamic>;
      AppLogger.info(
        'auth',
        "google id_token aud=${claims['aud']} iss=${claims['iss']} "
        "email_verified=${claims['email_verified']}",
      );
    } catch (e) {
      AppLogger.warn('auth', 'could not read id_token claims: $e');
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
