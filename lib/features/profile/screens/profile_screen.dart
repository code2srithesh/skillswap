import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/theme.dart';
import '../../../core/theme_provider.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/animations.dart';
import 'edit_profile_screen.dart';
import 'developer_info_screen.dart';
import '../../home/screens/my_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  Future<Map<String, dynamic>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) return doc.data()!;
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }

    return {
      'uid': user.uid,
      'email': user.email ?? '',
      'name': 'Student',
      'username': 'user',
      'role': 'Student',
      'bio': '',
      'photoUrl': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final data = snapshot.data ?? {};
        final name = data['name']?.toString().isNotEmpty == true ? data['name'] : 'Student';
        final username = data['username']?.toString().isNotEmpty == true ? data['username'] : 'user';
        final role = data['role']?.toString().isNotEmpty == true ? data['role'] : 'Student';
        final photoUrl = data['photoUrl'];

        return PremiumBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Align(
              alignment: Alignment.topCenter,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Header
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: _buildProfileHeader(name, username, role, photoUrl, data),
                      ),
                    ),
                  ),

                  // 2. Stats
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: StreamBuilder<Map<String, dynamic>>(
                            stream: _getUserStats(),
                            builder: (context, statsSnapshot) {
                              final postsCount = statsSnapshot.data?['posts'] ?? '0';
                              final swapsCount = statsSnapshot.data?['swaps'] ?? '0';
                              return Row(
                                children: [
                                  Expanded(child: _buildStatGlass("Posts", postsCount, Icons.grid_view_rounded)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildStatGlass("Swaps", swapsCount, Icons.swap_calls_rounded)),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. MENU GRID
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: _buildMenuGrid(context),
                        ),
                      ),
                    ),
                  ),

                  // 4. Logout & Footer
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 40, 20, 120 + bottomPadding),
                      child: Column(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: BouncyTap(
                              onTap: () async {
                                await AuthService().signOut();
                                if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.red.withOpacity(0.05),
                                ),
                                child: Center(
                                  child: Text("Log Out", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildDeveloperFooter(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGETS ---

  Widget _buildMenuGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        final items = [
          _MenuOption(
            title: "My Posts",
            subtitle: "Manage listings",
            icon: Icons.layers_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPostsScreen())),
          ),
          _MenuOption(
            title: isDark ? "Light Mode" : "Dark Mode",
            subtitle: "Switch theme",
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
            isToggle: true,
            onTap: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
          ),
          _MenuOption(
            title: "About App",
            subtitle: "Version info",
            icon: Icons.info_outline_rounded,
            color: const Color(0xFF10B981),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperInfoScreen())),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisExtent: 180, // INCREASED HEIGHT (Fixes Overflow)
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildGridCard(items[index]);
          },
        );
      },
    );
  }

  Widget _buildGridCard(_MenuOption item) {
    return GlassCard(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.all(16), // REDUCED PADDING (Fixes Overflow)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(item.subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String username, String role, String? photoUrl, Map<String, dynamic> rawData) {
    return SizedBox(
      height: 450,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 450,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryColor.withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              ScaleInAnimation(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
                    boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 40, spreadRadius: 5)],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF1A1F3A),
                    backgroundImage: (photoUrl != null && photoUrl.startsWith('data:'))
                        ? MemoryImage(base64Decode(photoUrl.split(',')[1]))
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.white))
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(role, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Text("@$username", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ),
              const SizedBox(height: 24),
              BouncyTap(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(userData: rawData)));
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradientBrush,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Text("Edit Profile", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGlass(String label, String value, IconData icon) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperFooter() {
    return Column(
      children: [
        Text("DESIGNED & DEVELOPED BY", style: GoogleFonts.inter(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Text("Sritheshwar Rachakonda", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text("v1.0.0 • 2026", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Stream<Map<String, dynamic>> _getUserStats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value({'posts': '0', 'swaps': '0'});

    return FirebaseFirestore.instance
        .collection('posts')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .map((postsSnap) => {'posts': postsSnap.docs.length.toString(), 'swaps': '0'}); 
  }
}

class _MenuOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isToggle;

  _MenuOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isToggle = false,
  });
}