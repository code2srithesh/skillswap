import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../../../core/theme.dart';
import '../../../core/animations.dart';
import '../../../core/widgets/premium_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_autoCompleteEmail);
  }

  void _autoCompleteEmail() {
    String text = _emailController.text;
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
    _emailController.dispose();
    super.dispose();
  }

  void _handleForgotPassword() async {
    setState(() => _emailError = null);

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = "Please enter your email");
      return;
    }

    if (!email.endsWith("@vitapstudent.ac.in")) {
      setState(
        () => _emailError = "Only @vitapstudent.ac.in emails are allowed",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email);
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset link sent to $email"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _emailError = "Error: $e");
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.white)),
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
                  ScaleInAnimation(
                    child: Center(
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
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _emailSent ? "Check Your Email" : "Reset Password",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _emailSent
                        ? "We've sent a password reset link to your email. Click the link to set a new password."
                        : "Enter your VIT-AP email address and we'll send you a link to reset your password.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_emailSent) ...[
                              TextField(
                                controller: _emailController,
                                enabled: !_isLoading,
                                style: GoogleFonts.inter(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "VIT-AP Email Address",
                                  labelStyle: TextStyle(color: Colors.grey.shade400),
                                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                                  errorText: _emailError,
                                  errorStyle: GoogleFonts.inter(
                                    color: Colors.red.shade400,
                                    fontSize: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              SizedBox(
                                height: 56,
                                child: BouncyTap(
                                  onTap: _isLoading ? () {} : _handleForgotPassword,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.accentGradientBrush,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                                    ),
                                    child: Center(
                                      child: _isLoading 
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text("Send Reset Link", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              ScaleInAnimation(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 64,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Email Sent Successfully!",
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Check your email for the reset link",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.green.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              SizedBox(
                                height: 56,
                                child: BouncyTap(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.accentGradientBrush,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                                    ),
                                    child: Center(
                                      child: Text("Back to Login", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (!_emailSent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Remember your password? ",
                          style: GoogleFonts.inter(color: Colors.grey.shade400),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Back to Login",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
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
