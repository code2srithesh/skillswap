import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../../home/services/database_service.dart';
import '../../../core/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final _nameController = TextEditingController();
  final _roleController = TextEditingController(); // e.g., "2nd Year CSE"
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Services
  final _authService = AuthService();
  final _dbService = DatabaseService();

  bool _isLoading = false;
  String? _emailError;
  String? _nameError;
  String? _roleError;

  @override
  void initState() {
    super.initState();
    // Add listener to auto-complete email domain
    _emailController.addListener(_autoCompleteEmail);
  }

  void _autoCompleteEmail() {
    String text = _emailController.text;
    // Only auto-complete if @ is typed and there's text before it
    if (text.contains('@') && !text.endsWith('@vitapstudent.ac.in')) {
      String localPart = text.split('@')[0];
      if (localPart.isNotEmpty) {
        _emailController.removeListener(_autoCompleteEmail);
        _emailController.text = '$localPart@vitapstudent.ac.in';
        _emailController.selection = TextSelection.collapsed(
          offset: localPart.length,
        );
        _emailController.addListener(_autoCompleteEmail);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndSignup() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _nameError = null;
      _roleError = null;
    });

    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final role = _roleController.text.trim();

    // Validate email
    if (email.isEmpty) {
      setState(() => _emailError = "Email is required");
      return;
    }

    if (!email.endsWith("@vitapstudent.ac.in")) {
      setState(
        () => _emailError = "Only @vitapstudent.ac.in emails are allowed",
      );
      return;
    }

    // Validate name
    if (name.isEmpty) {
      setState(() => _nameError = "Name is required");
      return;
    }

    // Validate role
    if (role.isEmpty) {
      setState(() => _roleError = "Year & Branch is required");
      return;
    }

    // All validation passed, proceed with signup
    _handleSignup(email, name, role);
  }

  Future<void> _handleSignup(String email, String name, String role) async {
    setState(() => _isLoading = true);

    try {
      // 1. Create Auth User
      User? user = await _authService.signUp(
        email,
        _passwordController.text.trim(),
      );

      // 2. Create Database Profile
      if (user != null) {
        await _dbService.createUserProfile(user.uid, user.email!, name, role);

        // 3. Success -> Go Home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Join SkillSwap Community",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Create your profile and start learning",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Name Field
            Text(
              'Full Name',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Your full name",
                prefixIcon: const Icon(Icons.person_outlined),
                errorText: _nameError,
                hintStyle: GoogleFonts.inter(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Role Field
            Text(
              'Year & Branch',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _roleController,
              decoration: InputDecoration(
                labelText: "e.g., 3rd Year CSE",
                prefixIcon: const Icon(Icons.school_outlined),
                errorText: _roleError,
                hintStyle: GoogleFonts.inter(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Email Field
            Text(
              'VIT-AP Email Address',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "your.email@vitapstudent.ac.in",
                prefixIcon: const Icon(Icons.email_outlined),
                errorText: _emailError,
                hintStyle: GoogleFonts.inter(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password Field
            Text(
              'Password',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Create a strong password",
                prefixIcon: const Icon(Icons.lock_outlined),
                hintStyle: GoogleFonts.inter(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Signup Button
            SizedBox(
              height: 48,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _validateAndSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Create Account",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Login Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: GoogleFonts.inter(color: Colors.grey.shade600),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
