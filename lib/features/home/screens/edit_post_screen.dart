import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post_model.dart';
import '../services/database_service.dart';
import '../../../core/theme.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late TextEditingController _teachSkillController;
  late TextEditingController _learnSkillController;
  late TextEditingController _descriptionController;
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _teachSkillController = TextEditingController(text: widget.post.teachSkill);
    _learnSkillController = TextEditingController(text: widget.post.learnSkill);
    _descriptionController = TextEditingController(
      text: widget.post.description,
    );
  }

  @override
  void dispose() {
    _teachSkillController.dispose();
    _learnSkillController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    if (_teachSkillController.text.isEmpty ||
        _learnSkillController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _dbService.updatePost(
        widget.post.id,
        _teachSkillController.text,
        _learnSkillController.text,
        _descriptionController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Post updated successfully',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating post: $e', style: GoogleFonts.inter()),
          backgroundColor: Colors.red,
        ),
      );
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
          'Edit Post',
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
            // Teach Skill
            Text(
              'Skill You Teach',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _teachSkillController,
              decoration: InputDecoration(
                hintText: 'e.g., Python Programming',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 24),

            // Learn Skill
            Text(
              'Skill You Want to Learn',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _learnSkillController,
              decoration: InputDecoration(
                hintText: 'e.g., Web Design',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 24),

            // Description
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
                hintText: 'Add more details about your skills...',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 32),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePost,
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
                        'Update Post',
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
}
