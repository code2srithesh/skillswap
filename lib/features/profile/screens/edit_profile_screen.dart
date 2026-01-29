import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _bioController;
  late TextEditingController _usernameController;

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  Uint8List? _webImage;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _roleController = TextEditingController(text: widget.userData['role']);
    _bioController = TextEditingController(text: widget.userData['bio'] ?? "");
    _usernameController = TextEditingController(
      text: widget.userData['username'] ?? "",
    );
    _photoUrl = widget.userData['photoUrl'];
  }

  // Check username availability
  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    setState(() => _isCheckingUsername = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      // If any user exists with this username, and it's not the current user
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final isTaken = snapshot.docs.any((doc) => doc.id != currentUid);

      setState(() {
        _usernameError = isTaken ? 'Username already taken' : null;
        _isCheckingUsername = false;
      });
    } catch (e) {
      setState(() {
        _usernameError = 'Error checking username';
        _isCheckingUsername = false;
      });
    }
  }

  // 1. Pick Image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Using simple gallery source with compression
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20, // KEEP THIS: Compresses image to avoid database limits
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _webImage = bytes;
      });
    }
  }

  // 2. The "Smart Hack": Convert Image to Text String
  String? _convertImageToBase64() {
    if (_webImage == null) return null;
    String base64String = base64Encode(_webImage!);
    return "data:image/jpeg;base64,$base64String";
  }

  // 3. Save to Database
  void _updateProfile() async {
    // Validate username if changed
    if (_usernameError != null && _usernameError!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_usernameError!)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Prepare basic data
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'role': _roleController.text.trim(),
        'bio': _bioController.text.trim(),
        'username': _usernameController.text.trim(),
      };

      // If a new image was picked, turn it into text and save it
      String? newImageString = _convertImageToBase64();
      if (newImageString != null) {
        updateData['photoUrl'] = newImageString;
      }

      // Update Firestore directly
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // IMAGE PICKER
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    // If we have a new pick, show it. If not, show existing URL.
                    backgroundImage: _webImage != null
                        ? MemoryImage(_webImage!)
                        : (_photoUrl != null &&
                              _photoUrl!.toString().startsWith('data:'))
                        ? MemoryImage(
                            base64Decode(_photoUrl!.toString().split(',')[1]),
                          ) // Decode stored text
                        : null,
                    child:
                        (_webImage == null &&
                            (_photoUrl == null || _photoUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              onChanged: _checkUsernameAvailability,
              decoration: InputDecoration(
                labelText: "Username",
                border: const OutlineInputBorder(),
                helperText: _usernameError,
                helperStyle: TextStyle(
                  color: _usernameError != null ? Colors.red : Colors.green,
                ),
                suffixIcon: _isCheckingUsername
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _usernameError == null &&
                          _usernameController.text.isNotEmpty
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: "Role/Year",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text("Save Changes"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
