import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/animations.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _handleLogin() async {
    final input = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // This will now throw an error if email is not verified
      await _authService.signInWithUsernameOrEmail(input, password);
      // Navigation is handled by AuthStateChanges in main.dart
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.accentGradientBrush,
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: const Icon(Icons.swap_calls_rounded, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text("Welcome Back", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Sign in to continue swapping skills", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade400)),
                  const SizedBox(height: 40),
                  
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1F3A).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Username or Email",
                                labelStyle: TextStyle(color: Colors.grey.shade400),
                                prefixIcon: Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: "Password",
                                labelStyle: TextStyle(color: Colors.grey.shade400),
                                prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.primaryColor),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: BouncyTap(
                                onTap: _isLoading ? () {} : _handleLogin,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradientBrush,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                                  ),
                                  child: Center(
                                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text("Sign In", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                              child: Text("Forgot Password?", style: GoogleFonts.inter(color: AppTheme.primaryColor)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: GoogleFonts.inter(color: Colors.grey.shade400)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: Text("Sign Up", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}