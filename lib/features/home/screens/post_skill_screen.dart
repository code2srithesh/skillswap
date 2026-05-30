import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../../../core/theme.dart';
import '../../../core/animations.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/glass_card.dart';

class PostSkillScreen extends StatefulWidget {
  const PostSkillScreen({super.key});

  @override
  State<PostSkillScreen> createState() => _PostSkillScreenState();
}

class _PostSkillScreenState extends State<PostSkillScreen> {
  final _teachController = TextEditingController();
  final _learnController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  int _selectedExpiryDays = 0; // 0 = no expiry

  void _handlePost() async {
    if (_teachController.text.isEmpty || _learnController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please login first', style: GoogleFonts.inter()),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';
      final role = userDoc.data()?['role'] ?? 'Student';

      await DatabaseService().createPost(
        user.uid,
        userName,
        role,
        _teachController.text.trim(),
        _learnController.text.trim(),
        _descriptionController.text.trim(),
        expiryDays: _selectedExpiryDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Post created successfully!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Share Your Skills',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Teach Skill Section
                    Text(
                      'Skill You Can Teach',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _teachController,
                      hint: 'e.g. Flutter, Python, Guitar, Photography',
                      icon: Icons.school_rounded,
                      iconColor: AppTheme.successColor,
                    ),

                    const SizedBox(height: 24),

                    // Learn Skill Section
                    Text(
                      'Skill You Want to Learn',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _learnController,
                      hint: 'e.g. Web Design, Machine Learning, Piano',
                      icon: Icons.lightbulb_rounded,
                      iconColor: AppTheme.primaryColor,
                    ),

                    const SizedBox(height: 24),

                    // Description Section
                    Text(
                      'Description (Optional)',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _descriptionController,
                      hint: 'Add more details about your skills and experience...',
                      icon: Icons.description_rounded,
                      iconColor: AppTheme.accentColor,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 24),

                    // Expiry Days Section
                    Text(
                      'Post Expiry (Optional - Max 7 Days)',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedExpiryDays,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                          items: const [
                            DropdownMenuItem(
                              value: 0,
                              child: Text('No Expiry (Post Never Expires)'),
                            ),
                            DropdownMenuItem(value: 1, child: Text('1 Day')),
                            DropdownMenuItem(value: 3, child: Text('3 Days')),
                            DropdownMenuItem(value: 7, child: Text('7 Days')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedExpiryDays = value);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Post Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: BouncyTap(
                        onTap: _isLoading ? () {} : _handlePost,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradientBrush,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Post Skill Request',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: iconColor.withOpacity(0.7), size: 20),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _teachController.dispose();
    _learnController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
