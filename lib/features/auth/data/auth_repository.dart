import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../notifications/data/push_service.dart';
import '../domain/saved_account.dart';
import 'saved_accounts_store.dart';

/// Domain-level auth error carrying a user-presentable message.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Whether Google sign-in exists on the platform the app is running on.
///
/// `google_sign_in` declares four: android, ios, macos and web. Windows and
/// Linux have no implementation at all, so the button there fails on the tap
/// rather than at sign-in — no OAuth client of any kind changes that, because
/// there is no code to use one.
///
/// Web is excluded too. It is a supported platform for the package, but this
/// app hands `serverClientId` to it, which is the mobile arrangement; making
/// the browser flow work is its own piece of setup, and until it is done the
/// button would be an offer the app cannot keep.
///
/// A button that cannot work is worse than no button: it reads as the way in,
/// and the person who taps it concludes the app is broken rather than that this
/// door was never open here.
bool get isGoogleSignInSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Wraps Supabase Auth. Supabase is the sole identity provider; Google is used
/// only to obtain an ID token that we hand to Supabase.
class AuthRepository {
  AuthRepository(this._accounts);

  /// The accounts this device may return to without a password. The repository
  /// owns it because every event that changes it is an auth event: a sign-in
  /// records one, a token rotation refreshes one, a sign-out removes one.
  final SavedAccountsStore _accounts;

  SavedAccountsStore get accounts => _accounts;

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

  /// Updates the signed-in user's own email address.
  ///
  /// Through the `admin-set-email` Edge Function rather than
  /// `auth.updateUser(email:)`: the auth-side self-service flow mails
  /// confirmation links to both addresses, and this mission hands accounts
  /// out in person — nothing is mailed, the address just changes. The
  /// function lets anyone in good standing change their own; a duplicate
  /// comes back as `email_taken` (auth enforces uniqueness itself).
  Future<void> updateEmail(String newEmail) async {
    final res = await supabase.functions.invoke(
      'admin-set-email',
      body: {'id': supabase.auth.currentUser!.id, 'email': newEmail.trim()},
    );
    final data = res.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
  }

  /// Records the account that is signed in now, so it can be reopened later
  /// with a tap instead of a password.
  ///
  /// Called on every profile load rather than on sign-in alone, for two
  /// reasons: the name and the photo are only known once the profile is read,
  /// and they change afterwards — a card in the switcher showing last year's
  /// photo is a card the person hesitates over.
  Future<void> rememberCurrentAccount({String? name, String? photoUrl}) async {
    final session = supabase.auth.currentSession;
    final token = session?.refreshToken;
    if (session == null || token == null) return;

    await _accounts.remember(
      userId: session.user.id,
      email: session.user.email ?? '',
      refreshToken: token,
      name: name,
      photoUrl: photoUrl,
    );
  }

  /// Brings the stored token for the active account in line with the one
  /// Supabase is now using.
  ///
  /// Refresh tokens rotate — each renewal issues a new one and retires the old.
  /// Without this the entry saved at sign-in would quietly go dead in the hour
  /// after it was written, and the switcher would offer a door that no longer
  /// opens. Cheap to call: it writes only when the token actually changed.
  Future<void> syncStoredToken() async {
    final session = supabase.auth.currentSession;
    final token = session?.refreshToken;
    if (session == null || token == null) return;
    await _accounts.updateToken(session.user.id, token);
  }

  /// Opens a saved account, replacing the current session with it.
  ///
  /// Nothing is signed out. Supabase revokes a session the moment you ask it
  /// to sign out — even locally scoped, the call reaches the server — and a
  /// revoked session is one the switcher can never reopen. So the account being
  /// left keeps its session, and its stored token stays good; this is the whole
  /// reason switching and signing out are two different actions in this app.
  ///
  /// Push is dropped first, and it has to be first: [PushService.mute] deletes
  /// the row belonging to whoever is signed in, and after the swap that would
  /// be the account we just arrived at. The new one re-subscribes when the
  /// session settles.
  ///
  /// If the stored token has died — revoked elsewhere, or expired past its
  /// reuse window — Supabase ends the current session too, which is why the
  /// account is forgotten here: the app lands on the login screen, and the door
  /// that did not open is no longer offered.
  Future<void> switchTo(SavedAccount account) async {
    if (account.userId == currentUser?.id) return;

    await PushService.instance.mute().timeout(
      const Duration(seconds: 4),
      onTimeout: () {},
    );

    try {
      await supabase.auth.setSession(account.refreshToken);
    } on AuthException catch (e) {
      await _accounts.forget(account.userId);
      unawaited(PushService.instance.start());
      throw AuthFailure(e.message);
    } catch (e) {
      unawaited(PushService.instance.start());
      throw AuthFailure('$e');
    }
  }

  /// Removes an account from the switcher without touching the current session.
  Future<void> forgetAccount(String userId) => _accounts.forget(userId);

  /// Signs out, dropping this device's push subscriptions first: FCM topics
  /// outlive a session, and the next person to use the phone must not receive
  /// the last one's files. The device token row goes too — [PushService.mute]
  /// rather than just the topics, or pushes addressed to the departed account
  /// personally would keep reaching this phone, including after somebody else
  /// signs in on it.
  ///
  /// Neither step is allowed to hold the door shut. Unsubscribing talks to
  /// Firebase one topic at a time and on a bad connection simply does not come
  /// back; the sign-out itself talks to Supabase. A person who has decided to
  /// leave must leave, so each half is bounded, and if the server cannot be
  /// reached the session is cleared on the device anyway — a token that outlives
  /// its use is the lesser problem, and it expires on its own.
  ///
  /// The account also leaves the switcher, and that is not a preference: this
  /// call revokes the session on the server, so the token saved for it stops
  /// working. Keeping the card would be keeping a door that reports itself
  /// locked only after it has been tried. Whoever wants to come back without a
  /// password uses "switch account", which revokes nothing.
  Future<void> signOut() async {
    final uid = currentUser?.id;

    await PushService.instance.mute().timeout(
      const Duration(seconds: 4),
      onTimeout: () {},
    );
    if (uid != null) await _accounts.forget(uid);

    try {
      await supabase.auth.signOut().timeout(const Duration(seconds: 8));
    } catch (_) {
      try {
        await supabase.auth.signOut(scope: SignOutScope.local);
      } catch (_) {
        // Out of options worth taking: the session listener is what moves the
        // app to the login screen, and a local clear is the last thing that
        // triggers it.
      }
    }
  }
}
