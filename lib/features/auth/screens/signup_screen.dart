import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/premium_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController(); // Added Username
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  // Auto-fill VIT domain
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
      // 1. Create User
      User? user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // 2. Create Database Profile
        // IMPORTANT: Use set() with merge: true to avoid crashes
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

        // 3. Show Verification Dialog instead of going Home
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
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to Login Screen
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
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: BackButton(color: Colors.white)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                  Text("Create Account", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 32),
                  
                  _buildField("Full Name", Icons.person, _nameController),
                  const SizedBox(height: 16),
                  _buildField("Username", Icons.alternate_email, _usernameController),
                  const SizedBox(height: 16),
                  _buildField("Year & Branch", Icons.school, _roleController),
                  const SizedBox(height: 16),
                  _buildField("VIT Email", Icons.email, _emailController),
                  const SizedBox(height: 16),
                  _buildField("Password", Icons.lock, _passwordController, isPass: true),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Sign Up", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}