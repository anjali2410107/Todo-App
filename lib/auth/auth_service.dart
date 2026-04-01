import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _googleInitialized = false;

  static Future<void> initializeGoogleSignIn() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  static Stream<User?> get userStream => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;


  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser =
          await GoogleSignIn.instance.authenticate();
      if (gUser == null) return null;

      final GoogleSignInAuthentication gAuth = gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    } catch (e) {
      throw 'Google Sign-In failed. Please try again.';
    }
  }

  static Future<UserCredential> signInWithEmail(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  static Future<UserCredential> signUpWithEmail(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _parseAuthException(e);
    }
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
    }
    await _auth.signOut();
  }

  static String _parseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'invalid-verification-code':
        return 'Invalid OTP code. Please try again.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number with country code.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
