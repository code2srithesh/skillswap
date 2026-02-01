import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    hostedDomain: 'vitapstudent.ac.in',
  );

  static const String collegeDomain = "@vitapstudent.ac.in";

  // 1. Sign Up & Send Verification
  Future<User?> signUp(String email, String password) async {
    if (!email.endsWith(collegeDomain)) {
      throw "You must use a $collegeDomain email to register";
    }
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // SEND VERIFICATION EMAIL IMMEDIATELY
      if (result.user != null && !result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
      }
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during sign up";
    }
  }

  // 2. Sign In (With Verification Check)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // BLOCK LOGIN IF NOT VERIFIED
      if (result.user != null && !result.user!.emailVerified) {
        await _auth.signOut(); // Force logout
        throw "Email not verified. Please check your inbox and verify your email.";
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "An error occurred during sign in";
    }
  }

  // 3. Smart Login (Username OR Email) - FIXED for 'sreelu' vs 'Sreelu'
  Future<User?> signInWithUsernameOrEmail(String input, String password) async {
    String emailToUse = input.trim();

    // Check if input is NOT an email
    if (!input.contains('@')) {
      final usersRef = FirebaseFirestore.instance.collection('users');
      
      // Attempt 1: Exact Match (e.g. 'sreelu')
      var query = await usersRef
          .where('username', isEqualTo: input)
          .limit(1)
          .get();

      // Attempt 2: If failed, try Capitalized (e.g. 'Sreelu')
      if (query.docs.isEmpty && input.isNotEmpty) {
        String capitalized = input[0].toUpperCase() + input.substring(1);
        query = await usersRef
            .where('username', isEqualTo: capitalized)
            .limit(1)
            .get();
      }
      
      // Attempt 3: Try Lowercase (e.g. 'SREELU' -> 'sreelu')
      if (query.docs.isEmpty) {
        query = await usersRef
            .where('username', isEqualTo: input.toLowerCase())
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) {
         throw "Username '$input' not found. Please try your Email instead.";
      }

      final data = query.docs.first.data();
      if (data['email'] == null) {
        throw "System Error: No email linked to this username.";
      }

      emailToUse = data['email'] as String;
    }

    return await signIn(emailToUse, password);
  }

  // 4. Resend Verification Link
  Future<void> resendVerificationEmail(User user) async {
    await user.sendEmailVerification();
  }

  // 5. Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    if (!email.endsWith(collegeDomain)) {
      throw "Password reset only available for $collegeDomain emails";
    }
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  // 6. Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}