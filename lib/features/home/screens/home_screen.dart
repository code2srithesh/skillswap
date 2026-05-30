import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/database_service.dart';
import 'post_skill_screen.dart';
import 'activity_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../messaging/screens/conversations_screen.dart';
import '../../skill_details/screens/skill_detail_screen.dart';
import '../../../core/theme.dart';
import '../../../core/animations.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/premium_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final DatabaseService _dbService = DatabaseService();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Stream<int> _getUnreadCount() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final unreadRaw = data['unread'] as Map?;
            final count = (unreadRaw?[currentUserId] as num?)?.toInt() ?? 0;
            total += count;
          }
          return total;
        });
  }

  Future<void> _refreshFeed() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine Body
    Widget currentBody;
    if (_selectedIndex == 0) {
      currentBody = _buildDiscoverFeed(isDark, screenWidth);
    } else if (_selectedIndex == 1) {
      currentBody = const ActivityScreen();
    } else if (_selectedIndex == 2) {
      currentBody = const ConversationsScreen();
    } else if (_selectedIndex == 3) {
      currentBody = const ProfileScreen();
    } else {
      currentBody = Container();
    }

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true, // Allows content to flow behind the dock
        body: Stack(
          alignment: Alignment.center,
          children: [
            // LAYER 1: Full Screen Content
            Positioned.fill(
              child: currentBody,
            ),

            // LAYER 2: Floating Dock (Centered & Responsive)
            Positioned(
              bottom: 30,
              left: 20, 
              right: 20,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _buildFloatingDock(isDark),
                ),
              ),
            ),

            // LAYER 3: FAB (Responsive Position)
            if (_selectedIndex == 0)
              Positioned(
                bottom: 110,
                right: screenWidth > 600 ? 50 : 20, // Adjust padding for web
                child: _buildGradientFAB(),
              ),
          ],
        ),
      ),
    );
  }

  // --- RESPONSIVE FEED ---
  Widget _buildDiscoverFeed(bool isDark, double screenWidth) {
    return RefreshIndicator(
      onRefresh: _refreshFeed,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header (Full Width)
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _buildPremiumHeader(isDark),
              ),
            ),
          ),

          // 2. Responsive Grid Posts
          StreamBuilder<List<PostModel>>(
            stream: _dbService.getPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState());
              }

              final posts = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400, // Cards will be max 400px wide
                    mainAxisExtent: 200,     // Fixed height for consistency
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return StaggeredItem(
                        index: index,
                        child: _buildGridCard(post, context),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(PostModel post, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SkillDetailScreen(post: post)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: User
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.accentGradientBrush,
                  ),
                  child: Center(
                    child: Text(
                      post.userName.isNotEmpty ? post.userName[0].toUpperCase() : "?",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.userName, 
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, 
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        post.role, 
                        style: GoogleFonts.inter(
                          fontSize: 11, 
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Middle: Skills
            Column(
              children: [
                _buildSkillRow("TEACHES", post.teachSkill, const Color(0xFF10B981), isDark),
                const SizedBox(height: 8),
                _buildSkillRow("LEARNS", post.learnSkill, const Color(0xFF8B5CF6), isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillRow(String label, String skill, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            label, 
            style: GoogleFonts.outfit(
              fontSize: 9, 
              fontWeight: FontWeight.w800, 
              color: isDark ? color.withOpacity(0.9) : color,
              letterSpacing: 0.5,
            )
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            skill, 
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, 
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // --- DOCK, FAB, HEADER (Same as before but responsive constraints handled by parent) ---
  
  Widget _buildFloatingDock(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF1A1F3A).withOpacity(0.85) 
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.explore_rounded, Icons.explore_outlined),
              _buildNavItem(1, Icons.notifications_rounded, Icons.notifications_outlined),
              _buildNavItem(2, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, isInbox: true),
              _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, {bool isInbox = false}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: isSelected 
            ? BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade500,
              size: 26,
            ),
            if (isInbox)
              StreamBuilder<int>(
                stream: _getUnreadCount(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == 0) return const SizedBox();
                  return Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientFAB() {
    return BouncyTap(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostSkillScreen()),
        );
      },
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradientBrush,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildPremiumHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.accentGradientBrush.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            child: Text(
              "Discover Swaps",
              style: GoogleFonts.outfit(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Connect with top minds & barter your expertise seamlessly.",
            style: GoogleFonts.inter(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.dashboard_customize_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("No Posts Yet", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}