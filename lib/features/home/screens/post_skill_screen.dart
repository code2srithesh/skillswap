import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../../../core/theme.dart';

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
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get Current User
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please login first', style: GoogleFonts.inter()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Fetch User Details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';
      final role = userDoc.data()?['role'] ?? 'Student';

      // Save to Firestore
      await DatabaseService().createPost(
        user.uid,
        userName,
        role,
        _teachController.text.trim(),
        _learnController.text.trim(),
        _descriptionController.text.trim(),
        expiryDays: _selectedExpiryDays,
      );

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Post created successfully!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.inter()),
            backgroundColor: Colors.red,
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Share Your Skills',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teach Skill Section
            Text(
              'Skill You Can Teach',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _teachController,
              decoration: InputDecoration(
                hintText: 'e.g. Flutter, Python, Guitar, Photography',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.school_rounded,
                  color: AppTheme.successColor,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Learn Skill Section
            Text(
              'Skill You Want to Learn',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _learnController,
              decoration: InputDecoration(
                hintText: 'e.g. Web Design, Machine Learning, Piano',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.lightbulb_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Description Section
            Text(
              'Description (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Add more details about your skills and experience...',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Icon(
                    Icons.description_rounded,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Expiry Days Section
            Text(
              'Post Expiry (Optional - Max 7 Days)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: DropdownButton<int>(
                value: _selectedExpiryDays,
                isExpanded: true,
                underline: SizedBox(),
                items: [
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

            const SizedBox(height: 40),

            // Post Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Post Skill Request',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
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
