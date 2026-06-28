import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Acquires provider ID tokens from Google / Apple to exchange with our backend.
///
/// The Google **server client id** (the backend's OAuth web client) is required
/// for a verifiable ID token; supply it via `--dart-define=GOOGLE_SERVER_CLIENT_ID`.
class SocialAuth {
  static const _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  bool _googleInitialized = false;

  /// Returns a Google ID token, or null if the user cancelled.
  Future<String?> googleIdToken() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            _googleServerClientId.isEmpty ? null : _googleServerClientId,
      );
      _googleInitialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken;
  }

  /// Returns an Apple identity token, or null if the user cancelled.
  Future<String?> appleIdentityToken() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    return credential.identityToken;
  }
}
