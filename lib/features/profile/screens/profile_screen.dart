import 'dart:convert'; // REQUIRED for decoding the image
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_service.dart';
import '../../messaging/screens/conversations_screen.dart';
import '../../messaging/services/messaging_service.dart';
import '../../../core/theme_provider.dart';
import '../../../core/theme.dart';
import 'edit_profile_screen.dart';
import '../../home/screens/my_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;
        final name = data?['name'] ?? 'Student';
        final username = data?['username'] ?? 'user';
        final role = data?['role'] ?? 'Unknown Role';
        final credits = data?['credits'] ?? 0;
        final photoUrl = data?['photoUrl'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 1. HEADER (Profile Pic)
              Center(
                child: Hero(
                  tag: 'profile_pic',
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF6C63FF),
                    // LOGIC: Check if it's a Base64 text string
                    backgroundImage:
                        (photoUrl != null &&
                            photoUrl.toString().startsWith('data:'))
                        ? MemoryImage(
                            base64Decode(photoUrl.toString().split(',')[1]),
                          )
                        : null,
                    child: (photoUrl == null || photoUrl.toString().isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // NAME AND EDIT BUTTON ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        role,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // THE EDIT BUTTON
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF6C63FF)),
                    onPressed: () {
                      if (data != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(userData: data),
                          ),
                        ).then((_) {
                          // Optional: formatting/refresh logic could go here
                        });
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // My Posts Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyPostsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.post_add_rounded),
                  label: Text(
                    'My Posts',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Messages Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConversationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_rounded),
                  label: Text(
                    'Messages',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // REQUESTS SECTION
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Pending Requests",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('requests')
                    .where(
                      'receiverUid',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                    )
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "No new requests.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text("${doc['senderName']} wants to swap"),
                          subtitle: Text(doc['message'] ?? 'No message'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  try {
                                    // Get sender's name and uid
                                    final senderDoc = await FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(doc['senderUid'])
                                        .get();
                                    final senderName =
                                        senderDoc['name'] ??
                                        doc['senderName'] ??
                                        'Unknown';

                                    // Update request status
                                    await doc.reference.update({
                                      'status': 'accepted',
                                    });

                                    // Initiate conversation with the first message from the request
                                    await MessagingService().initiateConversation(
                                      otherUserId: doc['senderUid'],
                                      otherUserName: senderName,
                                      initialMessage:
                                          doc['message'] ??
                                          'Hey! Let\'s start our skill swap!',
                                    );

                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Request accepted! Chat started.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  doc.reference.update({'status': 'rejected'});
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // 2. STATS ROW
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(credits.toString(), "Credits", Colors.green),
                    _buildContainerDivider(),
                    _buildStat("0", "Swaps", Colors.blue),
                    _buildContainerDivider(),
                    _buildStat("5.0", "Rating", Colors.orange),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. THEME SETTINGS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          Provider.of<ThemeProvider>(context).isDarkMode
                              ? "Dark Mode"
                              : "Light Mode",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    Switch(
                      value: Provider.of<ThemeProvider>(context).isDarkMode,
                      onChanged: (_) {
                        Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).toggleTheme();
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Log Out",
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildContainerDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade300);
  }
}
