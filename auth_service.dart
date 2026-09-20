import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _google = GoogleSignIn();

  static Future<void> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return; // cancelled
    final tokens = await account.authentication;
    await _auth.signInWithCredential(GoogleAuthProvider.credential(
      accessToken: tokens.accessToken,
      idToken: tokens.idToken,
    ));
  }

  static Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}
