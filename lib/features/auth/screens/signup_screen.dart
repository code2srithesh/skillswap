import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/animations.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      final text = _emailController.text;
      if (text.contains('@') && !text.endsWith('@vitapstudent.ac.in')) {
        final local = text.split('@')[0];
        if (local.isNotEmpty) {
           _emailController.value = TextEditingValue(
             text: '$local@vitapstudent.ac.in',
             selection: TextSelection.collapsed(offset: local.length),
           );
        }
      }
    });
  }

  void _handleSignup() async {
    if (_nameController.text.isEmpty || 
        _usernameController.text.isEmpty ||
        _roleController.text.isEmpty ||
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _roleController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'photoUrl': '',
          'bio': 'Student at VIT-AP',
        }, SetOptions(merge: true));

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1F3A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Verify Your Email", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text(
                "We have sent a verification link to ${_emailController.text}.\n\nPlease check your inbox (and spam folder) and verify your email before logging in.",
                style: GoogleFonts.inter(color: Colors.grey.shade300),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text("OK, I'll Check", style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
                  Text("Create Account", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("Join the student exchange community", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade400)),
                  const SizedBox(height: 32),
                  
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
                            _buildField("Full Name", Icons.person_rounded, _nameController),
                            const SizedBox(height: 16),
                            _buildField("Username", Icons.alternate_email, _usernameController),
                            const SizedBox(height: 16),
                            _buildField("Year & Branch", Icons.school_rounded, _roleController),
                            const SizedBox(height: 16),
                            _buildField("VIT Email", Icons.email, _emailController),
                            const SizedBox(height: 16),
                            _buildField("Password", Icons.lock_rounded, _passwordController, isPass: true),
                            const SizedBox(height: 24),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: BouncyTap(
                                onTap: _isLoading ? () {} : _handleSignup,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.accentGradientBrush,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                                  ),
                                  child: Center(
                                    child: _isLoading 
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text("Sign Up", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, IconData icon, TextEditingController controller, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
      ),
    );
  }
}