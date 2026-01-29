import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Use Web OAuth Client ID for Google Sign-in
    clientId:
        '1035406953237-mql8klo8j9vfc4h7c8lj8fq8j9vfc4h7.apps.googleusercontent.com',
    hostedDomain: 'vitapstudent.ac.in', // Only allow college domain
    forceCodeForRefreshToken: true,
  );

  static const String collegeDomain = "@vitapstudent.ac.in";

  // 1. Sign Up (Create new user)
  Future<User?> signUp(String email, String password) async {
    // Validate college email
    if (!email.endsWith(collegeDomain)) {
      throw "You must use a $collegeDomain email to register";
    }

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during sign up";
    }
  }

  // 2. Sign In (Login existing user)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during sign in";
    }
  }

  // 2b. Sign In with Username or Email
  Future<User?> signInWithUsernameOrEmail(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      // First, check if it's a username
      if (!usernameOrEmail.contains('@')) {
        // It's a username, find the associated email
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: usernameOrEmail)
            .get();

        if (userQuery.docs.isEmpty) {
          throw "User not found";
        }

        final email = userQuery.docs.first['email'];
        return await signIn(email, password);
      } else {
        // It's an email
        return await signIn(usernameOrEmail, password);
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // 3. Google Sign In (NEW)
  Future<User?> signInWithGoogle() async {
    try {
      // Sign out first to allow account selection
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw "Google Sign-in was cancelled";
      }

      // Check if email is from college domain
      if (!googleUser.email.endsWith(collegeDomain)) {
        await _googleSignIn.signOut();
        throw "Only $collegeDomain emails are allowed.\n\nYou used: ${googleUser.email}";
      }

      try {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential result = await _auth.signInWithCredential(credential);
        return result.user;
      } catch (e) {
        throw "Firebase authentication failed: $e";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // 4. Forgot Password - Send Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Validate college email
      if (!email.endsWith(collegeDomain)) {
        throw "Password reset only available for $collegeDomain emails";
      }

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Failed to send password reset email";
    }
  }

  // 5. Verify password reset code and set new password
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Failed to reset password";
    }
  }

  // 6. Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 7. Get Current User (To check if logged in)
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
