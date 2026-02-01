import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/animations.dart'; // Ensure BouncyTap is imported

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _roleController;
  late TextEditingController _bioController;

  bool _isLoading = false;
  Uint8List? _webImage;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _usernameController = TextEditingController(text: widget.userData['username'] ?? '');
    _roleController = TextEditingController(text: widget.userData['role'] ?? '');
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    _photoUrl = widget.userData['photoUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 1. Pick Image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20, 
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webImage = bytes;
      });
    }
  }

  // 2. Remove Photo (NEW)
  void _removePhoto() {
    setState(() {
      _webImage = null; // Clear new image
      _photoUrl = "";   // Clear existing url reference
    });
  }

  // 3. Helper to Check if Photo Exists
  bool _hasPhoto() {
    return _webImage != null || (_photoUrl != null && _photoUrl!.isNotEmpty);
  }

  // 4. Convert Image to Base64
  String? _convertImageToBase64() {
    if (_webImage == null) return null;
    String base64String = base64Encode(_webImage!);
    return "data:image/jpeg;base64,$base64String";
  }

  // 5. Save to Database
  void _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final email = FirebaseAuth.instance.currentUser?.email;

      if (uid == null) {
        throw "User not logged in";
      }

      // Prepare data
      Map<String, dynamic> updateData = {
        'uid': uid,
        'email': email,
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'role': _roleController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Handle Image Logic
      if (_webImage != null) {
        // Case A: New image selected -> Save it
        updateData['photoUrl'] = _convertImageToBase64();
      } else if (_photoUrl == null || _photoUrl!.isEmpty) {
        // Case B: Photo was removed -> Clear it in DB
        updateData['photoUrl'] = "";
      }
      // Case C: No change -> Do nothing (keeps existing photo)

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
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
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("Edit Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // IMAGE PICKER SECTION
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryColor, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                            ]
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFF1A1F3A),
                            backgroundImage: _webImage != null
                                ? MemoryImage(_webImage!)
                                : (_photoUrl != null && _photoUrl!.startsWith('data:'))
                                    ? MemoryImage(base64Decode(_photoUrl!.split(',')[1]))
                                    : null,
                            child: !_hasPhoto()
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ACTION BUTTONS (Upload / Remove)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, color: Colors.white70, size: 18),
                        label: Text("Change Photo", style: GoogleFonts.inter(color: Colors.white70)),
                      ),
                      if (_hasPhoto()) ...[
                        const SizedBox(width: 16),
                        Container(width: 1, height: 20, color: Colors.white24),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          onPressed: _removePhoto,
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          label: Text("Remove", style: GoogleFonts.inter(color: Colors.redAccent)),
                        ),
                      ]
                    ],
                  ),

                  const SizedBox(height: 32),

                  _buildTextField("Full Name", _nameController),
                  const SizedBox(height: 16),
                  _buildTextField("Username (for login)", _usernameController, icon: Icons.alternate_email),
                  const SizedBox(height: 16),
                  _buildTextField("Role/Year", _roleController, icon: Icons.school),
                  const SizedBox(height: 16),
                  _buildTextField("Bio", _bioController, maxLines: 3, icon: Icons.info_outline),

                  const SizedBox(height: 32),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: BouncyTap(
                      onTap: _isLoading ? () {} : _updateProfile,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradientBrush,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Save Changes",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
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
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, IconData icon = Icons.edit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.7), size: 20),
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
        ),
      ],
    );
  }
}